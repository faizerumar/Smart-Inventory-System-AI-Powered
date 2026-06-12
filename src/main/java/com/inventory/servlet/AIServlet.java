package com.inventory.servlet;

import com.google.gson.Gson;
import com.inventory.ai.AnomalyDetector;
import com.inventory.ai.DemandForecaster;
import com.inventory.ai.NLPQueryEngine;
import com.inventory.ai.SmartReorderEngine;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/api/ai")
public class AIServlet extends HttpServlet {
    
    private final NLPQueryEngine nlpEngine = new NLPQueryEngine();
    private final DemandForecaster forecaster = new DemandForecaster();
    private final AnomalyDetector anomalyDetector = new AnomalyDetector();
    private final SmartReorderEngine reorderEngine = new SmartReorderEngine();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String action = request.getParameter("action");
        PrintWriter out = response.getWriter();
        
        try {
            if ("forecast".equals(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                Map<String, Object> data = forecaster.getProductForecast(productId, 3);
                out.print(gson.toJson(data));
                
            } else if ("anomalies".equals(action)) {
                List<AnomalyDetector.AnomalyLog> logs = anomalyDetector.detectAnomalies();
                out.print(gson.toJson(logs));
                
            } else if ("reorder_recommendations".equals(action)) {
                List<SmartReorderEngine.ReorderRecommendation> recs = reorderEngine.getReorderRecommendations();
                out.print(gson.toJson(recs));
                
            } else {
                Map<String, String> err = new HashMap<>();
                err.put("error", "Invalid action");
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print(gson.toJson(err));
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, String> err = new HashMap<>();
            err.put("error", e.getMessage());
            out.print(gson.toJson(err));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String action = request.getParameter("action");
        PrintWriter out = response.getWriter();
        
        try {
            if ("chatbot".equals(action)) {
                String message = request.getParameter("message");
                NLPQueryEngine.ChatResponse chatRes = nlpEngine.processQuery(message);
                out.print(gson.toJson(chatRes));
                
            } else if ("run_auto_reorder".equals(action)) {
                int poCreated = reorderEngine.autoGeneratePurchaseOrders();
                Map<String, Object> res = new HashMap<>();
                res.put("success", true);
                res.put("poCreated", poCreated);
                out.print(gson.toJson(res));
                
            } else {
                Map<String, String> err = new HashMap<>();
                err.put("error", "Invalid action");
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print(gson.toJson(err));
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, String> err = new HashMap<>();
            err.put("error", e.getMessage());
            out.print(gson.toJson(err));
        }
    }
}
