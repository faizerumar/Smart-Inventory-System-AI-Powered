package com.inventory.dao;

import com.inventory.model.Product;
import com.inventory.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ProductDAO {

    public List<Product> getAllProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.*, s.name as supplier_name FROM products p LEFT JOIN suppliers s ON p.supplier_id = s.id ORDER BY p.id DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Product p = mapResultSetToProduct(rs);
                p.setSupplierName(rs.getString("supplier_name"));
                products.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }

    public Product getProductById(int id) {
        String sql = "SELECT p.*, s.name as supplier_name FROM products p LEFT JOIN suppliers s ON p.supplier_id = s.id WHERE p.id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Product p = mapResultSetToProduct(rs);
                    p.setSupplierName(rs.getString("supplier_name"));
                    return p;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public Product getProductBySku(String sku) {
        String sql = "SELECT p.*, s.name as supplier_name FROM products p LEFT JOIN suppliers s ON p.supplier_id = s.id WHERE p.sku = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, sku);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Product p = mapResultSetToProduct(rs);
                    p.setSupplierName(rs.getString("supplier_name"));
                    return p;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean insertProduct(Product p) {
        String sql = "INSERT INTO products (sku, name, description, price, category, stock_level, reorder_threshold, lead_time, expiry_date, supplier_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, p.getSku());
            ps.setString(2, p.getName());
            ps.setString(3, p.getDescription());
            ps.setBigDecimal(4, p.getPrice());
            ps.setString(5, p.getCategory());
            ps.setInt(6, p.getStockLevel());
            ps.setInt(7, p.getReorderThreshold());
            ps.setInt(8, p.getLeadTime());
            ps.setDate(9, p.getExpiryDate());
            if (p.getSupplierId() != null) {
                ps.setInt(10, p.getSupplierId());
            } else {
                ps.setNull(10, Types.INTEGER);
            }
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateProduct(Product p) {
        String sql = "UPDATE products SET sku=?, name=?, description=?, price=?, category=?, stock_level=?, reorder_threshold=?, lead_time=?, expiry_date=?, supplier_id=? WHERE id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, p.getSku());
            ps.setString(2, p.getName());
            ps.setString(3, p.getDescription());
            ps.setBigDecimal(4, p.getPrice());
            ps.setString(5, p.getCategory());
            ps.setInt(6, p.getStockLevel());
            ps.setInt(7, p.getReorderThreshold());
            ps.setInt(8, p.getLeadTime());
            ps.setDate(9, p.getExpiryDate());
            if (p.getSupplierId() != null) {
                ps.setInt(10, p.getSupplierId());
            } else {
                ps.setNull(10, Types.INTEGER);
            }
            ps.setInt(11, p.getId());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateStockLevel(int id, int adjustmentQty) {
        String sql = "UPDATE products SET stock_level = stock_level + ? WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, adjustmentQty);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteProduct(int id) {
        String sql = "DELETE FROM products WHERE id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Product> getLowStockProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.*, s.name as supplier_name FROM products p LEFT JOIN suppliers s ON p.supplier_id = s.id WHERE p.stock_level <= p.reorder_threshold ORDER BY p.stock_level ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Product p = mapResultSetToProduct(rs);
                p.setSupplierName(rs.getString("supplier_name"));
                products.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }

    public List<Product> getExpiredOrNearExpiryProducts(int daysThreshold) {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.*, s.name as supplier_name FROM products p LEFT JOIN suppliers s ON p.supplier_id = s.id " +
                     "WHERE p.expiry_date IS NOT NULL AND p.expiry_date <= DATE_ADD(CURDATE(), INTERVAL ? DAY) ORDER BY p.expiry_date ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, daysThreshold);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = mapResultSetToProduct(rs);
                    p.setSupplierName(rs.getString("supplier_name"));
                    products.add(p);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }

    public List<String> getAllCategories() {
        List<String> categories = new ArrayList<>();
        String sql = "SELECT DISTINCT category FROM products ORDER BY category";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                categories.add(rs.getString("category"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return categories;
    }

    public BigDecimal getInventoryValuation() {
        String sql = "SELECT SUM(stock_level * price) as total_valuation FROM products";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                BigDecimal valuation = rs.getBigDecimal("total_valuation");
                return valuation != null ? valuation : BigDecimal.ZERO;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public List<Map<String, Object>> getValuationByCategory() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT category, SUM(stock_level) as total_qty, SUM(stock_level * price) as category_val FROM products GROUP BY category";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("category", rs.getString("category"));
                map.put("quantity", rs.getInt("total_qty"));
                map.put("valuation", rs.getBigDecimal("category_val"));
                list.add(map);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private Product mapResultSetToProduct(ResultSet rs) throws SQLException {
        Product p = new Product();
        p.setId(rs.getInt("id"));
        p.setSku(rs.getString("sku"));
        p.setName(rs.getString("name"));
        p.setDescription(rs.getString("description"));
        p.setPrice(rs.getBigDecimal("price"));
        p.setCategory(rs.getString("category"));
        p.setStockLevel(rs.getInt("stock_level"));
        p.setReorderThreshold(rs.getInt("reorder_threshold"));
        p.setLeadTime(rs.getInt("lead_time"));
        p.setExpiryDate(rs.getDate("expiry_date"));
        int supId = rs.getInt("supplier_id");
        if (rs.wasNull()) {
            p.setSupplierId(null);
        } else {
            p.setSupplierId(supId);
        }
        return p;
    }
}
