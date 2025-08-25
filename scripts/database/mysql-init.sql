-- MySQL initialization script for APM Examples
-- This script creates the necessary tables and data for the examples

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT IGNORE INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Johnson', 'bob@example.com');

-- Create orders table for testing
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Insert sample orders
INSERT IGNORE INTO orders (user_id, amount, status) VALUES 
    (1, 99.99, 'completed'),
    (2, 149.50, 'pending'),
    (3, 75.25, 'completed');

-- Grant permissions to testuser
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';
FLUSH PRIVILEGES;
