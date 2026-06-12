package com.inventory.ai;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.PurchaseOrderDAO;
import com.inventory.model.Product;
import com.inventory.model.PurchaseOrder;
import com.inventory.model.PurchaseOrderItem;
import com.inventory.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SmartReorderEngine {

    private final ProductDAO productDAO = new ProductDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();

    public static class ReorderRecommendation {
        private int productId;
        private String sku;
        private String productName;
        private Integer supplierId;
        private String supplierName;
        private int reliabilityScore;
        private int leadTime;
        private double avgDailySales;
        private int safetyStock;
        private int reorderPoint;
        private int currentStock;
        private int recommendedQty;
        private BigDecimal unitPrice;
        private BigDecimal totalCost;

        public ReorderRecommendation() {}

        public int getProductId() { return productId; }
        public String getSku() { return sku; }
        public String getProductName() { return productName; }
        public Integer getSupplierId() { return supplierId; }
        public String getSupplierName() { return supplierName; }
        public int getReliabilityScore() { return reliabilityScore; }
        public int getLeadTime() { return leadTime; }
        public double getAvgDailySales() { return avgDailySales; }
        public int getSafetyStock() { return safetyStock; }
        public int getReorderPoint() { return reorderPoint; }
        public int getCurrentStock() { return currentStock; }
        public int getRecommendedQty() { return recommendedQty; }
        public BigDecimal getUnitPrice() { return unitPrice; }
        public BigDecimal getTotalCost() { return totalCost; }
    }

    /**
     * Calculates safety stock and ROP based on sales history and supplier characteristics,
     * compiling list of recommended items to order.
     */
    public List<ReorderRecommendation> getReorderRecommendations() {
        List<ReorderRecommendation> recs = new ArrayList<>();
        
        // 1. Fetch sales rates over last 60 days for all products
        Map<Integer, Double> avgSalesMap = getAverageDailySales(60);
        
        // 2. Fetch all products
        List<Product> products = productDAO.getAllProducts();
        
        // 3. For each product, calculate ROP
        String supplierSql = "SELECT reliability_score, name FROM suppliers WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement psSup = conn.prepareStatement(supplierSql)) {
             
            for (Product p : products) {
                if (p.getSupplierId() == null) continue; // Cannot order without a supplier
                
                // Fetch supplier details
                int reliability = 100;
                String supName = "Unknown";
                psSup.setInt(1, p.getSupplierId());
                try (ResultSet rs = psSup.executeQuery()) {
                    if (rs.next()) {
                        reliability = rs.getInt("reliability_score");
                        supName = rs.getString("name");
                    }
                }
                
                double avgDailySales = avgSalesMap.getOrDefault(p.getId(), 0.5); // fallback to 0.5 unit/day if new
                
                // Safety Stock formula considering lead time and reliability
                // Multiplier increases from 0.5 to 1.5 as reliability score falls from 100 to 0
                double reliabilityMultiplier = 1.5 - (reliability / 100.0);
                double safetyStockCalc = avgDailySales * p.getLeadTime() * reliabilityMultiplier;
                int safetyStock = (int) Math.ceil(safetyStockCalc);
                
                // Reorder Point = (Daily Sales * Lead Time) + Safety Stock
                int reorderPoint = (int) Math.ceil(avgDailySales * p.getLeadTime()) + safetyStock;
                
                // If stock level is at or below reorder point, recommend order
                if (p.getStockLevel() <= reorderPoint) {
                    ReorderRecommendation rec = new ReorderRecommendation();
                    rec.productId = p.getId();
                    rec.sku = p.getSku();
                    rec.productName = p.getName();
                    rec.supplierId = p.getSupplierId();
                    rec.supplierName = supName;
                    rec.reliabilityScore = reliability;
                    rec.leadTime = p.getLeadTime();
                    rec.avgDailySales = Math.round(avgDailySales * 100.0) / 100.0;
                    rec.safetyStock = safetyStock;
                    rec.reorderPoint = reorderPoint;
                    rec.currentStock = p.getStockLevel();
                    
                    // Recommended qty is: 30 days of sales + safety stock - current stock
                    int targetStock = (int) Math.ceil(avgDailySales * 30) + safetyStock;
                    int recommendedQty = Math.max(10, targetStock - p.getStockLevel()); // Order at least 10 units
                    rec.recommendedQty = recommendedQty;
                    
                    rec.unitPrice = p.getPrice();
                    rec.totalCost = p.getPrice().multiply(new BigDecimal(recommendedQty));
                    
                    recs.add(rec);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return recs;
    }

    /**
     * Groups recommendations by supplier and generates purchase order draft records in database.
     * Returns the count of purchase orders successfully created.
     */
    public int autoGeneratePurchaseOrders() {
        List<ReorderRecommendation> recs = getReorderRecommendations();
        if (recs.isEmpty()) return 0;
        
        // Group recommendations by Supplier ID
        Map<Integer, List<ReorderRecommendation>> supplierGroups = new HashMap<>();
        for (ReorderRecommendation r : recs) {
            supplierGroups.putIfAbsent(r.getSupplierId(), new ArrayList<>());
            supplierGroups.get(r.getSupplierId()).add(r);
        }
        
        int poCount = 0;
        
        for (Map.Entry<Integer, List<ReorderRecommendation>> entry : supplierGroups.entrySet()) {
            int supplierId = entry.getKey();
            List<ReorderRecommendation> itemsToOrder = entry.getValue();
            
            PurchaseOrder po = new PurchaseOrder();
            po.setSupplierId(supplierId);
            po.setStatus("PENDING");
            po.setOrderDate(new Timestamp(System.currentTimeMillis()));
            
            // Expected delivery date is: current date + max lead time of items in this order
            int maxLeadTime = 0;
            for (ReorderRecommendation r : itemsToOrder) {
                if (r.getLeadTime() > maxLeadTime) {
                    maxLeadTime = r.getLeadTime();
                }
            }
            long deliveryMillis = System.currentTimeMillis() + ((long) maxLeadTime * 24 * 60 * 60 * 1000);
            po.setExpectedDeliveryDate(new Date(deliveryMillis));
            
            // Compile purchase order items
            for (ReorderRecommendation r : itemsToOrder) {
                PurchaseOrderItem item = new PurchaseOrderItem();
                item.setProductId(r.getProductId());
                item.setQuantity(r.getRecommendedQty());
                item.setUnitPrice(r.getUnitPrice());
                po.addItem(item);
            }
            
            boolean ok = poDAO.insertPurchaseOrder(po);
            if (ok) {
                poCount++;
            }
        }
        
        return poCount;
    }

    /**
     * Calculates the average daily sales of all products over a trailing window of days.
     */
    private Map<Integer, Double> getAverageDailySales(int trailingDays) {
        Map<Integer, Double> map = new HashMap<>();
        String sql = "SELECT product_id, SUM(quantity) as total_sold " +
                     "FROM transactions " +
                     "WHERE transaction_type = 'SALE' AND transaction_date >= DATE_SUB(NOW(), INTERVAL ? DAY) " +
                     "GROUP BY product_id";
                     
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, trailingDays);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int prodId = rs.getInt("product_id");
                    int totalSold = rs.getInt("total_sold");
                    double dailyAvg = (double) totalSold / trailingDays;
                    map.put(prodId, dailyAvg);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return map;
    }
}
