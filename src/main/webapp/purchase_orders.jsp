<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.PurchaseOrder" %>
<%@ page import="com.inventory.model.Supplier" %>
<%@ page import="com.inventory.model.Product" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.gson.Gson" %>
<%@ include file="/includes/header.jsp" %>

<%
    List<PurchaseOrder> purchaseOrders = (List<PurchaseOrder>) request.getAttribute("purchaseOrders");
    List<Supplier> suppliers = (List<Supplier>) request.getAttribute("suppliers");
    List<Product> products = (List<Product>) request.getAttribute("products");
    String msg = request.getParameter("msg");
    
    // Convert products list to JSON for dynamic JS selection
    String productsJson = new Gson().toJson(products);
%>

<div class="glass-panel main-panel">
    <div class="panel-header table-panel-header">
        <div class="header-titles">
            <h2>Supplier Purchase Orders</h2>
            <p>Draft supply orders, project delivery buffers, and record inventory intake on delivery receipts</p>
        </div>
        <div class="header-actions-row">
            <button class="btn btn-primary" onclick="openPOModal()">
                <i class="fa-solid fa-file-invoice-dollar btn-icon"></i>Create Purchase Order
            </button>
        </div>
    </div>

    <!-- Alert Banner -->
    <% if (msg != null) { %>
        <div class="alert-banner <%= msg.contains("success") || msg.contains("updated") ? "alert-success" : "alert-error" %>">
            <div class="alert-content">
                <i class="fa-solid <%= msg.contains("success") || msg.contains("updated") ? "fa-circle-check" : "fa-circle-xmark" %> alert-icon"></i>
                <span>
                    <% if (msg.equals("success")) { %>
                        Purchase Order created successfully!
                    <% } else if (msg.equals("status_updated")) { %>
                        Order status updated! Product quantities adjusted.
                    <% } else if (msg.equals("status_error")) { %>
                        Failed to update order status.
                    <% } else { %>
                        An error occurred while compiling the purchase order.
                    <% } %>
                </span>
            </div>
            <button class="close-alert-btn" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <% } %>

    <div class="table-container">
        <table class="inventory-table" id="poTable">
            <thead>
                <tr>
                    <th>PO Code</th>
                    <th>Supplier</th>
                    <th>Date Ordered</th>
                    <th>Expected Delivery</th>
                    <th>Total Cost</th>
                    <th>Status</th>
                    <th class="text-right">Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (purchaseOrders != null && !purchaseOrders.isEmpty()) {
                        for (PurchaseOrder po : purchaseOrders) {
                            String status = po.getStatus().toUpperCase();
                            String badgeClass = "badge-po-pending";
                            if (status.equals("DELIVERED")) badgeClass = "badge-po-delivered";
                            if (status.equals("CANCELLED")) badgeClass = "badge-po-cancelled";
                %>
                <tr>
                    <td class="font-mono text-cyan font-semibold">PO-<%= String.format("%04d", po.getId()) %></td>
                    <td class="font-semibold"><%= po.getSupplierName() != null ? po.getSupplierName() : "<span class='text-muted'>None</span>" %></td>
                    <td class="font-mono text-muted"><%= po.getOrderDate().toString().substring(0, 16) %></td>
                    <td class="font-mono">
                        <% if (po.getExpectedDeliveryDate() != null) { 
                            boolean isOverdue = "PENDING".equals(status) && po.getExpectedDeliveryDate().before(new java.util.Date(System.currentTimeMillis() - 24*60*60*1000));
                        %>
                            <span class="<%= isOverdue ? "text-red font-bold" : "" %>">
                                <%= po.getExpectedDeliveryDate().toString() %>
                                <% if (isOverdue) { %>
                                    <span class="block-badge text-red"><i class="fa-solid fa-triangle-exclamation"></i> Overdue</span>
                                <% } %>
                            </span>
                        <% } else { %>
                            <span class="text-muted">N/A</span>
                        <% } %>
                    </td>
                    <td class="font-semibold">$<%= String.format("%.2f", po.getTotalAmount()) %></td>
                    <td>
                        <span class="badge <%= badgeClass %>"><%= status %></span>
                    </td>
                    <td class="text-right">
                        <div class="row-actions justify-end">
                            <a href="${pageContext.request.contextPath}/purchaseorders?action=view&id=<%= po.getId() %>" class="btn btn-secondary btn-small" title="View Items">
                                <i class="fa-solid fa-eye"></i> Items
                            </a>
                            
                            <% if (status.equals("PENDING")) { %>
                                <form action="${pageContext.request.contextPath}/purchaseorders?action=status_change" method="POST" style="display:inline;">
                                    <input type="hidden" name="id" value="<%= po.getId() %>">
                                    <input type="hidden" name="status" value="DELIVERED">
                                    <button type="submit" class="btn btn-success btn-small ml-1" title="Receive Stock" onclick="return confirm('Confirm receipt. This will add items to stock levels.')">
                                        <i class="fa-solid fa-circle-check"></i> Receive
                                    </button>
                                </form>
                                <form action="${pageContext.request.contextPath}/purchaseorders?action=status_change" method="POST" style="display:inline;">
                                    <input type="hidden" name="id" value="<%= po.getId() %>">
                                    <input type="hidden" name="status" value="CANCELLED">
                                    <button type="submit" class="btn btn-danger btn-small ml-1" title="Cancel Order" onclick="return confirm('Are you sure you want to cancel this purchase order?')">
                                        <i class="fa-solid fa-ban"></i>
                                    </button>
                                </form>
                            <% } %>
                        </div>
                    </td>
                </tr>
                <% 
                        }
                    } else {
                %>
                <tr>
                    <td colspan="7" class="text-center table-empty-state">
                        <i class="fa-solid fa-file-invoice-dollar empty-icon"></i>
                        <p>No purchase orders recorded.</p>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Dialog for Creating Purchase Order -->
<div class="modal" id="poModal">
    <div class="modal-content glass-panel po-modal-content">
        <div class="modal-header">
            <h3>Compile Purchase Order</h3>
            <button class="close-modal-btn" onclick="closePOModal()">&times;</button>
        </div>
        
        <form action="${pageContext.request.contextPath}/purchaseorders?action=create" method="POST" class="modal-form">
            <div class="form-row">
                <div class="form-group">
                    <label for="poSupplier">Supplier*</label>
                    <select name="supplierId" id="poSupplier" required onchange="filterProductsBySupplier()" class="form-control select-control">
                        <option value="">-- Choose Supplier --</option>
                        <% if (suppliers != null) {
                            for (Supplier s : suppliers) { %>
                                <option value="<%= s.getId() %>"><%= s.getName() %> (Reliability: <%= s.getReliabilityScore() %>%)</option>
                            <% }
                        } %>
                    </select>
                </div>
                <div class="form-group">
                    <label for="poExpected">Expected Delivery Date*</label>
                    <input type="date" name="expectedDeliveryDate" id="poExpected" required class="form-control">
                </div>
            </div>

            <!-- PO Items Compilation Section -->
            <div class="po-items-section">
                <h4>Order Line Items</h4>
                <div class="line-items-headers">
                    <span class="header-product">Product</span>
                    <span class="header-price">Unit Price</span>
                    <span class="header-qty">Quantity</span>
                    <span class="header-total">Subtotal</span>
                    <span class="header-action"></span>
                </div>
                
                <div class="line-items-container" id="lineItemsContainer">
                    <!-- Dynamic rows appended here by JS -->
                </div>
                
                <button type="button" class="btn btn-secondary btn-small mt-2" onclick="addLineItem()">
                    <i class="fa-solid fa-plus btn-icon"></i>Add Line Item
                </button>
            </div>
            
            <div class="po-totals-section">
                <span class="totals-label">Grand Total:</span>
                <span class="totals-value" id="poGrandTotal">$0.00</span>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closePOModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Generate Order</button>
            </div>
        </form>
    </div>
</div>

<script>
    // Store products list locally in JS
    var allProductsList = <%= productsJson %>;

    function openPOModal() {
        document.getElementById("poSupplier").value = "";
        document.getElementById("poExpected").value = "";
        document.getElementById("lineItemsContainer").innerHTML = "";
        document.getElementById("poGrandTotal").innerText = "$0.00";
        document.getElementById("poModal").classList.add("active");
    }

    function closePOModal() {
        document.getElementById("poModal").classList.remove("active");
    }

    function filterProductsBySupplier() {
        // Clear items when supplier changes, since items are supplier specific
        document.getElementById("lineItemsContainer").innerHTML = "";
        updateGrandTotal();
        
        // Auto-calculate expected delivery date based on lead times
        var supplierSelect = document.getElementById("poSupplier");
        var supplierId = supplierSelect.value;
        if (supplierId) {
            // Find products of this supplier to average lead time
            var leadTimeSum = 0;
            var count = 0;
            allProductsList.forEach(function(p) {
                if (p.supplierId == supplierId) {
                    leadTimeSum += p.leadTime;
                    count++;
                }
            });
            var avgLead = count > 0 ? Math.ceil(leadTimeSum / count) : 5;
            
            // Set date
            var today = new Date();
            today.setDate(today.getDate() + avgLead);
            var dd = String(today.getDate()).padStart(2, '0');
            var mm = String(today.getMonth() + 1).padStart(2, '0');
            var yyyy = today.getFullYear();
            
            document.getElementById("poExpected").value = yyyy + '-' + mm + '-' + dd;
            
            // Proactively add first line item
            addLineItem();
        }
    }

    function addLineItem() {
        var supplierId = document.getElementById("poSupplier").value;
        if (!supplierId) {
            alert("Please select a Supplier first.");
            return;
        }

        // Filter products matching selected supplier
        var filteredProducts = allProductsList.filter(function(p) {
            return p.supplierId == supplierId;
        });

        if (filteredProducts.length === 0) {
            alert("No products registered for this supplier.");
            return;
        }

        var container = document.getElementById("lineItemsContainer");
        var rowIndex = container.children.length;
        
        var rowHtml = document.createElement("div");
        rowHtml.className = "line-item-row";
        
        var selectHtml = '<select name="productId[]" required onchange="onProductSelect(this)" class="form-control select-control line-product-select">';
        selectHtml += '<option value="">-- Choose Item --</option>';
        filteredProducts.forEach(function(p) {
            selectHtml += '<option value="' + p.id + '" data-price="' + p.price + '">' + p.sku + ' - ' + p.name + '</option>';
        });
        selectHtml += '</select>';

        rowHtml.innerHTML = 
            selectHtml + 
            '<input type="text" class="form-control line-price" readonly value="0.00">' + 
            '<input type="number" name="quantity[]" min="1" required class="form-control line-qty" onkeyup="onQtyChange(this)" onchange="onQtyChange(this)" value="1">' + 
            '<input type="text" class="form-control line-total" readonly value="$0.00">' + 
            '<button type="button" class="btn-delete-line" onclick="deleteLineRow(this)"><i class="fa-regular fa-trash-can"></i></button>';

        container.appendChild(rowHtml);
    }

    function deleteLineRow(btn) {
        btn.parentElement.remove();
        updateGrandTotal();
    }

    function onProductSelect(select) {
        var option = select.options[select.selectedIndex];
        var price = option.getAttribute("data-price") || "0.00";
        var row = select.parentElement;
        
        row.querySelector(".line-price").value = parseFloat(price).toFixed(2);
        
        var qty = row.querySelector(".line-qty").value;
        var subtotal = parseFloat(price) * parseInt(qty);
        row.querySelector(".line-total").value = "$" + subtotal.toFixed(2);
        
        updateGrandTotal();
    }

    function onQtyChange(input) {
        var row = input.parentElement;
        var price = row.querySelector(".line-price").value;
        var qty = input.value || 0;
        
        var subtotal = parseFloat(price) * parseInt(qty);
        row.querySelector(".line-total").value = "$" + subtotal.toFixed(2);
        
        updateGrandTotal();
    }

    function updateGrandTotal() {
        var totals = document.querySelectorAll(".line-total");
        var grandTotal = 0;
        totals.forEach(function(t) {
            var val = parseFloat(t.value.replace("$", "")) || 0;
            grandTotal += val;
        });
        document.getElementById("poGrandTotal").innerText = "$" + grandTotal.toFixed(2);
    }
</script>

<%@ include file="/includes/footer.jsp" %>
