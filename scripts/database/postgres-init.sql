-- PostgreSQL initialization script for APM Examples
-- This script creates the necessary tables and data for the examples

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Johnson', 'bob@example.com')
ON CONFLICT (email) DO NOTHING;

-- Create orders table for testing
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample orders
INSERT INTO orders (user_id, amount, status) VALUES 
    (1, 99.99, 'completed'),
    (2, 149.50, 'pending'),
    (3, 75.25, 'completed')
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO testuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO testuser;
