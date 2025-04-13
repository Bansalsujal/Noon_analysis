# noon Food Delivery Analytics Project

![image alt](https://github.com/Bansalsujal/Noon_analysis/blob/ec288403b7ddbadced097a2e29fb46bd146a1853/nooncom_noon_food_image.jpeg)

## Overview
noon food delivery marketplace launched in the Middle East on January 1, 2025. This analytics project aims to extract valuable insights and answer critical business questions based on the available dataset, supporting the growth and optimization of noon's food delivery operations in Dubai.

## Project Objectives

### 1. Customer Segmentation & Behavioral Analysis
Write SQL queries to identify distinct customer groups based on their order patterns, promo code usage, and acquisition timelines — helping stakeholders understand user behavior and lifecycle stages.

### 2. Promotion Effectiveness & Organic Growth Insights
Analyze customer data to evaluate the impact of promotional campaigns versus organic acquisition, providing actionable insights on customer quality and retention potential.

### 3. Churn Risk Identification & Re-engagement Opportunities
Surface segments of users at risk of churning — such as those inactive after initial engagement — to assist business teams in planning potential re-engagement strategies.

### 4. Milestone-Based User Identification for Personalization
Generate lists of customers who hit key activity milestones (e.g., third order) to support business teams in planning personalized content or reward mechanisms.
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


## Business requirement and solutions

### 1. Top Restaurants by Cuisine
Identifying the top restaurant for each cuisine category based on order count:

```sql
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

### 2. Daily Customer Acquisition Tracking
Monitoring new customer acquisition on a daily basis:

```sql

SELECT FIRST_ORDER, COUNT(customer_code) AS new_customers 
FROM (
    SELECT customer_code, CAST(MIN(Placed_at) AS DATE) AS FIRST_ORDER 
    FROM orders
    GROUP BY Customer_code
) AS first_orders
GROUP BY FIRST_ORDER;
```

### 3. One-Time January Customer Analysis
Identifying customers who only placed a single order in January and never returned:

```sql

SELECT COUNT(*) 
FROM (
    SELECT * FROM orders
    GROUP BY Customer_code
    HAVING COUNT(Order_id) = 1 AND MONTH(MIN(placed_at)) = 1
) Jan_customers;
```

###4.  Inactive Customers at Risk of Churn
Identifying potentially churned customers who haven't ordered in the past week:

```sql

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

### 5. Milestone-Based Customer Identification
Identifying customers who have just completed their third order for personalized engagement:

```sql

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

### 6. Promo-Dependent Customers
Finding customers who always use promotions when ordering:

```sql

WITH cte AS (
    SELECT customer_code, COUNT(Order_id) AS order_number, COUNT(Promo_code_Name) AS promo_count 
    FROM orders
    GROUP BY customer_code
    HAVING COUNT(Order_id) > 1
)
SELECT * FROM cte
WHERE order_number = promo_count;
```

### 7. Organic Customer Acquisition
Identifying customers acquired organically (without promotion) in January 2025:

```sql

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

