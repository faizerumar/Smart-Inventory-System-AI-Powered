<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.Product" %>
<%@ page import="com.inventory.dao.ProductDAO" %>
<%@ page import="java.util.List" %>
<%@ include file="/includes/header.jsp" %>

<%
    ProductDAO prodDAO = new ProductDAO();
    List<Product> products = prodDAO.getAllProducts();
%>

<div class="ai-center-wrapper">
    <!-- Section 1: Demand Forecasting Dashboard -->
    <div class="glass-panel forecasting-panel">
        <div class="panel-header">
            <div class="header-titles">
                <h2><i class="fa-solid fa-chart-line header-icon text-purple"></i>Predictive Demand Forecasting</h2>
                <p>Holt-Winters double exponential model forecasting next 3-month sales from historical transaction spikes</p>
            </div>
            <div class="forecasting-selector">
                <label for="forecastProductSelect">Select Product: </label>
                <select id="forecastProductSelect" onchange="loadForecastChart()" class="form-control select-control font-semibold">
                    <% if (products != null) {
                        for (Product p : products) { %>
                            <option value="<%= p.getId() %>"><%= p.getSku() %> - <%= p.getName() %></option>
                        <% }
                    } %>
                </select>
            </div>
        </div>
        
        <div class="forecasting-body">
            <!-- Chart Frame -->
            <div class="forecasting-chart-frame">
                <canvas id="forecastChart"></canvas>
            </div>
            
            <!-- Reorder Suggestion Details -->
            <div class="forecasting-recommendations glass-panel">
                <h4>AI Insights & Recommendations</h4>
                <div class="recommendation-content" id="forecastRecommendationBox">
                    <p class="text-muted text-center pt-4">Select a product to view AI insights.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Row 2: Smart Reordering and Anomaly Detection -->
    <div class="ai-bottom-row">
        
        <!-- Left: Smart Reordering recommendations -->
        <div class="glass-panel smart-reorder-panel">
            <div class="panel-header">
                <div class="header-titles">
                    <h3><i class="fa-solid fa-robot header-icon text-cyan"></i>Smart Reordering Recommendations</h3>
                    <p>Calculates safety stock buffered by supplier reliability scores</p>
                </div>
                <button class="btn btn-primary btn-small" id="runAutoReorderBtn" onclick="runAutoReorder()">
                    <i class="fa-solid fa-gears btn-icon"></i>Auto-Generate POs
                </button>
            </div>
            
            <div class="table-container compact-table-container">
                <table class="inventory-table compact-table" id="reorderRecommendationsTable">
                    <thead>
                        <tr>
                            <th>Product</th>
                            <th>Supplier (Score)</th>
                            <th>Lead Time</th>
                            <th>Safety Stock</th>
                            <th>ROP</th>
                            <th>Current Stock</th>
                            <th>Suggested Order</th>
                        </tr>
                    </thead>
                    <tbody id="reorderRecommendationsBody">
                        <tr>
                            <td colspan="7" class="text-center py-4 text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Analyzing stock profiles...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Right: Anomaly Detection Logs -->
        <div class="glass-panel anomaly-panel">
            <div class="panel-header">
                <div class="header-titles">
                    <h3><i class="fa-solid fa-shield-virus header-icon text-red"></i>Transactional Anomaly Scanner</h3>
                    <p>Flags transactions exceeding Z-score threshold (|Z| > 2.0) representing data entries errors, spoilage, or shrinkage</p>
                </div>
                <button class="btn btn-danger btn-small" onclick="runAnomalyScan()">
                    <i class="fa-solid fa-eye-dropper btn-icon"></i>Scan Records
                </button>
            </div>
            
            <div class="anomaly-logs-container" id="anomalyLogsContainer">
                <div class="text-center py-4 text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Initializing scan engine...</div>
            </div>
        </div>

    </div>
</div>

<script>
    window.CONTEXT_PATH = "${pageContext.request.contextPath}";
    
    // Global variable to keep track of chart instance
    var currentChartInstance = null;

    document.addEventListener("DOMContentLoaded", function() {
        // Run initial loads
        loadForecastChart();
        loadReorderRecommendations();
        runAnomalyScan();
    });

    function loadForecastChart() {
        var prodId = document.getElementById("forecastProductSelect").value;
        if (!prodId) return;
        
        fetch(window.CONTEXT_PATH + "/api/ai?action=forecast&productId=" + prodId)
            .then(function(res) { return res.json(); })
            .then(function(data) {
                var history = data.history || [];
                var histLabels = data.historyLabels || [];
                var forecast = data.forecast || [];
                var fcLabels = data.forecastLabels || [];
                
                // Combine labels
                var allLabels = histLabels.concat(fcLabels);
                
                // Compile historical points (fill forecast indices with null so it matches)
                var histDataPoints = [];
                for (var i = 0; i < history.length; i++) {
                    histDataPoints.push(history[i]);
                }
                
                // Compile forecast points (connect last history element to forecast line)
                var fcDataPoints = [];
                for (var i = 0; i < history.length - 1; i++) {
                    fcDataPoints.push(null);
                }
                fcDataPoints.push(history[history.length - 1]); // Connect point
                for (var i = 0; i < forecast.length; i++) {
                    fcDataPoints.push(forecast[i]);
                }
                
                // Update insights panel
                var select = document.getElementById("forecastProductSelect");
                var text = select.options[select.selectedIndex].text;
                var recQty = data.recommendedRestock;
                
                var rBox = document.getElementById("forecastRecommendationBox");
                rBox.innerHTML = 
                    '<div class="insight-row">' +
                        '<span class="insight-label">Product SKU / Name</span>' +
                        '<span class="insight-value text-cyan">' + text + '</span>' +
                    '</div>' +
                    '<div class="insight-row">' +
                        '<span class="insight-label">Next Month Est. Sales</span>' +
                        '<span class="insight-value text-purple">' + forecast[0] + ' units</span>' +
                    '</div>' +
                    '<div class="insight-row">' +
                        '<span class="insight-label">Recommended Restock Target</span>' +
                        '<span class="insight-value text-green font-bold">' + recQty + ' units</span>' +
                    '</div>' +
                    '<div class="insight-desc-box mt-3">' +
                        '<p><i class="fa-solid fa-circle-info text-cyan"></i> The recommendation suggests stocking enough inventory to cover the predicted monthly demand. Safe thresholds buffer supplier delays.</p>' +
                    '</div>';

                // Redraw Chart
                var ctx = document.getElementById("forecastChart").getContext("2d");
                
                if (currentChartInstance) {
                    currentChartInstance.destroy();
                }
                
                currentChartInstance = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: allLabels,
                        datasets: [
                            {
                                label: 'Historical Monthly Sales',
                                data: histDataPoints,
                                borderColor: 'rgba(56, 189, 248, 1)',
                                backgroundColor: 'rgba(56, 189, 248, 0.15)',
                                fill: true,
                                tension: 0.35,
                                borderWidth: 3
                            },
                            {
                                label: 'AI Projected Forecast (3 Months)',
                                data: fcDataPoints,
                                borderColor: 'rgba(192, 132, 252, 1)',
                                backgroundColor: 'rgba(192, 132, 252, 0.1)',
                                borderDash: [6, 6],
                                fill: false,
                                tension: 0.35,
                                borderWidth: 3,
                                pointBackgroundColor: 'rgba(192, 132, 252, 1)'
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                labels: {
                                    color: '#f8fafc',
                                    font: { family: 'Inter', size: 12 }
                                }
                            }
                        },
                        scales: {
                            y: {
                                ticks: { color: '#94a3b8' },
                                grid: { color: 'rgba(255, 255, 255, 0.05)' }
                            },
                            x: {
                                ticks: { color: '#94a3b8' },
                                grid: { color: 'rgba(255, 255, 255, 0.05)' }
                            }
                        }
                    }
                });
            })
            .catch(function(err) {
                console.error("Forecaster Error: ", err);
            });
    }

    function loadReorderRecommendations() {
        var body = document.getElementById("reorderRecommendationsBody");
        
        fetch(window.CONTEXT_PATH + "/api/ai?action=reorder_recommendations")
            .then(function(res) { return res.json(); })
            .then(function(data) {
                body.innerHTML = "";
                if (data.length === 0) {
                    body.innerHTML = '<tr><td colspan="7" class="text-center py-4 text-green"><i class="fa-solid fa-circle-check"></i> All items have safe stock levels! No reordering required.</td></tr>';
                    document.getElementById("runAutoReorderBtn").disabled = true;
                    return;
                }
                
                document.getElementById("runAutoReorderBtn").disabled = false;
                
                data.forEach(function(r) {
                    var supColorClass = "text-green";
                    if (r.reliabilityScore < 75) supColorClass = "text-red";
                    else if (r.reliabilityScore < 90) supColorClass = "text-yellow";
                    
                    var rowHtml = '<tr>' +
                        '<td>' +
                            '<div class="product-info-cell">' +
                                '<span class="product-name-txt">' + r.productName + '</span>' +
                                '<span class="product-sku-txt font-mono text-cyan">' + r.sku + '</span>' +
                            '</div>' +
                        '</td>' +
                        '<td>' +
                            '<div class="product-info-cell">' +
                                '<span>' + r.supplierName + '</span>' +
                                '<span class="font-bold ' + supColorClass + '">' + r.reliabilityScore + '% Reliability</span>' +
                            '</div>' +
                        '</td>' +
                        '<td class="font-mono">' + r.leadTime + ' days</td>' +
                        '<td class="font-mono">' + r.safetyStock + ' units</td>' +
                        '<td class="font-mono text-yellow font-bold">' + r.reorderPoint + ' units</td>' +
                        '<td class="font-mono">' + r.currentStock + ' units</td>' +
                        '<td class="font-mono text-green font-bold">' + r.recommendedQty + ' units ($' + r.totalCost.toFixed(2) + ')</td>' +
                    '</tr>';
                    
                    body.innerHTML += rowHtml;
                });
            })
            .catch(function(err) {
                body.innerHTML = '<tr><td colspan="7" class="text-center py-4 text-red">Failed to analyze reorders.</td></tr>';
            });
    }

    function runAutoReorder() {
        if (!confirm("Are you sure you want to let the AI auto-generate drafted Purchase Orders for all these products?")) {
            return;
        }
        
        var btn = document.getElementById("runAutoReorderBtn");
        btn.disabled = true;
        btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Generating...';
        
        fetch(window.CONTEXT_PATH + "/api/ai?action=run_auto_reorder", { method: 'POST' })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data.success) {
                    alert("Success! " + data.poCreated + " Purchase Orders were generated as 'PENDING' drafts. You can review them in the Purchase Orders page.");
                    loadReorderRecommendations();
                } else {
                    alert("Error: PO generation failed.");
                }
            })
            .catch(function(err) {
                alert("PO generation request failed.");
            })
            .finally(function() {
                btn.innerHTML = '<i class="fa-solid fa-gears btn-icon"></i>Auto-Generate POs';
            });
    }

    function runAnomalyScan() {
        var container = document.getElementById("anomalyLogsContainer");
        container.innerHTML = '<div class="text-center py-4 text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Scanning historical transactions...</div>';
        
        fetch(window.CONTEXT_PATH + "/api/ai?action=anomalies")
            .then(function(res) { return res.json(); })
            .then(function(data) {
                container.innerHTML = "";
                if (data.length === 0) {
                    container.innerHTML = '<div class="text-center py-4 text-green"><i class="fa-solid fa-shield-halved"></i> No statistical anomalies detected in audit logs.</div>';
                    return;
                }
                
                data.forEach(function(l) {
                    var type = l.transactionType.toUpperCase();
                    var colorClass = "text-red border-left-red";
                    
                    var dateStr = new Date(l.transactionDate).toISOString().substring(0, 16).replace("T", " ");
                    
                    var cardHtml = 
                        '<div class="anomaly-card glass-panel">' +
                            '<div class="anomaly-card-top">' +
                                '<span class="anomaly-tag badge badge-type-' + type.toLowerCase() + '">' + type + '</span>' +
                                '<span class="anomaly-time font-mono text-muted">' + dateStr + '</span>' +
                            '</div>' +
                            '<div class="anomaly-card-middle mt-2">' +
                                '<span class="font-semibold">' + l.productName + ' (' + l.productSku + ')</span>' +
                                '<span class="anomaly-qty font-bold text-red">Quantity: ' + l.quantity + ' units</span>' +
                            '</div>' +
                            '<div class="anomaly-card-bottom mt-2">' +
                                '<p class="anomaly-desc text-yellow font-medium"><i class="fa-solid fa-triangle-exclamation"></i> ' + l.anomalyReason + '</p>' +
                                '<p class="anomaly-notes text-muted mt-1">Audit note: "' + l.notes + '"</p>' +
                            '</div>' +
                        '</div>';
                        
                    container.innerHTML += cardHtml;
                });
            })
            .catch(function(err) {
                container.innerHTML = '<div class="text-center py-4 text-red">Failed to compile anomalies.</div>';
            });
    }
</script>

<%@ include file="/includes/footer.jsp" %>
