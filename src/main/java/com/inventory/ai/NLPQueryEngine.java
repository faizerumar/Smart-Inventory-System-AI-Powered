package com.inventory.ai;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.TransactionDAO;
import com.inventory.model.Product;
import com.inventory.model.Transaction;
import com.inventory.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Map;

public class NLPQueryEngine {
    
    private final ProductDAO productDAO = new ProductDAO();
    private final TransactionDAO transactionDAO = new TransactionDAO();
    private final NumberFormat curFormat = NumberFormat.getCurrencyInstance(Locale.US);

    public static class ChatResponse {
        private String text;
        private boolean success;
        private String actionType; // UPDATE, QUERY, FORECAST, HELP

        public ChatResponse(String text, boolean success, String actionType) {
            this.text = text;
            this.success = success;
            this.actionType = actionType;
        }

        public String getText() { return text; }
        public boolean isSuccess() { return success; }
        public String getActionType() { return actionType; }
    }

    public ChatResponse processQuery(String query) {
        if (query == null || query.trim().isEmpty()) {
            return new ChatResponse("Please ask me a question about your inventory.", false, "HELP");
        }
        
        String cleanQuery = query.toLowerCase().trim();

        // 1. Match: "Which items will run out this week?" or "low stock" or "out of stock"
        if (cleanQuery.contains("run out") || cleanQuery.contains("low stock") || cleanQuery.contains("out of stock")) {
            return handleLowStockQuery();
        }

        // 2. Match: "What's our best-selling category?" or "best selling category" or "top selling category"
        if (cleanQuery.contains("best-selling category") || cleanQuery.contains("best selling category") || cleanQuery.contains("top selling category")) {
            return handleBestSellingCategoryQuery();
        }

        // 3. Match: "Increase stock of SKU [SKU] by [quantity]" or "add stock of SKU [SKU] by [quantity]"
        Pattern increasePattern = Pattern.compile("(?:increase|add)\\s+stock\\s+of\\s+(?:sku\\s+)?([a-zA-Z0-9\\-]+)\\s+by\\s+(\\d+)", Pattern.CASE_INSENSITIVE);
        Matcher increaseMatcher = increasePattern.matcher(cleanQuery);
        if (increaseMatcher.find()) {
            String sku = increaseMatcher.group(1).toUpperCase();
            int qty = Integer.parseInt(increaseMatcher.group(2));
            return handleStockAdjustment(sku, qty, "increase");
        }

        // 4. Match: "Decrease stock of SKU [SKU] by [quantity]" or "remove stock of SKU [SKU] by [quantity]"
        Pattern decreasePattern = Pattern.compile("(?:decrease|reduce|remove)\\s+stock\\s+of\\s+(?:sku\\s+)?([a-zA-Z0-9\\-]+)\\s+by\\s+(\\d+)", Pattern.CASE_INSENSITIVE);
        Matcher decreaseMatcher = decreasePattern.matcher(cleanQuery);
        if (decreaseMatcher.find()) {
            String sku = decreaseMatcher.group(1).toUpperCase();
            int qty = Integer.parseInt(decreaseMatcher.group(2));
            return handleStockAdjustment(sku, qty, "decrease");
        }

        // 5. Match: "What is the valuation of category [category]?" or "valuation of [category]"
        Pattern valuationPattern = Pattern.compile("valuation\\s+of\\s+(?:category\\s+)?([a-zA-Z0-9\\s\\-]+)", Pattern.CASE_INSENSITIVE);
        Matcher valuationMatcher = valuationPattern.matcher(cleanQuery);
        if (valuationMatcher.find()) {
            String category = valuationMatcher.group(1).trim();
            // Capitalize first letter of category for safety
            if (!category.isEmpty()) {
                category = category.substring(0, 1).toUpperCase() + category.substring(1);
            }
            return handleCategoryValuationQuery(category);
        }

        // 6. Match: "Predict demand for SKU [SKU]" or "forecast demand for SKU [SKU]"
        Pattern forecastPattern = Pattern.compile("(?:predict|forecast|forecasted)\\s+demand\\s+for\\s+(?:sku\\s+)?([a-zA-Z0-9\\-]+)", Pattern.CASE_INSENSITIVE);
        Matcher forecastMatcher = forecastPattern.matcher(cleanQuery);
        if (forecastMatcher.find()) {
            String sku = forecastMatcher.group(1).toUpperCase();
            return handleForecastQuery(sku);
        }

        // Default: Help instructions
        return getHelpResponse();
    }

    private ChatResponse handleLowStockQuery() {
        List<Product> lowStock = productDAO.getLowStockProducts();
        if (lowStock.isEmpty()) {
            return new ChatResponse("Great news! No products are currently below their reorder thresholds.", true, "QUERY");
        }
        
        StringBuilder sb = new StringBuilder("Here are the products currently low on stock:\n\n");
        for (Product p : lowStock) {
            sb.append(String.format("• **%s** (%s) - Stock: **%d** (Threshold: %d, Supplier: %s)\n", 
                      p.getName(), p.getSku(), p.getStockLevel(), p.getReorderThreshold(), 
                      p.getSupplierName() != null ? p.getSupplierName() : "None"));
        }
        return new ChatResponse(sb.toString(), true, "QUERY");
    }

    private ChatResponse handleBestSellingCategoryQuery() {
        String sql = "SELECT p.category, SUM(t.quantity) as total_sold " +
                     "FROM transactions t JOIN products p ON t.product_id = p.id " +
                     "WHERE t.transaction_type = 'SALE' " +
                     "GROUP BY p.category ORDER BY total_sold DESC LIMIT 1";
                     
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
             
            if (rs.next()) {
                String category = rs.getString("category");
                int totalSold = rs.getInt("total_sold");
                return new ChatResponse(String.format("Our best-selling category is **%s**, with a total of **%d** units sold in recorded transactions!", category, totalSold), true, "QUERY");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return new ChatResponse("I couldn't aggregate sales data. Check if transactions have been recorded.", false, "QUERY");
    }

    private ChatResponse handleStockAdjustment(String sku, int quantity, String direction) {
        Product p = productDAO.getProductBySku(sku);
        if (p == null) {
            return new ChatResponse(String.format("I couldn't find a product with SKU **%s**. Please check and try again.", sku), false, "UPDATE");
        }

        int adjustmentValue = direction.equalsIgnoreCase("increase") ? quantity : -quantity;
        
        if (direction.equalsIgnoreCase("decrease") && p.getStockLevel() < quantity) {
            return new ChatResponse(String.format("Cannot decrease stock for **%s** by %d. Current stock is only %d.", p.getName(), quantity, p.getStockLevel()), false, "UPDATE");
        }

        Transaction t = new Transaction();
        t.setProductId(p.getId());
        t.setTransactionType("ADJUSTMENT");
        t.setQuantity(adjustmentValue);
        t.setNotes("Stock adjusted via AI Chatbot Command");
        t.setTransactionDate(new Timestamp(System.currentTimeMillis()));

        boolean ok = transactionDAO.insertTransaction(t);
        if (ok) {
            int newStock = p.getStockLevel() + adjustmentValue;
            return new ChatResponse(String.format("Stock updated! SKU **%s** (%s) has been %sd by **%d** units. New inventory level: **%d**.", 
                                    sku, p.getName(), direction + "d", quantity, newStock), true, "UPDATE");
        } else {
            return new ChatResponse("Sorry, a database error occurred while updating the stock level.", false, "UPDATE");
        }
    }

    private ChatResponse handleCategoryValuationQuery(String category) {
        String sql = "SELECT SUM(stock_level) as total_qty, SUM(stock_level * price) as val " +
                     "FROM products WHERE LOWER(category) = LOWER(?)";
                     
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
             
            ps.setString(1, category);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int totalQty = rs.getInt("total_qty");
                    BigDecimal val = rs.getBigDecimal("val");
                    if (val == null || totalQty == 0) {
                        return new ChatResponse(String.format("Category **%s** has no current stock or does not exist.", category), true, "QUERY");
                    }
                    return new ChatResponse(String.format("The current inventory valuation for **%s** is **%s** (across **%d** total items in stock).", 
                                            category, curFormat.format(val), totalQty), true, "QUERY");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return new ChatResponse("Failed to calculate valuation due to database error.", false, "QUERY");
    }

    private ChatResponse handleForecastQuery(String sku) {
        Product p = productDAO.getProductBySku(sku);
        if (p == null) {
            return new ChatResponse(String.format("I couldn't find a product with SKU **%s**.", sku), false, "FORECAST");
        }

        DemandForecaster forecaster = new DemandForecaster();
        Map<String, Object> forecastData = forecaster.getProductForecast(p.getId(), 3);
        List<Double> forecast = (List<Double>) forecastData.get("forecast");
        
        if (forecast == null || forecast.isEmpty()) {
            return new ChatResponse("Insufficient data to generate a forecast.", false, "FORECAST");
        }

        double nextMonthFC = forecast.get(0);
        int recommendedRestock = (int) forecastData.get("recommendedRestock");

        StringBuilder sb = new StringBuilder();
        sb.append(String.format("### Demand Forecast for **%s** (%s)\n\n", p.getName(), p.getSku()));
        sb.append(String.format("• **Current stock level**: %d units\n", p.getStockLevel()));
        sb.append(String.format("• **Predicted demand (Next Month)**: **%.1f** units\n", nextMonthFC));
        sb.append(String.format("• **Recommended purchase order quantity**: **%d** units\n\n", 
                                Math.max(0, recommendedRestock - p.getStockLevel())));
        sb.append("*You can view detailed multi-month forecasting lines in the **AI Center** page.*");

        return new ChatResponse(sb.toString(), true, "FORECAST");
    }

    private ChatResponse getHelpResponse() {
        String helpText = "Hello! I am your local AI Assistant. Here are some natural language commands I understand:\n\n" +
                          "1. **Stock Queries**\n" +
                          "   • *\"Which items will run out this week?\"*\n" +
                          "   • *\"What is our low stock level?\"*\n\n" +
                          "2. **Sales Analytics**\n" +
                          "   • *\"What's our best-selling category?\"*\n" +
                          "   • *\"Valuation of category Electronics\"*\n\n" +
                          "3. **Quick Stock Modifications**\n" +
                          "   • *\"Increase stock of SKU PROD-102 by 15\"*\n" +
                          "   • *\"Decrease stock of SKU PROD-101 by 2\"*\n\n" +
                          "4. **Smart Demand Forecasting**\n" +
                          "   • *\"Predict demand for SKU PROD-101\"*";
                          
        return new ChatResponse(helpText, true, "HELP");
    }
}
