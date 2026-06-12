<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.dao.ProductDAO" %>
<%@ page import="com.inventory.dao.PurchaseOrderDAO" %>
<%@ page import="com.inventory.model.Product" %>
<%@ page import="com.inventory.model.PurchaseOrder" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.google.gson.Gson" %>

<%@ include file="/includes/header.jsp" %>

<%
    // Instantiate DAOs for real-time dashboard stats
    ProductDAO prodDAO = new ProductDAO();
    PurchaseOrderDAO orderDAO = new PurchaseOrderDAO();

    // 1. Inventory Valuation
    BigDecimal valuation = prodDAO.getInventoryValuation();
    NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(Locale.US);
    String formattedValuation = currencyFormat.format(valuation);

    // 2. Low Stock Count
    int lowStockCount = prodDAO.getLowStockProducts().size();

    // 3. Expiring/Near Expiry (within 30 days)
    int expiringCount = prodDAO.getExpiredOrNearExpiryProducts(30).size();

    // 4. Pending Purchase Orders
    List<PurchaseOrder> allOrders = orderDAO.getAllPurchaseOrders();
    int pendingPOCount = 0;
    for (PurchaseOrder po : allOrders) {
        if ("PENDING".equalsIgnoreCase(po.getStatus())) {
            pendingPOCount++;
        }
    }

    // 5. Categorical Stock Distribution (For Chart.js representation)
    List<Map<String, Object>> categoriesData = prodDAO.getValuationByCategory();
    String categoriesJson = new Gson().toJson(categoriesData);
%>

<div class="dashboard-wrapper">
    <!-- Row 1: KPI Stats Grid -->
    <div class="stats-grid">
        <!-- Card 1: Valuation -->
        <div class="stat-card valuation-card">
            <div class="card-icon-container bg-glow-blue">
                <i class="fa-solid fa-coins icon-blue"></i>
            </div>
            <div class="card-details">
                <span class="card-title">Inventory Valuation</span>
                <span class="card-value"><%= formattedValuation %></span>
                <span class="card-subtitle">Real-time asset value</span>
            </div>
            <div class="glow-layer"></div>
        </div>

        <!-- Card 2: Low Stock Alerts -->
        <a href="${pageContext.request.contextPath}/products?filter=low" class="stat-card alert-card low-stock-card">
            <div class="card-icon-container bg-glow-yellow">
                <i class="fa-solid fa-triangle-exclamation icon-yellow"></i>
            </div>
            <div class="card-details">
                <span class="card-title">Low Stock Items</span>
                <span class="card-value <%= lowStockCount > 0 ? "text-yellow animate-pulse" : "" %>"><%= lowStockCount %></span>
                <span class="card-subtitle">At or below threshold</span>
            </div>
            <div class="glow-layer"></div>
        </a>

        <!-- Card 3: Expiry warnings -->
        <div class="stat-card alert-card expiry-card">
            <div class="card-icon-container bg-glow-red">
                <i class="fa-solid fa-hourglass-half icon-red"></i>
            </div>
            <div class="card-details">
                <span class="card-title">Expiring / Expired</span>
                <span class="card-value <%= expiringCount > 0 ? "text-red" : "" %>"><%= expiringCount %></span>
                <span class="card-subtitle">Critical window (30 days)</span>
            </div>
            <div class="glow-layer"></div>
        </div>

        <!-- Card 4: Pending Invoices -->
        <a href="${pageContext.request.contextPath}/purchaseorders" class="stat-card po-card">
            <div class="card-icon-container bg-glow-purple">
                <i class="fa-solid fa-truck-ramp-box icon-purple"></i>
            </div>
            <div class="card-details">
                <span class="card-title">Pending Orders</span>
                <span class="card-value"><%= pendingPOCount %></span>
                <span class="card-subtitle">Awaiting shipment</span>
            </div>
            <div class="glow-layer"></div>
        </a>
    </div>

    <!-- Row 2: Charts & Chatbot Assistant Layout -->
    <div class="dashboard-body">
        <!-- Left Column: Visual Analytics -->
        <div class="visual-analytics">
            <div class="glass-panel chart-panel">
                <div class="panel-header">
                    <h3>Category Stock Allocation</h3>
                    <i class="fa-solid fa-chart-pie panel-header-icon"></i>
                </div>
                <div class="chart-container">
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>
            
            <!-- Quick System Audit Info -->
            <div class="glass-panel system-info-panel">
                <div class="panel-header">
                    <h3>Core Engine Status</h3>
                    <i class="fa-solid fa-microchip panel-header-icon"></i>
                </div>
                <div class="system-logs">
                    <div class="log-row">
                        <span class="log-label"><i class="fa-solid fa-check text-green"></i> Forecasting Model</span>
                        <span class="log-val text-green font-semibold">Holt-Winters Active</span>
                    </div>
                    <div class="log-row">
                        <span class="log-label"><i class="fa-solid fa-check text-green"></i> Anomaly Scanner</span>
                        <span class="log-val text-green font-semibold">Z-Score Engine Online</span>
                    </div>
                    <div class="log-row">
                        <span class="log-label"><i class="fa-solid fa-check text-green"></i> Database Connection</span>
                        <span class="log-val text-cyan font-semibold">MySQL Localhost</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Interactive AI Chatbot -->
        <div class="chatbot-container glass-panel">
            <div class="chatbot-header">
                <div class="bot-info">
                    <div class="bot-avatar">
                        <i class="fa-solid fa-wand-magic-sparkles"></i>
                    </div>
                    <div class="bot-status-container">
                        <h4>AURA Chatbot</h4>
                        <span class="bot-status"><span class="pulse-dot"></span>Online (Local CPU)</span>
                    </div>
                </div>
                <div class="chatbot-actions">
                    <button class="clear-chat-btn" onclick="clearChat()" title="Reset chat"><i class="fa-solid fa-rotate-left"></i></button>
                </div>
            </div>
            
            <div class="chat-messages" id="chatMessages">
                <!-- Welcome Message -->
                <div class="chat-bubble bot-message">
                    <div class="bubble-content">
                        Hello! I am your local AI Inventory Assistant. You can ask me questions in natural language:
                        <ul>
                            <li>Which items will run out this week?</li>
                            <li>What is our best-selling category?</li>
                            <li>What is the valuation of category Electronics?</li>
                            <li>Increase stock of SKU PROD-102 by 15</li>
                            <li>Predict demand for SKU PROD-101</li>
                        </ul>
                    </div>
                    <span class="bubble-time">Just now</span>
                </div>
            </div>
            
            <div class="chat-input-area">
                <form id="chatForm" onsubmit="submitChat(event)">
                    <input type="text" id="chatInput" placeholder="Ask AURA to query or adjust stock..." autocomplete="off">
                    <button type="submit" class="send-btn"><i class="fa-solid fa-paper-plane"></i></button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Embedded JS config for category chart and chatbot logic -->
<script>
    window.CATEGORIES_DATA = <%= categoriesJson %>;
    window.CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>

<script src="${pageContext.request.contextPath}/js/charts.js"></script>
<script src="${pageContext.request.contextPath}/js/chatbot.js"></script>

<%@ include file="/includes/footer.jsp" %>
