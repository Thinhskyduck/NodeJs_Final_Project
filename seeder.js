// seeder.js
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

// Load models
const User = require('./src/api/models/userModel');
const Product = require('./src/api/models/productModel');
const Category = require('./src/api/models/categoryModel');
const Order = require('./src/api/models/orderModel');
const Discount = require('./src/api/models/discountModel');
const Cart = require('./src/api/models/cartModel');
const { indexProduct, esClient } = require('./src/config/elastic');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected for Seeder...');
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

const importData = async () => {
  await connectDB();
  try {
    // 1. Clear Data
    await Order.deleteMany();
    await Product.deleteMany();
    await User.deleteMany();
    await Category.deleteMany();
    await Discount.deleteMany();
    await Cart.deleteMany();
    
    console.log('Data Destroyed!');

    // 2. Create Categories
    const categoriesData = [
      { name: 'Laptop', slug: 'laptop' },
      { name: 'Màn hình', slug: 'man-hinh' },
      { name: 'Chuột', slug: 'chuot' },
      { name: 'Bàn phím', slug: 'ban-phim' },
      { name: 'Ổ cứng', slug: 'o-cung' },
      { name: 'Tai nghe', slug: 'tai-nghe' },
    ];

    const createdCategories = await Category.insertMany(categoriesData);
    
    const catIds = {
      laptop: createdCategories.find(c => c.slug === 'laptop')._id,
      screen: createdCategories.find(c => c.slug === 'man-hinh')._id,
      mouse: createdCategories.find(c => c.slug === 'chuot')._id,
      keyboard: createdCategories.find(c => c.slug === 'ban-phim')._id,
      storage: createdCategories.find(c => c.slug === 'o-cung')._id,
      audio: createdCategories.find(c => c.slug === 'tai-nghe')._id,
    };

    console.log('Categories Created!');

    // 3. Create Users
    await User.create({
      fullName: 'Admin User',
      email: 'khantrinh293@gmail.com',
      password: '123456', 
      role: 'admin',
    });

    await User.create({
      fullName: 'Customer User',
      email: 'thinhskyduct@gmail.com',
      password: '123456',
      role: 'customer',
    });

    console.log('Users Created!');

    // 4. Create Products (10 items per category)
    const productsData = [
      // --- 1. LAPTOP (10 SP) ---
      {
        name: "Laptop ASUS TUF Gaming F15",
        description: "Laptop gaming bền bỉ chuẩn quân đội, hiệu năng cao với RTX 3050.",
        brand: "ASUS", category: catIds.laptop,
        images: ["assets/img/asus_tuf_f15.jpg"],
        variants: [{ name: "i5/8GB/512GB", price: 17990000, stockQuantity: 15 }, { name: "i7/16GB/512GB", price: 21990000, stockQuantity: 8 }],
        averageRating: 4.5, numReviews: 10
      },
      {
        name: "Laptop Dell XPS 13 Plus",
        description: "Thiết kế sang trọng, mỏng nhẹ, màn hình OLED tuyệt đẹp.",
        brand: "Dell", category: catIds.laptop,
        images: ["assets/img/dell_xps_13.jpg"],
        variants: [{ name: "i7/16GB/1TB", price: 45990000, stockQuantity: 5 }],
        averageRating: 5, numReviews: 2
      },
      {
        name: "MacBook Air M1 2020",
        description: "MacBook hiệu năng tốt, pin trâu, thiết kế mỏng nhẹ.",
        brand: "Apple", category: catIds.laptop,
        images: ["assets/img/macbookm1.jpg"],
        variants: [{ name: "8GB/256GB", price: 18900000, stockQuantity: 20 }, { name: "16GB/512GB", price: 24900000, stockQuantity: 10 }],
        averageRating: 4.8, numReviews: 50
      },
      {
        name: "Laptop Acer Aspire 7",
        description: "Laptop gaming giá rẻ, phù hợp học tập và giải trí.",
        brand: "Acer", category: catIds.laptop,
        images: ["assets/img/aspire7.jpg"],
        variants: [{ name: "Ryzen 5/8GB/512GB", price: 14500000, stockQuantity: 12 }],
        averageRating: 4.0, numReviews: 8
      },
      {
        name: "Laptop MSI Gaming GF63 Thin",
        description: "Mỏng nhẹ, cấu hình mạnh mẽ trong tầm giá.",
        brand: "MSI", category: catIds.laptop,
        images: ["assets/img/asus_tuf_f15.jpg"], // Dùng tạm ảnh
        variants: [{ name: "i5/8GB/RTX 3050", price: 16490000, stockQuantity: 15 }],
        averageRating: 4.2, numReviews: 12
      },
      {
        name: "Laptop Lenovo Legion 5",
        description: "Ông vua laptop gaming tầm trung, tản nhiệt cực tốt.",
        brand: "Lenovo", category: catIds.laptop,
        images: ["assets/img/asus_tuf_f15.jpg"], // Dùng tạm ảnh
        variants: [{ name: "Ryzen 7/RTX 3060", price: 27990000, stockQuantity: 6 }],
        averageRating: 4.9, numReviews: 25
      },
      {
        name: "Laptop HP Pavilion 15",
        description: "Thiết kế thời trang, vỏ kim loại, màn hình IPS.",
        brand: "HP", category: catIds.laptop,
        images: ["assets/img/dell_xps_13.jpg"], // Dùng tạm ảnh
        variants: [{ name: "i5/8GB/512GB", price: 15990000, stockQuantity: 18 }],
        averageRating: 4.1, numReviews: 5
      },
      {
        name: "MacBook Pro 14 M3",
        description: "Sức mạnh pro, chip M3 thế hệ mới nhất.",
        brand: "Apple", category: catIds.laptop,
        images: ["assets/img/macbookm1.jpg"],
        variants: [{ name: "M3/8GB/512GB", price: 39990000, stockQuantity: 5 }],
        averageRating: 5.0, numReviews: 3
      },
      {
        name: "Laptop Gigabyte G5",
        description: "Hiệu năng trên giá thành cực tốt cho game thủ.",
        brand: "Gigabyte", category: catIds.laptop,
        images: ["assets/img/asus_tuf_f15.jpg"],
        variants: [{ name: "i5/RTX 4050", price: 19990000, stockQuantity: 10 }],
        averageRating: 4.3, numReviews: 7
      },
      {
        name: "Laptop LG Gram 2023",
        description: "Siêu nhẹ, pin siêu lâu, độ bền chuẩn quân đội.",
        brand: "LG", category: catIds.laptop,
        images: ["assets/img/dell_xps_13.jpg"],
        variants: [{ name: "14 inch/i7/16GB", price: 29990000, stockQuantity: 4 }],
        averageRating: 4.7, numReviews: 6
      },

      // --- 2. MÀN HÌNH (10 SP) ---
      {
        name: "Màn hình Samsung Odyssey G5",
        description: "Màn hình cong 2K 144Hz, HDR10.",
        brand: "Samsung", category: catIds.screen,
        images: ["assets/img/harddriver1.jpg"], 
        variants: [{ name: "27 inch", price: 6500000, stockQuantity: 10 }, { name: "32 inch", price: 7500000, stockQuantity: 9 }],
        averageRating: 5, numReviews: 1
      },
      {
        name: "Màn hình LG UltraGear 24GN650",
        description: "Màn hình Gaming 144Hz, IPS, 1ms.",
        brand: "LG", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "24 inch", price: 3990000, stockQuantity: 20 }],
        averageRating: 4.8, numReviews: 15
      },
      {
        name: "Màn hình Dell UltraSharp U2422H",
        description: "Chuyên đồ họa, màu sắc chuẩn 100% sRGB.",
        brand: "Dell", category: catIds.screen,
        images: ["assets/img/dell_u2422h.jpg"],
        variants: [{ name: "24 inch", price: 6290000, stockQuantity: 10 }],
        averageRating: 4.9, numReviews: 8
      },
      {
        name: "Màn hình Asus ProArt PA248QV",
        description: "Thiết kế cho Designer, độ sai lệch màu cực thấp.",
        brand: "Asus", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "24 inch", price: 5490000, stockQuantity: 15 }],
        averageRating: 4.6, numReviews: 5
      },
      {
        name: "Màn hình ViewSonic VX2428",
        description: "Màn hình gaming giá rẻ 165Hz IPS.",
        brand: "ViewSonic", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "24 inch", price: 2990000, stockQuantity: 30 }],
        averageRating: 4.3, numReviews: 20
      },
      {
        name: "Màn hình Cong MSI Optix G27C4",
        description: "Cong 1500R, 165Hz, trải nghiệm đắm chìm.",
        brand: "MSI", category: catIds.screen,
        images: ["assets/img/harddriver1.jpg"],
        variants: [{ name: "27 inch", price: 4500000, stockQuantity: 12 }],
        averageRating: 4.4, numReviews: 9
      },
      {
        name: "Màn hình BenQ Zowie XL2411K",
        description: "Chuẩn eSports cho FPS, DyAc technology.",
        brand: "BenQ", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "24 inch", price: 5190000, stockQuantity: 8 }],
        averageRating: 4.7, numReviews: 12
      },
      {
        name: "Màn hình Gigabyte G27F 2",
        description: "Cân bằng giữa làm việc và giải trí.",
        brand: "Gigabyte", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "27 inch", price: 3890000, stockQuantity: 18 }],
        averageRating: 4.5, numReviews: 6
      },
      {
        name: "Màn hình Samsung Smart Monitor M5",
        description: "Màn hình thông minh không cần PC, tích hợp Netflix/Youtube.",
        brand: "Samsung", category: catIds.screen,
        images: ["assets/img/harddriver1.jpg"],
        variants: [{ name: "27 inch", price: 4290000, stockQuantity: 10 }],
        averageRating: 4.2, numReviews: 4
      },
      {
        name: "Màn hình AOC 24G2",
        description: "Viền siêu mỏng, chân đế linh hoạt.",
        brand: "AOC", category: catIds.screen,
        images: ["assets/img/lg_ultragear.jpg"],
        variants: [{ name: "24 inch", price: 3490000, stockQuantity: 25 }],
        averageRating: 4.6, numReviews: 18
      },

      // --- 3. CHUỘT (10 SP) ---
      {
        name: "Chuột Logitech G102 Lightsync",
        description: "Chuột gaming quốc dân, LED RGB 16.8 triệu màu.",
        brand: "Logitech", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Đen", price: 350000, stockQuantity: 100 }, { name: "Trắng", price: 370000, stockQuantity: 80 }],
        averageRating: 4.8, numReviews: 200
      },
      {
        name: "Chuột Logitech MX Master 3S",
        description: "Đỉnh cao chuột văn phòng, cuộn vô cực, yên tĩnh.",
        brand: "Logitech", category: catIds.mouse,
        images: ["assets/img/mx_master_3s.jpg"],
        variants: [{ name: "Graphite", price: 2490000, stockQuantity: 30 }],
        averageRating: 4.9, numReviews: 50
      },
      {
        name: "Chuột Razer DeathAdder Essential",
        description: "Form cầm huyền thoại, cảm biến quang học.",
        brand: "Razer", category: catIds.mouse,
        images: ["assets/img/deathadder.jpg"],
        variants: [{ name: "Đen", price: 490000, stockQuantity: 40 }],
        averageRating: 4.5, numReviews: 30
      },
      {
        name: "Chuột SteelSeries Rival 3",
        description: "Bền bỉ, đèn LED đẹp, mắt đọc TrueMove.",
        brand: "SteelSeries", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Wireless", price: 990000, stockQuantity: 15 }],
        averageRating: 4.4, numReviews: 12
      },
      {
        name: "Chuột không dây Logitech Pebble M350",
        description: "Mỏng nhẹ, thời trang, click không tiếng.",
        brand: "Logitech", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Hồng", price: 550000, stockQuantity: 20 }, { name: "Xanh", price: 550000, stockQuantity: 20 }],
        averageRating: 4.7, numReviews: 45
      },
      {
        name: "Chuột Gaming Zowie EC2-C",
        description: "Dành cho thi đấu chuyên nghiệp, không cần driver.",
        brand: "Zowie", category: catIds.mouse,
        images: ["assets/img/deathadder.jpg"],
        variants: [{ name: "Medium", price: 1690000, stockQuantity: 10 }],
        averageRating: 4.8, numReviews: 8
      },
      {
        name: "Chuột Glorious Model O",
        description: "Chuột lỗ siêu nhẹ, dây mềm như không dây.",
        brand: "Glorious", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Matte Black", price: 1190000, stockQuantity: 12 }],
        averageRating: 4.6, numReviews: 15
      },
      {
        name: "Chuột Asus ROG Gladius III",
        description: "Hotswap switch, cảm biến 19000 DPI.",
        brand: "Asus", category: catIds.mouse,
        images: ["assets/img/deathadder.jpg"],
        variants: [{ name: "Wireless", price: 2190000, stockQuantity: 8 }],
        averageRating: 4.7, numReviews: 6
      },
      {
        name: "Chuột Corsair Harpoon RGB",
        description: "Nhỏ gọn, phù hợp tay nhỏ, giá rẻ.",
        brand: "Corsair", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Wireless", price: 890000, stockQuantity: 18 }],
        averageRating: 4.3, numReviews: 10
      },
      {
        name: "Chuột DareU EM908",
        description: "Ngon bổ rẻ cho học sinh sinh viên.",
        brand: "DareU", category: catIds.mouse,
        images: ["assets/img/g102.jpg"],
        variants: [{ name: "Black", price: 299000, stockQuantity: 60 }],
        averageRating: 4.2, numReviews: 35
      },

      // --- 4. BÀN PHÍM (10 SP) ---
      {
        name: "Bàn phím cơ Akko 3068B Plus",
        description: "Layout 65% nhỏ gọn, 3 modes kết nối, hotswap.",
        brand: "Akko", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "Jelly Pink Switch", price: 1690000, stockQuantity: 15 }, { name: "Jelly Purple Switch", price: 1690000, stockQuantity: 12 }],
        averageRating: 4.7, numReviews: 20
      },
      {
        name: "Bàn phím Keychron K2 Pro",
        description: "Bàn phím custom không dây, hỗ trợ QMK/VIA.",
        brand: "Keychron", category: catIds.keyboard,
        images: ["assets/img/keychron_k2_pro.jpg"],
        variants: [{ name: "Red Switch", price: 2790000, stockQuantity: 10 }],
        averageRating: 4.8, numReviews: 18
      },
      {
        name: "Bàn phím Logitech K380",
        description: "Kết nối 3 thiết bị, mỏng nhẹ di động.",
        brand: "Logitech", category: catIds.keyboard,
        images: ["assets/img/k380.jpg"],
        variants: [{ name: "Đen", price: 650000, stockQuantity: 40 }, { name: "Hồng", price: 650000, stockQuantity: 30 }],
        averageRating: 4.6, numReviews: 55
      },
      {
        name: "Bàn phím cơ Corsair K70 RGB",
        description: "Khung nhôm bền bỉ, switch Cherry MX.",
        brand: "Corsair", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "Red Switch", price: 3490000, stockQuantity: 5 }],
        averageRating: 4.9, numReviews: 12
      },
      {
        name: "Bàn phím Razer BlackWidow V3",
        description: "Switch xanh clicky đặc trưng của Razer.",
        brand: "Razer", category: catIds.keyboard,
        images: ["assets/img/keychron_k2_pro.jpg"],
        variants: [{ name: "Green Switch", price: 2190000, stockQuantity: 8 }],
        averageRating: 4.5, numReviews: 15
      },
      {
        name: "Bàn phím Leopold FC900R",
        description: "Keycap PBT Double shot chất lượng cao nhất.",
        brand: "Leopold", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "Brown Switch", price: 3150000, stockQuantity: 6 }],
        averageRating: 5.0, numReviews: 4
      },
      {
        name: "Bàn phím DareU EK87",
        description: "Bàn phím cơ giá rẻ tốt nhất tầm giá.",
        brand: "DareU", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "Red Switch", price: 499000, stockQuantity: 50 }],
        averageRating: 4.3, numReviews: 40
      },
      {
        name: "Bàn phím Logitech G Pro X",
        description: "Thiết kế TKL cho game thủ, thay thế switch được.",
        brand: "Logitech", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "GX Blue", price: 2590000, stockQuantity: 10 }],
        averageRating: 4.7, numReviews: 9
      },
      {
        name: "Bàn phím Fuhlen M87s",
        description: "Led RGB đẹp, switch bền bỉ.",
        brand: "Fuhlen", category: catIds.keyboard,
        images: ["assets/img/akko3068b.jpg"],
        variants: [{ name: "Blue Switch", price: 750000, stockQuantity: 25 }],
        averageRating: 4.2, numReviews: 20
      },
      {
        name: "Bàn phím FL-Esports CMK87",
        description: "Build đầm chắc, âm thanh gõ cực hay.",
        brand: "FL-Esports", category: catIds.keyboard,
        images: ["assets/img/keychron_k2_pro.jpg"],
        variants: [{ name: "Samurai Grey", price: 3200000, stockQuantity: 7 }],
        averageRating: 4.9, numReviews: 10
      },

      // --- 5. Ổ CỨNG (10 SP) ---
      {
        name: "SSD Samsung 970 EVO Plus",
        description: "Tốc độ đọc ghi cực nhanh, độ bền cao.",
        brand: "Samsung", category: catIds.storage,
        images: ["assets/img/970evo.jpg"],
        variants: [{ name: "500GB", price: 1490000, stockQuantity: 30 }, { name: "1TB", price: 2590000, stockQuantity: 15 }],
        averageRating: 4.9, numReviews: 30
      },
      {
        name: "SSD Kingston NV2",
        description: "Giải pháp NVMe Gen 4 giá rẻ.",
        brand: "Kingston", category: catIds.storage,
        images: ["assets/img/kingston_nv2.jpg"],
        variants: [{ name: "500GB", price: 990000, stockQuantity: 50 }],
        averageRating: 4.5, numReviews: 40
      },
      {
        name: "HDD Seagate Barracuda",
        description: "Lưu trữ dữ liệu lớn với chi phí thấp.",
        brand: "Seagate", category: catIds.storage,
        images: ["assets/img/seagate1tb.jpg"],
        variants: [{ name: "1TB", price: 950000, stockQuantity: 25 }, { name: "2TB", price: 1450000, stockQuantity: 20 }],
        averageRating: 4.4, numReviews: 15
      },
      {
        name: "SSD WD Blue SN570",
        description: "Hiệu năng ổn định cho sáng tạo nội dung.",
        brand: "Western Digital", category: catIds.storage,
        images: ["assets/img/970evo.jpg"],
        variants: [{ name: "500GB", price: 1190000, stockQuantity: 20 }],
        averageRating: 4.6, numReviews: 10
      },
      {
        name: "SSD Samsung 980 Pro",
        description: "Chuẩn PCIe 4.0 đỉnh cao cho PS5 và PC.",
        brand: "Samsung", category: catIds.storage,
        images: ["assets/img/970evo.jpg"],
        variants: [{ name: "1TB", price: 2990000, stockQuantity: 10 }],
        averageRating: 5.0, numReviews: 8
      },
      {
        name: "HDD WD Black",
        description: "Tối ưu cho chơi game, tốc độ cao hơn HDD thường.",
        brand: "Western Digital", category: catIds.storage,
        images: ["assets/img/seagate1tb.jpg"],
        variants: [{ name: "1TB", price: 1200000, stockQuantity: 10 }],
        averageRating: 4.5, numReviews: 5
      },
      {
        name: "SSD Crucial P3",
        description: "Giá rẻ, dung lượng lớn.",
        brand: "Crucial", category: catIds.storage,
        images: ["assets/img/kingston_nv2.jpg"],
        variants: [{ name: "1TB", price: 1590000, stockQuantity: 15 }],
        averageRating: 4.3, numReviews: 12
      },
      {
        name: "SSD Di động Sandisk Extreme",
        description: "Chống nước, chống sốc, tốc độ cao.",
        brand: "Sandisk", category: catIds.storage,
        images: ["assets/img/970evo.jpg"],
        variants: [{ name: "1TB", price: 3290000, stockQuantity: 5 }],
        averageRating: 4.8, numReviews: 6
      },
      {
        name: "SSD Lexar NM620",
        description: "Lựa chọn kinh tế cho nâng cấp máy.",
        brand: "Lexar", category: catIds.storage,
        images: ["assets/img/kingston_nv2.jpg"],
        variants: [{ name: "512GB", price: 890000, stockQuantity: 40 }],
        averageRating: 4.2, numReviews: 20
      },
      {
        name: "Thẻ nhớ Sandisk Ultra",
        description: "Thẻ nhớ cho điện thoại, camera.",
        brand: "Sandisk", category: catIds.storage,
        images: ["assets/img/kingston_nv2.jpg"],
        variants: [{ name: "64GB", price: 250000, stockQuantity: 100 }],
        averageRating: 4.6, numReviews: 50
      },

      // --- 6. TAI NGHE (10 SP) ---
      {
        name: "Tai nghe HyperX Cloud II",
        description: "Tai nghe gaming huyền thoại, giả lập 7.1.",
        brand: "HyperX", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Đỏ", price: 1890000, stockQuantity: 20 }],
        averageRating: 4.7, numReviews: 30
      },
      {
        name: "Tai nghe Sony WH-CH520",
        description: "Pin 50 giờ, chất âm Sony, giá rẻ.",
        brand: "Sony", category: catIds.audio,
        images: ["assets/img/sony520.jpg"],
        variants: [{ name: "Xanh", price: 1190000, stockQuantity: 15 }],
        averageRating: 4.5, numReviews: 25
      },
      {
        name: "Apple AirPods Pro 2",
        description: "Chống ồn đỉnh cao, xuyên âm tự nhiên.",
        brand: "Apple", category: catIds.audio,
        images: ["assets/img/airpods_pro_2.jpg"],
        variants: [{ name: "Type-C", price: 5990000, stockQuantity: 10 }],
        averageRating: 4.9, numReviews: 40
      },
      {
        name: "Tai nghe Logitech G733",
        description: "Không dây, nhẹ, đèn LED RGB cá tính.",
        brand: "Logitech", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Tím", price: 2990000, stockQuantity: 8 }],
        averageRating: 4.6, numReviews: 12
      },
      {
        name: "Tai nghe Razer Kraken",
        description: "Bass mạnh mẽ, thiết kế hầm hố.",
        brand: "Razer", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Xanh lá", price: 1490000, stockQuantity: 18 }],
        averageRating: 4.4, numReviews: 22
      },
      {
        name: "Tai nghe SteelSeries Arctis 5",
        description: "Micro lọc tạp âm tốt nhất, đệm tai thoáng khí.",
        brand: "SteelSeries", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Đen", price: 2290000, stockQuantity: 10 }],
        averageRating: 4.5, numReviews: 15
      },
      {
        name: "Tai nghe Sennheiser Momentum 4",
        description: "Chất âm Audiophile, pin 60 giờ.",
        brand: "Sennheiser", category: catIds.audio,
        images: ["assets/img/sony520.jpg"],
        variants: [{ name: "Đen", price: 8490000, stockQuantity: 3 }],
        averageRating: 4.8, numReviews: 5
      },
      {
        name: "Tai nghe JBL Quantum 100",
        description: "Giá rẻ, micro rời, tương thích mọi nền tảng.",
        brand: "JBL", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Đen", price: 790000, stockQuantity: 35 }],
        averageRating: 4.2, numReviews: 28
      },
      {
        name: "Tai nghe Asus ROG Delta S",
        description: "DAC ESS 9281 Quad, đèn RGB.",
        brand: "Asus", category: catIds.audio,
        images: ["assets/img/cloud2.jpg"],
        variants: [{ name: "Đen", price: 4590000, stockQuantity: 5 }],
        averageRating: 4.6, numReviews: 7
      },
      {
        name: "Tai nghe Bose QuietComfort 45",
        description: "Huyền thoại chống ồn, đeo cực thoải mái.",
        brand: "Bose", category: catIds.audio,
        images: ["assets/img/sony520.jpg"],
        variants: [{ name: "Trắng khói", price: 6990000, stockQuantity: 4 }],
        averageRating: 4.9, numReviews: 10
      },
    ];

    await Product.insertMany(productsData);
    const allProducts = await Product.find({}); // Lấy lại tất cả
    for (const p of allProducts) {
      await indexProduct(p); // Đẩy từng cái vào ES
    }
    console.log('Products Indexed to Elasticsearch!');

    // 5. Create Coupons
    await Discount.create({
      code: "SALE5",
      value: 50000,
      maxUses: 10,
      discountType: "fixed"
    });
    
    await Discount.create({
      code: "TDTU1",
      value: 10, // 10%
      maxUses: 10,
      discountType: "percentage"
    });

    console.log('Coupons Created!');

    console.log('Data Imported Success!');
    process.exit();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
  
};

const destroyData = async () => {
  await connectDB();
  try {
    await Order.deleteMany();
    await Product.deleteMany();
    await User.deleteMany();
    await Category.deleteMany();
    await Discount.deleteMany();
    await Cart.deleteMany();
    
    console.log('Data Destroyed!');
    process.exit();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

if (process.argv[2] === '-d') {
  destroyData();
} else {
  importData();
}