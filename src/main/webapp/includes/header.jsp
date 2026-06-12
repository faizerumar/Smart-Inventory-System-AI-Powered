<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Inventory System | AI Powered</title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Chart.js for data visualizations -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <!-- Custom Premium Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <div class="app-container">
        <!-- Sidebar Navigation -->
        <aside class="sidebar">
            <div class="sidebar-brand">
                <i class="fa-solid fa-brain-circuit brand-icon"></i>
                <span class="brand-text">AURA <span class="accent-text">INV</span></span>
            </div>
            
            <nav class="sidebar-menu">
                <a href="${pageContext.request.contextPath}/" class="menu-item ${pageContext.request.servletPath == '/index.jsp' ? 'active' : ''}">
                    <i class="fa-solid fa-chart-pie menu-icon"></i>
                    <span>Dashboard</span>
                </a>
                <a href="${pageContext.request.contextPath}/products" class="menu-item ${pageContext.request.servletPath == '/products.jsp' ? 'active' : ''}">
                    <i class="fa-solid fa-boxes-stacked menu-icon"></i>
                    <span>Products</span>
                </a>
                <a href="${pageContext.request.contextPath}/transactions" class="menu-item ${pageContext.request.servletPath == '/transactions.jsp' ? 'active' : ''}">
                    <i class="fa-solid fa-clock-rotate-left menu-icon"></i>
                    <span>Stock Tracking</span>
                </a>
                <a href="${pageContext.request.contextPath}/suppliers" class="menu-item ${pageContext.request.servletPath == '/suppliers.jsp' ? 'active' : ''}">
                    <i class="fa-solid fa-truck-field menu-icon"></i>
                    <span>Suppliers</span>
                </a>
                <a href="${pageContext.request.contextPath}/purchaseorders" class="menu-item ${pageContext.request.servletPath == '/purchase_orders.jsp' || pageContext.request.servletPath == '/purchase_order_detail.jsp' ? 'active' : ''}">
                    <i class="fa-solid fa-file-invoice-dollar menu-icon"></i>
                    <span>Purchase Orders</span>
                </a>
                <a href="${pageContext.request.contextPath}/ai_center.jsp" class="menu-item ${pageContext.request.servletPath == '/ai_center.jsp' ? 'active' : ''} ai-nav-item">
                    <i class="fa-solid fa-wand-magic-sparkles menu-icon"></i>
                    <span>AI Center</span>
                </a>
            </nav>
            
            <div class="sidebar-footer">
                <div class="user-profile">
                    <div class="avatar">
                        <i class="fa-solid fa-user-gear"></i>
                    </div>
                    <div class="user-info">
                        <span class="username">Admin User</span>
                        <span class="role">System Administrator</span>
                    </div>
                </div>
            </div>
        </aside>

        <!-- Main Content Area -->
        <main class="main-content">
            <header class="content-header">
                <div class="header-search">
                    <!-- Placeholder/Visual header search -->
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" placeholder="Search sku, transactions, invoices..." disabled class="search-input">
                </div>
                <div class="header-actions">
                    <div class="system-status">
                        <span class="status-indicator online"></span>
                        <span class="status-label">AI Engine Active</span>
                    </div>
                    <div class="notification-bell">
                        <i class="fa-regular fa-bell"></i>
                        <span class="badge">2</span>
                    </div>
                </div>
            </header>
            
            <div class="page-container">
