-- Database creation
CREATE DATABASE IF NOT EXISTS bookstoreDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE bookstoreDB;

-- USERS AND PRIVILEGES
CREATE USER 'gloria'@'%' IDENTIFIED BY '5678';
GRANT ALL PRIVILEGES ON bookstoredb TO 'gloria'@'%';

-- CREATE TABLES
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



-- PHASE TWO: DATA POPPULATION
USE bookstoreDB;

INSERT INTO book_language (language_code, language_name) 
VALUES
('en', 'English'),
('es', 'Spanish'),
('fr', 'French');

INSERT INTO publisher (publisher_name) 
VALUES
('Longhorn Publishers'),
('Storymoja Publishers'),
('Phoenix Publishers'),
('Kenya Literature Bureau'),
('Moran Publishers');

INSERT INTO author (first_name, last_name) 
VALUES
('Stephen', 'Oundo'),
('Gloria’', 'Barasa'),
('George', 'Muia'),
('Joseph', 'Mukhwana'),
('Jane', 'Oduor');

INSERT INTO country (country_name) 
VALUES
('Kenya'),
('Uganda'),
('Canada'),
('Tanzania');

INSERT INTO address_status (status_value) 
VALUES
('Current'),
('Old'),
('Billing'),
('Shipping');

INSERT INTO shipping_method (method_name, cost) 
VALUES
('Standard Shipping', 5.00),
('Express Shipping', 15.00),
('Next Day Air', 25.00);

INSERT INTO order_status (status_value) 
VALUES
('Pending'),          
('Processing'),       
('Payment Failed'),   
('Shipped'),          
('Delivered'),        
('Cancelled'),        
('Returned');        


INSERT INTO book (title, num_pages, publication_date, price, language_id, publisher_id) 
VALUES
('The Shining', 688, '1977-01-28', 15.99, 1, 3), 
('Harry Potter and the Sorcerer''s Stone', 320, '1998-09-01', 12.50, 2, 2), 
('1984', 328, '1950-07-19', 9.95, 3, 1), 
('Pride and Prejudice', 480, '1813-01-28', 8.50, 2, 5),
('Anne of Green Gables', 832, '1904-2-7', 300, 1, 4),
('The Lord of the Rings', 492, '1999-6-29', 90, 2, 5),
('Harry Potter and the Philosophers Stone', 274, '2002-12-12', 900, 1,1),
('A Tale of Two Cities',  295, '1984-12-12', 700, 1,4),
('The Great Escape',  994, '2000-1-12', 900, 3,1),
('The Alchemist', 778, '1992-12-9', 900, 1,1),
('The Diary of a Young Girl', 500, '1978-3-2', 900, 1,2); 

INSERT INTO customer(first_name, last_name, email, phone)
VALUES('felix', 'kibet', 'kibetjyrt@example.com', 1234567890),
('anthony', 'masai', 'tfdghkw@example.com', 2345678901),
('faith', 'choge', 'fayfayfay@example.com', 3456789012),
('adelight', 'lubisia', 'boardinhr@example.com', 4567890123),
('janet', 'sitati', 'janosito@example.com', 5678901234),
('catherine', 'muniafu', 'defchyAHBDY@example.com', 6789012345),
('jeff', 'onyango', 'mtuwaduka@example.com', 7890123456),
('juliet', 'nyarrasa', 'kayukutu@example.com', 8901234567),
('mercy', 'silei', 'mercypeer@example.com', 9012345678),
('george', 'oleSahani', 'mashakura@example.com', 0123456789);


INSERT INTO address (street_number, street_name, city, postal_code, country_id) 
VALUES
('123', 'Muindi mbingu', 'Nairobi', 'MMN', 1),
('45', 'Sore drive', 'Nakuru', 'SDN', 1),
('10', 'Kijiji', 'Mombasa', 'KMS', 2),
('24', 'Sana Sana', 'Eldoret', 'SSE', 3);


INSERT INTO book_author (book_id, author_id) 
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4); 

-- Link customers to addresses with statuses
INSERT INTO customer_address (customer_id, address_id, status_id) 
VALUES
(1, 1, 1),
(2, 2, 1), 
(1, 3, 2);


INSERT INTO cust_order (customer_id, order_date, dest_address_id, shipping_method_id, current_status_id) VALUES
(1, NOW(), 1, 1, 1);
SET @last_order_id = LAST_INSERT_ID();


INSERT INTO order_line (order_id, book_id, quantity, price) 
VALUES
(@last_order_id, 1, 1, 15.99), 
(@last_order_id, 3, 2, 9.95); 

-- 3. Calculate the order total (books + shipping)
-- This might be done by application logic, but we can do it in SQL for this example
SET @order_books_total = (SELECT SUM(quantity * price) FROM order_line WHERE order_id = @last_order_id);
SET @shipping_cost = (SELECT cost FROM shipping_method WHERE method_id = (SELECT shipping_method_id FROM cust_order WHERE order_id = @last_order_id));
UPDATE cust_order
SET order_total = @order_books_total + @shipping_cost
WHERE order_id = @last_order_id;

-- 4. Add initial order history record
INSERT INTO order_history (order_id, status_id, status_date, notes) VALUES
(@last_order_id, 1, NOW(), 'Order placed by customer.'); -- Status 1 = Pending

    -- Phase 4: TESTING
-- 1. Find all books by Stephen Oundo
SELECT
    b.title,
    b.publication_date,
    p.publisher_name
FROM book b
JOIN book_author ba ON b.book_id = ba.book_id
JOIN author a ON ba.author_id = a.author_id
JOIN publisher p ON b.publisher_id = p.publisher_id
WHERE a.first_name = 'Stephen' AND a.last_name = 'Oundo';

-- 2. Find all orders placed by Anthony Masai
SELECT
    co.order_id,
    co.order_date,
    co.order_total,
    os.status_value AS current_status
FROM cust_order co
JOIN Customer c ON co.customer_id = c.customer_id
JOIN order_status os ON co.current_status_id = os.status_id
WHERE c.first_name = 'anthony' AND c.last_name = 'masai';
