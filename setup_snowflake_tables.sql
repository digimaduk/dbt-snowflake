-- Setup script for dbt-poc Snowflake tables
-- Run this in your Snowflake console to create sample source tables

-- Create raw schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS ORI_RAW_DB.raw;

-- Switch to raw schema
USE SCHEMA ORI_RAW_DB.raw;

-- Create customers table
CREATE OR REPLACE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Create orders table
CREATE OR REPLACE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_date DATE,
    status VARCHAR(50),
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample data into customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, city, state, zip_code) VALUES
(1, 'John', 'Doe', 'john.doe@email.com', '555-0101', 'New York', 'NY', '10001'),
(2, 'Jane', 'Smith', 'jane.smith@email.com', '555-0102', 'Los Angeles', 'CA', '90210'),
(3, 'Bob', 'Johnson', 'bob.johnson@email.com', '555-0103', 'Chicago', 'IL', '60601'),
(4, 'Alice', 'Brown', 'alice.brown@email.com', '555-0104', 'Houston', 'TX', '77001'),
(5, 'Charlie', 'Davis', 'charlie.davis@email.com', '555-0105', 'Phoenix', 'AZ', '85001'),
(6, 'Diana', 'Wilson', 'diana.wilson@email.com', '555-0106', 'Philadelphia', 'PA', '19101'),
(7, 'Edward', 'Miller', 'edward.miller@email.com', '555-0107', 'San Antonio', 'TX', '78201'),
(8, 'Fiona', 'Taylor', 'fiona.taylor@email.com', '555-0108', 'San Diego', 'CA', '92101'),
(9, 'George', 'Anderson', 'george.anderson@email.com', '555-0109', 'Dallas', 'TX', '75201'),
(10, 'Helen', 'Thomas', 'helen.thomas@email.com', '555-0110', 'San Jose', 'CA', '95101');

-- Insert sample data into orders
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount) VALUES
(1, 1, '2024-01-15', 'completed', 150.00),
(2, 2, '2024-01-16', 'completed', 89.99),
(3, 1, '2024-01-20', 'completed', 200.50),
(4, 3, '2024-01-22', 'pending', 75.25),
(5, 4, '2024-01-25', 'completed', 300.00),
(6, 2, '2024-02-01', 'completed', 125.75),
(7, 5, '2024-02-03', 'shipped', 99.99),
(8, 6, '2024-02-05', 'completed', 180.00),
(9, 1, '2024-02-10', 'completed', 250.00),
(10, 7, '2024-02-12', 'pending', 45.50),
(11, 8, '2024-02-15', 'completed', 320.25),
(12, 3, '2024-02-18', 'shipped', 110.00),
(13, 9, '2024-02-20', 'completed', 85.75),
(14, 4, '2024-02-22', 'completed', 195.50),
(15, 10, '2024-02-25', 'pending', 65.00);

-- Verify the data
SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'orders' as table_name, COUNT(*) as row_count FROM orders;

-- Show sample data
SELECT 'Sample customers:' as info;
SELECT * FROM customers LIMIT 5;

SELECT 'Sample orders:' as info;
SELECT * FROM orders LIMIT 5;
