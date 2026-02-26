-- Table Schema ---

-- =========================
-- 1) USERS TABLE
-- =========================
CREATE TABLE users (
  user_id           INT PRIMARY KEY,
  name              TEXT,
  age               INT,
  gender            TEXT,
  marital_status    TEXT,
  occupation        TEXT
);

-- =========================
-- 2) RESTAURANTS TABLE
-- =========================
DROP TABLE IF EXISTS restaurants CASCADE;

CREATE TABLE restaurants (
  restaurant_id INT PRIMARY KEY,
  name TEXT,
  country TEXT,
  city TEXT,
  rating NUMERIC(2,1),
  rating_count TEXT,
  cuisine TEXT
);


-- =========================
-- 3) FOOD TABLE
-- =========================
CREATE TABLE food (
  food_id     TEXT PRIMARY KEY,
  item        TEXT,
  food_type   TEXT
);

-- =========================
-- 4) MENU TABLE (Restaurant ↔ Food + Price)
-- =========================
DROP TABLE IF EXISTS menu CASCADE;

CREATE TABLE menu (
  id BIGSERIAL PRIMARY KEY,     -- auto unique key
  menu_id TEXT,                 -- keep menu_id (can repeat)
  restaurant_id INT REFERENCES restaurants(restaurant_id),
  food_id TEXT REFERENCES food(food_id),
  cuisine TEXT,
  price NUMERIC(10,2)
);

-- =========================
-- 5) ORDERS TABLE
-- =========================
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
  order_id BIGSERIAL PRIMARY KEY,
  order_date DATE,
  sales_qty INT,
  sales_amount INT,
  currency TEXT,
  user_id INT REFERENCES users(user_id),
  restaurant_id INT REFERENCES restaurants(restaurant_id)
);



DROP TABLE IF EXISTS orders_stage;

CREATE TABLE orders_stage (
  order_date TEXT,
  sales_qty TEXT,
  sales_amount TEXT,
  currency TEXT,
  user_id TEXT,
  restaurant_id TEXT
);

INSERT INTO orders(order_date, sales_qty, sales_amount, currency, user_id, restaurant_id)
SELECT
  TO_DATE(order_date, 'YYYY-MM-DD'),
  sales_qty::INT,
  sales_amount::INT,
  currency,
  user_id::INT,
  NULLIF(REGEXP_REPLACE(restaurant_id, '\.0$', ''), '')::INT
FROM orders_stage
WHERE sales_amount <> '-1'
  AND NULLIF(REGEXP_REPLACE(restaurant_id, '\.0$', ''), '')::INT
      IN (SELECT restaurant_id FROM restaurants);

	  
ALTER TABLE menu
DROP CONSTRAINT menu_food_id_fkey;

SELECT COUNT(*) FROM food;

ALTER TABLE menu
DROP CONSTRAINT menu_restaurant_id_fkey;


----------------------------------------
SELECT COUNT(*) AS users_rows FROM users;
SELECT COUNT(*) AS restaurants_rows FROM restaurants;
SELECT COUNT(*) AS food_rows FROM food;
SELECT COUNT(*) AS menu_rows FROM menu;
SELECT COUNT(*) AS orders_rows FROM orders;
-------------------------------

-- Q1) Total Revenue

Select sum(sales_amount) as Totale_sale
 from orders;



-- Q2) Total Number of Orders

Select Count(order_id) As Total_Orders
From orders;

-- Q3) Average Order Value (AOV)

Select ROUND(AVG(sales_amount),2) AS AOV
From orders;

-- Q4) Revenue by City

select r.city,SUM(o.sales_amount) as City_Revenue
from orders as o
join restaurants as r
on o.restaurant_id = r.restaurant_id
group by r.city
order by City_Revenue Desc;


-- Q5) Top 5 Restaurants by Revenue

select r.name,SUM(o.sales_amount) as Restaurant_Revenue
from orders as o
join restaurants as r
on o.restaurant_id = r.restaurant_id
group by r.name
order by Restaurant_Revenue Desc 
limit 5;

-- Q6) Revenue by Cuisine

select r.cuisine,SUM(o.sales_amount) as cuisine_Revenue
from orders as o
join restaurants as r
on o.restaurant_id = r.restaurant_id
group by r.cuisine
order by cuisine_Revenue Desc ;

-- Q7) Revenue by Gender

select u.gender,SUM(o.sales_amount) as gender_Revenue
from orders as o
join users as u
on o.user_id = u.user_id
group by u.gender
order by gender_Revenue Desc ;


-- Q8) Revenue by age

 select u.age,SUM(o.sales_amount) as Revenue
from orders as o
join users as u
on o.user_id = u.user_id
group by u.age
order by Revenue Desc ;

-- Q9) Revenue by occupation

 select u.occupation,SUM(o.sales_amount) as Revenue
from orders as o
join users as u
on o.user_id = u.user_id
group by u.occupation
order by Revenue Desc ;



-- Q10) Revenue by marital_status

 select u.marital_status,SUM(o.sales_amount) as Revenue
from orders as o
join users as u
on o.user_id = u.user_id
group by u.marital_status
order by Revenue Desc ;


-- Q11) Repeat Customers

SELECT user_id,
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY user_id
HAVING COUNT(order_id) > 1;


-- Q12) Monthly Revenue Trend


 select 
      date_trunc('month',order_date) as months,
	  sum(sales_amount) as Monthly_Revenue
 FROM orders
 group by months
 order by months ;

-- Q13) Average Rating by City


 SELECT city,round(avg(rating),2) AS Avg_Rating
 From restaurants
 WHERE rating IS NOT NULL
 group by city
 order by Avg_Rating desc ;


-- Q14) Revenue Contribution % by Restaurant

  SELECT r.name,
       SUM(o.sales_amount) AS revenue,
       ROUND(
           100.0 * SUM(o.sales_amount) 
           / SUM(SUM(o.sales_amount)) OVER (),
       2) AS revenue_percentage
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.name
ORDER BY revenue DESC;


-- Q15) Top Revenue Restaurant Per City (Using RANK)

SELECT *
FROM (
    SELECT r.city,
           r.name,
           SUM(o.sales_amount) AS revenue,
           RANK() OVER (PARTITION BY r.city 
                        ORDER BY SUM(o.sales_amount) DESC) AS rank_in_city
    FROM orders o
    JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
    GROUP BY r.city, r.name
) ranked
WHERE rank_in_city = 1;


-- Q16) Cumulative Revenue (Running Total Over Time) 

SELECT
    order_date,
    SUM(sales_amount) AS daily_revenue,
    SUM(SUM(sales_amount)) OVER (
        ORDER BY order_date
    ) AS cumulative_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;


-- Q17) Customer Lifetime Revenue

 
  Select u.user_id,
         u.name,
		 sum(o.sales_amount) as Lifetime_Rev
  From users as u
  join orders o
  on u.user_id = o.user_id
  group by u.user_id,u.name
  order by Lifetime_Rev DESC

  -- Q18) Age Group Revenue Segmentation

  SELECT 
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 40 THEN '25-40'
        ELSE 'Above 40'
    END AS age_group,
    SUM(o.sales_amount) AS revenue
FROM orders o
JOIN users u
ON o.user_id = u.user_id
GROUP BY age_group
ORDER BY revenue DESC;


-- Q19) Revenue vs Rating Correlation View 

SELECT r.name,
       r.rating,
       SUM(o.sales_amount) AS revenue
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
 WHERE rating IS NOT NULL
GROUP BY r.name, r.rating
ORDER BY r.rating DESC;


-- Q20) Revenue Per Order

SELECT
    r.name,
    ROUND(SUM(o.sales_amount)::NUMERIC 
          / COUNT(o.order_id), 2) AS avg_order_revenue
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.name
ORDER BY avg_order_revenue DESC;


-- Q21) Top 20% Restaurants Driving Revenue

WITH restaurant_revenue AS (
    SELECT r.name,
           SUM(o.sales_amount) AS revenue,
           SUM(SUM(o.sales_amount)) OVER () AS total_revenue
    FROM orders o
    JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
    GROUP BY r.name
),
ranked AS (
    SELECT *,
           SUM(revenue) OVER (
               ORDER BY revenue DESC
           ) AS cumulative_revenue
    FROM restaurant_revenue
)
SELECT *
FROM ranked
WHERE cumulative_revenue <= 0.8 * total_revenue;



-- Q22) Monthly Active Users (MAU)

 SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT user_id) AS monthly_active_users
FROM orders
GROUP BY month
ORDER BY month;


-- Q23) New Users Per Month (Growth Indicator)

SELECT 
    TO_CHAR(first_order_date, 'MM/YYYY') AS month_year, 
    COUNT(user_id) AS new_users
FROM (
    SELECT 
        user_id, 
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY user_id
) AS user_first_orders
GROUP BY month_year, DATE_TRUNC('month', first_order_date)
ORDER BY DATE_TRUNC('month', first_order_date);


-- Q24) Repeat vs One-Time Users

  SELECT 
    customer_type, 
    COUNT(*) AS total_users
FROM (
    SELECT 
        user_id,
        CASE 
            WHEN COUNT(order_id) = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS customer_type
    FROM orders
    GROUP BY user_id
) AS user_categories
GROUP BY customer_type;


-- Q25) First Order Revenue vs Repeat Revenue

 WITH user_orders AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY user_id 
                              ORDER BY order_date) AS order_rank
    FROM orders
)
SELECT 
    CASE 
        WHEN order_rank = 1 THEN 'First Order'
        ELSE 'Repeat Order'
    END AS order_type,
    SUM(sales_amount) AS revenue
FROM user_orders
GROUP BY order_type;

-- Q26) Revenue Volatility (Monthly Growth %)

WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', order_date) AS month,
           SUM(sales_amount) AS revenue
    FROM orders
    GROUP BY month
)
SELECT month,
       revenue,
       ROUND(
           100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
           / LAG(revenue) OVER (ORDER BY month),
       2) AS growth_percentage
FROM monthly_revenue
ORDER BY month;

-- Q27) Restaurant Revenue Stability

SELECT r.name,
       COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) AS active_months
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.name
ORDER BY active_months DESC;


-- Q28) Revenue Concentration Among Users (Pareto Users)
WITH user_revenue AS (
    SELECT user_id,
           SUM(sales_amount) AS revenue
    FROM orders
    GROUP BY user_id
),
ranked AS (
    SELECT *,
           SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
           SUM(revenue) OVER () AS total_revenue
    FROM user_revenue
)
SELECT *
FROM ranked
WHERE cumulative_revenue <= 0.8 * total_revenue;

-- Q29) Price Sensitivity (Revenue vs Price Tier)

SELECT 
    CASE 
        WHEN price < 200 THEN 'Low'
        WHEN price BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Premium'
    END AS price_category,
    SUM(o.sales_amount) AS revenue
FROM menu m
JOIN orders o ON o.restaurant_id = m.restaurant_id
GROUP BY price_category
ORDER BY revenue DESC;


-- Q30) Full Business Health Summary (Identify strongest market & strongest partner)

WITH city_revenue AS (
    SELECT r.city,
           SUM(o.sales_amount) AS revenue
    FROM orders o
    JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
    GROUP BY r.city
),
top_city AS (
    SELECT city
    FROM city_revenue
    ORDER BY revenue DESC
    LIMIT 1
)
SELECT r.name,
       SUM(o.sales_amount) AS revenue
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
WHERE r.city = (SELECT city FROM top_city)
GROUP BY r.name
ORDER BY revenue DESC
LIMIT 1;


