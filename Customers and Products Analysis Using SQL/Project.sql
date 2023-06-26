/* It contains eight tables:
Customers: customer data
Employees: all employee information
Offices: sales office information
Orders: customers' sales orders
OrderDetails: sales order line for each sales order
Payments: customers' payment records
Products: a list of scale model cars
ProductLines: a list of product line categories
*/

/* Screen 3 */
-- Table descriptions

SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;

/* Screen 4: Which Products Should We Order More of or Less of? */

/* The low stock represents the quantity of the sum of each product ordered divided by the quantity of product in stock.
We can consider the ten highest rates. 
These will be the top ten products that are almost out-of-stock or completely out-of-stock*/

SELECT productCode,
	   ROUND(SUM(quantityOrdered) * 1.0 / (SELECT p.quantityInStock FROM products AS p
											WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails AS od
 GROUP BY productCode
 ORDER BY low_stock 
 LIMIT 10;

-- The product performance represents the sum of sales per product.

SELECT productCode, 
	   quantityOrdered * priceEach AS performance
  FROM orderdetails
 GROUP BY productCode
 ORDER BY performance DESC
 LIMIT 10;
 
-- Priority products for restocking are those with high product performance that are on the brink of being out of stock.

WITH
low_stock_table AS (
SELECT productCode,
	   ROUND(SUM(quantityOrdered) * 1.0 / (SELECT p.quantityInStock FROM products AS p
										    WHERE od.productCode = p.productCode), 2) AS low_stock
											
  FROM orderdetails AS od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10
)

SELECT productCode,
	   quantityOrdered * priceEach AS performance
  FROM orderdetails AS od
 WHERE productCode IN (SELECT productCode 
					   FROM low_stock_table)
 GROUP BY productCode
 ORDER BY performance DESC
 LIMIT 10;
 
/* Screen 5: How Should We Match Marketing and Communication Strategies to Customer Behavior? */
-- Before we begin, let's compute how much profit each customer generates
SELECT o.customerNumber,
	   SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber
 GROUP by o.customerNumber;
	
-- Finding the VIP and Less Engaged Customers
WITH
profit_by_customer AS (
SELECT o.customerNumber,
	   SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products AS p 
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT contactLastName, 
	   contactFirstName,
	   city,
	   country,
	   pc.profit
  FROM customers AS c
  JOIN profit_by_customer AS pc
    ON c.customerNumber = pc.customerNumber
 ORDER BY pc.profit DESC
 LIMIT 5;

WITH
profit_by_customer AS (
SELECT o.customerNumber,
	   SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products AS p 
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT contactLastName, 
	   contactFirstName,
	   city,
	   country,
	   pc.profit
  FROM customers AS c
  JOIN profit_by_customer AS pc
    ON c.customerNumber = pc.customerNumber
 ORDER BY pc.profit
 LIMIT 5;
 
/*
TOP 5 VIP customers
Freyre	Diego 	Madrid	Spain	326519.66
Nelson	Susan	San Rafael	USA	236769.39
Young	Jeff	NYC	USA	72370.09
Ferguson	Peter	Melbourne	Australia	70311.07
Labrune	Janine 	Nantes	France	60875.3
*/
/*
TOP 5 Less Engaged Customers
Young	Mary	Glendale	USA	2610.87
Taylor	Leslie	Brickhaven	USA	6586.02
Ricotti	Franco	Milan	Italy	9532.93
Schmitt	Carine 	Nantes	France	10063.8
Smith	Thomas 	London	UK	10868.04
*/

-- Question 3: How Much Can We Spend on Acquiring New Customers?
-- Before answering this question, let's find the number of new customers arriving each month. 
-- That way we can check if it's worth spending money on acquiring new customers. This query helps to find these numbers.

WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

/*the number of clients has been decreasing since 2003, and in 2004, we had the lowest values. 
The year 2005, which is present in the database as well, isn't present in the table above, 
this means that the store has not had any new customers since September of 2004. 
This means it makes sense to spend money acquiring new customers*/

/* To determine how much money we can spend acquiring new customers, 
we can compute the Customer Lifetime Value (LTV), which represents the average amount of money a customer generates. 
We can then determine how much we can spend on marketing */

WITH
profit_by_customer AS (
SELECT o.customerNumber,
	   SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products AS p 
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)
SELECT AVG(pc.profit) AS LTV
  FROM profit_by_customer AS pc;