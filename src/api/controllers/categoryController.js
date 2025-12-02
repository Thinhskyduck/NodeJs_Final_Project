// src/api/controllers/categoryController.js

const Category = require('../models/categoryModel');

// @desc    Tạo category mới
// @route   POST /api/categories
// @access  Private/Admin
const createCategory = async (req, res) => {
  const { name } = req.body;
  const slug = name.toLowerCase().split(' ').join('-'); // vd: "Laptop Gaming" -> "laptop-gaming"

  try {
    const categoryExists = await Category.findOne({ name });
    if (categoryExists) {
      return res.status(400).json({ message: 'Danh mục đã tồn tại' });
    }

    const category = await Category.create({ name, slug });
    res.status(201).json(category);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy tất cả categories
// @route   GET /api/categories
// @access  Public
const getCategories = async (req, res) => {
  try {
    const categories = await Category.find({});
    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Cập nhật category
// @route   PUT /api/categories/:id
// @access  Private/Admin
const updateCategory = async (req, res) => {
  const { name } = req.body;
  const slug = name ? name.toLowerCase().split(' ').join('-') : undefined;

  try {
    const category = await Category.findById(req.params.id);

    if (category) {
      category.name = name || category.name;
      category.slug = slug || category.slug;
      const updatedCategory = await category.save();
      res.json(updatedCategory);
    } else {
      res.status(404).json({ message: 'Không tìm thấy danh mục' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};


// @desc    Xóa category
// @route   DELETE /api/categories/:id
// @access  Private/Admin
const deleteCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (category) {
      // (Nâng cao) Cần kiểm tra xem có sản phẩm nào đang dùng category này không trước khi xóa
      // const productInCategory = await Product.findOne({ category: req.params.id });
      // if (productInCategory) {
      //   return res.status(400).json({ message: 'Không thể xóa danh mục đang được sử dụng' });
      // }
      await category.deleteOne(); // hoặc category.remove() tùy phiên bản mongoose
      res.json({ message: 'Danh mục đã được xóa' });
    } else {
      res.status(404).json({ message: 'Không tìm thấy danh mục' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};


module.exports = {
  createCategory,
  getCategories,
  updateCategory,
  deleteCategory,
};