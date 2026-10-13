# Integrating a local Lambda function with Neo4j using LocalStack

| Key          | Value                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------- |
| Environment  | LocalStack, AWS                                                                                    |
| Services     | Lambda, CloudWatch                                                           |
| Integrations | SAM                                                                                           |
| Categories   | Serverless; Databases                                       |
| Level        | Beginner                                                                                      |
| GitHub       | [Repository link](https://github.com/localstack-samples/sample-lambda-neo4j) |

## Introduction

This sample application will guide you through the process of integrating a local Lambda function with a local Neo4j database using LocalStack. We will use the Serverless Application Model (SAM) to deploy the Lambda function and spin a local Neo4j database using Docker. We will also use the AWS CLI to invoke the Lambda function and execute a sample query on the Neo4j database.

## Prerequisites

- LocalStack with the [`lstk` CLI](https://docs.localstack.cloud/aws/developer-tools/running-localstack/lstk/).
- [Serverless Application Model](https://docs.localstack.cloud/user-guide/integrations/aws-sam/) with `aws-sam-cli` installed, used via the `lstk sam` proxy.
- [AWS CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/), required by `lstk aws`.
- [Python 3.12](https://www.python.org/downloads/) & `pip`, matching the Lambda runtime for `sam build`
- [Docker Compose](https://docs.docker.com/compose/install/)
- A valid [LocalStack for AWS license](https://localstack.cloud/pricing). Your license provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/aws/getting-started/auth-token/) to activate LocalStack.

Start LocalStack Pro with the `LOCALSTACK_AUTH_TOKEN` pre-configured:

```shell
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
make start
```

The Docker Compose file will start LocalStack Pro and a local Neo4j database on a shared network, and `make start` waits until both are ready. The `LOCALSTACK_AUTH_TOKEN` environment variable is required to activate the LocalStack Pro features, such as Lambda Layers in this example.

## Instructions

### Installing the dependencies

You can install the dependencies using the following command:

```shell
cd function
pip install --target ../package/python -r requirements.txt
```

### Building the application

To build the SAM application, run the following command from the root directory of the application:

```shell
lstk sam build
```

If you see a `Build Succeeded` message, you can proceed to the next step.


### Deploying the application

To deploy the SAM application, run the following command:

```shell
lstk sam deploy --no-confirm-changeset
```

`samconfig.toml` deploys the `sam-app` stack and lets SAM create a managed S3 bucket for the artifacts. `make deploy` runs the install, build and deploy steps in one go.

The function reads the Neo4j connection from the `NEO4J_URI`, `NEO4J_USERNAME` and `NEO4J_PASSWORD` environment variables. The template sets them from parameters whose defaults match the Docker Compose setup (`bolt://neo4j:7687`, `neo4j`, `neo4j-harsh-test`). To use another database, override them:

```shell
lstk sam deploy --no-confirm-changeset \
    --parameter-overrides Neo4jUri=bolt://my-host:7687 Neo4jUsername=neo4j Neo4jPassword=my-password
```

### Invoking the Lambda function

You can invoke the Lambda function using the following command:

```shell
FUNCTION=$(lstk aws cloudformation describe-stack-resource --stack-name sam-app --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
lstk aws lambda invoke \
    --function-name $FUNCTION \
    --payload file://event.json \
    --cli-binary-format raw-in-base64-out out.json
```

The following output would be displayed in the terminal:

```json
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```

You can see the following in the `out.json` file:

```json
{"TotalCodeSize": 29662331, "FunctionCount": 1}
```

The function also stores the event as a `LambdaEvent` node in Neo4j. You can see it with `cypher-shell`:

```shell
docker exec neo4j cypher-shell -u neo4j -p neo4j-harsh-test \
    "MATCH (e:LambdaEvent) RETURN e.created ORDER BY e.created DESC LIMIT 5"
```

### Testing the application

`make test` invokes the function with a uniquely tagged event, checks it returns the account usage, and checks Neo4j has exactly one `LambdaEvent` node for that event.

### Cleaning up

To clean up the resources created by the SAM application, run the following command:

```shell
make stop
```

LocalStack is ephemeral, and all the resources will be deleted once the LocalStack process is stopped.

### GitHub Action

This application sample hosts an example GitHub Action workflow that starts LocalStack and Neo4j with Docker Compose, builds and deploys the SAM application, and runs `make test` on the runner.

You can find the workflow in the `.github/workflows/main.yml` file. To run the workflow, you can fork this repository and push a commit to the `main` branch.

## License

[Apache 2.0](./LICENSE)
