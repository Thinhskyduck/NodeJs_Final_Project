// src/api/controllers/cartController.js
const Cart = require('../models/cartModel');
const Product = require('../models/productModel');

// @desc    Lấy giỏ hàng của người dùng
// @route   GET /api/cart
// @access  Private
const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      return res.json({ items: [], totalPrice: 0 });
    }
    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Thêm/Cập nhật sản phẩm trong giỏ hàng
// @route   POST /api/cart
// @access  Private
const addItemToCart = async (req, res) => {
  const { productId, variantId, quantity } = req.body;
  const userId = req.user._id;

  try {
    // Tìm sản phẩm và variant tương ứng
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Không tìm thấy sản phẩm' });
    }
    const variant = product.variants.id(variantId);
    if (!variant) {
      return res.status(404).json({ message: 'Không tìm thấy biến thể sản phẩm' });
    }

    // Tìm giỏ hàng của người dùng, nếu chưa có thì tạo mới
    let cart = await Cart.findOne({ user: userId });
    if (!cart) {
      cart = await Cart.create({ user: userId, items: [] });
    }

    // Kiểm tra xem sản phẩm + variant đó đã có trong giỏ hàng chưa
    const itemIndex = cart.items.findIndex(
      (item) => item.product.toString() === productId && item.variant.toString() === variantId
    );

    if (itemIndex > -1) {
      // Nếu có rồi, cập nhật số lượng
      cart.items[itemIndex].quantity += quantity;
    } else {
      // Nếu chưa có, thêm mới vào mảng
      cart.items.push({
        product: productId,
        variant: variantId,
        quantity,
        name: product.name + ' - ' + variant.name,
        price: variant.price,
        image: product.images[0], // Lấy ảnh đầu tiên làm đại diện
      });
    }

    const updatedCart = await cart.save();

    // --- REAL-TIME SOCKET: Báo cho client biết giỏ hàng đã thay đổi ---
    const io = req.app.get('socketio');
    if (io) {
        io.emit('cart_updated', {
            userId: userId.toString(), // Client sẽ check ID này để biết có phải giỏ của mình không
            cart: updatedCart
        });
    }
    // ------------------------------------------------------------------

    res.status(200).json(updatedCart);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Xóa sản phẩm khỏi giỏ hàng
// @route   DELETE /api/cart/items/:itemId
// @access  Private
const removeItemFromCart = async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user._id;
  
    try {
      const cart = await Cart.findOne({ user: userId });
  
      if (!cart) {
        return res.status(404).json({ message: 'Không tìm thấy giỏ hàng' });
      }
  
      // Tìm vị trí của item cần xóa
      const itemIndex = cart.items.findIndex(item => item._id.toString() === itemId);
      
      if (itemIndex > -1) {
        cart.items.splice(itemIndex, 1); // Xóa item khỏi mảng
        const updatedCart = await cart.save();

        // --- REAL-TIME SOCKET: Báo xóa item thành công ---
        const io = req.app.get('socketio');
        if (io) {
            io.emit('cart_updated', {
                userId: userId.toString(),
                cart: updatedCart
            });
        }
        // -------------------------------------------------

        res.json(updatedCart);
      } else {
        res.status(404).json({ message: 'Không tìm thấy sản phẩm trong giỏ hàng' });
      }
    } catch (error) {
      res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

module.exports = { getCart, addItemToCart, removeItemFromCart };