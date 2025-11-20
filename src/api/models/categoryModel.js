// src/api/models/categoryModel.js

const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    slug: { // Dùng cho URL thân thiện, vd: /categories/laptop-gaming
      type: String,
      unique: true,
      lowercase: true,
    },
  },
  { timestamps: true }
);

const Category = mongoose.model('Category', categorySchema);
module.exports = Category;