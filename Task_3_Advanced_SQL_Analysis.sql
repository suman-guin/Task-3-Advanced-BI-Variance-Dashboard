/* ============================================================
   DATA ANALYTICS & BUSINESS INTELLIGENCE - TASK 3
   Advanced SQL Analysis, KPI Modeling & Variance Analysis
   Database: task2_bi
   SQL dialect: MySQL 8.0+
   ============================================================ */

USE task2_bi;


/* ============================================================
   1. DATA QUALITY AND BASE KPI CHECKS
   ============================================================ */

SELECT
    COUNT(*) AS Total_Order_Lines,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage
FROM orders;


/* ============================================================
   2. MONTHLY PERFORMANCE ANALYSIS
   ============================================================ */

SELECT
    YEAR(Order_Date) AS Sales_Year,
    MONTH(Order_Date) AS Sales_Month_Number,
    MONTHNAME(Order_Date) AS Sales_Month,
    ROUND(SUM(Sales), 2) AS Monthly_Sales,
    ROUND(SUM(Profit), 2) AS Monthly_Profit,
    COUNT(DISTINCT Customer_ID) AS Active_Customers
FROM orders
GROUP BY
    YEAR(Order_Date),
    MONTH(Order_Date),
    MONTHNAME(Order_Date)
ORDER BY Sales_Year, Sales_Month_Number;


/* ============================================================
   3. MONTH-OVER-MONTH SALES GROWTH AND VARIANCE
      A derived-table subquery is used. LAG correctly compares
      January with December of the previous year.
   ============================================================ */

SELECT
    Sales_Year,
    Sales_Month_Number,
    Sales_Month,
    ROUND(Monthly_Sales, 2) AS Current_Month_Sales,
    ROUND(Previous_Month_Sales, 2) AS Previous_Month_Sales,
    ROUND(Monthly_Sales - Previous_Month_Sales, 2) AS Sales_Variance,
    ROUND(
        (Monthly_Sales - Previous_Month_Sales)
        / NULLIF(Previous_Month_Sales, 0) * 100,
        2
    ) AS Growth_Percentage
FROM (
    SELECT
        YEAR(Order_Date) AS Sales_Year,
        MONTH(Order_Date) AS Sales_Month_Number,
        MONTHNAME(Order_Date) AS Sales_Month,
        SUM(Sales) AS Monthly_Sales,
        LAG(SUM(Sales)) OVER (
            ORDER BY YEAR(Order_Date), MONTH(Order_Date)
        ) AS Previous_Month_Sales
    FROM orders
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date),
        MONTHNAME(Order_Date)
) AS Monthly_Performance
ORDER BY Sales_Year, Sales_Month_Number;


/* ============================================================
   4. ANNUAL SALES GROWTH
   ============================================================ */

SELECT
    Sales_Year,
    ROUND(Annual_Sales, 2) AS Current_Year_Sales,
    ROUND(Previous_Year_Sales, 2) AS Previous_Year_Sales,
    ROUND(Annual_Sales - Previous_Year_Sales, 2) AS Sales_Variance,
    ROUND(
        (Annual_Sales - Previous_Year_Sales)
        / NULLIF(Previous_Year_Sales, 0) * 100,
        2
    ) AS Growth_Percentage
FROM (
    SELECT
        YEAR(Order_Date) AS Sales_Year,
        SUM(Sales) AS Annual_Sales,
        LAG(SUM(Sales)) OVER (ORDER BY YEAR(Order_Date))
            AS Previous_Year_Sales
    FROM orders
    GROUP BY YEAR(Order_Date)
) AS Annual_Performance
ORDER BY Sales_Year;


/* ============================================================
   5. CASE STATEMENT - ORDER VALUE CLASSIFICATION
   ============================================================ */

SELECT
    Order_ID,
    Order_Date,
    ROUND(Sales, 2) AS Sales,
    CASE
        WHEN Sales > 1000 THEN 'High Value'
        WHEN Sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Order_Type
FROM orders;


/* Summary of the CASE classifications */

SELECT
    Order_Type,
    COUNT(*) AS Total_Order_Lines,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM (
    SELECT
        Sales,
        Profit,
        CASE
            WHEN Sales > 1000 THEN 'High Value'
            WHEN Sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS Order_Type
    FROM orders
) AS Classified_Orders
GROUP BY Order_Type
ORDER BY Total_Sales DESC;


/* ============================================================
   6. UNDERPERFORMING REGIONS USING HAVING AND A SUBQUERY
      A region is flagged when its margin is below the overall
      company profit margin. Sort ascending to see the weakest.
   ============================================================ */

SELECT
    c.Region,
    ROUND(SUM(o.Sales), 2) AS Total_Sales,
    ROUND(SUM(o.Profit), 2) AS Total_Profit,
    ROUND(SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage
FROM orders o
INNER JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
HAVING SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) < (
    SELECT SUM(Profit) / NULLIF(SUM(Sales), 0)
    FROM orders
)
ORDER BY Profit_Margin_Percentage;


/* The single weakest region by profit margin */

SELECT
    c.Region,
    ROUND(SUM(o.Sales), 2) AS Total_Sales,
    ROUND(SUM(o.Profit), 2) AS Total_Profit,
    ROUND(SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage
FROM orders o
INNER JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Profit_Margin_Percentage
LIMIT 1;


/* ============================================================
   7. CATEGORY PERFORMANCE AND YEAR-OVER-YEAR GROWTH
   ============================================================ */

SELECT
    Product_Category,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2016 THEN Sales ELSE 0 END), 2)
        AS Sales_2016,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2017 THEN Sales ELSE 0 END), 2)
        AS Sales_2017,
    ROUND(
        SUM(CASE WHEN YEAR(Order_Date) = 2017 THEN Sales ELSE 0 END)
        - SUM(CASE WHEN YEAR(Order_Date) = 2016 THEN Sales ELSE 0 END),
        2
    ) AS Sales_Variance,
    ROUND(
        (
            SUM(CASE WHEN YEAR(Order_Date) = 2017 THEN Sales ELSE 0 END)
            - SUM(CASE WHEN YEAR(Order_Date) = 2016 THEN Sales ELSE 0 END)
        ) / NULLIF(
            SUM(CASE WHEN YEAR(Order_Date) = 2016 THEN Sales ELSE 0 END),
            0
        ) * 100,
        2
    ) AS Growth_Percentage
FROM orders
GROUP BY Product_Category
ORDER BY Growth_Percentage DESC;


/* ============================================================
   8. DISCOUNT IMPACT ON PROFITABILITY
   ============================================================ */

SELECT
    ROUND(Discount * 100, 0) AS Discount_Percentage,
    COUNT(*) AS Total_Order_Lines,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage,
    CASE
        WHEN SUM(Profit) < 0 THEN 'Loss-Making'
        ELSE 'Profitable'
    END AS Profitability_Status
FROM orders
GROUP BY Discount
ORDER BY Discount;


/* ============================================================
   9. CUSTOMER SEGMENT REVENUE CONTRIBUTION
   ============================================================ */

SELECT
    c.Segment,
    COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
    ROUND(SUM(o.Sales), 2) AS Total_Sales,
    ROUND(SUM(o.Profit), 2) AS Total_Profit,
    ROUND(SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage,
    ROUND(
        SUM(o.Sales) / NULLIF((SELECT SUM(Sales) FROM orders), 0) * 100,
        2
    ) AS Revenue_Contribution_Percentage
FROM orders o
INNER JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Segment
ORDER BY Total_Sales DESC;


/* ============================================================
   10. TOP 10 CUSTOMERS BY REVENUE
   ============================================================ */

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Region,
    c.Segment,
    ROUND(SUM(o.Sales), 2) AS Total_Revenue,
    ROUND(SUM(o.Profit), 2) AS Total_Profit
FROM orders o
INNER JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Region,
    c.Segment
ORDER BY Total_Revenue DESC
LIMIT 10;


/* ============================================================
   11. REGION PERFORMANCE TABLE FOR THE EXECUTIVE DASHBOARD
   ============================================================ */

SELECT
    c.Region,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
    ROUND(SUM(o.Sales), 2) AS Total_Sales,
    ROUND(SUM(o.Profit), 2) AS Total_Profit,
    ROUND(SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) * 100, 2)
        AS Profit_Margin_Percentage,
    ROUND(
        SUM(o.Sales) / NULLIF((SELECT SUM(Sales) FROM orders), 0) * 100,
        2
    ) AS Sales_Contribution_Percentage
FROM orders o
INNER JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Total_Sales DESC;
