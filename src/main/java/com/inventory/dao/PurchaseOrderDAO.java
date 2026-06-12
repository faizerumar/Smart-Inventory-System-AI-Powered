package com.inventory.dao;

import com.inventory.model.PurchaseOrder;
import com.inventory.model.PurchaseOrderItem;
import com.inventory.model.Transaction;
import com.inventory.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PurchaseOrderDAO {

    public List<PurchaseOrder> getAllPurchaseOrders() {
        List<PurchaseOrder> list = new ArrayList<>();
        String sql = "SELECT po.*, s.name as supplier_name FROM purchase_orders po " +
                     "LEFT JOIN suppliers s ON po.supplier_id = s.id ORDER BY po.order_date DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToPurchaseOrder(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public PurchaseOrder getPurchaseOrderById(int id) {
        String sql = "SELECT po.*, s.name as supplier_name FROM purchase_orders po " +
                     "LEFT JOIN suppliers s ON po.supplier_id = s.id WHERE po.id = ?";
        PurchaseOrder po = null;
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    po = mapResultSetToPurchaseOrder(rs);
                }
            }
            if (po != null) {
                po.setItems(getPurchaseOrderItems(id, conn));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return po;
    }

    private List<PurchaseOrderItem> getPurchaseOrderItems(int poId, Connection conn) throws SQLException {
        List<PurchaseOrderItem> items = new ArrayList<>();
        String sql = "SELECT poi.*, p.name as product_name, p.sku as product_sku FROM purchase_order_items poi " +
                     "JOIN products p ON poi.product_id = p.id WHERE poi.purchase_order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PurchaseOrderItem item = new PurchaseOrderItem();
                    item.setId(rs.getInt("id"));
                    item.setPurchaseOrderId(rs.getInt("purchase_order_id"));
                    item.setProductId(rs.getInt("product_id"));
                    item.setQuantity(rs.getInt("quantity"));
                    item.setUnitPrice(rs.getBigDecimal("unit_price"));
                    item.setProductName(rs.getString("product_name"));
                    item.setProductSku(rs.getString("product_sku"));
                    items.add(item);
                }
            }
        }
        return items;
    }

    /**
     * Inserts a purchase order and its list of items.
     */
    public boolean insertPurchaseOrder(PurchaseOrder po) {
        String insertPoSql = "INSERT INTO purchase_orders (supplier_id, order_date, expected_delivery_date, status, total_amount) VALUES (?, ?, ?, ?, ?)";
        String insertItemSql = "INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)";
        
        Connection conn = null;
        PreparedStatement psPo = null;
        PreparedStatement psItem = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Begin Transaction
            
            // Calculate total amount from items
            BigDecimal total = BigDecimal.ZERO;
            for (PurchaseOrderItem item : po.getItems()) {
                BigDecimal itemCost = item.getUnitPrice().multiply(new BigDecimal(item.getQuantity()));
                total = total.add(itemCost);
            }
            po.setTotalAmount(total);

            // 1. Insert Purchase Order
            psPo = conn.prepareStatement(insertPoSql, Statement.RETURN_GENERATED_KEYS);
            if (po.getSupplierId() != null) {
                psPo.setInt(1, po.getSupplierId());
            } else {
                psPo.setNull(1, Types.INTEGER);
            }
            psPo.setTimestamp(2, po.getOrderDate() != null ? po.getOrderDate() : new Timestamp(System.currentTimeMillis()));
            psPo.setDate(3, po.getExpectedDeliveryDate());
            psPo.setString(4, po.getStatus());
            psPo.setBigDecimal(5, po.getTotalAmount());
            
            int affected = psPo.executeUpdate();
            if (affected == 0) {
                conn.rollback();
                return false;
            }
            
            // Get the generated PO ID
            int poId = 0;
            try (ResultSet generatedKeys = psPo.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    poId = generatedKeys.getInt(1);
                } else {
                    conn.rollback();
                    return false;
                }
            }
            
            // 2. Insert items
            psItem = conn.prepareStatement(insertItemSql);
            for (PurchaseOrderItem item : po.getItems()) {
                psItem.setInt(1, poId);
                psItem.setInt(2, item.getProductId());
                psItem.setInt(3, item.getQuantity());
                psItem.setBigDecimal(4, item.getUnitPrice());
                psItem.addBatch();
            }
            psItem.executeBatch();
            
            conn.commit(); // Commit Transaction
            return true;
            
        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            return false;
        } finally {
            try {
                if (psPo != null) psPo.close();
                if (psItem != null) psItem.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Updates status. If transitioning to DELIVERED, automatically triggers product restock.
     */
    public boolean updatePurchaseOrderStatus(int poId, String newStatus) {
        PurchaseOrder po = getPurchaseOrderById(poId);
        if (po == null) return false;
        
        // If already delivered, don't re-deliver (avoid double stock adjustment)
        if (po.getStatus().equalsIgnoreCase("DELIVERED") && newStatus.equalsIgnoreCase("DELIVERED")) {
            return false;
        }
        
        String sql = "UPDATE purchase_orders SET status = ? WHERE id = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Begin Transaction
            
            // Update PO Status
            ps = conn.prepareStatement(sql);
            ps.setString(1, newStatus);
            ps.setInt(2, poId);
            int affected = ps.executeUpdate();
            if (affected == 0) {
                conn.rollback();
                return false;
            }
            
            // If new status is DELIVERED, add a PURCHASE transaction for each item
            if (newStatus.equalsIgnoreCase("DELIVERED")) {
                TransactionDAO transDao = new TransactionDAO();
                for (PurchaseOrderItem item : po.getItems()) {
                    Transaction t = new Transaction();
                    t.setProductId(item.getProductId());
                    t.setTransactionType("PURCHASE");
                    t.setQuantity(item.getQuantity());
                    t.setNotes("Delivered stock from PO #" + poId);
                    t.setTransactionDate(new Timestamp(System.currentTimeMillis()));
                    
                    // We call transaction insert inside our current connection context to ensure atomicity,
                    // or just use transactionDao since we are committing. Let's insert directly to keep transaction atomic.
                    String transSql = "INSERT INTO transactions (product_id, transaction_type, quantity, notes, transaction_date) VALUES (?, 'PURCHASE', ?, ?, ?)";
                    String prodSql = "UPDATE products SET stock_level = stock_level + ? WHERE id = ?";
                    
                    try (PreparedStatement psTrans = conn.prepareStatement(transSql);
                         PreparedStatement psProd = conn.prepareStatement(prodSql)) {
                        
                        psTrans.setInt(1, item.getProductId());
                        psTrans.setInt(2, item.getQuantity());
                        psTrans.setString(3, "Delivered stock from PO #" + poId);
                        psTrans.setTimestamp(4, new Timestamp(System.currentTimeMillis()));
                        psTrans.executeUpdate();
                        
                        psProd.setInt(1, item.getQuantity());
                        psProd.setInt(2, item.getProductId());
                        psProd.executeUpdate();
                    }
                }
            }
            
            conn.commit(); // Commit all
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            return false;
        } finally {
            try {
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    private PurchaseOrder mapResultSetToPurchaseOrder(ResultSet rs) throws SQLException {
        PurchaseOrder po = new PurchaseOrder();
        po.setId(rs.getInt("id"));
        int supId = rs.getInt("supplier_id");
        if (rs.wasNull()) {
            po.setSupplierId(null);
        } else {
            po.setSupplierId(supId);
        }
        po.setOrderDate(rs.getTimestamp("order_date"));
        po.setExpectedDeliveryDate(rs.getDate("expected_delivery_date"));
        po.setStatus(rs.getString("status"));
        po.setTotalAmount(rs.getBigDecimal("total_amount"));
        po.setSupplierName(rs.getString("supplier_name"));
        return po;
    }
}
