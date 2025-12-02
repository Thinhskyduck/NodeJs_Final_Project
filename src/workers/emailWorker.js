// src/workers/emailWorker.js
const amqp = require('amqplib');
const dotenv = require('dotenv');
const { sendOrderConfirmationEmail, sendNewUserPasswordEmail } = require('../utils/emailService');

dotenv.config();

const startEmailWorker = async () => {
  try {
    // Dùng tên service 'rabbitmq' trong docker-compose hoặc localhost nếu chạy ngoài
    const amqpServer = process.env.RABBITMQ_URI || 'amqp://rabbitmq:5672';
    
    console.log(`⏳ Worker connecting to RabbitMQ at ${amqpServer}...`);
    
    const connection = await amqp.connect(amqpServer);
    const channel = await connection.createChannel();
    
    await channel.assertQueue('email_queue');
    console.log('✅ Email Worker connected and waiting for messages...');

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
          
          channel.ack(data);
        } catch (err) {
          console.error('Worker Processing Error:', err);
          // Không ack để xử lý lại sau hoặc log vào dead letter queue
        }
      }
    });

    // Xử lý khi mất kết nối đột ngột
    connection.on('close', () => {
        console.error('RabbitMQ connection closed. Reconnecting...');
        setTimeout(startEmailWorker, 5000);
    });

  } catch (error) {
    console.error('❌ Worker connection failed:', error.message);
    console.log('🔄 Retrying in 5 seconds...');
    // Đợi 5 giây rồi gọi lại hàm này
    setTimeout(startEmailWorker, 5000);
  }
};

startEmailWorker();