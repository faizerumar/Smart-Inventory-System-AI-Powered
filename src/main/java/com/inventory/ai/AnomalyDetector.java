package com.inventory.ai;

import com.inventory.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AnomalyDetector {

    public static class AnomalyLog {
        private int transactionId;
        private String productSku;
        private String productName;
        private String transactionType;
        private int quantity;
        private Timestamp transactionDate;
        private String notes;
        private double mean;
        private double stdDev;
        private double zScore;
        private String anomalyReason;

        public AnomalyLog(int transactionId, String productSku, String productName, String transactionType, 
                          int quantity, Timestamp transactionDate, String notes, double mean, double stdDev, 
                          double zScore, String anomalyReason) {
            this.transactionId = transactionId;
            this.productSku = productSku;
            this.productName = productName;
            this.transactionType = transactionType;
            this.quantity = quantity;
            this.transactionDate = transactionDate;
            this.notes = notes;
            this.mean = mean;
            this.stdDev = stdDev;
            this.zScore = zScore;
            this.anomalyReason = anomalyReason;
        }

        public int getTransactionId() { return transactionId; }
        public String getProductSku() { return productSku; }
        public String getProductName() { return productName; }
        public String getTransactionType() { return transactionType; }
        public int getQuantity() { return quantity; }
        public Timestamp getTransactionDate() { return transactionDate; }
        public String getNotes() { return notes; }
        public double getMean() { return mean; }
        public double getStdDev() { return stdDev; }
        public double getZScore() { return zScore; }
        public String getAnomalyReason() { return anomalyReason; }
    }

    /**
     * Scans all transactions and flags statistical outliers using Z-score logic.
     */
    public List<AnomalyLog> detectAnomalies() {
        List<AnomalyLog> anomalies = new ArrayList<>();
        
        // 1. Fetch all transactions along with SKU/Name
        String sql = "SELECT t.*, p.sku as product_sku, p.name as product_name " +
                     "FROM transactions t JOIN products p ON t.product_id = p.id " +
                     "ORDER BY t.transaction_date DESC";
                     
        // 2. We will group transaction quantities by (productId + "_" + transactionType)
        // to calculate the mean and standard deviation for each unique product-transaction type category.
        Map<String, List<Integer>> transactionGroups = new HashMap<>();
        List<Map<String, Object>> allRecords = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
             
            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("id", rs.getInt("id"));
                record.put("product_id", rs.getInt("product_id"));
                record.put("sku", rs.getString("product_sku"));
                record.put("name", rs.getString("product_name"));
                record.put("type", rs.getString("transaction_type"));
                record.put("qty", rs.getInt("quantity"));
                record.put("date", rs.getTimestamp("transaction_date"));
                record.put("notes", rs.getString("notes"));
                allRecords.add(record);
                
                String key = rs.getInt("product_id") + "_" + rs.getString("transaction_type");
                transactionGroups.putIfAbsent(key, new ArrayList<>());
                transactionGroups.get(key).add(rs.getInt("quantity"));
            }
            
            // Calculate statistical parameters for each group
            Map<String, Double> means = new HashMap<>();
            Map<String, Double> stdDevs = new HashMap<>();
            
            for (Map.Entry<String, List<Integer>> entry : transactionGroups.entrySet()) {
                String key = entry.getKey();
                List<Integer> qties = entry.getValue();
                
                // Calculate Mean
                double sum = 0;
                for (int q : qties) sum += q;
                double mean = sum / qties.size();
                means.put(key, mean);
                
                // Calculate Standard Deviation
                double sqDiffSum = 0;
                for (int q : qties) {
                    sqDiffSum += Math.pow(q - mean, 2);
                }
                double variance = sqDiffSum / qties.size();
                double stdDev = Math.sqrt(variance);
                
                // Avoid division by zero if all values are identical
                if (stdDev < 1.0) {
                    stdDev = 1.0;
                }
                stdDevs.put(key, stdDev);
            }
            
            // 3. Scan records and compute Z-Score
            for (Map<String, Object> r : allRecords) {
                int id = (int) r.get("id");
                int prodId = (int) r.get("product_id");
                String sku = (String) r.get("sku");
                String name = (String) r.get("name");
                String type = (String) r.get("type");
                int qty = (int) r.get("qty");
                Timestamp date = (Timestamp) r.get("date");
                String notes = (String) r.get("notes");
                
                String key = prodId + "_" + type;
                double mean = means.get(key);
                double stdDev = stdDevs.get(key);
                
                // Formula: Z = (X - Mean) / StdDev
                double z = (qty - mean) / stdDev;
                
                // Flag as Anomaly if |Z| > 2.0 (standard statistical threshold for small-mid datasets)
                // Also flag manual stock ADJUSTMENTS with high quantities since they represent data loss/spoilage.
                boolean isOutlier = Math.abs(z) > 2.0;
                boolean isLargeAdjustment = type.equalsIgnoreCase("ADJUSTMENT") && qty >= 15;
                
                if (isOutlier || isLargeAdjustment) {
                    String reason = "";
                    if (isLargeAdjustment && !isOutlier) {
                        reason = "Manual Adjustment warning: Stock modification of " + qty + " units represents a significant inventory write-off.";
                    } else {
                        reason = String.format("Statistical Outlier: Quantity of %d is %.2f standard deviations away from the product's normal %s average of %.1f units.", 
                                              qty, Math.abs(z), type, mean);
                    }
                    
                    // Add to results
                    anomalies.add(new AnomalyLog(
                        id, sku, name, type, qty, date, notes, 
                        Math.round(mean * 10.0)/10.0, 
                        Math.round(stdDev * 10.0)/10.0, 
                        Math.round(z * 100.0)/100.0, 
                        reason
                    ));
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return anomalies;
    }
}
