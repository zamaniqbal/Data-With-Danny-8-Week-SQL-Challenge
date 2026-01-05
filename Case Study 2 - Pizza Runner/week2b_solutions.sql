-- SECTION B: Runner and Customer Experience
-- Q1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    DATE_TRUNC('week',registration_date) + 4
    ,COUNT(runner_id) AS signups
FROM runners
GROUP BY 1
ORDER BY 1;

-- Q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    ro.runner_id
    ,AVG(DATEDIFF('minute',co.order_time, CAST(ro.pickup_time AS TIMESTAMP))) AS avg_time_taken_to_pickup
FROM customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
WHERE ro.pickup_time <> 'null'
GROUP BY 1
ORDER BY 2;

-- Q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS
    (
    SELECT
        co.order_id
        ,COUNT(pizza_id) AS number_of_pizzas
        ,MIN(DATEDIFF('minute',co.order_time, CAST(ro.pickup_time AS TIMESTAMP))) AS time_taken
    FROM customer_orders co
    INNER JOIN runner_orders ro
        ON ro.order_id = co.order_id
    WHERE ro.pickup_time <> 'null'
    GROUP BY 1
    )
SELECT
    number_of_pizzas
    ,AVG(time_taken) AS prep_time_mins
FROM cte
GROUP BY 1
ORDER BY 1 DESC;

-- Q4 What was the average distance travelled for each customer?
SELECT
    co.customer_id
    ,AVG(CAST(REPLACE (ro.distance,'km','') AS FLOAT)) AS avg_distance_travelled_km
FROm customer_orders co
INNER JOIN runner_orders ro
    ON ro.order_id = co.order_id
WHERE distance <> 'null'
GROUP BY 1
ORDER BY 2 DESC;

-- Q5 What was the difference between the longest and shortest delivery times for all orders?
SELECT 
    MAX(CAST(REGEXP_REPLACE(duration, '[a-z]', '') AS INT)) - MIN(CAST(REGEXP_REPLACE(duration, '[a-z]', '') AS INT)) AS diff_between_longest_and_shortest_delivery_mins
FROM runner_orders
WHERE duration <> 'null';

-- Q6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    runner_id
    ,order_id
    ,CAST(REPLACE (distance,'km','') AS FLOAT) AS distance_km
    ,CAST(REGEXP_REPLACE(duration, '[a-z]', '') AS INT) AS duration_mins
    ,(SUM(CAST(REPLACE (distance,'km','') AS FLOAT))
    /SUM(CAST(REGEXP_REPLACE(duration, '[a-z]', '') AS INT))) AS avg_speed_km_per_min
FROM runner_orders
WHERE pickup_time <> 'null'
GROUP BY 1,2,3,4
ORDER BY 5;
-- Generally, longer duration = lower speed

-- Q7 What is the successful delivery percentage for each runner?
WITH 
success AS
    (
    SELECT 
        runner_id
        ,COUNT(order_id) AS successful_order
    FROM runner_orders
    WHERE pickup_time <> 'null'
    GROUP BY 1
    ),
failed AS
    (
    SELECT 
        runner_id
        ,SUM(CASE
        WHEN pickup_time = 'null' THEN 1
        ELSE 0 END) AS failed_order
    FROM runner_orders
    GROUP BY 1
    )
SELECT
    s.runner_id
    ,(SUM(s.successful_order)
    /SUM(f.failed_order + s.successful_order)) * 100 AS successful_delivery_percentage
FROM success s
LEFT JOIN failed AS f
    ON f.runner_id = s.runner_id
GROUP BY 1;