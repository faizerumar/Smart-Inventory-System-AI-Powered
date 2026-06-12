-- Create Database
CREATE DATABASE IF NOT EXISTS inventory_db;
USE inventory_db;

-- Drop Tables if they exist (to reset cleanly)
DROP TABLE IF EXISTS purchase_order_items;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS users;

-- 1. Users Table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL
);

-- 2. Suppliers Table
CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    reliability_score INT DEFAULT 100 -- Percentage score (0 - 100)
);

-- 3. Products Table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    stock_level INT DEFAULT 0,
    reorder_threshold INT DEFAULT 10,
    lead_time INT DEFAULT 5, -- in days
    expiry_date DATE,
    supplier_id INT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- 4. Transactions Table (for inventory stock changes)
CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL, -- positive for stock in, negative for stock out (handled mathematically in Java, or stored as absolute value depending on type. Here we store as absolute value and determine flow by transaction_type)
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 5. Purchase Orders Table
CREATE TABLE purchase_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, DELIVERED, CANCELLED
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- 6. Purchase Order Items Table
CREATE TABLE purchase_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- =========================================================================
-- MOCK DATA POPULATION
-- =========================================================================

-- Insert Users
INSERT INTO users (username, password, role) VALUES 
('admin', 'admin123', 'ADMIN'),
('manager', 'manager123', 'MANAGER');

-- Insert Suppliers
INSERT INTO suppliers (name, contact_person, email, phone, reliability_score) VALUES
('Nexus Tech Corp', 'John Doe', 'nexus@gmail.com', '+1-555-0101', 95),
('Aura Global Supplies', 'Jane Smith', 'aura@global.com', '+1-555-0102', 88),
('Apex Wholesalers', 'Robert Lee', 'contact@apex.com', '+1-555-0103', 75); -- Low reliability supplier

-- Insert Products
-- Expiry dates are set to both expired and upcoming to test warnings
INSERT INTO products (sku, name, description, price, category, stock_level, reorder_threshold, lead_time, expiry_date, supplier_id) VALUES
('PROD-101', 'Quantum Laptop', 'High-end developer laptop with 32GB RAM', 1200.00, 'Electronics', 15, 10, 4, '2027-12-31', 1),
('PROD-102', 'Supercharge Wireless Mouse', 'Ergonomic mouse with rechargeable battery', 45.00, 'Electronics', 8, 20, 3, '2026-10-15', 1), -- Low stock
('PROD-103', 'Pro Noise Cancelling Headphones', 'Active noise cancelling wireless headphones', 180.00, 'Electronics', 4, 15, 5, '2026-11-20', 2), -- Low stock
('PROD-104', 'Organic Almond Milk 1L', 'Unsweetened premium organic almond milk', 4.50, 'Groceries', 50, 25, 2, '2026-06-30', 3), -- Short expiry
('PROD-105', 'Fresh Greek Yogurt 500g', 'Traditional strained greek yogurt', 3.20, 'Groceries', 20, 15, 2, '2026-05-10', 3), -- Already Expired (if current date is past May 10, 2026)
('PROD-106', 'Heavy Duty Office Chair', 'Ergonomic lumbar support desk chair', 250.00, 'Furniture', 12, 5, 7, '2029-01-01', 2);

-- Insert Historical Sales Transactions (For AI Demand Forecasting & Trend Tracking)
-- Spans over the last 6 months (Dec 2025 - May 2026)
-- Product 101: Quantum Laptop (Steady sales)
INSERT INTO transactions (product_id, transaction_type, quantity, transaction_date, notes) VALUES
(1, 'SALE', 10, '2025-12-05 14:00:00', 'Dec Sales Week 1'),
(1, 'SALE', 8, '2025-12-19 10:30:00', 'Dec Sales Week 3'),
(1, 'PURCHASE', 20, '2026-01-02 09:00:00', 'Restock PO #1001'),
(1, 'SALE', 12, '2026-01-15 16:45:00', 'Jan Sales Week 2'),
(1, 'SALE', 11, '2026-01-28 11:15:00', 'Jan Sales Week 4'),
(1, 'SALE', 9, '2026-02-10 13:00:00', 'Feb Sales Week 2'),
(1, 'SALE', 15, '2026-02-24 15:30:00', 'Feb Sales Week 4'),
(1, 'PURCHASE', 30, '2026-03-01 10:00:00', 'Restock PO #1002'),
(1, 'SALE', 14, '2026-03-12 11:00:00', 'Mar Sales Week 2'),
(1, 'SALE', 16, '2026-03-25 14:20:00', 'Mar Sales Week 4'),
(1, 'SALE', 13, '2026-04-10 09:30:00', 'Apr Sales Week 2'),
(1, 'SALE', 18, '2026-04-26 16:00:00', 'Apr Sales Week 4'),
(1, 'SALE', 20, '2026-05-12 10:45:00', 'May Sales Week 2'),
(1, 'SALE', 22, '2026-05-27 15:00:00', 'May Sales Week 4');

-- Product 102: Wireless Mouse (Seasonal/Growing demand)
INSERT INTO transactions (product_id, transaction_type, quantity, transaction_date, notes) VALUES
(2, 'SALE', 15, '2025-12-10 12:00:00', 'Dec Sales'),
(2, 'SALE', 18, '2025-12-24 14:00:00', 'Holiday Sale'),
(2, 'PURCHASE', 50, '2026-01-05 10:00:00', 'Restock PO #1003'),
(2, 'SALE', 25, '2026-01-18 11:30:00', 'Jan Sales'),
(2, 'SALE', 22, '2026-02-12 15:45:00', 'Feb Sales'),
(2, 'SALE', 30, '2026-03-15 13:00:00', 'Spring Term Sale'),
(2, 'PURCHASE', 50, '2026-04-02 09:00:00', 'Restock PO #1004'),
(2, 'SALE', 35, '2026-04-20 16:30:00', 'Apr Sales'),
(2, 'SALE', 45, '2026-05-15 12:00:00', 'May Promo Sales'),
(2, 'SALE', 48, '2026-05-29 14:00:00', 'Late May Sales');

-- Product 104: Almond Milk (Groceries - High frequency, seasonal summer increase)
INSERT INTO transactions (product_id, transaction_type, quantity, transaction_date, notes) VALUES
(4, 'SALE', 40, '2025-12-15 10:00:00', 'Dec Sales'),
(4, 'PURCHASE', 100, '2026-01-04 09:00:00', 'Restock PO #1005'),
(4, 'SALE', 45, '2026-01-20 11:00:00', 'Jan Sales'),
(4, 'SALE', 38, '2026-02-15 15:00:00', 'Feb Sales'),
(4, 'SALE', 55, '2026-03-18 16:00:00', 'March Sales'),
(4, 'PURCHASE', 100, '2026-04-03 10:00:00', 'Restock PO #1006'),
(4, 'SALE', 65, '2026-04-22 13:00:00', 'Spring Warmup Sales'),
(4, 'SALE', 85, '2026-05-18 11:00:00', 'Early Summer Sales'),
(4, 'SALE', 92, '2026-05-30 15:30:00', 'Summer Peak Sales');

-- =========================================================================
-- ANOMALIES (To test local Anomaly Detection engine)
-- =========================================================================
-- Product 103: Headphones (Normally sells 2-5 units, suddenly there's a huge adjustment and massive sale)
INSERT INTO transactions (product_id, transaction_type, quantity, transaction_date, notes) VALUES
(3, 'SALE', 3, '2026-01-10 11:00:00', 'Normal Headphones Sale'),
(3, 'SALE', 4, '2026-02-14 14:00:00', 'Normal Headphones Sale'),
(3, 'PURCHASE', 30, '2026-03-05 09:00:00', 'Restock PO #1007'),
(3, 'SALE', 2, '2026-03-20 10:30:00', 'Normal Headphones Sale'),
(3, 'SALE', 5, '2026-04-12 16:00:00', 'Normal Headphones Sale'),
-- Anomaly 1: Massive data entry error or theft (Z-Score will flag this adjustment as extremely abnormal)
(3, 'ADJUSTMENT', 45, '2026-04-28 09:15:00', 'Manual Stock Adjustment: Spoilage / Lost items reported'), 
-- Anomaly 2: Extreme sales spike in a single transaction (Normal is ~3, this is 65)
(3, 'SALE', 65, '2026-05-10 11:30:00', 'Wholesale order processed by front desk');

-- Product 105: Greek Yogurt (Short lifespan - tracking adjustment/spoilation)
INSERT INTO transactions (product_id, transaction_type, quantity, transaction_date, notes) VALUES
(5, 'PURCHASE', 40, '2026-04-10 09:00:00', 'Initial Yogurt Batch'),
(5, 'SALE', 10, '2026-04-18 10:00:00', 'Yogurt Sales'),
(5, 'SALE', 8, '2026-04-28 14:00:00', 'Yogurt Sales'),
-- Anomaly 3: Large adjustment due to spoilage (yogurt expired on May 10)
(5, 'ADJUSTMENT', 15, '2026-05-11 17:00:00', 'Spoilage Write-Off: Expired Greek Yogurt');

-- Insert some historical Purchase Orders (to show PO tracking functionality)
INSERT INTO purchase_orders (supplier_id, order_date, expected_delivery_date, status, total_amount) VALUES
(1, '2026-05-01 10:00:00', '2026-05-05', 'DELIVERED', 24000.00),
(2, '2026-05-10 11:00:00', '2026-05-15', 'DELIVERED', 5400.00),
(1, '2026-06-05 09:00:00', '2026-06-09', 'PENDING', 900.00),  -- Active PO
(3, '2026-06-08 14:00:00', '2026-06-10', 'PENDING', 225.00);  -- Active PO, Overdue expected delivery date

-- Insert Purchase Order Items
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price) VALUES
(1, 1, 20, 1200.00),
(2, 3, 30, 180.00),
(3, 2, 20, 45.00),
(4, 4, 50, 4.50);
