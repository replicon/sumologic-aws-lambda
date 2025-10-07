const { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } = require("@aws-sdk/client-sqs");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");

class Messages {
  constructor(env) {
    const sqsConfig = { region: env.AWS_REGION };

    // Disable MD5 checksum if environment variable is set
    if (env.DISABLE_MD5 === 'true') {
      sqsConfig.md5 = false;
    }

    this.sqs = new SQSClient(sqsConfig);
    this.env = env;
  }

  async receiveMessages(messageCount) {
    const params = {
      QueueUrl: this.env.TASK_QUEUE_URL,
      MaxNumberOfMessages: messageCount,
    };

    const command = new ReceiveMessageCommand(params);
    const response = await this.sqs.send(command);
    return response.Messages || [];
  }

  async deleteMessage(receiptHandle) {
    const params = {
      ReceiptHandle: receiptHandle,
      QueueUrl: this.env.TASK_QUEUE_URL,
    };

    const command = new DeleteMessageCommand(params);
    await this.sqs.send(command);
  }
}

async function invokeLambdas(awsRegion, numOfWorkers, functionName, payload, context) {
  const lambda = new LambdaClient({ region: awsRegion });

  for (let i = 0; i < numOfWorkers; i++) {
    const command = new InvokeCommand({
      InvocationType: 'Event',
      FunctionName: functionName,
      Payload: payload,
    });

    try {
      await lambda.send(command);
      context.succeed('success');
    } catch (err) {
      context.fail(err);
    }
  }
}

module.exports = {
  Messages,
  invokeLambdas,
};