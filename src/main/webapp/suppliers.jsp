<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inventory.model.Supplier" %>
<%@ page import="java.util.List" %>
<%@ include file="/includes/header.jsp" %>

<%
    List<Supplier> suppliers = (List<Supplier>) request.getAttribute("suppliers");
    String msg = request.getParameter("msg");
%>

<div class="glass-panel main-panel">
    <div class="panel-header table-panel-header">
        <div class="header-titles">
            <h2>Suppliers Database</h2>
            <p>Maintain supplier contact records and track reliability scores for replenishment calculations</p>
        </div>
        <div class="header-actions-row">
            <button class="btn btn-primary" onclick="openSupplierModal()">
                <i class="fa-solid fa-user-plus btn-icon"></i>Add Supplier
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
                        Supplier details saved successfully!
                    <% } else if (msg.equals("deleted")) { %>
                        Supplier successfully deleted.
                    <% } else { %>
                        An error occurred while saving the supplier details.
                    <% } %>
                </span>
            </div>
            <button class="close-alert-btn" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <% } %>

    <div class="table-container">
        <table class="inventory-table" id="suppliersTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Supplier Name</th>
                    <th>Contact Agent</th>
                    <th>Email Address</th>
                    <th>Phone Number</th>
                    <th>Reliability Score</th>
                    <th class="text-right">Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (suppliers != null && !suppliers.isEmpty()) {
                        for (Supplier s : suppliers) {
                            int score = s.getReliabilityScore();
                            String colorClass = "gauge-green";
                            if (score < 75) {
                                colorClass = "gauge-red";
                            } else if (score < 90) {
                                colorClass = "gauge-yellow";
                            }
                %>
                <tr>
                    <td class="font-mono text-muted">SUP-<%= String.format("%03d", s.getId()) %></td>
                    <td class="font-semibold text-cyan"><%= s.getName() %></td>
                    <td><%= s.getContactPerson() != null ? s.getContactPerson() : "N/A" %></td>
                    <td><%= s.getEmail() != null ? s.getEmail() : "N/A" %></td>
                    <td class="font-mono"><%= s.getPhone() != null ? s.getPhone() : "N/A" %></td>
                    <td>
                        <div class="reliability-cell">
                            <span class="reliability-val <%= colorClass.replace("gauge-", "text-") %> font-semibold"><%= score %>%</span>
                            <div class="progress-bar-container">
                                <div class="progress-bar <%= colorClass %>" style="width: <%= score %>%"></div>
                            </div>
                        </div>
                    </td>
                    <td class="text-right">
                        <div class="row-actions">
                            <button class="action-btn edit-btn" onclick="editSupplier(<%= s.getId() %>, '<%= s.getName().replace("'", "\\'") %>', '<%= s.getContactPerson() != null ? s.getContactPerson().replace("'", "\\'") : "" %>', '<%= s.getEmail() != null ? s.getEmail() : "" %>', '<%= s.getPhone() != null ? s.getPhone() : "" %>', <%= s.getReliabilityScore() %>)" title="Edit">
                                <i class="fa-regular fa-pen-to-square"></i>
                            </button>
                            <a href="${pageContext.request.contextPath}/suppliers?action=delete&id=<%= s.getId() %>" class="action-btn delete-btn" onclick="return confirm('Are you sure you want to delete this supplier? Any associated products will have their supplier references set to empty.')" title="Delete">
                                <i class="fa-regular fa-trash-can"></i>
                            </a>
                        </div>
                    </td>
                </tr>
                <% 
                        }
                    } else {
                %>
                <tr>
                    <td colspan="7" class="text-center table-empty-state">
                        <i class="fa-solid fa-users-slash empty-icon"></i>
                        <p>No supplier records saved in the system.</p>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Dialog for Supplier Operations -->
<div class="modal" id="supplierModal">
    <div class="modal-content glass-panel">
        <div class="modal-header">
            <h3 id="modalTitle">Add Supplier</h3>
            <button class="close-modal-btn" onclick="closeSupplierModal()">&times;</button>
        </div>
        
        <form action="${pageContext.request.contextPath}/suppliers?action=save" method="POST" class="modal-form">
            <input type="hidden" name="id" id="supId">
            
            <div class="form-group">
                <label for="supName">Supplier Name*</label>
                <input type="text" name="name" id="supName" required placeholder="e.g. Nexus Tech Corp" class="form-control">
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="supContact">Contact Person</label>
                    <input type="text" name="contactPerson" id="supContact" placeholder="e.g. John Doe" class="form-control">
                </div>
                <div class="form-group">
                    <label for="supScore">Reliability Score (0 - 100)%*</label>
                    <input type="number" name="reliabilityScore" id="supScore" min="0" max="100" required placeholder="100" class="form-control">
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="supEmail">Email Address</label>
                    <input type="email" name="email" id="supEmail" placeholder="e.g. info@nexus.com" class="form-control">
                </div>
                <div class="form-group">
                    <label for="supPhone">Phone Number</label>
                    <input type="text" name="phone" id="supPhone" placeholder="e.g. +1-555-0101" class="form-control">
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeSupplierModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Save Supplier</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openSupplierModal() {
        document.getElementById("modalTitle").innerText = "Add Supplier";
        document.getElementById("supId").value = "";
        document.getElementById("supName").value = "";
        document.getElementById("supContact").value = "";
        document.getElementById("supEmail").value = "";
        document.getElementById("supPhone").value = "";
        document.getElementById("supScore").value = "100";
        
        document.getElementById("supplierModal").classList.add("active");
    }

    function editSupplier(id, name, contact, email, phone, score) {
        document.getElementById("modalTitle").innerText = "Edit Supplier";
        document.getElementById("supId").value = id;
        document.getElementById("supName").value = name;
        document.getElementById("supContact").value = contact;
        document.getElementById("supEmail").value = email;
        document.getElementById("supPhone").value = phone;
        document.getElementById("supScore").value = score;
        
        document.getElementById("supplierModal").classList.add("active");
    }

    function closeSupplierModal() {
        document.getElementById("supplierModal").classList.remove("active");
    }
</script>

<%@ include file="/includes/footer.jsp" %>
