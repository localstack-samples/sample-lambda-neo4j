export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

usage:		## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

install:	## Install dependencies
	@which lstk || npm install -g @localstack/lstk
	@which aws || pip install awscli
	@which sam || pip install aws-sam-cli

start:		## Start LocalStack and Neo4j using Docker Compose, and wait until both are ready
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set. Find your token at https://app.localstack.cloud/workspace/auth-token"; exit 1)
	@LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) docker compose up -d
	@for i in $$(seq 1 60); do curl -sf localhost:4566/_localstack/health > /dev/null && break; sleep 2; done
	@curl -sf localhost:4566/_localstack/health > /dev/null || (echo "LocalStack did not become ready"; exit 1)
	@for i in $$(seq 1 60); do docker exec neo4j cypher-shell -u neo4j -p neo4j-harsh-test "RETURN 1" > /dev/null 2>&1 && break; sleep 2; done
	@docker exec neo4j cypher-shell -u neo4j -p neo4j-harsh-test "RETURN 1" > /dev/null || (echo "Neo4j did not become ready"; exit 1)
	@echo "LocalStack and Neo4j are ready"

stop:		## Stop LocalStack and Neo4j
	@docker compose down

logs:		## Save the logs in a separate file
	@lstk logs > logs.txt

deploy:		## Build and deploy the SAM application
	cd function && pip install --target ../package/python -r requirements.txt
	lstk sam build
	lstk sam deploy --no-confirm-changeset

test:		## Invoke the function and check it wrote to Neo4j
	./test.sh

.PHONY: usage install start stop logs deploy test
