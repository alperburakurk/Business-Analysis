-- ============================================================
-- Business Analysis SQL Queries
-- Dataset: AdventureWorks (Microsoft SQL Server)
-- Author: Burak Urk
-- ============================================================


-- ============================================================
-- Q1. How has monthly revenue changed over time?
--     Shows trend analysis + window functions (LAG).
-- ============================================================

-- Q1a: Monthly revenue trend
WITH monthly_revenue AS (
    SELECT
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        d.CalendarYear,
        d.MonthNumberOfYear
),
bounds AS (
    SELECT
        MIN(MonthStart) AS MinMonth,
        MAX(MonthStart) AS MaxMonth
    FROM monthly_revenue
)
SELECT
    mr.MonthStart,
    ROUND(mr.Revenue, 2) AS Revenue
FROM monthly_revenue mr
CROSS JOIN bounds b
WHERE mr.MonthStart > b.MinMonth
  AND mr.MonthStart < b.MaxMonth
ORDER BY mr.MonthStart;


-- Q1b: Month-over-month (MoM) revenue growth rate
WITH monthly_revenue AS (
    SELECT
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        d.CalendarYear,
        d.MonthNumberOfYear
),
bounds AS (
    SELECT
        MIN(MonthStart) AS MinMonth,
        MAX(MonthStart) AS MaxMonth
    FROM monthly_revenue
),
trimmed AS (
    SELECT
        mr.MonthStart,
        mr.Revenue
    FROM monthly_revenue mr
    CROSS JOIN bounds b
    WHERE mr.MonthStart > b.MinMonth
      AND mr.MonthStart < b.MaxMonth
),
mom_calc AS (
    SELECT
        MonthStart,
        ROUND(Revenue, 2) AS Revenue,
        ROUND(
            (Revenue - LAG(Revenue) OVER (ORDER BY MonthStart))
            / NULLIF(LAG(Revenue) OVER (ORDER BY MonthStart), 0) * 100.0,
            2
        ) AS MoM_Growth_Pct
    FROM trimmed
)
SELECT *
FROM mom_calc
WHERE MoM_Growth_Pct IS NOT NULL
ORDER BY MonthStart;


-- ============================================================
-- Q2. What are the year-over-year (YoY) revenue growth rates?
--     Tests seasonality-adjusted growth — more meaningful than MoM alone.
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        d.CalendarYear,
        d.MonthNumberOfYear
),
bounds AS (
    SELECT
        MIN(MonthStart) AS MinMonth,
        MAX(MonthStart) AS MaxMonth
    FROM monthly_revenue
),
trimmed AS (
    SELECT
        mr.MonthStart,
        mr.Revenue
    FROM monthly_revenue mr
    CROSS JOIN bounds b
    WHERE mr.MonthStart > b.MinMonth
      AND mr.MonthStart < b.MaxMonth
),
yoy_base AS (
    SELECT
        MonthStart,
        Revenue,
        LAG(Revenue, 12) OVER (ORDER BY MonthStart) AS PrevYearRevenue
    FROM trimmed
)
SELECT
    MonthStart,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(PrevYearRevenue, 2) AS PrevYearRevenue,
    ROUND(
        (Revenue - PrevYearRevenue) / NULLIF(PrevYearRevenue, 0) * 100.0,
        2
    ) AS YoY_Growth_Pct
FROM yoy_base
WHERE PrevYearRevenue IS NOT NULL
ORDER BY MonthStart;


-- ============================================================
-- Q3. Which countries generate the most revenue?
--     Classic geographic performance + revenue contribution analysis.
-- ============================================================

WITH country_revenue AS (
    SELECT
        st.SalesTerritoryCountry AS Country,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimSalesTerritory st
        ON f.SalesTerritoryKey = st.SalesTerritoryKey
    GROUP BY
        st.SalesTerritoryCountry
)
SELECT
    Country,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(Revenue * 100.0 / SUM(Revenue) OVER (), 2) AS Revenue_Share_Pct,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS Revenue_Rank
FROM country_revenue
ORDER BY Revenue DESC;


-- ============================================================
-- Q4. Which product categories and subcategories drive the
--     highest revenue and gross profit?
--     Connects top-line sales to profitability.
-- ============================================================

-- Q4a: Category level
WITH category_perf AS (
    SELECT
        pc.EnglishProductCategoryName AS Category,
        SUM(f.SalesAmount) AS Revenue,
        SUM(f.TotalProductCost) AS TotalCost
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p
        ON f.ProductKey = p.ProductKey
    JOIN dbo.DimProductSubcategory ps
        ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN dbo.DimProductCategory pc
        ON ps.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY
        pc.EnglishProductCategoryName
)
SELECT
    Category,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(TotalCost, 2) AS TotalCost,
    ROUND(Revenue - TotalCost, 2) AS GrossProfit,
    ROUND((Revenue - TotalCost) * 100.0 / NULLIF(Revenue, 0), 2) AS GrossMargin_Pct,
    ROUND(Revenue * 100.0 / SUM(Revenue) OVER (), 2) AS Revenue_Share_Pct,
    ROUND((Revenue - TotalCost) * 100.0 / NULLIF(SUM(Revenue - TotalCost) OVER (), 0), 2) AS GrossProfit_Share_Pct
FROM category_perf
ORDER BY GrossProfit DESC;


-- Q4b: Subcategory level
WITH subcategory_perf AS (
    SELECT
        pc.EnglishProductCategoryName AS Category,
        ps.EnglishProductSubcategoryName AS Subcategory,
        SUM(f.SalesAmount) AS Revenue,
        SUM(f.TotalProductCost) AS TotalCost
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p
        ON f.ProductKey = p.ProductKey
    JOIN dbo.DimProductSubcategory ps
        ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN dbo.DimProductCategory pc
        ON ps.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY
        pc.EnglishProductCategoryName,
        ps.EnglishProductSubcategoryName
)
SELECT
    Category,
    Subcategory,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(TotalCost, 2) AS TotalCost,
    ROUND(Revenue - TotalCost, 2) AS GrossProfit,
    ROUND((Revenue - TotalCost) * 100.0 / NULLIF(Revenue, 0), 2) AS GrossMargin_Pct,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS Revenue_Rank,
    DENSE_RANK() OVER (ORDER BY (Revenue - TotalCost) DESC) AS GrossProfit_Rank
FROM subcategory_perf
ORDER BY GrossProfit DESC;


-- ============================================================
-- Q5. What are the top 10 products by revenue, and how
--     concentrated is revenue across those products?
--     Helps identify concentration risk and revenue dependency.
-- ============================================================

-- Q5a: Top 10 products ranked by revenue
WITH product_revenue AS (
    SELECT
        p.EnglishProductName AS ProductName,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p
        ON f.ProductKey = p.ProductKey
    GROUP BY
        p.EnglishProductName
),
ranked AS (
    SELECT
        ProductName,
        Revenue,
        ROW_NUMBER() OVER (ORDER BY Revenue DESC, ProductName) AS Revenue_Rank,
        SUM(Revenue) OVER () AS TotalRevenue
    FROM product_revenue
)
SELECT
    Revenue_Rank,
    ProductName,
    CAST(Revenue AS DECIMAL(18,2)) AS Revenue,
    CAST(Revenue * 100.0 / TotalRevenue AS DECIMAL(10,2)) AS Revenue_Share_Pct,
    CAST(
        SUM(Revenue) OVER (
            ORDER BY Revenue_Rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / TotalRevenue
    AS DECIMAL(10,2)) AS Cumulative_Share_Pct
FROM ranked
WHERE Revenue_Rank <= 10
ORDER BY Revenue_Rank;


-- Q5b: Revenue concentration summary (Top 1 / 3 / 5 / 10)
WITH product_revenue AS (
    SELECT
        p.EnglishProductName AS ProductName,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p
        ON f.ProductKey = p.ProductKey
    GROUP BY
        p.EnglishProductName
),
ranked AS (
    SELECT
        ProductName,
        Revenue,
        ROW_NUMBER() OVER (ORDER BY Revenue DESC, ProductName) AS Revenue_Rank
    FROM product_revenue
),
tot AS (
    SELECT
        SUM(Revenue) AS TotalRevenue,
        COUNT(*) AS TotalProducts
    FROM product_revenue
)
SELECT
    MAX(t.TotalProducts) AS TotalProducts,
    CAST(SUM(CASE WHEN r.Revenue_Rank <= 1  THEN r.Revenue ELSE 0 END) * 100.0 / MAX(t.TotalRevenue) AS DECIMAL(10,2)) AS Top1_Share_Pct,
    CAST(SUM(CASE WHEN r.Revenue_Rank <= 3  THEN r.Revenue ELSE 0 END) * 100.0 / MAX(t.TotalRevenue) AS DECIMAL(10,2)) AS Top3_Share_Pct,
    CAST(SUM(CASE WHEN r.Revenue_Rank <= 5  THEN r.Revenue ELSE 0 END) * 100.0 / MAX(t.TotalRevenue) AS DECIMAL(10,2)) AS Top5_Share_Pct,
    CAST(SUM(CASE WHEN r.Revenue_Rank <= 10 THEN r.Revenue ELSE 0 END) * 100.0 / MAX(t.TotalRevenue) AS DECIMAL(10,2)) AS Top10_Share_Pct
FROM ranked r
CROSS JOIN tot t;


-- ============================================================
-- Q6. Which products or categories are declining?
--     Compares recent 3-month avg revenue vs prior 3-month avg.
--     Good for early warning signals and action recommendations.
-- ============================================================

-- Q6a: Category-level trend
WITH analysis_month AS (
    SELECT DATEADD(month, -1, MAX(DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1))) AS AnalysisMonth
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
),
month_window AS (
    SELECT
        DATEADD(month, -v.n, a.AnalysisMonth) AS MonthStart,
        CASE WHEN v.n BETWEEN 0 AND 2 THEN 'Recent3' ELSE 'Prior3' END AS Period
    FROM analysis_month a
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5)) v(n)
),
categories AS (
    SELECT DISTINCT pc.EnglishProductCategoryName AS Category
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
    JOIN dbo.DimProductSubcategory ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN dbo.DimProductCategory pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
),
monthly_category AS (
    SELECT
        pc.EnglishProductCategoryName AS Category,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
    JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
    JOIN dbo.DimProductSubcategory ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN dbo.DimProductCategory pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY
        pc.EnglishProductCategoryName,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1)
),
category_window AS (
    SELECT
        c.Category,
        mw.MonthStart,
        mw.Period,
        COALESCE(mc.Revenue, 0) AS Revenue
    FROM categories c
    CROSS JOIN month_window mw
    LEFT JOIN monthly_category mc
        ON mc.Category = c.Category
        AND mc.MonthStart = mw.MonthStart
)
SELECT
    Category,
    CAST(AVG(CASE WHEN Period = 'Prior3'  THEN Revenue END) AS DECIMAL(18,2)) AS Prior3_AvgMonthlyRevenue,
    CAST(AVG(CASE WHEN Period = 'Recent3' THEN Revenue END) AS DECIMAL(18,2)) AS Recent3_AvgMonthlyRevenue,
    CAST(
        AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
        - AVG(CASE WHEN Period = 'Prior3'  THEN Revenue END)
    AS DECIMAL(18,2)) AS Revenue_Change_Amount,
    CAST(
        (AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
         - AVG(CASE WHEN Period = 'Prior3' THEN Revenue END)) * 100.0
        / NULLIF(AVG(CASE WHEN Period = 'Prior3' THEN Revenue END), 0)
    AS DECIMAL(10,2)) AS Revenue_Change_Pct,
    CASE
        WHEN AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
             < AVG(CASE WHEN Period = 'Prior3' THEN Revenue END)
        THEN 'Declining'
        ELSE 'Growing_or_Stable'
    END AS Trend_Status
FROM category_window
GROUP BY Category
ORDER BY Revenue_Change_Pct ASC;


-- Q6b: Product-level declines (top 100 products by lifetime revenue)
WITH analysis_month AS (
    SELECT DATEADD(month, -1, MAX(DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1))) AS AnalysisMonth
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
),
month_window AS (
    SELECT
        DATEADD(month, -v.n, a.AnalysisMonth) AS MonthStart,
        CASE WHEN v.n BETWEEN 0 AND 2 THEN 'Recent3' ELSE 'Prior3' END AS Period
    FROM analysis_month a
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5)) v(n)
),
product_pool AS (
    SELECT TOP (100)
        p.EnglishProductName AS ProductName,
        SUM(f.SalesAmount) AS LifetimeRevenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
    GROUP BY p.EnglishProductName
    ORDER BY SUM(f.SalesAmount) DESC
),
monthly_product AS (
    SELECT
        p.EnglishProductName AS ProductName,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
    JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
    GROUP BY
        p.EnglishProductName,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1)
),
product_window AS (
    SELECT
        pp.ProductName,
        pp.LifetimeRevenue,
        mw.MonthStart,
        mw.Period,
        COALESCE(mp.Revenue, 0) AS Revenue
    FROM product_pool pp
    CROSS JOIN month_window mw
    LEFT JOIN monthly_product mp
        ON mp.ProductName = pp.ProductName
        AND mp.MonthStart = mw.MonthStart
)
SELECT TOP (25)
    ProductName,
    CAST(LifetimeRevenue AS DECIMAL(18,2)) AS LifetimeRevenue,
    CAST(AVG(CASE WHEN Period = 'Prior3'  THEN Revenue END) AS DECIMAL(18,2)) AS Prior3_AvgMonthlyRevenue,
    CAST(AVG(CASE WHEN Period = 'Recent3' THEN Revenue END) AS DECIMAL(18,2)) AS Recent3_AvgMonthlyRevenue,
    CAST(
        AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
        - AVG(CASE WHEN Period = 'Prior3'  THEN Revenue END)
    AS DECIMAL(18,2)) AS Revenue_Change_Amount,
    CAST(
        (AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
         - AVG(CASE WHEN Period = 'Prior3' THEN Revenue END)) * 100.0
        / NULLIF(AVG(CASE WHEN Period = 'Prior3' THEN Revenue END), 0)
    AS DECIMAL(10,2)) AS Revenue_Change_Pct
FROM product_window
GROUP BY ProductName, LifetimeRevenue
HAVING
    AVG(CASE WHEN Period = 'Recent3' THEN Revenue END)
    < AVG(CASE WHEN Period = 'Prior3' THEN Revenue END)
    AND AVG(CASE WHEN Period = 'Prior3' THEN Revenue END) >= 10000
ORDER BY Revenue_Change_Pct ASC, Revenue_Change_Amount ASC;


-- ============================================================
-- Q7. How many new vs returning customers do we have each month?
--     Core customer health metric — great for retention story.
-- ============================================================

WITH customer_monthly AS (
    SELECT
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1)
),
first_purchase AS (
    SELECT
        CustomerKey,
        MIN(MonthStart) AS FirstPurchaseMonth
    FROM customer_monthly
    GROUP BY CustomerKey
)
SELECT
    cm.MonthStart,
    COUNT(DISTINCT CASE WHEN cm.MonthStart = fp.FirstPurchaseMonth THEN cm.CustomerKey END) AS New_Customers,
    COUNT(DISTINCT CASE WHEN cm.MonthStart > fp.FirstPurchaseMonth  THEN cm.CustomerKey END) AS Returning_Customers,
    COUNT(DISTINCT cm.CustomerKey) AS Active_Customers,
    CAST(
        COUNT(DISTINCT CASE WHEN cm.MonthStart > fp.FirstPurchaseMonth THEN cm.CustomerKey END) * 100.0
        / NULLIF(COUNT(DISTINCT cm.CustomerKey), 0)
    AS DECIMAL(10,2)) AS Returning_Share_Pct
FROM customer_monthly cm
JOIN first_purchase fp
    ON cm.CustomerKey = fp.CustomerKey
GROUP BY cm.MonthStart
ORDER BY cm.MonthStart;


-- ============================================================
-- Q8. What is the customer retention rate at M1, M3, and M6?
--     Advanced cohort analysis — impressive for analyst portfolios.
-- ============================================================

-- Q8a: M1 / M3 / M6 retention by cohort
WITH customer_monthly AS (
    SELECT
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1)
),
cohorts AS (
    SELECT
        CustomerKey,
        MIN(MonthStart) AS CohortMonth
    FROM customer_monthly
    GROUP BY CustomerKey
),
cohort_size AS (
    SELECT
        CohortMonth,
        COUNT(*) AS CohortCustomers
    FROM cohorts
    GROUP BY CohortMonth
),
retention_flags AS (
    SELECT
        c.CohortMonth,
        c.CustomerKey,
        MAX(CASE WHEN cm.MonthStart = DATEADD(month, 1, c.CohortMonth) THEN 1 ELSE 0 END) AS Retained_M1,
        MAX(CASE WHEN cm.MonthStart = DATEADD(month, 3, c.CohortMonth) THEN 1 ELSE 0 END) AS Retained_M3,
        MAX(CASE WHEN cm.MonthStart = DATEADD(month, 6, c.CohortMonth) THEN 1 ELSE 0 END) AS Retained_M6
    FROM cohorts c
    LEFT JOIN customer_monthly cm
        ON cm.CustomerKey = c.CustomerKey
    GROUP BY c.CohortMonth, c.CustomerKey
)
SELECT
    rf.CohortMonth,
    cs.CohortCustomers,
    SUM(rf.Retained_M1) AS Retained_Customers_M1,
    CAST(SUM(rf.Retained_M1) * 100.0 / NULLIF(cs.CohortCustomers, 0) AS DECIMAL(10,2)) AS Retention_M1_Pct,
    SUM(rf.Retained_M3) AS Retained_Customers_M3,
    CAST(SUM(rf.Retained_M3) * 100.0 / NULLIF(cs.CohortCustomers, 0) AS DECIMAL(10,2)) AS Retention_M3_Pct,
    SUM(rf.Retained_M6) AS Retained_Customers_M6,
    CAST(SUM(rf.Retained_M6) * 100.0 / NULLIF(cs.CohortCustomers, 0) AS DECIMAL(10,2)) AS Retention_M6_Pct
FROM retention_flags rf
JOIN cohort_size cs
    ON rf.CohortMonth = cs.CohortMonth
GROUP BY rf.CohortMonth, cs.CohortCustomers
ORDER BY rf.CohortMonth;


-- Q8b: Full cohort heatmap (month 0 through month 12)
WITH customer_monthly AS (
    SELECT
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1) AS MonthStart
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY
        f.CustomerKey,
        DATEFROMPARTS(d.CalendarYear, d.MonthNumberOfYear, 1)
),
cohorts AS (
    SELECT
        CustomerKey,
        MIN(MonthStart) AS CohortMonth
    FROM customer_monthly
    GROUP BY CustomerKey
),
cohort_size AS (
    SELECT
        CohortMonth,
        COUNT(*) AS CohortCustomers
    FROM cohorts
    GROUP BY CohortMonth
),
retention_by_offset AS (
    SELECT
        c.CohortMonth,
        DATEDIFF(month, c.CohortMonth, cm.MonthStart) AS MonthOffset,
        COUNT(DISTINCT c.CustomerKey) AS RetainedCustomers
    FROM cohorts c
    JOIN customer_monthly cm
        ON cm.CustomerKey = c.CustomerKey
    WHERE DATEDIFF(month, c.CohortMonth, cm.MonthStart) BETWEEN 0 AND 12
    GROUP BY
        c.CohortMonth,
        DATEDIFF(month, c.CohortMonth, cm.MonthStart)
)
SELECT
    r.CohortMonth,
    r.MonthOffset,
    cs.CohortCustomers,
    r.RetainedCustomers,
    CAST(r.RetainedCustomers * 100.0 / NULLIF(cs.CohortCustomers, 0) AS DECIMAL(10,2)) AS Retention_Pct
FROM retention_by_offset r
JOIN cohort_size cs
    ON r.CohortMonth = cs.CohortMonth
ORDER BY r.CohortMonth, r.MonthOffset;


-- ============================================================
-- Q9. How do Average Order Value (AOV) and purchase frequency
--     differ by region and customer segment?
--     Strong business segmentation insight.
-- ============================================================

-- Q9a: By region only
WITH customer_orders AS (
    SELECT
        c.CustomerKey,
        COALESCE(g.EnglishCountryRegionName, 'Unknown') AS Region,
        COUNT(DISTINCT f.SalesOrderNumber) AS OrdersCount,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimCustomer c
        ON f.CustomerKey = c.CustomerKey
    LEFT JOIN dbo.DimGeography g
        ON c.GeographyKey = g.GeographyKey
    GROUP BY
        c.CustomerKey,
        COALESCE(g.EnglishCountryRegionName, 'Unknown')
)
SELECT
    Region,
    COUNT(*) AS Customers,
    SUM(OrdersCount) AS TotalOrders,
    CAST(SUM(Revenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(Revenue) / NULLIF(SUM(OrdersCount), 0) AS DECIMAL(18,2)) AS AOV,
    CAST(SUM(OrdersCount) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS Avg_Orders_Per_Customer,
    CAST(SUM(Revenue) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(18,2)) AS Avg_Revenue_Per_Customer
FROM customer_orders
GROUP BY Region
ORDER BY TotalRevenue DESC;


-- Q9b: By region and customer segment (occupation)
WITH customer_orders AS (
    SELECT
        c.CustomerKey,
        COALESCE(g.EnglishCountryRegionName, 'Unknown') AS Region,
        COALESCE(c.EnglishOccupation, 'Unknown') AS CustomerSegment,
        COUNT(DISTINCT f.SalesOrderNumber) AS OrdersCount,
        SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimCustomer c
        ON f.CustomerKey = c.CustomerKey
    LEFT JOIN dbo.DimGeography g
        ON c.GeographyKey = g.GeographyKey
    GROUP BY
        c.CustomerKey,
        COALESCE(g.EnglishCountryRegionName, 'Unknown'),
        COALESCE(c.EnglishOccupation, 'Unknown')
)
SELECT
    Region,
    CustomerSegment,
    COUNT(*) AS Customers,
    SUM(OrdersCount) AS TotalOrders,
    CAST(SUM(Revenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(Revenue) / NULLIF(SUM(OrdersCount), 0) AS DECIMAL(18,2)) AS AOV,
    CAST(SUM(OrdersCount) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS Avg_Orders_Per_Customer,
    CAST(SUM(Revenue) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(18,2)) AS Avg_Revenue_Per_Customer
FROM customer_orders
GROUP BY Region, CustomerSegment
ORDER BY Region, TotalRevenue DESC;


-- ============================================================
-- Q10. Which products have high volume but weak gross margin?
--      Identifies hidden margin risk inside high-revenue SKUs.
--      Uses NTILE() to flag volume/margin quadrants.
-- ============================================================

WITH product_economics AS (
    SELECT
        p.ProductKey,
        p.EnglishProductName AS ProductName,
        COUNT(DISTINCT f.SalesOrderNumber) AS Orders,
        SUM(f.OrderQuantity) AS Units,
        SUM(f.SalesAmount) AS Revenue,
        SUM(f.TotalProductCost) AS TotalCost,
        SUM(f.SalesAmount - f.TotalProductCost) AS GrossProfit
    FROM dbo.FactInternetSales f
    JOIN dbo.DimProduct p
        ON f.ProductKey = p.ProductKey
    GROUP BY
        p.ProductKey,
        p.EnglishProductName
),
scored AS (
    SELECT
        ProductKey,
        ProductName,
        Orders,
        Units,
        CAST(Revenue AS DECIMAL(18,2)) AS Revenue,
        CAST(TotalCost AS DECIMAL(18,2)) AS TotalCost,
        CAST(GrossProfit AS DECIMAL(18,2)) AS GrossProfit,
        CAST(GrossProfit * 100.0 / NULLIF(Revenue, 0) AS DECIMAL(10,2)) AS GrossMargin_Pct,
        NTILE(4) OVER (ORDER BY Revenue DESC) AS Revenue_Quartile,
        NTILE(4) OVER (ORDER BY GrossProfit * 1.0 / NULLIF(Revenue, 0)) AS Margin_Quartile
    FROM product_economics
    WHERE Revenue > 0
)
SELECT
    ProductKey,
    ProductName,
    Orders,
    Units,
    Revenue,
    TotalCost,
    GrossProfit,
    GrossMargin_Pct,
    Revenue_Quartile,
    Margin_Quartile,
    CASE
        WHEN Revenue_Quartile = 1 AND Margin_Quartile = 1 THEN 'High volume, low margin'
        WHEN Revenue_Quartile = 1                          THEN 'High volume'
        WHEN Margin_Quartile = 1                           THEN 'Low margin'
        ELSE 'Other'
    END AS Volume_Margin_Flag
FROM scored
ORDER BY Revenue DESC;
