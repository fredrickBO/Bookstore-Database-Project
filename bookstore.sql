CREATE DATABASE IF NOT EXISTS bookstoreDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bookstoreDB;
-- 4. book_language table
CREATE TABLE book_language (
    language_id INT AUTO_INCREMENT PRIMARY KEY,
    language_code VARCHAR(8) NOT NULL UNIQUE COMMENT 'e.g., en, es, fr',
    language_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'e.g., English, Spanish, French'
);
-- 5. publisher table
CREATE TABLE publisher (
   publisher_id INT AUTO_INCREMENT PRIMARY KEY,
   publisher_name VARCHAR(255) NOT NULL UNIQUE
   -- You could add address, contact info etc. here later
);
-- 3. author table
CREATE TABLE author (
   author_id INT AUTO_INCREMENT PRIMARY KEY,
   first_name VARCHAR(100) NOT NULL,
   last_name VARCHAR(100) NOT NULL
   -- You could add bio, birthdate etc. here later
);
-- 10. country table
CREATE TABLE country (
   country_id INT AUTO_INCREMENT PRIMARY KEY,
   country_name VARCHAR(100) NOT NULL UNIQUE
);
-- 8. address_status table
CREATE TABLE address_status (
   status_id INT AUTO_INCREMENT PRIMARY KEY,
   status_value VARCHAR(50) NOT NULL UNIQUE COMMENT 'e.g., Current, Old, Billing, Shipping'
);
-- 13. shipping_method table
CREATE TABLE shipping_method (
   method_id INT AUTO_INCREMENT PRIMARY KEY,
   method_name VARCHAR(100) NOT NULL UNIQUE,
   cost DECIMAL(6, 2) NOT NULL DEFAULT 0.00 COMMENT 'Base cost for this method'
);
-- 15. order_status table
CREATE TABLE order_status (
   status_id INT AUTO_INCREMENT PRIMARY KEY,
   status_value VARCHAR(50) NOT NULL UNIQUE COMMENT 'e.g., Pending, Processing, Shipped, Delivered, Cancelled'
);
-- Now create the main entity tables that might reference the lookup tables
-- 1. book table
CREATE TABLE book (
   book_id INT AUTO_INCREMENT PRIMARY KEY,
   title VARCHAR(255) NOT NULL,
   isbn13 VARCHAR(13) UNIQUE COMMENT 'Unique 13-digit ISBN',
   num_pages INT,
   publication_date DATE,
   price DECIMAL(8, 2) NOT NULL COMMENT 'Current selling price',
   language_id INT NOT NULL,
   publisher_id INT NOT NULL,
   FOREIGN KEY (language_id) REFERENCES book_language(language_id) ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- 6. Customer table (using Customer instead of customer for consistency)
CREATE TABLE Customer ( -- Renamed from customer for potential keyword conflict avoidance and clarity
   customer_id INT AUTO_INCREMENT PRIMARY KEY,
   first_name VARCHAR(100) NOT NULL,
   last_name VARCHAR(100) NOT NULL,
   email VARCHAR(255) NOT NULL UNIQUE,
   phone VARCHAR(20) -- Optional phone number
   -- registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Optional: track when customer registered
);
-- 9. address table
CREATE TABLE address (
   address_id INT AUTO_INCREMENT PRIMARY KEY,
   street_number VARCHAR(20),
   street_name VARCHAR(255) NOT NULL,
   address_line2 VARCHAR(255), -- Optional (e.g., Apt, Suite)
   city VARCHAR(100) NOT NULL,
   state_province VARCHAR(100), -- State or Province
   postal_code VARCHAR(20),
   country_id INT NOT NULL,
   FOREIGN KEY (country_id) REFERENCES country(country_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- 11. cust_order table (Customer Order)
CREATE TABLE cust_order (
   order_id INT AUTO_INCREMENT PRIMARY KEY,
   customer_id INT NOT NULL,
   order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   dest_address_id INT NOT NULL COMMENT 'The specific address snapshot for this order',
   shipping_method_id INT NOT NULL,
   order_total DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Calculated total for the order lines + shipping',
   -- Current status could be stored here, or derived from order_history
   -- Let's add a direct current status ID for efficiency
   current_status_id INT NOT NULL,
   FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY (dest_address_id) REFERENCES address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY (shipping_method_id) REFERENCES shipping_method(method_id) ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY (current_status_id) REFERENCES order_status(status_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Now create the linking (junction) tables for many-to-many relationships
-- 2. book_author table
CREATE TABLE book_author (
   book_id INT NOT NULL,
   author_id INT NOT NULL,
   PRIMARY KEY (book_id, author_id), -- Composite primary key
   FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE ON UPDATE CASCADE, -- Cascade delete if book removed
   FOREIGN KEY (author_id) REFERENCES author(author_id) ON DELETE CASCADE ON UPDATE CASCADE -- Cascade delete if author removed
);
-- 7. customer_address table
CREATE TABLE customer_address (
   customer_id INT NOT NULL,
   address_id INT NOT NULL,
   status_id INT NOT NULL COMMENT 'Link to address_status (Current, Old, etc.)',
   PRIMARY KEY (customer_id, address_id), -- A customer can have only one entry per physical address
   FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY (status_id) REFERENCES address_status(status_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- 12. order_line table (Details of books in an order)
CREATE TABLE order_line (
   line_id INT AUTO_INCREMENT PRIMARY KEY,
   order_id INT NOT NULL,
   book_id INT NOT NULL,
   quantity INT NOT NULL CHECK (quantity > 0),
   price DECIMAL(8, 2) NOT NULL COMMENT 'Price of the book AT THE TIME OF ORDER',
   FOREIGN KEY (order_id) REFERENCES cust_order(order_id) ON DELETE CASCADE ON UPDATE CASCADE, -- If order deleted, lines are deleted
   FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE RESTRICT ON UPDATE CASCADE -- Don't delete book if it's in an order line
);
-- 14. order_history table
CREATE TABLE order_history (
   history_id INT AUTO_INCREMENT PRIMARY KEY,
   order_id INT NOT NULL,
   status_id INT NOT NULL COMMENT 'The status being recorded',
   status_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When this status was set',
   notes TEXT COMMENT 'Optional notes about this status change',
   FOREIGN KEY (order_id) REFERENCES cust_order(order_id) ON DELETE CASCADE ON UPDATE CASCADE, -- If order is deleted, history goes too
   FOREIGN KEY (status_id) REFERENCES order_status(status_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Add Indexes for Performance on frequently queried columns (optional but good practice)
ALTER TABLE book ADD INDEX idx_book_title (title);
ALTER TABLE Customer ADD INDEX idx_customer_email (email);
ALTER TABLE cust_order ADD INDEX idx_cust_order_customer (customer_id);
ALTER TABLE cust_order ADD INDEX idx_cust_order_date (order_date);
ALTER TABLE order_line ADD INDEX idx_order_line_book (book_id);

