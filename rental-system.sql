DROP DATABASE IF EXISTS `rental_db`;
CREATE DATABASE `rental_db`;
USE `rental_db`;
 
-- Create `vehicles` table
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE `vehicles` (
   `veh_reg_no`  VARCHAR(8)    NOT NULL,
   `category`    ENUM('car', 'truck')  NOT NULL DEFAULT 'car',  
                 -- Enumeration of one of the items in the list
   `brand`       VARCHAR(30)   NOT NULL DEFAULT '',
   `desc`        VARCHAR(256)  NOT NULL DEFAULT '',
                 -- desc is a keyword (for descending) and must be back-quoted
   `photo`       BLOB          NULL,   -- binary large object of up to 64KB
                 -- to be implemented later
   `daily_rate`  DECIMAL(6,2)  NOT NULL DEFAULT 9999.99,
                 -- set default to max value
   PRIMARY KEY (`veh_reg_no`),
   INDEX (`category`)  -- Build index on this column for fast search
) ENGINE=InnoDB;
   -- MySQL provides a few ENGINEs.
   -- The InnoDB Engine supports foreign keys and transactions
DESC `vehicles`;
SHOW CREATE TABLE `vehicles`;
SHOW INDEX FROM `vehicles`;
 
-- Create `customers` table
DROP TABLE IF EXISTS `customers`;
CREATE TABLE `customers` (
   `customer_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                  -- Always use INT for AUTO_INCREMENT column to avoid run-over
   `name`         VARCHAR(30)   NOT NULL DEFAULT '',
   `address`      VARCHAR(80)   NOT NULL DEFAULT '',
   `phone`        VARCHAR(15)   NOT NULL DEFAULT '',
   `discount`     DOUBLE        NOT NULL DEFAULT 0.0,
   PRIMARY KEY (`customer_id`),
   UNIQUE INDEX (`phone`),  -- Build index on this unique-value column
   INDEX (`name`)           -- Build index on this column
) ENGINE=InnoDB;
DESC `customers`;
SHOW CREATE TABLE `customers`;
SHOW INDEX FROM `customers`;
 
-- Create `rental_records` table
DROP TABLE IF EXISTS `rental_records`;
CREATE TABLE `rental_records` (
   `rental_id`    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
   `veh_reg_no`   VARCHAR(8)    NOT NULL, 
   `customer_id`  INT UNSIGNED  NOT NULL,
   `start_date`   DATE          NOT NULL DEFAULT('0000-00-00'),
   `end_date`     DATE          NOT NULL DEFAULT('0000-00-00'),
   `lastUpdated`  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      -- Keep the created and last updated timestamp for auditing and security
   PRIMARY KEY (`rental_id`),
   FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`)
      ON DELETE RESTRICT ON UPDATE CASCADE,
      -- Disallow deletion of parent record if there are matching records here
      -- If parent record (customer_id) changes, update the matching records here
   FOREIGN KEY (`veh_reg_no`) REFERENCES `vehicles` (`veh_reg_no`)
      ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
DESC `rental_records`;
SHOW CREATE TABLE `rental_records`;
SHOW INDEX FROM `rental_records`;

-- Inserting test records
INSERT INTO `vehicles` VALUES
   ('SBA1111A', 'car', 'NISSAN SUNNY 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBB2222B', 'car', 'TOYOTA ALTIS 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBC3333C', 'car', 'HONDA CIVIC 1.8L',  '4 Door Saloon, Automatic', NULL, 119.99),
   ('GA5555E', 'truck', 'NISSAN CABSTAR 3.0L',  'Lorry, Manual ', NULL, 89.99),
   ('GA6666F', 'truck', 'OPEL COMBO 1.6L',  'Van, Manual', NULL, 69.99);
   -- No photo yet, set to NULL
SELECT * FROM `vehicles`;
 
INSERT INTO `customers` VALUES
   (1001, 'Angel', '8 Happy Ave', '88888888', 0.1),
   (NULL, 'Mohammed Ali', '1 Kg Java', '99999999', 0.15),
   (NULL, 'Kumar', '5 Serangoon Road', '55555555', 0),
   (NULL, 'Kevin Jones', '2 Sunset boulevard', '22222222', 0.2);
SELECT * FROM `customers`;
 
INSERT INTO `rental_records` VALUES
  (NULL, 'SBA1111A', 1001, '2012-01-01', '2012-01-21', NULL),
  (NULL, 'SBA1111A', 1001, '2012-02-01', '2012-02-05', NULL),
  (NULL, 'GA5555E',  1003, '2012-01-05', '2012-01-31', NULL),
  (NULL, 'GA6666F',  1004, '2012-01-20', '2012-02-20', NULL);
SELECT * FROM `rental_records`;

-- Q1 Customer 'Angel' has rented 'SBA1111A' from today for 10 days. 
INSERT INTO rental_records (rental_id, veh_reg_no, customer_id, start_date, end_date, lastUpdated)
VALUES(
	NULL, 
    'SBA1111A', 
    (SELECT customer_id FROM customers WHERE name = 'Angel'),
    NOW(),
    DATE_ADD(NOW(), INTERVAL 10 DAY),
    NULL
	);


-- Q2 Customer 'Kumar' has rented 'GA5555E' from tomorrow for 3 months.
INSERT INTO rental_records (rental_id, veh_reg_no, customer_id, start_date, end_date, lastUpdated)
VALUES(
	NULL, 
    'GA5555E', 
    (SELECT customer_id FROM customers WHERE name = 'Kumar'),
    DATE_ADD(NOW(), INTERVAL 1 DAY),
    DATE_ADD(NOW(), INTERVAL 3 MONTH),
    NULL
	);


-- Q3 List all rental records (start date, end date) with vehicle's registration number, brand, and customer name, sorted by vehicle's categories followed by start date.
SELECT t2.start_date, t2.end_date, t1.veh_reg_no, t1.brand, t3.name FROM vehicles AS t1 
INNER JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
INNER JOIN customers AS t3 ON t3.customer_id = t2.customer_id ORDER BY t1.category, t2.start_date;

-- Q4 List all the expired rental records (end_date before CURDATE()).
SELECT * FROM rental_records
WHERE end_date < CURDATE();


-- Q5 List the vehicles rented out on '2012-01-10' (not available for rental), in columns of vehicle registration no, customer name, start date and end date. 
SELECT t1.veh_reg_no AS Registration_no, t3.name AS Customer_name, t2.start_date, t2.end_date FROM vehicles AS t1 
INNER JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
INNER JOIN customers AS t3 ON t3.customer_id = t2.customer_id 
WHERE '2012-01-10' BETWEEN t2.start_date AND t2.end_date; 


-- Q6 List all vehicles rented out today, in columns registration number, customer name, start date, end date.
SELECT t1.veh_reg_no AS Registration_no, t3.name AS Customer_name, t2.start_date, t2.end_date FROM vehicles AS t1 
INNER JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
INNER JOIN customers AS t3 ON t3.customer_id = t2.customer_id 
WHERE t2.start_date = CURDATE(); 

-- Q7 Similarly, list the vehicles rented out (not available for rental) for the period from '2012-01-03' to '2012-01-18'. 
SELECT t1.veh_reg_no, t1.category, t1.brand, t2.start_date, t2.end_date FROM vehicles AS t1 
INNER JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
INNER JOIN customers AS t3 ON t3.customer_id = t2.customer_id 
WHERE t1.veh_reg_no IN (
	SELECT
		t1.veh_reg_no
	FROM
		vehicles
	WHERE
		(t2.start_date BETWEEN '2012-01-03' AND '2012-01-18')
        OR
        (t2.end_date BETWEEN '2012-01-03' AND '2012-01-18')
        OR
        (t2.start_date <= '2012-01-03' AND t2.end_date > '2012-01-18')
	);

-- Q8 List the vehicles (registration number, brand and description) available for rental (not rented out) on '2012-01-10' 
SELECT t1.veh_reg_no AS Registration_no, t1.brand AS Brand, t1.desc AS Description 
FROM vehicles AS t1 
LEFT JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
WHERE t1.veh_reg_no NOT IN (
	SELECT
		veh_reg_no
	FROM
		rental_records
	WHERE
		(t2.start_date < '2012-01-10')
        AND 
        (t2.end_date > '2012-01-10')
	) GROUP BY t1.veh_reg_no; 
   

-- Q9 list the vehicles available for rental for the period from '2012-01-03' to '2012-01-18'.
SELECT t1.veh_reg_no AS Registration_no, t1.category, t1.brand, t1.desc AS Description FROM vehicles AS t1 
LEFT JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
WHERE t1.veh_reg_no NOT IN (
	SELECT
		veh_reg_no
	FROM
		rental_records
	WHERE
		(t2.start_date < '2012-01-03')
        OR
        (t2.end_date > '2012-01-03')
        AND
        (t2.start_date < '2012-01-18')
        AND
        (t2.end_date > '2012-01-18')
	) GROUP BY t1.veh_reg_no;


-- Q10 list the vehicles available for rental from today for 10 days.
SELECT DISTINCT t1.veh_reg_no AS Registration_no, t1.brand, t1.desc AS Description FROM vehicles AS t1 
LEFT JOIN rental_records AS t2 ON t1.veh_reg_no = t2.veh_reg_no
WHERE t1.veh_reg_no NOT IN (
	SELECT
		veh_reg_no
	FROM
		rental_records
	WHERE
		rental_records.start_date BETWEEN CURDATE() AND date_add(CURDATE(), INTERVAL 10 day)
	);


