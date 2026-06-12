<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.PurchaseOrder" %>
<%@ page import="com.inventory.model.PurchaseOrderItem" %>
<%@ include file="/includes/header.jsp" %>

<%
    PurchaseOrder po = (PurchaseOrder) request.getAttribute("order");
    if (po == null) {
        response.sendRedirect(request.getContextPath() + "/purchaseorders");
        return;
    }
    
    String status = po.getStatus().toUpperCase();
    String badgeClass = "badge-po-pending";
    if (status.equals("DELIVERED")) badgeClass = "badge-po-delivered";
    if (status.equals("CANCELLED")) badgeClass = "badge-po-cancelled";
%>

<div class="glass-panel main-panel">
    <div class="panel-header po-detail-header">
        <div class="header-titles">
            <div class="po-detail-title-row">
                <h2>Purchase Order Details</h2>
                <span class="badge <%= badgeClass %>"><%= status %></span>
            </div>
            <p class="font-mono text-cyan">Code: PO-<%= String.format("%04d", po.getId()) %></p>
        </div>
        <div class="header-actions-row">
            <a href="${pageContext.request.contextPath}/purchaseorders" class="btn btn-secondary">
                <i class="fa-solid fa-arrow-left btn-icon"></i>Back to Orders
            </a>
            
            <% if (status.equals("PENDING")) { %>
                <form action="${pageContext.request.contextPath}/purchaseorders?action=status_change" method="POST" style="display:inline;">
                    <input type="hidden" name="id" value="<%= po.getId() %>">
                    <input type="hidden" name="status" value="DELIVERED">
                    <button type="submit" class="btn btn-success ml-2" onclick="return confirm('Confirm receipt. This will add items to stock levels.')">
                        <i class="fa-solid fa-circle-check btn-icon"></i>Receive Stock
                    </button>
                </form>
            <% } %>
        </div>
    </div>

    <!-- PO Summary Grid -->
    <div class="po-details-grid">
        <div class="po-detail-cell">
            <span class="detail-label">Supplier Name</span>
            <span class="detail-value text-cyan"><%= po.getSupplierName() %></span>
        </div>
        <div class="po-detail-cell">
            <span class="detail-label">Date Drafted</span>
            <span class="detail-value font-mono"><%= po.getOrderDate().toString().substring(0, 16) %></span>
        </div>
        <div class="po-detail-cell">
            <span class="detail-label">Expected Date</span>
            <span class="detail-value font-mono"><%= po.getExpectedDeliveryDate() != null ? po.getExpectedDeliveryDate() : "N/A" %></span>
        </div>
        <div class="po-detail-cell">
            <span class="detail-label">Total Outlay</span>
            <span class="detail-value text-green font-bold">$<%= String.format("%.2f", po.getTotalAmount()) %></span>
        </div>
    </div>

    <div class="table-container mt-4">
        <table class="inventory-table">
            <thead>
                <tr>
                    <th>SKU</th>
                    <th>Product Name</th>
                    <th class="text-center">Order Quantity</th>
                    <th>Contract Unit Cost</th>
                    <th class="text-right">Line Total</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (po.getItems() != null && !po.getItems().isEmpty()) {
                        for (PurchaseOrderItem item : po.getItems()) {
                            double subtotal = item.getUnitPrice().doubleValue() * item.getQuantity();
                %>
                <tr>
                    <td class="font-mono text-cyan"><%= item.getProductSku() %></td>
                    <td class="font-semibold"><%= item.getProductName() %></td>
                    <td class="text-center font-mono font-bold"><%= item.getQuantity() %> units</td>
                    <td class="font-mono">$<%= String.format("%.2f", item.getUnitPrice()) %></td>
                    <td class="text-right font-mono font-semibold">$<%= String.format("%.2f", subtotal) %></td>
                </tr>
                <% 
                        }
                    } else {
                %>
                <tr>
                    <td colspan="5" class="text-center table-empty-state">
                        <i class="fa-solid fa-file-excel empty-icon"></i>
                        <p>No line items found in this order.</p>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="/includes/footer.jsp" %>
