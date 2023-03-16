SELECT *
FROM sales

SELECT *
FROM menu

SELECT *
FROM members

--(1) What is the total amount each customer spent at the restaurant?
SELECT 
s.customer_id,SUM(m.price) Total_amount_spent
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id

--(2) How many days has each customer visited the restaurant?
SELECT 
customer_id,COUNT(DISTINCT order_date) Days_visited
FROM sales 
GROUP BY customer_id
;

--(3) What was the first item from the menu purchased by each customer?
WITH CTE AS
(SELECT s.*,m.product_name,m.price,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date)rn
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id)
SELECT customer_id,order_date,product_name
FROM CTE
WHERE rn = 1

--(4) What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name,COUNT(*) Total_purchased_item
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY Total_purchased_item DESC


--(5) Which item was the most popular for each customer?
WITH CTE AS
(SELECT s.customer_id,m.product_name,COUNT(*) no_of_orders
	,RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) row_num
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id,m.product_name)
SELECT customer_id,product_name
FROM CTE
WHERE row_num = 1
ORDER BY customer_id 

--(6) Which item was purchased first by the customer after they became a member?
WITH CTE AS
(SELECT s.customer_id,m.product_name,mem.join_date,s.order_date
,ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date)row_num
FROM sales s
LEFT JOIN members mem
ON s.customer_id = mem.customer_id
AND order_date >= join_date
LEFT JOIN menu m
ON s.product_id = m.product_id
WHERE mem.join_date IS NOT NULL)

SELECT customer_id,product_name
FROM CTE
WHERE row_num = 1
ORDER BY customer_id
;
--(7) Which item was purchased just before the customer became a member
WITH CTE2 AS
(SELECT s.customer_id,m.product_name,mem.join_date,s.order_date
,RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC)rank_num
,ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC)row_num
FROM sales s
LEFT JOIN members mem
ON s.customer_id = mem.customer_id
AND s.order_date < mem.join_date
LEFT JOIN menu m
ON s.product_id = m.product_id
WHERE mem.join_date IS NOT NULL)
SELECT customer_id,product_name
FROM CTE2
WHERE rank_num =1

--(8) What is the total item and amount spent for each member before they became a member?
WITH CTE3 AS
(SELECT s.customer_id,m.product_name,mem.join_date,s.order_date,m.price
FROM sales s
LEFT JOIN members mem
ON s.customer_id = mem.customer_id
AND s.order_date < mem.join_date
LEFT JOIN menu m
ON s.product_id = m.product_id
WHERE mem.join_date IS NOT NULL)
SELECT customer_id,COUNT(product_name) total_items,SUM(price)amount_spent
FROM CTE3
GROUP BY customer_id
;
--(9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier,how many points would each customer have?
SELECT s.customer_id,
SUM(CASE
WHEN m.product_name = 'curry' THEN price * 10
WHEN  m.product_name = 'ramen' THEN price * 10
ELSE m.price *10*2
END) total_points
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id

--(10) In the first week after a customer joins the program(including their join date) they earn 2x points on all items,not just sushi.How many points do customer A and B have at the end of January?
SELECT s.customer_id,
SUM(CASE
WHEN s.order_date BETWEEN mem.join_date AND DATEADD(day,6,mem.join_date) THEN m.price * 10*2
WHEN m.product_name = 'curry' THEN price * 10
WHEN  m.product_name = 'ramen' THEN price * 10
ELSE m.price *10*2
END) total_points
--,s.order_date
--,mem.join_date offer_startdate
--,DATEADD(day,6,mem.join_date) offer_enddate
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
INNER JOIN members mem
ON s.customer_id = mem.customer_id
WHERE MONTH(order_date)=1
GROUP BY s.customer_id

-- BONUS QUESTIONS
--Joining All Things — Recreating the table

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date < mem.join_date THEN 'N'
      WHEN s.order_date >= mem.join_date THEN 'Y'
            ELSE 'N'
			END members
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY customer_id,order_date,price DESC


--Ranking all things
WITH CTE AS(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date < mem.join_date THEN 'N'
      WHEN s.order_date >= mem.join_date THEN 'Y'
            ELSE 'N'
			END members
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id)



SELECT customer_id,order_date,product_name,price,members,
	   CASE  
       WHEN members = 'Y'
	   THEN RANK() OVER(PARTITION BY customer_id,members ORDER BY order_date)
	   ELSE NULL
       END AS ranking
FROM CTE



















