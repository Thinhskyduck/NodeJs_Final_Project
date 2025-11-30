// src/config/rabbitmq.js
const amqp = require('amqplib');

let channel = null;

const connectRabbitMQ = async () => {
  try {
    // Dùng biến môi trường hoặc mặc định localhost
    const amqpServer = process.env.RABBITMQ_URI || 'amqp://localhost:5672';
    const connection = await amqp.connect(amqpServer);
    channel = await connection.createChannel();
    await channel.assertQueue('email_queue');
    console.log('✅ Connected to RabbitMQ');
  } catch (error) {
    console.error('❌ RabbitMQ Connection Failed:', error.message);
    // Retry logic could be added here
  }
};

const sendToQueue = async (queueName, data) => {
  if (!channel) {
    await connectRabbitMQ();
  }
  try {
    channel.sendToQueue(queueName, Buffer.from(JSON.stringify(data)));
    console.log(`📩 Sent to ${queueName}:`, data);
  } catch (error) {
    console.error('Error sending to queue:', error);
  }
};

module.exports = { connectRabbitMQ, sendToQueue };