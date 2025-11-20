// server.js
const http = require('http');
const { Server } = require('socket.io'); // Import Socket.io
const app = require('./app');

const PORT = process.env.PORT || 5000;

// 1. Tạo HTTP Server từ Express App
const server = http.createServer(app);

// 2. Khởi tạo Socket.io
const io = new Server(server, {
  cors: {
    origin: '*', // Cho phép mọi Frontend kết nối (Sửa lại thành domain cụ thể khi deploy)
    methods: ['GET', 'POST'],
  },
});

// 3. Lắng nghe kết nối
io.on('connection', (socket) => {
  console.log(`⚡ New Client Connected: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

// 4. Lưu biến 'io' vào 'app' để dùng được trong Controllers
app.set('socketio', io);

// 5. Thay app.listen thành server.listen
server.listen(PORT, () => {
  console.log(`Server is running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
  console.log(`Socket.io is ready!`);
});