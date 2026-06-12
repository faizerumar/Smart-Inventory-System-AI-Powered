package com.inventory.model;

import java.math.BigDecimal;

public class PurchaseOrderItem {
    private int id;
    private int purchaseOrderId;
    private int productId;
    private int quantity;
    private BigDecimal unitPrice;
    
    // Auxiliary fields
    private String productName;
    private String productSku;

    public PurchaseOrderItem() {}

    public PurchaseOrderItem(int id, int purchaseOrderId, int productId, int quantity, BigDecimal unitPrice) {
        this.id = id;
        this.purchaseOrderId = purchaseOrderId;
        this.productId = productId;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getPurchaseOrderId() { return purchaseOrderId; }
    public void setPurchaseOrderId(int purchaseOrderId) { this.purchaseOrderId = purchaseOrderId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getProductSku() { return productSku; }
    public void setProductSku(String productSku) { this.productSku = productSku; }
}
