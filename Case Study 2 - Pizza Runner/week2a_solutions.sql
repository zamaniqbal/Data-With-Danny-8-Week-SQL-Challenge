-- SECTION A: Pizza Metrics
-- Q1 How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders;

-- Q2 How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders;

-- Q3 How many successful orders were delivered by each runner?
SELECT
    runner_id
    ,COUNT(DISTINCT order_id) AS successful_orders_delivered
FROM runner_orders
WHERE pickup_time <> 'null'
GROUP BY 1
ORDER BY 2 DESC;

-- Q4 How many of each type of pizza was delivered?
SELECT
    pn.pizza_name
    ,COUNT(co.order_id) AS number_of_pizzas_delivered
FROM customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
INNER JOIN pizza_names pn
    ON pn.pizza_id = co.pizza_id
WHERE ro.pickup_time <> 'null'
GROUP BY 1;

-- Q5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    co.customer_id
    ,pn.pizza_name
    ,COUNT(co.order_id) AS number_of_pizzas_delivered
FROM customer_orders co
INNER JOIN pizza_names pn
    ON pn.pizza_id = co.pizza_id
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- Q6 What was the maximum number of pizzas delivered in a single order?
SELECT
    co.order_id
    ,COUNT(co.order_id) AS delivered_pizzas
FROM customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
WHERE ro.pickup_time <> 'null'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    co.customer_id
    ,SUM(
        CASE
        WHEN 
            co.exclusions <> 'null' AND co.exclusions IS NOT NULL AND co.exclusions <> ''
            AND co.extras <> 'null' AND co.extras IS NOT NULL AND co.extras <> ''
        THEN 1
        ELSE 0
        END) AS changes
    ,SUM(
        CASE
        WHEN
           co.exclusions <> 'null' AND co.exclusions IS NOT NULL AND co.exclusions <> ''
           AND co.extras <> 'null' AND co.extras IS NOT NULL AND co.extras <> ''
        THEN 0
        ELSE 1
        END) AS no_changes
FROM customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
WHERE ro.pickup_time <> 'null'
GROUP BY 1
ORDER BY 1;

-- Q8 How many pizzas were delivered that had both exclusions and extras?
SELECT
    COUNT(pizza_id) AS pizzas_delivered_with_extras_and_exclusions
FROM customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
WHERE 
    ro.pickup_time <> 'null'
    AND co.exclusions <> 'null' AND co.exclusions IS NOT NULL AND co.exclusions <> ''
    AND co.extras <> 'null' AND co.extras IS NOT NULL AND co.extras <> '';

-- Q9 What was the total volume of pizzas ordered for each hour of the day?
SELECT
    DATE_PART('hour',order_time) AS hour_of_the_day
    ,COUNT(order_id) AS number_of_pizzas_ordered
FROM customer_orders
GROUP BY 1
ORDER BY 1;

-- Q10 What was the volume of orders for each day of the week?
SELECT
    DAYNAME(order_time) AS day_of_the_week
    ,COUNT(order_id) AS number_of_pizzas_ordered
FROM customer_orders
GROUP BY 1;