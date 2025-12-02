// src/api/controllers/paymentController.js
const moment = require('moment');
const qs = require('qs');
const crypto = require('crypto');
const Order = require('../models/orderModel');

function sortObject(obj) {
    let sorted = {};
    let str = [];
    let key;
    for (key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
            str.push(encodeURIComponent(key));
        }
    }
    str.sort();
    for (key = 0; key < str.length; key++) {
        sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
    }
    return sorted;
}

// 1. TẠO URL THANH TOÁN
const createPaymentUrl = async (req, res) => {
    try {
        const { orderId, amount, bankCode, language } = req.body;
        
        process.env.TZ = 'Asia/Ho_Chi_Minh';
        const date = new Date();
        const createDate = moment(date).format('YYYYMMDDHHmmss');
        
        const tmnCode = process.env.VNP_TMN_CODE;
        const secretKey = process.env.VNP_HASH_SECRET;
        let vnpUrl = process.env.VNP_URL;
        const returnUrl = process.env.VNP_RETURN_URL;

        let vnp_Params = {};
        vnp_Params['vnp_Version'] = '2.1.0';
        vnp_Params['vnp_Command'] = 'pay';
        vnp_Params['vnp_TmnCode'] = tmnCode;
        vnp_Params['vnp_Locale'] = language || 'vn';
        vnp_Params['vnp_CurrCode'] = 'VND';
        vnp_Params['vnp_TxnRef'] = orderId;
        vnp_Params['vnp_OrderInfo'] = 'Thanh toan don hang ' + orderId;
        vnp_Params['vnp_OrderType'] = 'other';
        vnp_Params['vnp_Amount'] = amount * 100;
        vnp_Params['vnp_ReturnUrl'] = returnUrl;
        vnp_Params['vnp_IpAddr'] = '127.0.0.1'; // Fix cứng IP
        vnp_Params['vnp_CreateDate'] = createDate;

        if (bankCode) {
            vnp_Params['vnp_BankCode'] = bankCode;
        }

        vnp_Params = sortObject(vnp_Params);
        const signData = qs.stringify(vnp_Params, { encode: false });
        const hmac = crypto.createHmac("sha512", secretKey);
        const signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex"); 
        
        vnp_Params['vnp_SecureHash'] = signed;
        vnpUrl += '?' + qs.stringify(vnp_Params, { encode: false });

        res.status(200).json({ paymentUrl: vnpUrl });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi tạo link', error: error.message });
    }
};

// 2. XỬ LÝ KẾT QUẢ VÀ UPDATE DB LUÔN TẠI ĐÂY
const vnpayReturn = async (req, res) => {
    try {
        let vnp_Params = req.query;
        const secureHash = vnp_Params['vnp_SecureHash'];
        const orderId = vnp_Params['vnp_TxnRef'];
        const rspCode = vnp_Params['vnp_ResponseCode'];

        delete vnp_Params['vnp_SecureHash'];
        delete vnp_Params['vnp_SecureHashType'];

        vnp_Params = sortObject(vnp_Params);
        const secretKey = process.env.VNP_HASH_SECRET;
        const signData = qs.stringify(vnp_Params, { encode: false });
        const hmac = crypto.createHmac("sha512", secretKey);
        const signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex");

        if (secureHash === signed) {
            // Checksum đúng
            if (rspCode === '00') {
                // --- UPDATE DATABASE ---
                const order = await Order.findById(orderId);
                if (order && order.status === 'pending') {
                    order.status = 'confirmed';
                    order.paymentMethod = 'VNPAY';
                    await order.save();

                    if (order.user) {
                        const user = await User.findById(order.user);
                        if (user) {
                            // Quy tắc: 1.000.000 VND = 100 điểm (Tức là chia 10,000)
                            const pointsEarned = Math.floor(order.totalPrice / 10000);
                            user.loyaltyPoints = (user.loyaltyPoints || 0) + pointsEarned;
                            await user.save();
                            console.log(`✅ Cộng ${pointsEarned} điểm cho user ${user.email}`);
                        }
                    }
                    
                    // Socket báo admin
                    const io = req.app.get('socketio');
                    if(io) io.emit('order_paid', { orderId: orderId });
                }
                // --- UPDATE XONG ---

                // Redirect về trang Success
                res.redirect(`${process.env.FRONTEND_URL}/order-success?orderId=${orderId}`);
            } else {
                // Thất bại
                res.redirect(`${process.env.FRONTEND_URL}/order-failed`);
            }
        } else {
            // Sai chữ ký
            res.redirect(`${process.env.FRONTEND_URL}/order-failed?reason=invalid_signature`);
        }
    } catch (error) {
        console.error(error);
        res.redirect(`${process.env.FRONTEND_URL}/order-failed?reason=server_error`);
    }
};

module.exports = { createPaymentUrl, vnpayReturn };