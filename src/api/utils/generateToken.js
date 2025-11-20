// src/api/utils/generateToken.js

const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d', // Token sẽ hết hạn sau 30 ngày
  });
};

module.exports = generateToken;