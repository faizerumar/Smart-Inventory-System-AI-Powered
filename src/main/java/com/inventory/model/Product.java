package com.inventory.model;

import java.math.BigDecimal;
import java.sql.Date;

public class Product {
    private int id;
    private String sku;
    private String name;
    private String description;
    private BigDecimal price;
    private String category;
    private int stockLevel;
    private int reorderThreshold;
    private int leadTime;
    private Date expiryDate;
    private Integer supplierId;
    
    // Auxiliary field for display
    private String supplierName;

    public Product() {}

    public Product(int id, String sku, String name, String description, BigDecimal price, String category, 
                   int stockLevel, int reorderThreshold, int leadTime, Date expiryDate, Integer supplierId) {
        this.id = id;
        this.sku = sku;
        this.name = name;
        this.description = description;
        this.price = price;
        this.category = category;
        this.stockLevel = stockLevel;
        this.reorderThreshold = reorderThreshold;
        this.leadTime = leadTime;
        this.expiryDate = expiryDate;
        this.supplierId = supplierId;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public int getStockLevel() { return stockLevel; }
    public void setStockLevel(int stockLevel) { this.stockLevel = stockLevel; }

    public int getReorderThreshold() { return reorderThreshold; }
    public void setReorderThreshold(int reorderThreshold) { this.reorderThreshold = reorderThreshold; }

    public int getLeadTime() { return leadTime; }
    public void setLeadTime(int leadTime) { this.leadTime = leadTime; }

    public Date getExpiryDate() { return expiryDate; }
    public void setExpiryDate(Date expiryDate) { this.expiryDate = expiryDate; }

    public Integer getSupplierId() { return supplierId; }
    public void setSupplierId(Integer supplierId) { this.supplierId = supplierId; }

    public String getSupplierName() { return supplierName; }
    public void setSupplierName(String supplierName) { this.supplierName = supplierName; }

    public boolean isLowStock() {
        return this.stockLevel <= this.reorderThreshold;
    }

    public boolean isExpired() {
        if (this.expiryDate == null) return false;
        return this.expiryDate.before(new java.util.Date());
    }
}
