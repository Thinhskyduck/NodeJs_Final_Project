// src/workers/emailWorker.js
const amqp = require('amqplib');
const dotenv = require('dotenv');
const { sendOrderConfirmationEmail, sendNewUserPasswordEmail } = require('../utils/emailService');

dotenv.config();

const startEmailWorker = async () => {
  try {
    const amqpServer = process.env.RABBITMQ_URI || 'amqp://localhost:5672';
    const connection = await amqp.connect(amqpServer);
    const channel = await connection.createChannel();
    
    await channel.assertQueue('email_queue');
    console.log('👷 Email Worker is running and waiting for messages...');

    channel.consume('email_queue', async (data) => {
      if (data) {
        const message = JSON.parse(data.content.toString());
        console.log('📥 Worker received task:', message.type);

        try {
          if (message.type === 'ORDER_CONFIRMATION') {
            await sendOrderConfirmationEmail(message.email, message.order);
          } else if (message.type === 'NEW_USER_PASSWORD') {
            await sendNewUserPasswordEmail(message.email, message.password);
          }
          
          // Báo cho RabbitMQ biết đã xử lý xong, có thể xóa tin nhắn
          channel.ack(data);
        } catch (err) {
          console.error('Worker Error:', err);
          // Nếu lỗi, có thể không ack để RabbitMQ gửi lại sau (tùy logic)
        }
      }
    });
  } catch (error) {
    console.error('Worker failed to start:', error);
  }
};

startEmailWorker();