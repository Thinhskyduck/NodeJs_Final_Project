// src/config/swagger.js

const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'E-commerce API for TDTU Final Project',
      version: '1.0.0',
      description: 'API documentation for the e-commerce website project.',
    },
    servers: [
      {
        url: 'http://localhost:5000/api', // URL base của API
      },
    ],
    // Thêm components để định nghĩa Bearer token (JWT)
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ],
  },
  // Đường dẫn đến các file chứa API routes của bạn
  apis: ['./src/api/routes/*.js'], 
};

const specs = swaggerJsdoc(options);

const setupSwagger = (app) => {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
};

module.exports = setupSwagger;