// src/api/controllers/productController.js

const Product = require('../models/productModel');
const jwt = require('jsonwebtoken');
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