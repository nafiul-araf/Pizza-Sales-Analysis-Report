-- 1. Data Loading from the Local Directory

-- Create schema and use it
CREATE SCHEMA pizza_sales;
USE pizza_sales;

-- Create the web_marketing_data fact table
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

-- Loading data using INFILE method
-- Enable local_infile if necessary
SHOW VARIABLES LIKE "local_infile";
-- SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pizza_sales_file.csv'
INTO TABLE pizza_dataset 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(pizza_id, order_id, quantity, @order_date, unit_price, total_price, pizza_size, 
pizza_category, pizza_name)
SET order_date = STR_TO_DATE(@order_date, '%m/%d/%Y');




-- 2. Start Analysis

select * from pizza_dataset;
select (SUM(quantity)) / COUNT(distinct order_id) from pizza_dataset;

-- Q-1. KPI: Total Revenue, Avg Orders Value, Total Pizzas Sold, Total Orders, Avg Pizzas per Order


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

SELECT * FROM kpi_summary;


-- Q-2. Total Revenue (%) by Pizza Category

SELECT 
    pizza_category, 
    ROUND(
        (SUM(total_price) / (SELECT SUM(total_price) FROM pizza_dataset) * 100), 
        2
    ) AS revenue_pct
FROM 
    pizza_dataset
GROUP BY 
    pizza_category;


-- Q-3. Total Revenue (%) by Pizza Size

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
    ROUND(
        (SUM(total_price) / (SELECT SUM(total_price) FROM pizza_dataset) * 100), 
        2
    ) AS revenue_pct
FROM 
    transformed_sizes
GROUP BY 
    pizza_size
ORDER BY
    revenue_pct DESC;


-- Q-4. Total Orders by Day Name

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


-- Q-5. Total Orders by Month Name

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


-- Q-6. Total Pizzas Sold by Pizza Category

SELECT 
    pizza_category, 
    SUM(quantity) AS revenue_pct
FROM 
    pizza_dataset
GROUP BY 
    pizza_category
ORDER BY
    SUM(quantity) DESC;






-- Top 5 BSET/WORSE SELLERS

-- SP for BEST SELLERS
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


-- SP for WORSE SELLERS
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


-- Q-7. Best 5 Pizzas By Revenue

CALL get_top_5('SUM(CAST(total_price AS DECIMAL(10, 2)))', 'revenue');


-- Q-8. Worse 5 Pizzas By Revenue

CALL get_bottom_5('SUM(CAST(total_price AS DECIMAL(10, 2)))', 'revenue');


-- Q-9. Best 5 Pizzas by Quantity

CALL get_top_5('SUM(quantity)', 'quantity');


-- Q-10. Worse 5 Pizzas by Quantity

CALL get_bottom_5('SUM(quantity)', 'quantity');


-- Q-11. Best 5 Pizzas by Orders

CALL get_top_5('COUNT(DISTINCT order_id)', 'orders');


-- Q-12. Worse 5 Pizzas by Orders

CALL get_bottom_5('COUNT(DISTINCT order_id)', 'orders');