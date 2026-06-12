package com.inventory.model;

import java.sql.Timestamp;

public class Transaction {
    private int id;
    private int productId;
    private String transactionType; // PURCHASE, SALE, RETURN, ADJUSTMENT
    private int quantity;
    private Timestamp transactionDate;
    private String notes;
    
    // Auxiliary fields for UI
    private String productName;
    private String productSku;

    public Transaction() {}

    public Transaction(int id, int productId, String transactionType, int quantity, Timestamp transactionDate, String notes) {
        this.id = id;
        this.productId = productId;
        this.transactionType = transactionType;
        this.quantity = quantity;
        this.transactionDate = transactionDate;
        this.notes = notes;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getTransactionType() { return transactionType; }
    public void setTransactionType(String transactionType) { this.transactionType = transactionType; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public Timestamp getTransactionDate() { return transactionDate; }
    public void setTransactionDate(Timestamp transactionDate) { this.transactionDate = transactionDate; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getProductSku() { return productSku; }
    public void setProductSku(String productSku) { this.productSku = productSku; }
}
