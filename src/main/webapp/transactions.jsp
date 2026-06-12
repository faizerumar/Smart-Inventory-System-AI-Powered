<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.Transaction" %>
<%@ page import="com.inventory.model.Product" %>
<%@ page import="java.util.List" %>
<%@ include file="/includes/header.jsp" %>

<%
    List<Transaction> transactions = (List<Transaction>) request.getAttribute("transactions");
    List<Product> products = (List<Product>) request.getAttribute("products");
    String msg = request.getParameter("msg");
%>

<div class="glass-panel main-panel">
    <div class="panel-header table-panel-header">
        <div class="header-titles">
            <h2>Inventory Stock Ledger</h2>
            <p>Real-time audit log of all stock changes, sales, restocks, and manual adjustments</p>
        </div>
        <div class="header-actions-row">
            <button class="btn btn-primary" onclick="openAdjustmentModal()">
                <i class="fa-solid fa-right-left btn-icon"></i>Adjust Stock Level
            </button>
        </div>
    </div>

    <!-- Alert Banner -->
    <% if (msg != null) { %>
        <div class="alert-banner <%= msg.equals("success") ? "alert-success" : "alert-error" %>">
            <div class="alert-content">
                <i class="fa-solid <%= msg.equals("success") ? "fa-circle-check" : "fa-circle-xmark" %> alert-icon"></i>
                <span>
                    <% if (msg.equals("success")) { %>
                        Stock transaction recorded successfully! Inventory levels updated.
                    <% } else { %>
                        Failed to process stock transaction. Make sure stock does not drop below zero on sales.
                    <% } %>
                </span>
            </div>
            <button class="close-alert-btn" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <% } %>

    <div class="table-container">
        <table class="inventory-table" id="transactionsTable">
            <thead>
                <tr>
                    <th>Date & Time</th>
                    <th>Product Details</th>
                    <th>Transaction Type</th>
                    <th>Quantity Flow</th>
                    <th>Notes / Audit Comments</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (transactions != null && !transactions.isEmpty()) {
                        for (Transaction t : transactions) {
                            String type = t.getTransactionType().toUpperCase();
                            String flowClass = "";
                            String sign = "";
                            
                            if (type.equals("SALE")) {
                                flowClass = "text-red font-bold";
                                sign = "-";
                            } else if (type.equals("PURCHASE") || type.equals("RETURN")) {
                                flowClass = "text-green font-bold";
                                sign = "+";
                            } else if (type.equals("ADJUSTMENT")) {
                                if (t.getQuantity() < 0) {
                                    flowClass = "text-red font-bold";
                                    sign = ""; // Negative sign is already inside the value
                                } else {
                                    flowClass = "text-green font-bold";
                                    sign = "+";
                                }
                            }
                %>
                <tr>
                    <td class="font-mono text-muted"><%= t.getTransactionDate().toString() %></td>
                    <td>
                        <div class="product-info-cell">
                            <span class="product-name-txt"><%= t.getProductName() %></span>
                            <span class="product-sku-txt font-mono text-cyan"><%= t.getProductSku() %></span>
                        </div>
                    </td>
                    <td>
                        <span class="badge badge-type-<%= type.toLowerCase() %>"><%= type %></span>
                    </td>
                    <td class="<%= flowClass %> font-mono">
                        <%= sign %><%= t.getQuantity() %> units
                    </td>
                    <td class="text-italic text-slate"><%= t.getNotes() != null ? t.getNotes() : "No notes recorded" %></td>
                </tr>
                <% 
                        }
                    } else {
                %>
                <tr>
                    <td colspan="5" class="text-center table-empty-state">
                        <i class="fa-solid fa-clock-rotate-left empty-icon"></i>
                        <p>No transaction history logged yet.</p>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Dialog for Stock Adjustment -->
<div class="modal" id="adjustmentModal">
    <div class="modal-content glass-panel">
        <div class="modal-header">
            <h3>Record Stock Transaction</h3>
            <button class="close-modal-btn" onclick="closeAdjustmentModal()">&times;</button>
        </div>
        
        <form action="${pageContext.request.contextPath}/transactions?action=add" method="POST" class="modal-form">
            
            <div class="form-group">
                <label for="adjProduct">Select Product*</label>
                <select name="productId" id="adjProduct" required class="form-control select-control">
                    <option value="">-- Choose Product --</option>
                    <% if (products != null) {
                        for (Product p : products) { %>
                            <option value="<%= p.getId() %>"><%= p.getSku() %> - <%= p.getName() %> (Stock: <%= p.getStockLevel() %>)</option>
                        <% }
                    } %>
                </select>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="adjType">Transaction Type*</label>
                    <select name="transactionType" id="adjType" required onchange="handleTypeChange()" class="form-control select-control">
                        <option value="SALE">SALE (Stock Out)</option>
                        <option value="PURCHASE">PURCHASE (Stock In)</option>
                        <option value="RETURN">RETURN (Stock In)</option>
                        <option value="ADJUSTMENT">ADJUSTMENT (Manual Correction)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="adjQty">Quantity*</label>
                    <input type="number" name="quantity" id="adjQty" min="1" required placeholder="1" class="form-control">
                    <small id="qtyHint" class="text-muted block-hint">Sales deduct stock, Purchases add stock.</small>
                </div>
            </div>
            
            <div class="form-group">
                <label for="adjNotes">Reason / Note*</label>
                <input type="text" name="notes" id="adjNotes" required placeholder="e.g. Month-end sale, inventory audit write-off..." class="form-control">
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeAdjustmentModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Log Transaction</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openAdjustmentModal() {
        document.getElementById("adjProduct").value = "";
        document.getElementById("adjType").value = "SALE";
        document.getElementById("adjQty").value = "";
        document.getElementById("adjQty").min = "1";
        document.getElementById("adjNotes").value = "";
        handleTypeChange();
        
        document.getElementById("adjustmentModal").classList.add("active");
    }

    function closeAdjustmentModal() {
        document.getElementById("adjustmentModal").classList.remove("active");
    }

    function handleTypeChange() {
        var type = document.getElementById("adjType").value;
        var qtyInput = document.getElementById("adjQty");
        var qtyHint = document.getElementById("qtyHint");
        
        if (type === "ADJUSTMENT") {
            // Adjustments can be negative (decrease stock) or positive (increase stock)
            qtyInput.min = "-10000";
            qtyHint.innerHTML = "Use negative number to decrease stock (theft, spoilage) and positive to increase.";
        } else {
            qtyInput.min = "1";
            if (type === "SALE") {
                qtyHint.innerHTML = "Sales will deduct specified quantity from stock level.";
            } else {
                qtyHint.innerHTML = "Purchases & returns will add specified quantity to stock level.";
            }
        }
    }
</script>

<%@ include file="/includes/footer.jsp" %>
