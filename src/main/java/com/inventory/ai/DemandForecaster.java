package com.inventory.ai;

import com.inventory.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DemandForecaster {

    private static final double ALPHA = 0.3; // Smoothing factor for data level
    private static final double BETA = 0.2;  // Smoothing factor for trend

    /**
     * Forecasts sales for the next N months using Holt's Linear Exponential Smoothing.
     */
    public static List<Double> forecastDemand(List<Double> history, int periodsToForecast) {
        List<Double> forecasts = new ArrayList<>();
        if (history == null || history.isEmpty()) {
            for (int i = 0; i < periodsToForecast; i++) forecasts.add(0.0);
            return forecasts;
        }

        int n = history.size();
        
        // Edge Case: 1 data point
        if (n == 1) {
            double val = history.get(0);
            for (int i = 0; i < periodsToForecast; i++) forecasts.add(val);
            return forecasts;
        }
        
        // Edge Case: 2 or 3 data points - use simple linear regression
        if (n < 4) {
            double slope = (history.get(n - 1) - history.get(0)) / (n - 1);
            double lastVal = history.get(n - 1);
            for (int i = 1; i <= periodsToForecast; i++) {
                double val = lastVal + (slope * i);
                forecasts.add(Math.max(0.0, Math.round(val * 10.0) / 10.0));
            }
            return forecasts;
        }

        // Double Exponential Smoothing (Holt's Method)
        double level = history.get(0);
        double trend = history.get(1) - history.get(0);

        // Warm up the level and trend through historical data
        for (int i = 1; i < n; i++) {
            double currentObs = history.get(i);
            double lastLevel = level;
            
            level = ALPHA * currentObs + (1.0 - ALPHA) * (level + trend);
            trend = BETA * (level - lastLevel) + (1.0 - BETA) * trend;
        }

        // Project forecasts
        for (int m = 1; m <= periodsToForecast; m++) {
            double forecastVal = level + (m * trend);
            forecasts.add(Math.max(0.0, Math.round(forecastVal * 10.0) / 10.0));
        }

        return forecasts;
    }

    /**
     * Queries database to compile historical monthly sales and predicts the next N months.
     */
    public Map<String, Object> getProductForecast(int productId, int forecastMonths) {
        Map<String, Object> result = new HashMap<>();
        List<Double> history = new ArrayList<>();
        List<String> labels = new ArrayList<>();
        
        String sql = "SELECT YEAR(transaction_date) as yr, MONTH(transaction_date) as mon, SUM(quantity) as total_qty " +
                     "FROM transactions " +
                     "WHERE product_id = ? AND transaction_type = 'SALE' " +
                     "GROUP BY YEAR(transaction_date), MONTH(transaction_date) " +
                     "ORDER BY yr ASC, mon ASC";
                     
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    double qty = rs.getDouble("total_qty");
                    int yr = rs.getInt("yr");
                    int mon = rs.getInt("mon");
                    history.add(qty);
                    labels.add(yr + "-" + String.format("%02d", mon));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        // If history is empty, populate with some zeros or fallback
        if (history.isEmpty()) {
            history.add(0.0);
            labels.add("Current");
        }

        List<Double> forecast = forecastDemand(history, forecastMonths);
        
        // Generate forecast month labels (project forward)
        List<String> forecastLabels = new ArrayList<>();
        int lastYr = 2026;
        int lastMon = 6; // default fallback starts after mock data end date (May 2026)
        
        if (labels.size() > 0 && labels.get(labels.size() - 1).contains("-")) {
            String[] parts = labels.get(labels.size() - 1).split("-");
            lastYr = Integer.parseInt(parts[0]);
            lastMon = Integer.parseInt(parts[1]);
        }
        
        for (int i = 1; i <= forecastMonths; i++) {
            lastMon++;
            if (lastMon > 12) {
                lastMon = 1;
                lastYr++;
            }
            forecastLabels.add(lastYr + "-" + String.format("%02d", monToShortName(lastMon)) + " (FC)");
        }

        result.put("history", history);
        result.put("historyLabels", labels);
        result.put("forecast", forecast);
        result.put("forecastLabels", forecastLabels);
        
        // Calculate dynamic recommended restock qty for next month
        double nextMonthForecast = forecast.isEmpty() ? 0.0 : forecast.get(0);
        result.put("recommendedRestock", (int) Math.ceil(nextMonthForecast));
        
        return result;
    }

    private String monToShortName(int month) {
        String[] months = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
        if (month >= 1 && month <= 12) return months[month];
        return "Month";
    }
}
