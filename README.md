# noon Food Delivery Analytics Project

![noon Logo](/api/placeholder/200/100)

## Overview
noon food delivery marketplace launched in the Middle East on January 1, 2025. This analytics project aims to extract valuable insights and answer critical business questions based on the available dataset, supporting the growth and optimization of noon's food delivery operations in Dubai.

## Project Objectives

### 1. Customer Segmentation & Behavioral Analysis
We use SQL queries to identify distinct customer groups based on their order patterns, promo code usage, and acquisition timelines. These insights help stakeholders understand user behavior and lifecycle stages.

### 2. Promotion Effectiveness & Organic Growth Insights
Our analysis evaluates the impact of promotional campaigns versus organic acquisition, providing actionable insights on customer quality and retention potential across different acquisition channels.

### 3. Churn Risk Identification & Re-engagement Opportunities
We identify segments of users at risk of churning—such as those inactive after initial engagement—to assist business teams in developing targeted re-engagement strategies.

### 4. Milestone-Based User Identification for Personalization
The project generates lists of customers who reach key activity milestones (e.g., third order) to support business teams in planning personalized content or reward mechanisms.

## Dataset

The project uses a self-created dataset with the following schema:

```sql
CREATE TABLE orders (
    Order_id VARCHAR(20),
    Customer_code VARCHAR(20),
    Placed_at DATETIME,
    Restaurant_id VARCHAR(10),
    Cuisine VARCHAR(20),
    Order_status VARCHAR(20),
    Promo_code_Name VARCHAR(20)
);
```

## Getting Started

### Prerequisites
- SQL database system (MySQL, PostgreSQL, etc.)
- Basic understanding of SQL queries
- Data visualization tool (optional)

### Installation
1. Clone this repository
```bash
git clone https://github.com/yourusername/noon-food-delivery-analytics.git
```

2. Import the dataset into your SQL database
```bash
# Example for MySQL
mysql -u username -p database_name < setup/database_init.sql
```

## Key SQL Queries & Analyses

### Top Restaurants by Cuisine
Identifying the top restaurant for each cuisine category based on order count:

```sql
-- Top 1 outlets by cuisine without using limit and top function
WITH cte AS (
    SELECT Cuisine, Restaurant_id, COUNT(Order_id) AS order_no 
    FROM orders 
    GROUP BY Cuisine, Restaurant_id
),
cte1 AS (
    SELECT DENSE_RANK() OVER(PARTITION BY Cuisine ORDER BY order_no DESC) AS rank1, 
           Cuisine, Restaurant_id, order_no 
    FROM cte
)
SELECT Cuisine, Restaurant_id 
FROM cte1 
WHERE rank1 = 1;
```

### Daily Customer Acquisition Tracking
Monitoring new customer acquisition on a daily basis:

```sql
-- Everyday how many customers are we acquiring
SELECT FIRST_ORDER, COUNT(customer_code) AS new_customers 
FROM (
    SELECT customer_code, CAST(MIN(Placed_at) AS DATE) AS FIRST_ORDER 
    FROM orders
    GROUP BY Customer_code
) AS first_orders
GROUP BY FIRST_ORDER;
```

### One-Time January Customer Analysis
Identifying customers who only placed a single order in January and never returned:

```sql
-- Customers acquired in Jan and placed only one order in Jan and did not place any other order by
SELECT COUNT(*) 
FROM (
    SELECT * FROM orders
    GROUP BY Customer_code
    HAVING COUNT(Order_id) = 1 AND MONTH(MIN(placed_at)) = 1
) Jan_customers;
```

### Inactive Customers at Risk of Churn
Identifying potentially churned customers who haven't ordered in the past week:

```sql
-- Customer did not place any order in last 7 days and were acquired one month ago with their first order promo
WITH cte AS (
    SELECT Customer_code, MIN(Placed_at) AS first_order, MAX(placed_at) AS latest_order 
    FROM orders
    GROUP BY customer_code
)
SELECT cte.customer_code, cte.first_order, cte.latest_order, orders.Promo_code_Name
FROM cte 
INNER JOIN orders ON cte.customer_code = orders.customer_code AND cte.first_order = orders.placed_at
WHERE DATEDIFF(CURDATE(), cte.latest_order) > 7 
  AND cte.first_order < CURDATE() - INTERVAL 1 MONTH 
  AND orders.Promo_code_Name IS NOT NULL;
```

### Milestone-Based Customer Identification
Identifying customers who have just completed their third order for personalized engagement:

```sql
-- Business team wants to send the personalized content to the customer instantly placing their each third order
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_code ORDER BY placed_at) AS order_nu 
    FROM orders
)
SELECT customer_code, MAX(placed_at) AS latest_order
FROM (
    SELECT * 
    FROM cte
    WHERE order_nu % 3 = 0
) con
GROUP BY customer_code;
```

### Promo-Dependent Customers
Finding customers who always use promotions when ordering:

```sql
-- List of customers placed more than 1 order and always used promo
WITH cte AS (
    SELECT customer_code, COUNT(Order_id) AS order_number, COUNT(Promo_code_Name) AS promo_count 
    FROM orders
    GROUP BY customer_code
    HAVING COUNT(Order_id) > 1
)
SELECT * FROM cte
WHERE order_number = promo_count;
```

### Organic Customer Acquisition
Identifying customers acquired organically (without promotion) in January 2025:

```sql
-- Organically acquired customer in Jan 2025 (no promo code used)
WITH cte AS (
    SELECT customer_code, MIN(Placed_at) AS acq_date 
    FROM orders
    GROUP BY customer_code
    HAVING MONTH(MIN(Placed_at)) = 1
)
SELECT cte.customer_code 
FROM cte 
INNER JOIN orders ON cte.Customer_code = orders.Customer_code AND cte.acq_date = orders.placed_at
WHERE orders.Promo_code_Name IS NULL;
```

