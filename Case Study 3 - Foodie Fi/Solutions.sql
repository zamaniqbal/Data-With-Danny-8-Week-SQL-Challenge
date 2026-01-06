-- SECTION A: Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
SELECT 
    s.customer_id
    ,p.plan_name
    ,p.price
    ,s.start_date
FROM subscriptions s
INNER JOIN plans p 
    ON s.plan_id = p.plan_id
WHERE customer_id IN (1,2,11,13,15,16,18,19);

-- SECTION B: Data Analysis Questions
-- Q1 How many customers has Foodie-Fi ever had?
SELECT
    COUNT(DISTINCT customer_id) AS no_of_customers
FROM subscriptions;

-- Q2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
    DATE_TRUNC('month', start_date)
    ,COUNT(*) AS plan_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1;

-- Q3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    plan_name
    ,COUNT(*) AS events
FROM subscriptions s
INNER JOIN plans p
    ON p.plan_id = s.plan_id
WHERE DATE_PART('year',s.start_date) > 2020
GROUP BY 1;

-- Q4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH total_customers AS 
    (
    SELECT
        COUNT(DISTINCT customer_id) AS customer_count
    FROM subscriptions
    )
SELECT
    tc.*
    ,ROUND((COUNT(DISTINCT s.customer_id)
        / MAX(tc.customer_count))*100,1) AS proportion_churned
FROM subscriptions s
CROSS JOIN total_customers tc
WHERE s.plan_id = 4
GROUP BY 1;

-- Q5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS
    (
    SELECT
        customer_id
        ,plan_id
        ,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
    FROM subscriptions
    ),
    all_cust AS
    (
    SELECT COUNT(DISTINCT customer_id) AS total_cust
    FROM subscriptions
    )
SELECT
    COUNT(DISTINCT cte.customer_id) AS churn_after_trial_customers
    ,ROUND((COUNT(DISTINCT cte.customer_id)/MAX(ac.total_cust))*100,0) AS percentage_churned
FROM cte
CROSS JOIN all_cust ac
WHERE 
    rn = 2
    AND plan_id = 4;

-- Q6 What is the number and percentage of customer plans after their initial free trial?
WITH cte AS
    (
    SELECT
        p.plan_name
        ,s.customer_id
        ,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
    FROM subscriptions s
    INNER JOIN plans p
        ON p.plan_id = s.plan_id
    ),
    all_cust AS
    (
    SELECT COUNT(DISTINCT customer_id) AS total_cust
    FROM subscriptions
    )
SELECT
    plan_name
    ,COUNT(DISTINCT customer_id) AS customer_plans
    ,ROUND((COUNT(DISTINCT customer_id)/MAX(total_cust))*100,1) AS percentage_customer_plans
FROM cte
CROSS JOIN all_cust ac
WHERE rn = 2
GROUP BY 1;

-- Q7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte AS
    (
    SELECT
        *
        ,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS rn
    FROM subscriptions s
    WHERE start_date <= '2020-12-31'
    ),
    all_cust AS
    (
    SELECT COUNT(DISTINCT customer_id) AS total_cust
    FROM subscriptions
    )
SELECT
    p.plan_name
    ,COUNT(DISTINCT customer_id) AS customer_plans
    ,ROUND((COUNT(DISTINCT customer_id)/MAX(total_cust))*100,1) AS percentage_customer_plans
FROM cte
CROSS JOIN all_cust ac
INNER JOIN plans p
    ON p.plan_id = cte.plan_id
WHERE rn = 1
GROUP BY 1;

-- Q8 How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS annual_upgrade_customers
FROM subscriptions s
WHERE 
    DATE_PART('year',start_date) = 2020
    AND plan_id = 3;

-- Q9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH beginning AS
    (
    SELECT
        customer_id
        ,start_date AS trial_start
    FROM subscriptions
    WHERE plan_id = 0
    ),
    annual AS
    (
    SELECT
    customer_id
        ,start_date AS annual_start
    FROM subscriptions
    WHERE plan_id = 3
    )
SELECT
ROUND(AVG(DATEDIFF('day',trial_start,annual_start)),0) AS avg_days_to_upgrade_to_annual
FROM beginning b
INNER JOIN annual a
    ON a.customer_id = b.customer_id;

-- Q10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH beginning AS
    (
    SELECT
        customer_id
        ,start_date AS trial_start
    FROM subscriptions
    WHERE plan_id = 0
    ),
    annual AS
    (
    SELECT
    customer_id
        ,start_date AS annual_start
    FROM subscriptions
    WHERE plan_id = 3
    )
SELECT
    CASE
        WHEN DATEDIFF('days',trial_start,annual_start)<=30  THEN '0-30'
        WHEN DATEDIFF('days',trial_start,annual_start)<=60  THEN '31-60'
        WHEN DATEDIFF('days',trial_start,annual_start)<=90  THEN '61-90'
        WHEN DATEDIFF('days',trial_start,annual_start)<=120  THEN '91-120'
        WHEN DATEDIFF('days',trial_start,annual_start)<=150  THEN '121-150'
        WHEN DATEDIFF('days',trial_start,annual_start)<=180  THEN '151-180'
        WHEN DATEDIFF('days',trial_start,annual_start)<=210  THEN '181-210'
        WHEN DATEDIFF('days',trial_start,annual_start)<=240  THEN '211-240'
        WHEN DATEDIFF('days',trial_start,annual_start)<=270  THEN '241-270'
        WHEN DATEDIFF('days',trial_start,annual_start)<=300  THEN '271-300'
        WHEN DATEDIFF('days',trial_start,annual_start)<=330  THEN '301-330'
        WHEN DATEDIFF('days',trial_start,annual_start)<=360  THEN '331-360'
    END as days_after_trial
    ,COUNT(DISTINCT b.customer_id) AS number_of_customers
    ,ROUND(AVG(DATEDIFF('day',trial_start,annual_start)),0) AS avg_days_to_upgrade_to_annual
FROM beginning b
INNER JOIN annual a
    ON a.customer_id = b.customer_id
GROUP BY 1
ORDER BY 3;

-- Q11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT
    COUNT(DISTINCT basic.customer_id) AS number_of_downgrades
FROM subscriptions basic
INNER JOIN subscriptions pro
    ON pro.customer_id = basic.customer_id
WHERE 
    YEAR(basic.start_date) = 2020
    AND basic.plan_id = 1
    AND pro.plan_id = 2
    AND pro.start_date < basic.start_date;