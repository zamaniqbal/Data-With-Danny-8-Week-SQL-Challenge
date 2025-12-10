-- Q1 What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id
    ,SUM(price) AS total_spent
FROM sales AS s
INNER JOIN menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_spent DESC;

-- Q2 How many days has each customer visited the restaurant?
SELECT
    customer_id
    ,COUNT(DISTINCT order_date) total_visits
FROM sales
GROUP BY customer_id
ORDER BY total_visits DESC;

-- Q3 What was the first item from the menu purchased by each customer?
WITH CTE AS
    (
    SELECT
        s.customer_id
        ,m.product_name
        ,MIN(s.order_date) AS first_order_date
        ,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY first_order_date) AS rn
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
    GROUP BY 1,2
    )

SELECT
    customer_id
    ,product_name
    ,first_order_date
FROM CTE
WHERE rn = 1;

-- Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte AS
    (
    SELECT
        m.product_name
        ,m.product_id
        ,COUNT(s.product_id) AS times_bought
    FROM sales s
    INNER JOIN menu m
        ON m.product_id = s.product_id
    GROUP BY 1,2
    ORDER BY times_bought DESC
    LIMIT 1
    )
SELECT
    s.customer_id
    ,cte.product_name
    ,COUNT(s.customer_id) AS times_bought
FROM cte
INNER JOIN sales s
    ON cte.product_id = s.product_id
GROUP BY 1,2
ORDER BY times_bought DESC;

-- Q5 Which item was the most popular for each customer? 
WITH cte AS
    (
    SELECT
        s.customer_id
        ,m.product_name
        ,COUNT(s.product_id) times_purchased
        ,ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY times_purchased DESC) AS rn
    FROM sales s
    INNER JOIN menu m
        ON m.product_id = s.product_id
    GROUP BY 1,2
    )
SELECT
    customer_id
    ,product_name
    ,times_purchased
FROM cte
WHERE rn = 1;

-- Q6 Which item was purchased first by the customer after they became a member?
WITH cte AS
    (
    SELECT
        s.customer_id
        ,m.product_name
        ,MIN(s.order_date) AS purchase_date
        ,ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY purchase_date ASC) AS rn
    FROM sales s
    INNER JOIN menu m
        ON m.product_id = s.product_id
    INNER JOIN members c
        ON c.customer_id = s.customer_id
    WHERE c.join_date <= s.order_date
    GROUP BY 1,2
    )
SELECT 
    customer_id
    ,product_name
    ,purchase_date
FROM cte
WHERE rn = 1;

-- Q7 Which item was purchased just before the customer became a member?
WITH cte AS
    (
    SELECT
        s.customer_id
        ,m.product_name
        ,MAX(s.order_date) AS purchase_date
        ,ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY purchase_date DESC) AS rn
    FROM sales s
    INNER JOIN menu m
        ON m.product_id = s.product_id
    INNER JOIN members c
        ON c.customer_id = s.customer_id
    WHERE c.join_date >= s.order_date
    GROUP BY 1,2
    )
SELECT 
    customer_id
    ,product_name
    ,purchase_date
FROM cte
WHERE rn = 1;

-- Q8 What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id
    ,COUNT(s.product_id) AS items_bought
    ,SUM(m.price) AS total_spent
FROM sales s
INNER JOIN menu m
    ON m.product_id = s.product_id
INNER JOIN members c
    ON c.customer_id = s.customer_id
WHERE c.join_date >= s.order_date
GROUP BY 1;

-- Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id
    ,SUM(CASE
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
        END) AS points
FROM sales s
INNER JOIN menu m
    ON m.product_id = s.product_id
GROUP BY 1;

-- Q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    s.customer_id
    ,SUM(CASE 
        WHEN s.order_date BETWEEN c.join_date AND DATEADD('day',6,c.join_date) THEN m.price * 20
        WHEN product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
        END) AS points
FROM sales s
INNER JOIN members c
    ON c.customer_id = s.customer_id
INNER JOIN menu m
    ON s.product_id = m.product_id
WHERE DATE_TRUNC('month',s.order_date) = '2021-01-01'
GROUP BY 1
ORDER BY points DESC;

-- BONUS QUESTIONS

-- Join All The Things
SELECT
    s.customer_id
    ,s.order_date
    ,m.product_name
    ,m.price
    ,CASE
    WHEN s.order_date >= c.join_date THEN 'Y'
    ELSE 'N'
    END AS member
FROM sales s
LEFT JOIN menu m
    ON m.product_id = s.product_id
LEFT JOIN members c
    ON c.customer_id = s.customer_id
ORDER BY 
  S.customer_id 
  ,order_date 
  ,price DESC;

-- Rank All The Things
WITH cte AS
    (
    SELECT
        s.customer_id
        ,s.order_date
        ,m.product_name
        ,m.price
        ,CASE
        WHEN s.order_date >= c.join_date THEN 'Y'
        ELSE 'N'
        END AS member
    FROM sales s
    LEFT JOIN menu m
        ON m.product_id = s.product_id
    LEFT JOIN members c
        ON c.customer_id = s.customer_id
    ORDER BY 
      S.customer_id
      ,order_date 
      ,price DESC
    )
SELECT 
    *
    ,CASE
    WHEN member = 'N' THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
    END AS ranking
FROM cte;