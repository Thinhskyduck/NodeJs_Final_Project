// src/api/controllers/productController.js

const Product = require('../models/productModel');
const jwt = require('jsonwebtoken');
const { indexProduct, removeProduct, searchProductsES } = require('../../config/elastic');
const Category = require('../models/categoryModel'); // Cần để kiểm tra category
const User = require('../models/userModel');

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
    // 1. Lấy các tham số từ query string
    const { keyword, page, limit, sort, category, brand, price } = req.query;

    // Khởi tạo bộ lọc rỗng
    let filter = {};

    // 2. Xử lý Tìm kiếm (Keyword)
    if (keyword) {
      try {
        // Ưu tiên dùng ElasticSearch nếu có
        const productIds = await searchProductsES(keyword);
        if (productIds.length > 0) {
            filter._id = { $in: productIds };
        } else {
            // Nếu ES không thấy, trả về rỗng ngay
            filter._id = "000000000000000000000000"; 
        }
      } catch (err) {
        // Fallback: Dùng Regex tìm trong tên nếu ES lỗi
        console.error("ES Error, using Regex fallback:", err.message);
        filter.name = { $regex: keyword, $options: 'i' };
      }
    }

    // 3. Xử lý Category
    if (category) {
        filter.category = category;
    }

    // 4. Xử lý Brand (Hỗ trợ nhiều brand cách nhau bằng dấu phẩy)
    if (brand) {
        filter.brand = { $in: brand.split(',') };
    }

    // 5. Xử lý Price (QUAN TRỌNG: Lọc theo variants.price)
    // Query string dạng: ?price[gte]=100000&price[lte]=500000
    if (price) {
        let priceQuery = {};
        
        // Ép kiểu sang Number để MongoDB so sánh đúng
        if (price.gte) priceQuery.$gte = Number(price.gte);
        if (price.gt)  priceQuery.$gt  = Number(price.gt);
        if (price.lte) priceQuery.$lte = Number(price.lte);
        if (price.lt)  priceQuery.$lt  = Number(price.lt);

        // Chỉ thêm vào filter nếu có ít nhất 1 điều kiện giá
        if (Object.keys(priceQuery).length > 0) {
            // LƯU Ý: Giá nằm trong mảng variants
            // MongoDB sẽ tìm sản phẩm có ÍT NHẤT 1 variant thỏa mãn điều kiện giá này
            filter['variants.price'] = priceQuery;
        }
    }

    // 6. Xử lý Sắp xếp (Sort)
    let sortQuery = '-createdAt'; // Mặc định mới nhất
    if (sort) {
        const sortParam = sort.split(',').join(' ');
        // Nếu sort theo price, ta cần trỏ vào variants.price
        if (sortParam.includes('price')) {
             // Lưu ý: Sort theo mảng trong Mongo có thể phức tạp, 
             // nhưng 'variants.price' thường sẽ lấy giá trị nhỏ nhất/lớn nhất trong mảng để sort
             sortQuery = sortParam.replace('price', 'variants.price');
        } else {
             sortQuery = sortParam;
        }
    }

    // 7. Phân trang
    const pageNum = Number(page) || 1;
    const limitNum = Number(limit) || 12;
    const skip = (pageNum - 1) * limitNum;

    // 8. Thực thi Query
    const totalProducts = await Product.countDocuments(filter);
    const products = await Product.find(filter)
                                  .sort(sortQuery)
                                  .skip(skip)
                                  .limit(limitNum)
                                  .populate('category', 'name');

    res.json({
      success: true,
      count: products.length,
      totalProducts,
      totalPages: Math.ceil(totalProducts / limitNum),
      currentPage: pageNum,
      products,
    });

  } catch (error) {
    console.error("Get Products Error:", error);
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
            console.error("Lỗi xác thực Token bình luận:", e.message);
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