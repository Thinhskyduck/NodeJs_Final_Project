// src/config/elastic.js
const { Client } = require('@elastic/elasticsearch');

// Kết nối tới ES (dùng biến môi trường hoặc localhost nếu chạy ngoài docker)
const esClient = new Client({ 
    node: process.env.ELASTICSEARCH_URI || 'http://localhost:9200' 
});

const INDEX_NAME = 'products';

// 1. Hàm khởi tạo Index (chạy khi server bật)
const createIndex = async () => {
    try {
        const exists = await esClient.indices.exists({ index: INDEX_NAME });
        if (!exists) {
            await esClient.indices.create({
                index: INDEX_NAME,
                body: {
                    mappings: {
                        properties: {
                            name: { type: 'text' },
                            description: { type: 'text' },
                            price: { type: 'float' },
                            category: { type: 'keyword' }, // keyword để filter chính xác
                            brand: { type: 'keyword' }
                        }
                    }
                }
            });
            console.log("✅ Elasticsearch Index created!");
        }
    } catch (error) {
        console.error("⚠️ ES Create Index Error:", error.message);
    }
};

// 2. Hàm thêm/cập nhật sản phẩm vào ES
const indexProduct = async (product) => {
    try {
        await esClient.index({
            index: INDEX_NAME,
            id: product._id.toString(), // ID trong ES phải là string
            body: {
                name: product.name,
                description: product.description,
                price: product.basePrice,
                category: product.category ? product.category.toString() : '',
                brand: product.brand,
            }
        });
        // console.log(`Indexed product ${product.name} to ES`);
    } catch (error) {
        console.error("❌ ES Index Error:", error.message);
    }
};

// 3. Hàm xóa sản phẩm khỏi ES
const removeProduct = async (productId) => {
    try {
        await esClient.delete({
            index: INDEX_NAME,
            id: productId.toString()
        });
    } catch (error) {
        // console.error("ES Delete Error:", error.message);
    }
};

// 4. Hàm tìm kiếm (Core Feature)
const searchProductsES = async (keyword) => {
    const result = await esClient.search({
        index: INDEX_NAME,
        body: {
            query: {
                multi_match: {
                    query: keyword,
                    fields: ['name^3', 'description'], // Ưu tiên tìm trong tên gấp 3 lần mô tả
                    fuzziness: 'AUTO', // Tự động sửa lỗi chính tả (vd: "loptop" -> "laptop")
                    operator: 'and'
                }
            }
        }
    });
    // Trả về danh sách ID sản phẩm để query lại từ MongoDB (hoặc trả về luôn data)
    return result.hits.hits.map(hit => hit._id);
};

module.exports = { 
    esClient, 
    createIndex, 
    indexProduct, 
    removeProduct, 
    searchProductsES 
};