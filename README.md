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

- [LocalStack Auth Token](https://docs.localstack.cloud/getting-started/auth-token/)
- [Serverless Application Model](https://docs.localstack.cloud/user-guide/integrations/aws-sam/) with the [`samlocal`](https://github.com/localstack/aws-sam-cli-local) installed.
- [AWS CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/) with the [`awslocal` wrapper](https://docs.localstack.cloud/user-guide/integrations/aws-cli/#localstack-aws-cli-awslocal).
- [Python 3.10](https://www.python.org/downloads/) & `pip`
- [Docker Compose](https://docs.docker.com/compose/install/)

Start LocalStack Pro with the `LOCALSTACK_AUTH_TOKEN` pre-configured:

```shell
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
docker-compose up
```

The Docker Compose file will start LocalStack Pro and a local Neo4j database. The `LOCALSTACK_AUTH_TOKEN` environment variable is required to activate the LocalStack Pro features, such as Lambda Layers in this example.

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
samlocal build
```

If you see a `Build Succeeded` message, you can proceed to the next step.


### Deploying the application

To deploy the SAM application, run the following command:

```shell
samlocal deploy --guided
```

The above command will create a new managed S3 bucket to store the artifacts of the SAM application. If you want to use an existing S3 bucket, you can use the `--s3-bucket` flag to specify the bucket name. Before being deployed, the CloudFormation changeset will be displayed in the terminal. If you want to deploy the application without confirmation, you can use the `--no-confirm-changeset` flag.

### Updating the Lambda function configuration

You need to update the Lambda function configuration to use the Neo4j environment variables. You can do this by running the following command:

```shell
export NEO4J_PASSWORD=neo4j-harsh-test
export NEO4J_URI=bolt://neo4j:7687
export NEO4J_USERNAME=neo4j
FUNCTION=$(awslocal cloudformation describe-stack-resource --stack-name sam-app --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
awslocal lambda update-function-configuration \
    --function-name $FUNCTION \
    --environment "Variables={NEO4J_USERNAME=$NEO4J_USERNAME,NEO4J_PASSWORD=$NEO4J_PASSWORD,NEO4J_URI=$NEO4J_URI}"
```

### Invoking the Lambda function

You can invoke the Lambda function using the following command:

```shell
awslocal lambda invoke \
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

### Cleaning up

To clean up the resources created by the SAM application, run the following command:

```shell
docker-compose down
```

LocalStack is ephemeral, and all the resources will be deleted once the LocalStack process is stopped.

### GitHub Action

This application sample hosts an example GitHub Action workflow that starts up LocalStack, builds the Lambda functions, and deploys the infrastructure on the runner. 

You can find the workflow in the `.github/workflows/main.yml` file. To run the workflow, you can fork this repository and push a commit to the `main` branch.

## License

[Apache 2.0](./LICENSE)
