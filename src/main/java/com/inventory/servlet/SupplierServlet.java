package com.inventory.servlet;

import com.inventory.dao.SupplierDAO;
import com.inventory.model.Supplier;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/suppliers")
public class SupplierServlet extends HttpServlet {
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
                    supplierDAO.deleteSupplier(deleteId);
                    response.sendRedirect(request.getContextPath() + "/suppliers?msg=deleted");
                    break;
                case "list":
                default:
                    showSupplierList(request, response);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            showSupplierList(request, response);
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
                String name = request.getParameter("name");
                String contactPerson = request.getParameter("contactPerson");
                String email = request.getParameter("email");
                String phone = request.getParameter("phone");
                int reliabilityScore = Integer.parseInt(request.getParameter("reliabilityScore"));

                Supplier s = new Supplier();
                s.setName(name);
                s.setContactPerson(contactPerson);
                s.setEmail(email);
                s.setPhone(phone);
                s.setReliabilityScore(reliabilityScore);

                boolean success;
                if (idStr == null || idStr.trim().isEmpty()) {
                    // Create New
                    success = supplierDAO.insertSupplier(s);
                } else {
                    // Update Existing
                    s.setId(Integer.parseInt(idStr));
                    success = supplierDAO.updateSupplier(s);
                }

                if (success) {
                    response.sendRedirect(request.getContextPath() + "/suppliers?msg=success");
                } else {
                    response.sendRedirect(request.getContextPath() + "/suppliers?msg=error");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/suppliers?msg=error");
        }
    }

    private void showSupplierList(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        List<Supplier> suppliers = supplierDAO.getAllSuppliers();
        request.setAttribute("suppliers", suppliers);
        request.getRequestDispatcher("/suppliers.jsp").forward(request, response);
    }
}
