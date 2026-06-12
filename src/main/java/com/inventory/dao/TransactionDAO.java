package com.inventory.dao;

import com.inventory.model.Transaction;
import com.inventory.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TransactionDAO {

    public List<Transaction> getAllTransactions() {
        List<Transaction> list = new ArrayList<>();
        String sql = "SELECT t.*, p.name as product_name, p.sku as product_sku " +
                     "FROM transactions t JOIN products p ON t.product_id = p.id " +
                     "ORDER BY t.transaction_date DESC, t.id DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Transaction t = mapResultSetToTransaction(rs);
                t.setProductName(rs.getString("product_name"));
                t.setProductSku(rs.getString("product_sku"));
                list.add(t);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Transaction> getTransactionsByProduct(int productId) {
        List<Transaction> list = new ArrayList<>();
        String sql = "SELECT t.*, p.name as product_name, p.sku as product_sku " +
                     "FROM transactions t JOIN products p ON t.product_id = p.id " +
                     "WHERE t.product_id = ? " +
                     "ORDER BY t.transaction_date DESC, t.id DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Transaction t = mapResultSetToTransaction(rs);
                    t.setProductName(rs.getString("product_name"));
                    t.setProductSku(rs.getString("product_sku"));
                    list.add(t);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Inserts a transaction and adjusts the product stock level atomically inside a transaction.
     */
    public boolean insertTransaction(Transaction t) {
        String insertSql = "INSERT INTO transactions (product_id, transaction_type, quantity, notes, transaction_date) VALUES (?, ?, ?, ?, ?)";
        String updateProductSql = "";
        
        // Determine stock adjustment based on type
        // SALE: decreases stock
        // PURCHASE / RETURN: increases stock
        // ADJUSTMENT: quantity specifies direct adjustment (can be positive or negative)
        int stockAdjustment = 0;
        String type = t.getTransactionType().toUpperCase();
        if (type.equals("SALE")) {
            stockAdjustment = -t.getQuantity();
        } else if (type.equals("PURCHASE") || type.equals("RETURN")) {
            stockAdjustment = t.getQuantity();
        } else if (type.equals("ADJUSTMENT")) {
            stockAdjustment = t.getQuantity(); // Direct modifier
        }

        Connection conn = null;
        PreparedStatement psInsert = null;
        PreparedStatement psUpdate = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Begin Transaction
            
            // 1. Insert transaction record
            psInsert = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS);
            psInsert.setInt(1, t.getProductId());
            psInsert.setString(2, t.getTransactionType());
            psInsert.setInt(3, t.getQuantity());
            psInsert.setString(4, t.getNotes());
            if (t.getTransactionDate() != null) {
                psInsert.setTimestamp(5, t.getTransactionDate());
            } else {
                psInsert.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
            }
            
            int inserted = psInsert.executeUpdate();
            if (inserted == 0) {
                conn.rollback();
                return false;
            }
            
            // 2. Update stock level in products
            updateProductSql = "UPDATE products SET stock_level = stock_level + ? WHERE id = ?";
            psUpdate = conn.prepareStatement(updateProductSql);
            psUpdate.setInt(1, stockAdjustment);
            psUpdate.setInt(2, t.getProductId());
            
            int updated = psUpdate.executeUpdate();
            if (updated == 0) {
                conn.rollback();
                return false;
            }
            
            conn.commit(); // Commit Transaction
            return true;
            
        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            return false;
        } finally {
            try {
                if (psInsert != null) psInsert.close();
                if (psUpdate != null) psUpdate.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    private Transaction mapResultSetToTransaction(ResultSet rs) throws SQLException {
        Transaction t = new Transaction();
        t.setId(rs.getInt("id"));
        t.setProductId(rs.getInt("product_id"));
        t.setTransactionType(rs.getString("transaction_type"));
        t.setQuantity(rs.getInt("quantity"));
        t.setTransactionDate(rs.getTimestamp("transaction_date"));
        t.setNotes(rs.getString("notes"));
        return t;
    }
}
