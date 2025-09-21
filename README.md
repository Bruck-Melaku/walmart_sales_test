# Walmart Data Analysis: End-to-End SQL + Python Project 

## Project Overview


This project is an end-to-end data analysis solution designed to extract critical business insights from Walmart sales data. We utilize Python for data processing and analysis, SQL for advanced querying, and structured problem-solving techniques to solve key business questions. The project is ideal for data analysts looking to develop skills in data manipulation, SQL querying, and data pipeline creation.

---

## Project Steps

### 1. Set Up the Environment
   - **Tools Used**: Visual Studio Code (VS Code), Python, SQL (MySQL)
   - **Goal**: Create a structured workspace within VS Code and organize project folders for smooth development and data handling.

### 2. Set Up Kaggle API
   - **API Setup**: Obtain your Kaggle API token from [Kaggle](https://www.kaggle.com/) by navigating to your profile settings and downloading the JSON file.
   - **Configure Kaggle**: 
      - Place the downloaded `kaggle.json` file in your local `.kaggle` folder.
      - Use the command `kaggle datasets download -d <dataset-path>` to pull datasets directly into your project.

### 3. Download Walmart Sales Data
   - **Data Source**: Use the Kaggle API to download the Walmart sales datasets from Kaggle.
   - **Dataset Link**: [Walmart Sales Dataset](https://www.kaggle.com/najir0123/walmart-10k-sales-datasets)
   - **Storage**: Save the data in the `data/` folder for easy reference and access.

### 4. Install Required Libraries and Load Data
   - **Libraries**: Install necessary Python libraries using:
     ```bash
     pip install pandas numpy sqlalchemy mysql-connector-python psycopg2
     ```
   - **Loading Data**: Read the data into a Pandas DataFrame for initial analysis and transformations.

### 5. Explore the Data
   - **Goal**: Conduct an initial data exploration to understand data distribution, check column names, types, and identify potential issues.
   - **Analysis**: Use functions like `.info()`, `.describe()`, and `.head()` to get a quick overview of the data structure and statistics.

### 6. Data Cleaning
   - **Remove Duplicates**: Identify and remove duplicate entries to avoid skewed results.
   - **Handle Missing Values**: Drop rows or columns with missing values if they are insignificant; fill values where essential.
   - **Fix Data Types**: Ensure all columns have consistent data types (e.g., dates as `datetime`, prices as `float`).
   - **Currency Formatting**: Use `.replace()` to handle and format currency values for analysis.
   - **Validation**: Check for any remaining inconsistencies and verify the cleaned data.

### 7. Feature Engineering
   - **Create New Columns**: Calculate the `Total Amount` for each transaction by multiplying `unit_price` by `quantity` and adding this as a new column.
   - **Enhance Dataset**: Adding this calculated field will streamline further SQL analysis and aggregation tasks.

### 8. Load Data into MySQL
   - **Set Up Connections**: Connect to MySQLusing `sqlalchemy` and load the cleaned data into each database.
   - **Table Creation**: Set up tables in MySQusing Python SQLAlchemy to automate table creation and data insertion.
   - **Verification**: Run initial SQL queries to confirm that the data has been loaded accurately.

### 9. SQL Analysis: Complex Queries and Business Problem Solving
**1. Analyze Payment Methods and Sales
Question: What are the different payment methods, and how many transactions and items were sold with each method?**
```sql
SELECT 
	payment_method, 
    COUNT(*) AS no_of_transactions, 
    SUM(quantity) AS items_sold
FROM walmart
GROUP BY 1;
```

**2. Identify the Highest-Rated Category in Each Branch
Question: Which category received the highest average rating in each branch?**
```sql
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
```

**3. Determine the Busiest Day for Each Branch
Question: What is the busiest day of the week for each branch based on transaction volume?**
```sql
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
```

**4. Calculate Total Quantity Sold by Payment Method
Question: How many items were sold through each payment method?**
```sql
SELECT
	payment_method, 
    SUM(quantity) AS total_sold
FROM walmart
GROUP BY 1;
```

**5. Analyze Category Ratings by City
Question: What are the average, minimum, and maximum ratings for each category in each city?**
```sql
SELECT 
	City,
    category,
    ROUND(avg(rating), 2) AS avg_rating, 
    min(rating) AS min_rating, 
    max(rating) AS max_rating
FROM walmart
GROUP BY 1, 2;
```

**6. Calculate Total Profit by Category
Question: What is the total profit for each category, ranked from highest to lowest?**
```sql
SELECT 
	category,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(SUM(total * profit_margin), 2) AS profit
FROM walmart
GROUP BY 1
ORDER BY 3 DESC;
```

**7. Determine the Most Common Payment Method per Branch
Question: What is the most frequently used payment method in each branch?**
```sql
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
```

**8. Analyze Sales Shifts Throughout the Day
Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?**
```sql
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
```

**9. Identify Branches with Highest Revenue Decline Year-Over-Year
Question: Which branches experienced the largest decrease in revenue compared to the previous year?**
```sql
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
```

---

### 10. Project Publishing and Documentation
   - **Documentation**: Maintain well-structured documentation of the entire process in Markdown or a Jupyter Notebook.
   - **Project Publishing**: Publish the completed project on GitHub or any other version control platform, including:
     - The `README.md` file (this document).
     - Jupyter Notebooks (if applicable).
     - SQL query scripts.
     - Data files (if possible) or steps to access them.

---

## Requirements

- **Python 3.8+**
- **SQL Databases**: MySQL
- **Python Libraries**:
  - `pandas`, `numpy`, `sqlalchemy`, `mysql-connector-python`
- **Kaggle API Key** (for data downloading)



## Future Enhancements

Possible extensions to this project:
- Integration with a dashboard tool (e.g., Power BI or Tableau) for interactive visualization.
- Additional data sources to enhance analysis depth.
- Automation of the data pipeline for real-time data ingestion and analysis.

---

## License

This project is licensed under the MIT License. 

---

## Author: Bruck Melaku

## Acknowledgments

- **Data Source**: Kaggle’s Walmart Sales Dataset
- **Inspiration**: Walmart’s business case studies on sales and supply chain optimization.
- **Author's note**: I would like to thank ZeroAnalyst for his guidance in this project

---
