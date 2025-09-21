SELECT * FROM walmart_db.walmart;

SELECT payment_method, COUNT(*)
FROM walmart
GROUP BY 1;

SELECT COUNT(DISTINCT branch)
FROM walmart;

-- 1. Analyze Payment Methods and Sales
-- Question: What are the different payment methods, and how many transactions and items were sold with each method?
SELECT 
	payment_method, 
    COUNT(*) AS no_of_transactions, 
    SUM(quantity) AS items_sold
FROM walmart
GROUP BY 1;

-- 2.  Identify the Highest-Rated Category in Each Branch
-- Question: Which category received the highest average rating in each branch?
SELECT 
	branch, 
	category
FROM 
(SELECT 
	branch,
	category,
	AVG(rating) as avg_rating, 
	RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS Ranking
FROM walmart
GROUP BY 1, 2) AS t
WHERE Ranking = 1;

-- 3.  Determine the Busiest Day for Each Branch
-- Question: What is the busiest day of the week for each branch based on transaction volume?
SELECT branch,
       day_of_week,
       transactions
FROM (
    SELECT branch,
           DAYNAME(date) AS day_of_week,
           COUNT(*) AS transactions,
           RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, DAYNAME(date)
) t
WHERE rnk = 1;

-- 4.  Calculate Total Quantity Sold by Payment Method
-- Question: How many items were sold through each payment method?
SELECT
	payment_method, 
    SUM(quantity) AS total_sold
FROM walmart
GROUP BY 1;

-- 5. Analyze Category Ratings by City
-- Question: What are the average, minimum, and maximum ratings for each category in each city?
SELECT 
	City,
    category,
    ROUND(avg(rating), 2) AS avg_rating, 
    min(rating) AS min_rating, 
    max(rating) AS max_rating
FROM walmart
GROUP BY 1, 2;

-- 6. Calculate Total Profit by Category
-- Question: What is the total profit for each category, ranked from highest to lowest?
SELECT 
	category,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(SUM(total * profit_margin), 2) AS profit
FROM walmart
GROUP BY 1
ORDER BY 3 DESC;

-- 7. Determine the Most Common Payment Method per Branch
-- Question: What is the most frequently used payment method in each branch?
SELECT
	branch,
    payment_method,
    total_transactions
FROM
(SELECT
	branch,
    payment_method,
    COUNT(*) AS total_transactions,
    RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
FROM walmart
GROUP BY 1, 2) AS t
WHERE rnk = 1; 

-- 8. Analyze Sales Shifts Throughout the Day
-- Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
With shifts_table AS 
(SELECT *, 
	CASE
	WHEN time_value BETWEEN '06:00:00' AND '11:59:59'
    THEN '1st shift: Morning'
    WHEN time_value BETWEEN '12:00:00' AND '17:59:59'
    THEN '2nd shift: Afternoon'
    WHEN time_value BETWEEN '18:00:00' AND '23:59:59'
    THEN '3rd shift: Evening'
    END AS shift
FROM    
(SELECT
	branch, 
    STR_TO_DATE(time, '%H:%i:%s') AS time_value,
    COUNT(*) AS transactions
FROM walmart
GROUP BY 1, 2) AS t)
SELECT branch, shift, SUM(transactions) AS total_transactions
FROM shifts_table
GROUP BY 1, 2
ORDER BY 1
;

-- 9. Identify Branches with Highest Revenue Decline Year-Over-Year
-- Question: Which branches experienced the largest decrease in revenue compared to the previous year?
WITH yearly_sales AS (
    SELECT 
        Branch,
        YEAR(STR_TO_DATE(date, '%Y-%m-%d')) AS sales_year,
        SUM(total) AS total_revenue
    FROM walmart
    GROUP BY Branch, YEAR(STR_TO_DATE(date, '%Y-%m-%d'))
),
sales_diff AS (
    SELECT 
        Branch,
        sales_year,
        total_revenue,
        LAG(total_revenue) OVER (PARTITION BY Branch ORDER BY sales_year) AS prev_year_revenue,
        (total_revenue - LAG(total_revenue) OVER (PARTITION BY Branch ORDER BY sales_year)) AS revenue_change
    FROM yearly_sales
)
SELECT 
    Branch,
    sales_year,
    total_revenue,
    prev_year_revenue,
    revenue_change
FROM sales_diff
WHERE revenue_change < 0
ORDER BY revenue_change ASC;
