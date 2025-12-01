// src/api/controllers/productController.js

const Product = require('../models/productModel');
const jwt = require('jsonwebtoken');
const { indexProduct, removeProduct, searchProductsES } = require('../../config/elastic');
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

// @desc    Lấy tất cả sản phẩm (hỗ trợ phân trang, lọc, sắp xếp, ELASTICSEARCH)
// @route   GET /api/products
// @access  Public
const getProducts = async (req, res) => {
  try {
    // 1. LỌC (FILTERING)
    const queryObj = { ...req.query };
    const excludedFields = ['page', 'sort', 'limit', 'fields', 'keyword'];
    excludedFields.forEach((el) => delete queryObj[el]);

    // Lọc nâng cao cho khoảng giá (gte, gt, lte, lt)
    let queryStr = JSON.stringify(queryObj);
    queryStr = queryStr.replace(/\b(gte|gt|lte|lt)\b/g, (match) => `$${match}`);
    
    let filter = JSON.parse(queryStr);

    // Xử lý lọc theo Brand
    if (req.query.brand) {
        filter.brand = { $in: req.query.brand.split(',') };
    }

    // --- XỬ LÝ TÌM KIẾM (ĐOẠN NÀY ĐÃ SỬA) ---
    if (req.query.keyword) {
      try {
        // Cách mới: Hỏi Elasticsearch trước
        const productIds = await searchProductsES(req.query.keyword);
        
        // Nếu tìm thấy, lọc Mongo theo danh sách ID trả về
        if (productIds.length > 0) {
            filter._id = { $in: productIds };
        } else {
            // Nếu Elastic không tìm thấy gì, ép Mongo trả về rỗng luôn (để tránh hiện tất cả)
            // Bằng cách gán _id là một ID giả không tồn tại
            filter._id = "000000000000000000000000"; 
        }
      } catch (err) {
        console.error("⚠️ Elasticsearch lỗi hoặc chưa bật, quay về tìm kiếm thường:", err.message);
        // Cách cũ (Fallback): Nếu ES lỗi thì dùng Regex như cũ
        filter.name = {
          $regex: req.query.keyword,
          $options: 'i',
        };
      }
    }
    // ----------------------------------------

    let query = Product.find(filter);

    // 2. SẮP XẾP (SORTING)
    if (req.query.sort) {
      const sortBy = req.query.sort.split(',').join(' ');
      query = query.sort(sortBy);
    } else {
      query = query.sort('-createdAt');
    }

    // 3. PHÂN TRANG (PAGINATION)
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 12;
    const skip = (page - 1) * limit;

    query = query.skip(skip).limit(limit);

    // Lấy tổng số document
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
            await indexProduct(updatedProduct);
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
            await removeProduct(req.params.id);
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
  const { rating, comment, guestName } = req.body;
  const productId = req.params.id;

  try {
    const product = await Product.findById(productId);
    if (!product) return res.status(404).json({ message: 'Sản phẩm không tồn tại' });

    let user = null;
    
    // 1. Kiểm tra xem có Token không (Soft Auth)
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            const token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            user = await User.findById(decoded.id);
        } catch (e) {
            // Token lỗi -> Coi như Guest
        }
    }

    // 2. Logic phân quyền
    if (user) {
        // --- LOGIC CHO USER ĐÃ LOGIN ---
        // User bắt buộc phải có rating (theo đề bài)
        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({ message: 'Thành viên vui lòng đánh giá sao (1-5)' });
        }

        // Check xem đã đánh giá chưa
        const alreadyReviewed = product.reviews.find(
            (r) => r.user && r.user.toString() === user._id.toString()
        );
        if (alreadyReviewed) {
            return res.status(400).json({ message: 'Bạn đã đánh giá sản phẩm này rồi' });
        }

        const review = {
            user: user._id,
            name: user.fullName, // Hoặc dùng populate sau này
            rating: Number(rating),
            comment,
        };
        product.reviews.push(review);

    } else {
        // --- LOGIC CHO GUEST ---
        // Guest KHÔNG được đánh giá sao (Rating = 0 hoặc bỏ qua tính toán)
        if (rating && Number(rating) > 0) {
            return res.status(400).json({ message: 'Khách vãng lai chỉ được bình luận, không được đánh giá sao.' });
        }
        if (!guestName) {
             return res.status(400).json({ message: 'Vui lòng nhập tên của bạn' });
        }

        const review = {
            user: null, // Không có user ID
            guestName: guestName,
            rating: 0, // Mặc định 0
            comment,
        };
        product.reviews.push(review);
    }

    // 3. Tính lại điểm trung bình (Chỉ tính những review có rating > 0)
    const ratedReviews = product.reviews.filter(r => r.rating > 0);
    if (ratedReviews.length > 0) {
        product.numReviews = ratedReviews.length;
        product.averageRating =
            ratedReviews.reduce((acc, item) => item.rating + acc, 0) / ratedReviews.length;
    }

    await product.save();

    // Socket Realtime
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_review', {
            productId: productId,
            review: product.reviews[product.reviews.length - 1],
            newAverageRating: product.averageRating,
            newNumReviews: product.numReviews
        });
    }

    res.status(201).json({ message: 'Bình luận đã được gửi' });

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