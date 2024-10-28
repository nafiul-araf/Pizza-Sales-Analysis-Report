# Pizza Sales Data Analysis using Power BI and SQL

[![My Project Screenshot](https://github.com/nafiul-araf/Pizza-Sales-Analysis-Report/blob/main/Home.JPG)](https://app.powerbi.com/view?r=eyJrIjoiNDEyOTJkMjktMGIwOS00MmRiLWJjNGEtN2U3ZTYyOWVhYWQwIiwidCI6IjhjMTI4NjJkLWZjYWYtNGEwNi05M2FjLTk0Yjk3YjVjZWQ1NSIsImMiOjEwfQ%3D%3D)

## Project Overview
This project focuses on analyzing pizza sales data using Power BI. The goal is to provide insights into key performance indicators (KPIs) such as total revenue, total pizzas sold, average order value, and more. The data includes sales, orders, and product performance for a pizza business across various dimensions like pizza categories, sizes, and time periods. This repository also contains SQL scripts for analyzing pizza sales data, including KPIs, revenue distribution by category and size, and ranking best/worst sellers by revenue, quantity, and order count.

## Key Objectives
- **Analyze sales performance**: Understand sales trends, best-selling pizzas, and revenue distribution.
- **Track customer behavior**: Examine average order values, order patterns by day and month, and pizza preferences.
- **Identify best and worst sellers**: Highlight the pizzas that generate the highest and lowest revenues and order quantities.
- **Optimize business performance**: Provide actionable insights to improve sales and inventory decisions.

## Data Sources
The dataset includes the following information:
- **Total Revenue**: Overall sales in dollar amounts.
- **Total Orders**: Number of orders placed.
- **Average Order Value**: The average dollar value of each order.
- **Total Pizzas Sold**: The number of pizzas sold in different categories (Classic, Supreme, Chicken, Veggie).
- **Sales by Pizza Size**: Distribution of revenue by pizza sizes (Large, Medium, Regular, X-Large).
- **Best and Worst Selling Pizzas**: Performance metrics for pizzas based on revenue and orders.
- **Orders by Day and Month**: Breakdown of total orders by each day of the week and each month of the year.

## KPIs Tracked
1. **Total Revenue**: Total sales generated within the reporting period.
2. **Total Orders**: Total number of pizza orders placed.
3. **Average Order Value**: Average value of each order.
4. **Total Pizzas Sold**: Total number of pizzas sold, broken down by category and size.
5. **Best and Worst Sellers**: Identifies the pizzas with the highest and lowest revenue and order counts.
6. **Orders by Day and Month**: Insights into peak sales periods.

## Tools and Technologies
- **Power BI**: For data visualization and reporting.
- **Excel**: For storing and processing the raw sales data.
- **PDF Reports**: Contain summaries of key metrics and insights (e.g., total revenue, top 5 best and worst-selling pizzas).

## Instructions for Running the Project
1. Load the provided dataset into Power BI.
2. Use the pre-built visualizations to analyze pizza sales by category, size, and time period.
3. Adjust filters to focus on specific metrics like revenue, orders, or product performance.
4. Review insights such as best-selling pizzas, daily and monthly sales trends, and average order values.

## Reports
The following insights can be generated from the data:
- **Total Revenue and Orders Report**: Provides an overview of revenue, total orders, and average order value.
- **Best and Worst Selling Pizzas**: Displays the top 5 and bottom 5 pizzas by revenue, order quantity, and overall performance.
- **Orders by Day and Month**: Highlights trends in customer ordering patterns by days of the week and months of the year.
- **Revenue by Pizza Category and Size**: Breaks down the revenue distribution by pizza type (Classic, Supreme, Veggie, Chicken) and by pizza size.

# Analysis with SQL

## Database Setup
### Data Loading with `LOAD DATA INFILE`

The `LOAD DATA INFILE` method is used here to import data from an external CSV file directly into the `pizza_dataset` table in MySQL. This bulk loading approach allows for efficient importing of large datasets. The command includes the following options for accurate data parsing and handling:

- **`FIELDS TERMINATED BY ','`**: Specifies that fields in the CSV file are separated by commas.
- **`OPTIONALLY ENCLOSED BY '"'`**: Allows fields to be optionally enclosed by double quotes, useful for text fields containing commas.
- **`LINES TERMINATED BY '\r\n'`**: Treats each line in the CSV file as a new row in the table.
- **Date Formatting**: Uses `STR_TO_DATE` to convert date strings into MySQL's DATE format during the import process.

This method helps streamline the data loading process by minimizing the need for manual data entry and ensuring efficient data import.

1. **Create Schema and Load Data**
    ```sql
    CREATE SCHEMA pizza_sales;
    USE pizza_sales;

    CREATE TABLE pizza_dataset (
        pizza_id INT,
        order_id INT,
        quantity INT,
        order_date DATE,
        unit_price DECIMAL(5, 2),
        total_price DECIMAL(5, 2),
        pizza_size VARCHAR(5),
        pizza_category VARCHAR(50),
        pizza_name VARCHAR(100)
    );

    LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pizza_sales_file.csv'
    INTO TABLE pizza_dataset 
    FIELDS TERMINATED BY ',' 
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (pizza_id, order_id, quantity, @order_date, unit_price, total_price, pizza_size, 
    pizza_category, pizza_name)
    SET order_date = STR_TO_DATE(@order_date, '%m/%d/%Y');
    ```

## Analysis Queries

### Q-1: Key Performance Indicators (KPIs)
- **Description:** Calculations for total revenue, average order value, total pizzas sold, total orders, and average pizzas per order.
    ```sql
    CREATE VIEW kpi_summary AS
    WITH KPI AS (
        SELECT 
            SUM(total_price) AS total_revenue,
            COUNT(DISTINCT order_id) AS total_orders,
            SUM(quantity) AS total_pizzas_sold,
            SUM(total_price) / COUNT(DISTINCT order_id) AS avg_order_value,
            SUM(quantity) / COUNT(DISTINCT order_id) AS avg_pizzas_per_order
        FROM 
            pizza_dataset
    )
    SELECT * FROM KPI;
    ```

### Q-2: Revenue Percentage by Pizza Category
- **Description:** Shows each pizza category's revenue as a percentage of total revenue.
    ```sql
    SELECT 
        pizza_category, 
        ROUND((SUM(total_price) / (SELECT SUM(total_price) FROM pizza_dataset) * 100), 2) AS revenue_pct
    FROM 
        pizza_dataset
    GROUP BY 
        pizza_category;
    ```

### Q-3: Revenue Percentage by Pizza Size
- **Description:** Calculates revenue percentage based on pizza size.
    ```sql
    WITH transformed_sizes AS (
        SELECT 
            CASE 
                WHEN pizza_size = 'S' THEN 'Regular'
                WHEN pizza_size = 'M' THEN 'Medium'
                WHEN pizza_size = 'L' THEN 'Large'
                WHEN pizza_size IN ('XL', 'XXL') THEN 'X-Large'
                ELSE pizza_size
            END AS pizza_size,
            total_price
        FROM 
            pizza_dataset
    )
    SELECT 
        pizza_size, 
        ROUND((SUM(total_price) / (SELECT SUM(total_price) FROM pizza_dataset) * 100), 2) AS revenue_pct
    FROM 
        transformed_sizes
    GROUP BY 
        pizza_size
    ORDER BY
        revenue_pct DESC;
    ```

### Q-4: Total Orders by Day of the Week
- **Description:** Calculates total orders by each day of the week.
    ```sql
    WITH DayOrders AS (
        SELECT 
            DAYNAME(order_date) AS day_name,
            COUNT(distinct order_id) AS total_orders
        FROM 
            pizza_dataset
        GROUP BY 
            DAYNAME(order_date)
    )
    SELECT 
        day_name,
        total_orders
    FROM 
        DayOrders
    ORDER BY 
        CASE day_name
            WHEN 'Sunday' THEN 1
            WHEN 'Monday' THEN 2
            WHEN 'Tuesday' THEN 3
            WHEN 'Wednesday' THEN 4
            WHEN 'Thursday' THEN 5
            WHEN 'Friday' THEN 6
            WHEN 'Saturday' THEN 7
        END;
    ```

### Q-5: Total Orders by Month
- **Description:** Calculates total orders for each month of the year.
    ```sql
    WITH MonthOrders AS (
        SELECT 
            MONTHNAME(order_date) AS month_name,
            COUNT(distinct order_id) AS total_orders
        FROM 
            pizza_dataset
        GROUP BY 
            MONTHNAME(order_date)
    )
    SELECT 
        month_name,
        total_orders
    FROM 
        MonthOrders
    ORDER BY 
        CASE month_name
            WHEN 'January' THEN 1
            WHEN 'February' THEN 2
            WHEN 'March' THEN 3
            WHEN 'April' THEN 4
            WHEN 'May' THEN 5
            WHEN 'June' THEN 6
            WHEN 'July' THEN 7
            WHEN 'August' THEN 8
            WHEN 'September' THEN 9
            WHEN 'October' THEN 10
            WHEN 'November' THEN 11
            WHEN 'December' THEN 12
        END;
    ```

### Q-6: Total Pizzas Sold by Pizza Category
- **Description:** Shows total pizzas sold for each pizza category.
    ```sql
    SELECT 
        pizza_category, 
        SUM(quantity) AS total_quantity
    FROM 
        pizza_dataset
    GROUP BY 
        pizza_category
    ORDER BY
        SUM(quantity) DESC;
    ```

## Ranking Queries

### Top and Bottom 5 Sellers
- **Stored Procedures** to retrieve top/bottom sellers based on various criteria (e.g., revenue, quantity, order count).

#### Stored Procedure for Top 5 Sellers:
- SP-1
    ```sql
    DELIMITER $$
    CREATE PROCEDURE get_top_5(IN expr VARCHAR(255), IN alias_name VARCHAR(255))
    BEGIN
        SET @sql_query = CONCAT(
            'SELECT pizza_name, ', 
            expr, ' AS ', alias_name, ' ',
            'FROM pizza_dataset ',
            'GROUP BY pizza_name ',
            'ORDER BY ', alias_name, ' DESC ',
            'LIMIT 5'
        );

        PREPARE stmt FROM @sql_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END $$
    DELIMITER ;
    ```

#### Stored Procedure for Bottom 5 Sellers:
- SP-2
    ```sql
    DELIMITER $$
    CREATE PROCEDURE get_bottom_5(IN expr VARCHAR(255), IN alias_name VARCHAR(255))
    BEGIN
        SET @sql_query = CONCAT(
            'SELECT pizza_name, ', 
            expr, ' AS ', alias_name, ' ',
            'FROM pizza_dataset ',
            'GROUP BY pizza_name ',
            'ORDER BY ', alias_name, ' ASC ',
            'LIMIT 5'
        );

        PREPARE stmt FROM @sql_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END $$
    DELIMITER ;
    ```

### Examples of Using the Stored Procedures:
#### Q-7: Top 5 Best-Selling Pizzas by Revenue
- Call SP-1
    ```sql
    CALL get_top_5('SUM(CAST(total_price AS DECIMAL(10, 2)))', 'revenue');
    ```

#### Q-8: Top 5 Worst-Selling Pizzas by Revenue
- Call SP-2
    ```sql
    CALL get_bottom_5('SUM(CAST(total_price AS DECIMAL(10, 2)))', 'revenue');
    ```

#### Q-9: Top 5 Best-Selling Pizzas by Quantity
- Call SP-1
    ```sql
    CALL get_top_5('SUM(quantity)', 'quantity');
    ```

#### Q-10: Top 5 Worst-Selling Pizzas by Quantity
- Call SP-2
    ```sql
    CALL get_bottom_5('SUM(quantity)', 'quantity');
    ```

#### Q-11: Top 5 Best-Selling Pizzas by Order Count
- Call SP-1
    ```sql
    CALL get_top_5('COUNT(DISTINCT order_id)', 'orders');
    ```
#### Q-12: Top 5 Worst-Selling Pizzas by Order Count
- Call SP-1
    ```sql
    CALL get_bottom_5('COUNT(DISTINCT order_id)', 'orders');
    ```

#### Q-12: Top 5 Worst-Selling Pizzas by Order Count
    ```sql
    CALL get_bottom_5('COUNT(DISTINCT order_id)', 'orders');
    ```
