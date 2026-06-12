<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.Product" %>
<%@ page import="com.inventory.model.Supplier" %>
<%@ page import="java.util.List" %>
<%@ include file="/includes/header.jsp" %>

<%
    List<Product> products = (List<Product>) request.getAttribute("products");
    List<Supplier> suppliers = (List<Supplier>) request.getAttribute("suppliers");
    List<String> categories = (List<String>) request.getAttribute("categories");
    
    // Check if there is an active filter from request parameters
    String filter = request.getParameter("filter");
    String msg = request.getParameter("msg");
%>

<div class="glass-panel main-panel">
    <div class="panel-header table-panel-header">
        <div class="header-titles">
            <h2>Product Catalog</h2>
            <p>Manage items, monitor stock thresholds, and track product expiries</p>
        </div>
        <div class="header-actions-row">
            <div class="table-search-box">
                <i class="fa-solid fa-magnifying-glass search-table-icon"></i>
                <input type="text" id="productSearch" onkeyup="filterProductsTable()" placeholder="Search by SKU, Name or Category...">
            </div>
            
            <button class="btn btn-primary" onclick="openProductModal()">
                <i class="fa-solid fa-plus btn-icon"></i>Add Product
            </button>
        </div>
    </div>

    <!-- Alert Banner -->
    <% if (msg != null) { %>
        <div class="alert-banner <%= msg.equals("success") || msg.equals("deleted") ? "alert-success" : "alert-error" %>">
            <div class="alert-content">
                <i class="fa-solid <%= msg.equals("success") || msg.equals("deleted") ? "fa-circle-check" : "fa-circle-xmark" %> alert-icon"></i>
                <span>
                    <% if (msg.equals("success")) { %>
                        Product details saved successfully!
                    <% } else if (msg.equals("deleted")) { %>
                        Product successfully deleted.
                    <% } else { %>
                        An error occurred while saving. Make sure SKU is unique.
                    <% } %>
                </span>
            </div>
            <button class="close-alert-btn" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <% } %>

    <div class="table-filters">
        <a href="${pageContext.request.contextPath}/products" class="filter-tab <%= filter == null ? "active" : "" %>">All Products</a>
        <a href="${pageContext.request.contextPath}/products?filter=low" class="filter-tab <%= "low".equals(filter) ? "active" : "" %>">Low Stock Alerts</a>
        <a href="${pageContext.request.contextPath}/products?filter=expired" class="filter-tab <%= "expired".equals(filter) ? "active" : "" %>">Expired / Short Expiry</a>
    </div>

    <div class="table-container">
        <table class="inventory-table" id="productsTable">
            <thead>
                <tr>
                    <th>SKU</th>
                    <th>Product Name</th>
                    <th>Category</th>
                    <th>Price</th>
                    <th>Stock Level</th>
                    <th>Reorder Thresh.</th>
                    <th>Expiry Date</th>
                    <th>Supplier</th>
                    <th class="text-right">Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    boolean hasItems = false;
                    if (products != null) {
                        for (Product p : products) {
                            // Apply server-side filters
                            if ("low".equals(filter) && !p.isLowStock()) continue;
                            if ("expired".equals(filter) && !p.isExpired()) {
                                // If not expired, check if it's near expiry (e.g. within 30 days)
                                boolean isNear = false;
                                if (p.getExpiryDate() != null) {
                                    long diff = p.getExpiryDate().getTime() - System.currentTimeMillis();
                                    long days = diff / (1000 * 60 * 60 * 24);
                                    if (days >= 0 && days <= 30) {
                                        isNear = true;
                                    }
                                }
                                if (!isNear) continue;
                            }
                            hasItems = true;
                %>
                <tr>
                    <td class="font-mono text-cyan font-semibold"><%= p.getSku() %></td>
                    <td>
                        <div class="product-info-cell">
                            <span class="product-name-txt"><%= p.getName() %></span>
                            <span class="product-desc-txt"><%= p.getDescription() != null ? p.getDescription() : "" %></span>
                        </div>
                    </td>
                    <td><span class="badge badge-category"><%= p.getCategory() %></span></td>
                    <td class="font-semibold">$<%= String.format("%.2f", p.getPrice()) %></td>
                    <td>
                        <div class="stock-cell">
                            <span class="stock-qty <%= p.isLowStock() ? "text-yellow font-bold" : "" %>"><%= p.getStockLevel() %></span>
                            <% if (p.isLowStock()) { %>
                                <span class="badge badge-warning-outline">Low Stock</span>
                            <% } %>
                        </div>
                    </td>
                    <td><%= p.getReorderThreshold() %> units</td>
                    <td>
                        <% if (p.getExpiryDate() != null) { 
                            boolean isExp = p.isExpired();
                            long diff = p.getExpiryDate().getTime() - System.currentTimeMillis();
                            long days = diff / (1000 * 60 * 60 * 24);
                            boolean isNear = days >= 0 && days <= 30;
                        %>
                            <span class="<%= isExp ? "text-red font-bold" : (isNear ? "text-yellow font-bold" : "") %>">
                                <%= p.getExpiryDate().toString() %>
                                <% if (isExp) { %>
                                    <span class="block-badge text-red"><i class="fa-solid fa-circle-exclamation"></i> Expired</span>
                                <% } else if (isNear) { %>
                                    <span class="block-badge text-yellow"><i class="fa-solid fa-clock"></i> Near (<%= days %>d)</span>
                                <% } %>
                            </span>
                        <% } else { %>
                            <span class="text-muted">N/A</span>
                        <% } %>
                    </td>
                    <td><%= p.getSupplierName() != null ? p.getSupplierName() : "<span class='text-muted'>None</span>" %></td>
                    <td class="text-right">
                        <div class="row-actions">
                            <button class="action-btn edit-btn" onclick="editProduct(<%= p.getId() %>, '<%= p.getSku() %>', '<%= p.getName().replace("'", "\\'") %>', '<%= p.getDescription() != null ? p.getDescription().replace("'", "\\'") : "" %>', <%= p.getPrice() %>, '<%= p.getCategory() %>', <%= p.getStockLevel() %>, <%= p.getReorderThreshold() %>, <%= p.getLeadTime() %>, '<%= p.getExpiryDate() != null ? p.getExpiryDate() : "" %>', <%= p.getSupplierId() != null ? p.getSupplierId() : 0 %>)" title="Edit">
                                <i class="fa-regular fa-pen-to-square"></i>
                            </button>
                            <a href="${pageContext.request.contextPath}/products?action=delete&id=<%= p.getId() %>" class="action-btn delete-btn" onclick="return confirm('Are you sure you want to delete this product? All transaction logs for it will be removed.')" title="Delete">
                                <i class="fa-regular fa-trash-can"></i>
                            </a>
                        </div>
                    </td>
                </tr>
                <% 
                        }
                    }
                    if (!hasItems) {
                %>
                <tr>
                    <td colspan="9" class="text-center table-empty-state">
                        <i class="fa-solid fa-box-open empty-icon"></i>
                        <p>No products found matching the criteria.</p>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Dialog for Product Creation/Modification -->
<div class="modal" id="productModal">
    <div class="modal-content glass-panel">
        <div class="modal-header">
            <h3 id="modalTitle">Add Product</h3>
            <button class="close-modal-btn" onclick="closeProductModal()">&times;</button>
        </div>
        
        <form action="${pageContext.request.contextPath}/products?action=save" method="POST" class="modal-form">
            <input type="hidden" name="id" id="prodId">
            
            <div class="form-row">
                <div class="form-group">
                    <label for="prodSku">SKU (Unique Code)*</label>
                    <input type="text" name="sku" id="prodSku" required placeholder="e.g. PROD-1001" class="form-control">
                </div>
                <div class="form-group">
                    <label for="prodName">Product Name*</label>
                    <input type="text" name="name" id="prodName" required placeholder="e.g. Quantum CPU" class="form-control">
                </div>
            </div>
            
            <div class="form-group">
                <label for="prodDescription">Description</label>
                <textarea name="description" id="prodDescription" rows="2" placeholder="Product details..." class="form-control"></textarea>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="prodPrice">Price ($)*</label>
                    <input type="number" name="price" id="prodPrice" step="0.01" min="0" required placeholder="0.00" class="form-control">
                </div>
                <div class="form-group">
                    <label for="prodCategory">Category*</label>
                    <input type="text" name="category" id="prodCategory" required placeholder="e.g. Electronics" list="categoryList" class="form-control">
                    <datalist id="categoryList">
                        <% if (categories != null) {
                            for (String cat : categories) { %>
                                <option value="<%= cat %>">
                            <% }
                        } %>
                    </datalist>
                </div>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="prodStock">Initial Stock Level*</label>
                    <input type="number" name="stockLevel" id="prodStock" min="0" required placeholder="0" class="form-control">
                </div>
                <div class="form-group">
                    <label for="prodThreshold">Reorder Threshold*</label>
                    <input type="number" name="reorderThreshold" id="prodThreshold" min="0" required placeholder="10" class="form-control">
                </div>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="prodLeadTime">Supplier Lead Time (Days)*</label>
                    <input type="number" name="leadTime" id="prodLeadTime" min="1" required placeholder="5" class="form-control">
                </div>
                <div class="form-group">
                    <label for="prodExpiry">Expiry Date</label>
                    <input type="date" name="expiryDate" id="prodExpiry" class="form-control">
                </div>
            </div>
            
            <div class="form-group">
                <label for="prodSupplier">Supplier</label>
                <select name="supplierId" id="prodSupplier" class="form-control select-control">
                    <option value="0">-- Select Supplier --</option>
                    <% if (suppliers != null) {
                        for (Supplier s : suppliers) { %>
                            <option value="<%= s.getId() %>"><%= s.getName() %> (Reliability: <%= s.getReliabilityScore() %>%)</option>
                        <% }
                    } %>
                </select>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeProductModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Save Product</button>
            </div>
        </form>
    </div>
</div>

<script>
    // Search box filtration
    function filterProductsTable() {
        var input = document.getElementById("productSearch");
        var filter = input.value.toLowerCase();
        var table = document.getElementById("productsTable");
        var tr = table.getElementsByTagName("tr");
        
        for (var i = 1; i < tr.length; i++) {
            var tdSku = tr[i].getElementsByTagName("td")[0];
            var tdName = tr[i].getElementsByTagName("td")[1];
            var tdCat = tr[i].getElementsByTagName("td")[2];
            
            if (tdSku || tdName || tdCat) {
                var skuVal = tdSku.textContent || tdSku.innerText;
                var nameVal = tdName.textContent || tdName.innerText;
                var catVal = tdCat.textContent || tdCat.innerText;
                
                if (skuVal.toLowerCase().indexOf(filter) > -1 || 
                    nameVal.toLowerCase().indexOf(filter) > -1 || 
                    catVal.toLowerCase().indexOf(filter) > -1) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            }
        }
    }

    // Modal Operations
    function openProductModal() {
        document.getElementById("modalTitle").innerText = "Add Product";
        document.getElementById("prodId").value = "";
        document.getElementById("prodSku").value = "";
        document.getElementById("prodSku").readOnly = false;
        document.getElementById("prodName").value = "";
        document.getElementById("prodDescription").value = "";
        document.getElementById("prodPrice").value = "";
        document.getElementById("prodCategory").value = "";
        document.getElementById("prodStock").value = "0";
        document.getElementById("prodStock").readOnly = false;
        document.getElementById("prodThreshold").value = "10";
        document.getElementById("prodLeadTime").value = "5";
        document.getElementById("prodExpiry").value = "";
        document.getElementById("prodSupplier").value = "0";
        
        document.getElementById("productModal").classList.add("active");
    }

    function editProduct(id, sku, name, desc, price, category, stock, threshold, leadTime, expiry, supplierId) {
        document.getElementById("modalTitle").innerText = "Edit Product";
        document.getElementById("prodId").value = id;
        document.getElementById("prodSku").value = sku;
        document.getElementById("prodSku").readOnly = true; // Sku shouldn't be edited once created
        document.getElementById("prodName").value = name;
        document.getElementById("prodDescription").value = desc;
        document.getElementById("prodPrice").value = price;
        document.getElementById("prodCategory").value = category;
        document.getElementById("prodStock").value = stock;
        document.getElementById("prodStock").readOnly = true; // Stock levels should be altered via transactions (Audit Trail!)
        document.getElementById("prodThreshold").value = threshold;
        document.getElementById("prodLeadTime").value = leadTime;
        
        // Handle date string formatting (yyyy-MM-dd)
        if (expiry && expiry !== "null" && expiry !== "") {
            document.getElementById("prodExpiry").value = expiry;
        } else {
            document.getElementById("prodExpiry").value = "";
        }
        
        document.getElementById("prodSupplier").value = supplierId ? supplierId : "0";
        
        document.getElementById("productModal").classList.add("active");
    }

    function closeProductModal() {
        document.getElementById("productModal").classList.remove("active");
    }
</script>

<%@ include file="/includes/footer.jsp" %>
