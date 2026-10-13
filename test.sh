#!/bin/bash
# Invoke the Lambda function with a uniquely tagged event, then check:
# 1. the invocation succeeds and returns the Lambda account usage
# 2. the function wrote the event as a LambdaEvent node to Neo4j
set -euo pipefail

STACK_NAME=${STACK_NAME:-sam-app}
NEO4J_CONTAINER=${NEO4J_CONTAINER:-neo4j}
NEO4J_USERNAME=${NEO4J_USERNAME:-neo4j}
NEO4J_PASSWORD=${NEO4J_PASSWORD:-neo4j-harsh-test}
MARKER="ci-$(date +%s)-$RANDOM"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

FUNCTION=$(lstk aws cloudformation describe-stack-resource --stack-name "$STACK_NAME" \
  --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
echo "Function: $FUNCTION"

jq --arg marker "$MARKER" '. + {testMarker: $marker}' event.json > "$WORKDIR/event.json"

result=$(lstk aws lambda invoke --function-name "$FUNCTION" \
  --payload "file://$WORKDIR/event.json" --cli-binary-format raw-in-base64-out \
  --cli-read-timeout 300 --query '[StatusCode, FunctionError]' --output text "$WORKDIR/out.json")
echo "Invocation: $result"
echo "Response: $(cat "$WORKDIR/out.json")"
if [ "$(echo "$result" | awk '{print $1}')" != "200" ] || [ "$(echo "$result" | awk '{print $2}')" != "None" ]; then
  echo "Test failed: the invocation returned '$result'"
  exit 1
fi
if ! jq -e '.FunctionCount >= 1 and .TotalCodeSize > 0' "$WORKDIR/out.json" > /dev/null; then
  echo "Test failed: the response is not the Lambda account usage"
  exit 1
fi
echo "PASS: the function returned the Lambda account usage"

count=$(docker exec "$NEO4J_CONTAINER" cypher-shell -u "$NEO4J_USERNAME" -p "$NEO4J_PASSWORD" --format plain \
  "MATCH (e:LambdaEvent) WHERE e.event CONTAINS '$MARKER' RETURN count(e)" | tail -1)
if [ "$count" != "1" ]; then
  echo "Test failed: expected 1 LambdaEvent node with marker $MARKER in Neo4j, found '$count'"
  exit 1
fi
echo "PASS: the event was written to Neo4j as a LambdaEvent node"

echo "Test passed: the Lambda function wrote to Neo4j"
