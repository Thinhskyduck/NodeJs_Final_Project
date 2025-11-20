// src/api/controllers/productController.js

const Product = require('../models/productModel');
const Category = require('../models/categoryModel'); // Cần để kiểm tra category

// @desc    Tạo sản phẩm mới
// @route   POST /api/products
// @access  Private/Admin
const createProduct = async (req, res) => {
  try {
    const { name, description, brand, category, images, variants } = req.body;

    // Validate dữ liệu cơ bản
    if (!name || !description || !brand || !category || !images || !variants) {
      return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin sản phẩm' });
    }
    
    // Yêu cầu của đề bài: phải có ít nhất 2 variants
    if (!Array.isArray(variants) || variants.length < 2) {
        return res.status(400).json({ message: 'Sản phẩm phải có ít nhất 2 biến thể (variants)' });
    }

    // Kiểm tra xem category có tồn tại không
    const categoryExists = await Category.findById(category);
    if (!categoryExists) {
      return res.status(400).json({ message: 'Danh mục không hợp lệ' });
    }

    const product = new Product({
      name,
      description,
      brand,
      category,
      images,
      variants,
      user: req.user._id, // Lưu lại admin nào đã tạo sản phẩm này
    });

    const createdProduct = await product.save();
    res.status(201).json(createdProduct);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy tất cả sản phẩm (hỗ trợ phân trang, lọc, sắp xếp)
// @route   GET /api/products
// @access  Public
const getProducts = async (req, res) => {
  try {
    // 1. LỌC (FILTERING)
    // Tạo một bản sao của req.query để không làm thay đổi object gốc
    const queryObj = { ...req.query };

    // Loại bỏ các trường đặc biệt ra khỏi query để xử lý riêng
    const excludedFields = ['page', 'sort', 'limit', 'fields', 'keyword'];
    excludedFields.forEach((el) => delete queryObj[el]);

    // Lọc nâng cao cho khoảng giá (gte, gt, lte, lt)
    // Ví dụ: /api/products?price[gte]=10000000&price[lte]=20000000
    let queryStr = JSON.stringify(queryObj);
    queryStr = queryStr.replace(/\b(gte|gt|lte|lt)\b/g, (match) => `$${match}`);
    
    // Xử lý lọc theo Brand - vì brand là một trường cụ thể, cần xử lý riêng nếu cần
    // Ví dụ, nếu client gửi brand=Dell,HP,Asus, ta sẽ chuyển thành { brand: { $in: ['Dell', 'HP', 'Asus'] } }
    let filter = JSON.parse(queryStr);
    if (req.query.brand) {
        filter.brand = { $in: req.query.brand.split(',') };
    }

    // Xử lý tìm kiếm bằng keyword
    if (req.query.keyword) {
      filter.name = {
        $regex: req.query.keyword,
        $options: 'i', // không phân biệt hoa thường
      };
    }

    let query = Product.find(filter);

    // 2. SẮP XẾP (SORTING)
    // Ví dụ: /api/products?sort=price (tăng dần), /api/products?sort=-price (giảm dần)
    // Hoặc sort=name,-price
    if (req.query.sort) {
      const sortBy = req.query.sort.split(',').join(' ');
      query = query.sort(sortBy);
    } else {
      // Mặc định sắp xếp theo sản phẩm mới nhất
      query = query.sort('-createdAt');
    }

    // 3. PHÂN TRANG (PAGINATION)
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 12; // Mặc định 12 sản phẩm/trang
    const skip = (page - 1) * limit;

    query = query.skip(skip).limit(limit);

    // Lấy tổng số document khớp với điều kiện lọc để tính tổng số trang
    const totalProducts = await Product.countDocuments(filter);

    // Thực thi câu query
    const products = await query.populate('category', 'name');

    res.json({
      success: true,
      count: products.length,
      totalProducts,
      totalPages: Math.ceil(totalProducts / limit),
      currentPage: page,
      products,
    });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy chi tiết một sản phẩm
// @route   GET /api/products/:id
// @access  Public
const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
                          .populate('category', 'name')
                          .populate('reviews.user', 'fullName'); // Lấy tên người review

    if (product) {
      res.json(product);
    } else {
      res.status(404).json({ message: 'Không tìm thấy sản phẩm' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Cập nhật sản phẩm
// @route   PUT /api/products/:id
// @access  Private/Admin
const updateProduct = async (req, res) => {
    try {
        const { name, description, brand, category, images, variants } = req.body;
        const product = await Product.findById(req.params.id);

        if (product) {
            product.name = name || product.name;
            product.description = description || product.description;
            product.brand = brand || product.brand;
            product.category = category || product.category;
            product.images = images || product.images;
            product.variants = variants || product.variants;

            const updatedProduct = await product.save();
            res.json(updatedProduct);
        } else {
            res.status(404).json({ message: 'Không tìm thấy sản phẩm' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Xóa sản phẩm
// @route   DELETE /api/products/:id
// @access  Private/Admin
const deleteProduct = async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);

        if (product) {
            await product.deleteOne();
            res.json({ message: 'Sản phẩm đã được xóa' });
        } else {
            res.status(404).json({ message: 'Không tìm thấy sản phẩm' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Tạo một đánh giá mới cho sản phẩm
// @route   POST /api/products/:id/reviews
// @access  Private (Cần đăng nhập)
const createProductReview = async (req, res) => {
  const { rating, comment } = req.body;

  try {
    const product = await Product.findById(req.params.id);

    if (product) {
      // Kiểm tra xem người dùng này đã đánh giá sản phẩm này chưa
      const alreadyReviewed = product.reviews.find(
        (r) => r.user.toString() === req.user._id.toString()
      );

      if (alreadyReviewed) {
        return res.status(400).json({ message: 'Bạn đã đánh giá sản phẩm này rồi' });
      }

      // Tạo object review mới
      const review = {
        user: req.user._id,
        rating: Number(rating),
        comment,
      };

      // Thêm review mới vào mảng reviews của sản phẩm
      product.reviews.push(review);

      // Cập nhật lại số lượng đánh giá và điểm trung bình
      product.numReviews = product.reviews.length;
      product.averageRating =
        product.reviews.reduce((acc, item) => item.rating + acc, 0) /
        product.reviews.length;

      // Lưu lại sản phẩm vào DB
      await product.save();

      // Lấy instance io
      const io = req.app.get('socketio');
      // Bắn sự kiện 'new_review' kèm theo productId và data review mới
      io.emit('new_review', {
          productId: req.params.id,
          review: review, // review vừa tạo
          newAverageRating: product.averageRating,
          newNumReviews: product.numReviews
      });

      res.status(201).json({ message: 'Đánh giá đã được thêm' });
    } else {
      res.status(404).json({ message: 'Không tìm thấy sản phẩm' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct,
  createProductReview,
};