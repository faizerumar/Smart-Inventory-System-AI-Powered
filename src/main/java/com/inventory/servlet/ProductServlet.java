package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.SupplierDAO;
import com.inventory.model.Product;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/products")
public class ProductServlet extends HttpServlet {
    private final ProductDAO productDAO = new ProductDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        try {
            switch (action) {
                case "delete":
                    int deleteId = Integer.parseInt(request.getParameter("id"));
                    productDAO.deleteProduct(deleteId);
                    response.sendRedirect(request.getContextPath() + "/products?msg=deleted");
                    break;
                case "list":
                default:
                    showProductList(request, response);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            showProductList(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        
        try {
            if ("save".equals(action)) {
                String idStr = request.getParameter("id");
                String sku = request.getParameter("sku");
                String name = request.getParameter("name");
                String description = request.getParameter("description");
                BigDecimal price = new BigDecimal(request.getParameter("price"));
                String category = request.getParameter("category");
                int stockLevel = Integer.parseInt(request.getParameter("stockLevel"));
                int reorderThreshold = Integer.parseInt(request.getParameter("reorderThreshold"));
                int leadTime = Integer.parseInt(request.getParameter("leadTime"));
                
                String expiryStr = request.getParameter("expiryDate");
                Date expiryDate = (expiryStr == null || expiryStr.trim().isEmpty()) ? null : Date.valueOf(expiryStr);
                
                String supplierIdStr = request.getParameter("supplierId");
                Integer supplierId = (supplierIdStr == null || supplierIdStr.trim().isEmpty() || supplierIdStr.equals("0")) ? null : Integer.parseInt(supplierIdStr);

                Product p = new Product();
                p.setSku(sku);
                p.setName(name);
                p.setDescription(description);
                p.setPrice(price);
                p.setCategory(category);
                p.setStockLevel(stockLevel);
                p.setReorderThreshold(reorderThreshold);
                p.setLeadTime(leadTime);
                p.setExpiryDate(expiryDate);
                p.setSupplierId(supplierId);

                boolean success;
                if (idStr == null || idStr.trim().isEmpty()) {
                    // Create New
                    success = productDAO.insertProduct(p);
                } else {
                    // Update Existing
                    p.setId(Integer.parseInt(idStr));
                    success = productDAO.updateProduct(p);
                }

                if (success) {
                    response.sendRedirect(request.getContextPath() + "/products?msg=success");
                } else {
                    response.sendRedirect(request.getContextPath() + "/products?msg=error");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/products?msg=error");
        }
    }

    private void showProductList(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        List<Product> listProducts = productDAO.getAllProducts();
        request.setAttribute("products", listProducts);
        request.setAttribute("suppliers", supplierDAO.getAllSuppliers());
        request.setAttribute("categories", productDAO.getAllCategories());
        
        request.getRequestDispatcher("/products.jsp").forward(request, response);
    }
}
