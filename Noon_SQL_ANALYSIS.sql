-- Top 1 outlets by cuisine without using limti and top function
with cte as (Select Cuisine, Restaurant_id, count(Order_id) as order_no from orders 
group by Cuisine, Restaurant_id),

cte1 as (select dense_rank()over(partition by Cuisine order by order_no desc) as rank1, Cuisine, Restaurant_id, order_no from cte)

select Cuisine, Restaurant_id from cte1 where rank1 = 1 ;

-- Everyday how many customers are we acquiring
Select FIRST_ORDER, COUNT(customer_code)as new_customers from (select customer_code, cast(min(Placed_at) AS DATE) AS FIRST_ORDER from orders
group by Customer_code) as first_orders
group by FIRST_ORDER;



-- Customers acquired in Jan and placed only one order in Jan and did not place any other order by

select count(*) from (select * from orders
group by Customer_code
having count(Order_id) = 1 and month(min(placed_at)) = 1) Jan_customers ;

-- Customer did not place any order in last 7 days and were acquired one month ago with their first order promo

with cte as (select Customer_code, min(Placed_at) as first_order, max(placed_at) as latest_order from orders
group by customer_code)

select cte.customer_code, cte.first_order, cte.latest_order, orders.Promo_code_Name
from cte inner join orders on cte.customer_code = orders.customer_code and cte.first_order = orders.placed_at
where DATEDIFF(CURDATE(), cte.latest_order) > 7 and cte.first_order < CURDATE() - INTERVAL 1 MONTH and orders.Promo_code_Name is not null ;

-- Business team wants to send the personalized content to the customer instantly placing their each third order

with cte as (Select*, row_number()over(partition by customer_code order by placed_at) as order_nu from orders)

SELECT customer_code, MAX(placed_at) as latest_order
FROM (
    SELECT * 
    FROM cte
    WHERE order_nu % 3 = 0
) con
GROUP BY customer_code;

-- List of customers placed more than 1 order and always used promo

 with cte as (select customer_code, count(Order_id) as order_number, count(Promo_code_Name) as promo_count from orders
group by customer_code
having count(Order_id) > 1)

select * from cte
where order_number = promo_count ;

-- 	Organically acquired customer in Jan 2025 (no promo code used)

with cte as (select customer_code, min(Placed_at) as acq_date from orders
group by customer_code
having month(min(Placed_at)) = 1)

select cte.customer_code from cte inner join orders on cte.Customer_code = orders.Customer_code and cte.acq_date = orders.placed_at
where orders.Promo_code_Name is null



