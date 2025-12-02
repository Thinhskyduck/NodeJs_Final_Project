# Sử dụng Node.js version 18
FROM node:20-alpine

# Tạo thư mục làm việc trong container
WORKDIR /app

# Copy file package.json trước để tận dụng cache của Docker
COPY package.json package-lock.json ./

# Cài đặt thư viện
RUN npm install

# Copy toàn bộ code vào container
COPY . .

# Mở port 5000
EXPOSE 5000

# Lệnh chạy mặc định
CMD ["npm", "run", "dev"]