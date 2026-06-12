package com.inventory.model;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class PurchaseOrder {
    private int id;
    private Integer supplierId;
    private Timestamp orderDate;
    private Date expectedDeliveryDate;
    private String status; // PENDING, DELIVERED, CANCELLED
    private BigDecimal totalAmount;
    
    // Auxiliary fields
    private String supplierName;
    private List<PurchaseOrderItem> items = new ArrayList<>();

    public PurchaseOrder() {}

    public PurchaseOrder(int id, Integer supplierId, Timestamp orderDate, Date expectedDeliveryDate, String status, BigDecimal totalAmount) {
        this.id = id;
        this.supplierId = supplierId;
        this.orderDate = orderDate;
        this.expectedDeliveryDate = expectedDeliveryDate;
        this.status = status;
        this.totalAmount = totalAmount;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public Integer getSupplierId() { return supplierId; }
    public void setSupplierId(Integer supplierId) { this.supplierId = supplierId; }

    public Timestamp getOrderDate() { return orderDate; }
    public void setOrderDate(Timestamp orderDate) { this.orderDate = orderDate; }

    public Date getExpectedDeliveryDate() { return expectedDeliveryDate; }
    public void setExpectedDeliveryDate(Date expectedDeliveryDate) { this.expectedDeliveryDate = expectedDeliveryDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

    public String getSupplierName() { return supplierName; }
    public void setSupplierName(String supplierName) { this.supplierName = supplierName; }

    public List<PurchaseOrderItem> getItems() { return items; }
    public void setItems(List<PurchaseOrderItem> items) { this.items = items; }
    
    public void addItem(PurchaseOrderItem item) {
        this.items.add(item);
    }
}
