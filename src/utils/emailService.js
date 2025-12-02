// src/utils/emailService.js
const nodemailer = require('nodemailer');
const dotenv = require('dotenv');

dotenv.config(); 

// --- DEBUG: In ra xem có đọc được không (Xóa sau khi sửa xong) ---
console.log("Email User:", process.env.EMAIL_USERNAME);
console.log("Email Pass:", process.env.EMAIL_PASSWORD ? "Đã có mật khẩu" : "Chưa có mật khẩu");

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USERNAME,
        pass: process.env.EMAIL_PASSWORD,
    },
});

// 1. Email xác nhận đơn hàng
const sendOrderConfirmationEmail = async (userEmail, order) => {
  const mailOptions = {
    from: `TDTU Computer Shop <${process.env.EMAIL_USERNAME}>`,
    to: userEmail,
    subject: `[TDTU Shop] Xác nhận đơn hàng #${order._id}`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2 style="color: #3F51B5;">Cảm ơn bạn đã đặt hàng!</h2>
        <p>Xin chào,</p>
        <p>Đơn hàng <strong>#${order._id}</strong> của bạn đã được đặt thành công.</p>
        
        <h3>Chi tiết đơn hàng:</h3>
        <ul>
          ${order.orderItems
            .map(
              (item) =>
                `<li><strong>${item.name}</strong> x ${item.quantity} - ${item.price.toLocaleString('vi-VN')}đ</li>`
            )
            .join('')}
        </ul>
        
        <p style="font-size: 16px;"><strong>Tổng thanh toán: <span style="color: red;">${order.totalPrice.toLocaleString('vi-VN')}đ</span></strong></p>
        <hr/>
        <p>Chúng tôi sẽ sớm liên hệ để giao hàng.</p>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Order confirmation email sent to', userEmail);
  } catch (error) {
    console.error('Error sending order email:', error);
  }
};

// 2. Email Reset Password
const sendResetPasswordEmail = async (email, resetUrl) => {
  const mailOptions = {
    from: `TDTU Computer Shop <${process.env.EMAIL_USERNAME}>`,
    to: email,
    subject: '[TDTU Shop] Yêu cầu đặt lại mật khẩu',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2>Bạn đã yêu cầu đặt lại mật khẩu</h2>
        <p>Vui lòng nhấn vào nút bên dưới để đặt lại mật khẩu (Link hết hạn sau 10 phút):</p>
        <a href="${resetUrl}" style="background-color: #3F51B5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Đặt lại mật khẩu</a>
        <p style="margin-top: 20px;">Hoặc copy link này: ${resetUrl}</p>
        <p>Nếu bạn không yêu cầu điều này, vui lòng bỏ qua email này.</p>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Reset password email sent to', email);
  } catch (error) {
    console.error('Error sending reset email:', error);
  }
};

// 3. Email gửi mật khẩu cho Guest (QUAN TRỌNG)
const sendNewUserPasswordEmail = async (userEmail, password) => {
  const mailOptions = {
    from: `TDTU Computer Shop <${process.env.EMAIL_USERNAME}>`,
    to: userEmail,
    subject: '[TDTU Shop] Thông tin tài khoản của bạn',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #2E7D32;">Chào mừng bạn đến với TDTU Shop!</h2>
        <p>Vì bạn đã đặt hàng mà chưa có tài khoản, hệ thống đã tự động tạo một tài khoản cho bạn để bạn dễ dàng theo dõi đơn hàng.</p>
        
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p><strong>Email đăng nhập:</strong> ${userEmail}</p>
            <p><strong>Mật khẩu tạm thời:</strong> <span style="font-size: 18px; color: #D32F2F; font-weight: bold;">${password}</span></p>
        </div>

        <p>Vui lòng đăng nhập và đổi mật khẩu ngay sau khi nhận được email này để bảo mật tài khoản.</p>
        <a href="${process.env.FRONTEND_URL || '#'}" style="color: #3F51B5;">Truy cập Website ngay</a>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('New user password email sent to', userEmail);
  } catch (error) {
    console.error('Error sending new user email:', error);
  }
};


module.exports = {
  sendOrderConfirmationEmail,
  sendResetPasswordEmail,
  sendNewUserPasswordEmail,
};