// src/config/rabbitmq.js
const amqp = require('amqplib');

let channel = null;

const connectRabbitMQ = async () => {
  try {
    const amqpServer = process.env.RABBITMQ_URI || 'amqp://rabbitmq:5672';
    console.log(`⏳ Backend connecting to RabbitMQ...`);
    
    const connection = await amqp.connect(amqpServer);
    channel = await connection.createChannel();
    await channel.assertQueue('email_queue');
    
    console.log('✅ Backend connected to RabbitMQ');
    
    connection.on('close', () => {
        console.error('RabbitMQ connection closed. Reconnecting...');
        setTimeout(connectRabbitMQ, 5000);
    });

  } catch (error) {
    console.error('❌ RabbitMQ Backend Connection Failed:', error.message);
    console.log('🔄 Backend retrying in 5 seconds...');
    setTimeout(connectRabbitMQ, 5000);
  }
};

const sendToQueue = async (queueName, data) => {
  if (!channel) {
    // Nếu chưa có kết nối, thử kết nối lại (nhưng không chặn luồng chính quá lâu)
    console.warn('RabbitMQ channel not ready, attempting to reconnect...');
    await connectRabbitMQ();
  }
  
  if (channel) {
      try {
        channel.sendToQueue(queueName, Buffer.from(JSON.stringify(data)));
        console.log(`📩 Sent to ${queueName}`);
      } catch (error) {
        console.error('Error sending message:', error);
      }
  } else {
      console.error('Cannot send message: RabbitMQ is offline.');
  }
};

// Gọi kết nối ngay khi file được load
connectRabbitMQ();

module.exports = { connectRabbitMQ, sendToQueue };