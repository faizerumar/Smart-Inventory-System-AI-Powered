package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.PurchaseOrderDAO;
import com.inventory.dao.SupplierDAO;
import com.inventory.model.Product;
import com.inventory.model.PurchaseOrder;
import com.inventory.model.PurchaseOrderItem;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/purchaseorders")
public class PurchaseOrderServlet extends HttpServlet {
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();
    private final ProductDAO productDAO = new ProductDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        try {
            switch (action) {
                case "view":
                    int id = Integer.parseInt(request.getParameter("id"));
                    PurchaseOrder po = poDAO.getPurchaseOrderById(id);
                    request.setAttribute("order", po);
                    request.getRequestDispatcher("/purchase_order_detail.jsp").forward(request, response);
                    break;
                case "list":
                default:
                    showPOList(request, response);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            showPOList(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                int supplierId = Integer.parseInt(request.getParameter("supplierId"));
                Date expectedDeliveryDate = Date.valueOf(request.getParameter("expectedDeliveryDate"));
                
                String[] productIds = request.getParameterValues("productId[]");
                String[] quantities = request.getParameterValues("quantity[]");
                
                if (productIds != null && quantities != null && productIds.length == quantities.length) {
                    PurchaseOrder po = new PurchaseOrder();
                    po.setSupplierId(supplierId);
                    po.setStatus("PENDING");
                    po.setOrderDate(new Timestamp(System.currentTimeMillis()));
                    po.setExpectedDeliveryDate(expectedDeliveryDate);
                    
                    List<PurchaseOrderItem> items = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int prodId = Integer.parseInt(productIds[i]);
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        
                        Product p = productDAO.getProductById(prodId);
                        if (p != null) {
                            PurchaseOrderItem item = new PurchaseOrderItem();
                            item.setProductId(prodId);
                            item.setQuantity(qty);
                            item.setUnitPrice(p.getPrice());
                            po.addItem(item);
                        }
                    }
                    
                    if (!po.getItems().isEmpty()) {
                        boolean ok = poDAO.insertPurchaseOrder(po);
                        if (ok) {
                            response.sendRedirect(request.getContextPath() + "/purchaseorders?msg=success");
                            return;
                        }
                    }
                }
                response.sendRedirect(request.getContextPath() + "/purchaseorders?msg=error");
                
            } else if ("status_change".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String newStatus = request.getParameter("status");
                
                boolean ok = poDAO.updatePurchaseOrderStatus(id, newStatus);
                if (ok) {
                    response.sendRedirect(request.getContextPath() + "/purchaseorders?msg=status_updated");
                } else {
                    response.sendRedirect(request.getContextPath() + "/purchaseorders?msg=status_error");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/purchaseorders?msg=error");
        }
    }

    private void showPOList(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        List<PurchaseOrder> list = poDAO.getAllPurchaseOrders();
        request.setAttribute("purchaseOrders", list);
        request.setAttribute("suppliers", supplierDAO.getAllSuppliers());
        request.setAttribute("products", productDAO.getAllProducts());
        
        request.getRequestDispatcher("/purchase_orders.jsp").forward(request, response);
    }
}
