package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.TransactionDAO;
import com.inventory.model.Product;
import com.inventory.model.Transaction;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/transactions")
public class TransactionServlet extends HttpServlet {
    private final TransactionDAO transactionDAO = new TransactionDAO();
    private final ProductDAO productDAO = new ProductDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        List<Transaction> list = transactionDAO.getAllTransactions();
        List<Product> products = productDAO.getAllProducts();
        
        request.setAttribute("transactions", list);
        request.setAttribute("products", products);
        
        request.getRequestDispatcher("/transactions.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("add".equals(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                String transactionType = request.getParameter("transactionType");
                int quantity = Integer.parseInt(request.getParameter("quantity"));
                String notes = request.getParameter("notes");

                Transaction t = new Transaction();
                t.setProductId(productId);
                t.setTransactionType(transactionType);
                t.setQuantity(quantity);
                t.setNotes(notes);
                t.setTransactionDate(new Timestamp(System.currentTimeMillis()));

                boolean ok = transactionDAO.insertTransaction(t);
                if (ok) {
                    response.sendRedirect(request.getContextPath() + "/transactions?msg=success");
                } else {
                    response.sendRedirect(request.getContextPath() + "/transactions?msg=error");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/transactions?msg=error");
        }
    }
}
