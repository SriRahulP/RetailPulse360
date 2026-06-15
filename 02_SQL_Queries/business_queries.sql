--Query 1 — Total Revenue by City
SELECT
    s.city,
    ROUND(SUM(fs.revenue)::numeric, 2)        AS total_revenue,
    SUM(fs.quantity)                           AS total_units_sold,
    COUNT(fs.sale_id)                          AS total_transactions
FROM retail.fact_sales fs
JOIN retail.dim_store s ON fs.store_key = s.store_key
GROUP BY s.city
ORDER BY total_revenue DESC;


--Query 2 — Monthly Revenue Trend (2022–2024)
SELECT
    d.year,
    d.month_num,
    d.month_name,
    ROUND(SUM(fs.revenue)::numeric, 2)   AS monthly_revenue,
    COUNT(fs.sale_id)                     AS transactions
FROM retail.fact_sales fs
JOIN retail.dim_date d ON fs.date_key = d.date_key
GROUP BY d.year, d.month_num, d.month_name
ORDER BY d.year, d.month_num;

--Query 3 — Top 10 Best Selling Products
SELECT
    p.product_name,
    p.category,
    p.brand,
    SUM(fs.quantity)                          AS total_units_sold,
    ROUND(SUM(fs.revenue)::numeric, 2)        AS total_revenue,
    ROUND(AVG(fs.discount_pct)::numeric, 2)   AS avg_discount_pct
FROM retail.fact_sales fs
JOIN retail.dim_product p ON fs.product_key = p.product_key
GROUP BY p.product_name, p.category, p.brand
ORDER BY total_revenue DESC
LIMIT 10;

--Query 4 — Store Performance vs Average
-- Business question: Which stores are above average and which are underperforming?
SELECT
    st.store_name,
    st.city,
    st.manager_name,
    ROUND(SUM(fs.revenue)::numeric, 2)        AS store_revenue,
    ROUND(AVG(SUM(fs.revenue)) OVER ()::numeric, 2) AS avg_all_stores,
    ROUND((SUM(fs.revenue) - AVG(SUM(fs.revenue)) OVER ())::numeric, 2) AS vs_average
FROM retail.fact_sales fs
JOIN retail.dim_store st ON fs.store_key = st.store_key
GROUP BY st.store_name, st.city, st.manager_name
ORDER BY store_revenue DESC;

--Query 5 — Festival vs Non-Festival Revenue
SELECT
    CASE WHEN d.is_festival = true THEN 'Festival Day'
         ELSE 'Normal Day' END            AS day_type,
    COUNT(DISTINCT d.date_key)            AS number_of_days,
    ROUND(SUM(fs.revenue)::numeric, 2)    AS total_revenue,
    ROUND(AVG(fs.revenue)::numeric, 2)    AS avg_revenue_per_transaction,
    COUNT(fs.sale_id)                     AS total_transactions
FROM retail.fact_sales fs
JOIN retail.dim_date d ON fs.date_key = d.date_key
GROUP BY day_type
ORDER BY total_revenue DESC;

--Query 6 — Revenue Ranking by Store Within Each City
--Business question: Within each city, how do stores rank against each other?
SELECT
    st.city,
    st.store_name,
    st.manager_name,
    ROUND(SUM(fs.revenue)::numeric, 2)    AS store_revenue,
    RANK() OVER (
        PARTITION BY st.city
        ORDER BY SUM(fs.revenue) DESC
    )                                      AS rank_in_city
FROM retail.fact_sales fs
JOIN retail.dim_store st ON fs.store_key = st.store_key
GROUP BY st.city, st.store_name, st.manager_name
ORDER BY st.city, rank_in_city;

--Query 7 — Customer Loyalty Tier Revenue Analysis
--Business question: Which loyalty tier generates the most revenue? Are Platinum customers really worth the investment?
SELECT
    c.loyalty_tier,
    COUNT(DISTINCT fs.customer_key)            AS unique_customers,
    COUNT(fs.sale_id)                          AS total_transactions,
    ROUND(SUM(fs.revenue)::numeric, 2)         AS total_revenue,
    ROUND(AVG(fs.revenue)::numeric, 2)         AS avg_transaction_value,
    ROUND(SUM(fs.revenue)::numeric / 
          COUNT(DISTINCT fs.customer_key), 2)  AS revenue_per_customer
FROM retail.fact_sales fs
JOIN retail.dim_customer c ON fs.customer_key = c.customer_key
GROUP BY c.loyalty_tier
ORDER BY revenue_per_customer DESC;

--Query 8 — Stockout Analysis by Store and Product
--Business question: Where are we running out of stock most often?
SELECT
    st.store_name,
    st.city,
    p.product_name,
    p.category,
    COUNT(*) FILTER (WHERE fi.is_stockout = true)   AS stockout_days,
    COUNT(*)                                          AS total_recorded_days,
    ROUND(
        COUNT(*) FILTER (WHERE fi.is_stockout = true)
        * 100.0 / COUNT(*), 2
    )                                                 AS stockout_rate_pct
FROM retail.fact_inventory fi
JOIN retail.dim_store st  ON fi.store_key   = st.store_key
JOIN retail.dim_product p ON fi.product_key = p.product_key
GROUP BY st.store_name, st.city, p.product_name, p.category
HAVING COUNT(*) FILTER (WHERE fi.is_stockout = true) > 0
ORDER BY stockout_rate_pct DESC
LIMIT 20;

--Query 9 — Supplier Reliability Scorecard
--Business question: Which suppliers are consistently late?
SELECT
    sup.supplier_name,
    sup.city                                           AS supplier_city,
    COUNT(po.po_id)                                    AS total_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'Delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'Delayed')   AS delayed_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'In Transit') AS in_transit,
    ROUND(
        COUNT(*) FILTER (WHERE po.po_status = 'Delivered')
        * 100.0 / NULLIF(COUNT(po.po_id), 0), 2
    )                                                  AS on_time_delivery_pct,
    ROUND(AVG(
        CASE WHEN po.actual_delivery_date IS NOT NULL
        THEN po.actual_delivery_date - po.expected_date
        END
    )::numeric, 1)                                     AS avg_delay_days
FROM retail.fact_purchase_orders po
JOIN retail.dim_supplier sup ON po.supplier_key = sup.supplier_key
GROUP BY sup.supplier_name, sup.city
ORDER BY on_time_delivery_pct ASC;SELECT
    sup.supplier_name,
    sup.city                                           AS supplier_city,
    COUNT(po.po_id)                                    AS total_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'Delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'Delayed')   AS delayed_orders,
    COUNT(*) FILTER (WHERE po.po_status = 'In Transit') AS in_transit,
    ROUND(
        COUNT(*) FILTER (WHERE po.po_status = 'Delivered')
        * 100.0 / NULLIF(COUNT(po.po_id), 0), 2
    )                                                  AS on_time_delivery_pct,
    ROUND(AVG(
        CASE WHEN po.actual_delivery_date IS NOT NULL
        THEN po.actual_delivery_date - po.expected_date
        END
    )::numeric, 1)                                     AS avg_delay_days
FROM retail.fact_purchase_orders po
JOIN retail.dim_supplier sup ON po.supplier_key = sup.supplier_key
GROUP BY sup.supplier_name, sup.city
ORDER BY on_time_delivery_pct ASC;

--Query 10 — Running Revenue Total (YTD) Using CTE
--Business question: What is our cumulative revenue at any point in the year?
WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month_num,
        d.month_name,
        ROUND(SUM(fs.revenue)::numeric, 2) AS monthly_revenue
    FROM retail.fact_sales fs
    JOIN retail.dim_date d ON fs.date_key = d.date_key
    GROUP BY d.year, d.month_num, d.month_name
)
SELECT
    year,
    month_name,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        PARTITION BY year
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS ytd_revenue
FROM monthly_revenue
ORDER BY year, month_num;

--Query 11 — Gross Margin by Product Category
--Business question: Which categories are actually profitable after costs?
SELECT
    p.category,
    ROUND(SUM(fs.revenue)::numeric, 2)       AS total_revenue,
    ROUND(SUM(fs.cost)::numeric, 2)          AS total_cost,
    ROUND(SUM(fs.gross_profit)::numeric, 2)  AS total_gross_profit,
    ROUND(
        SUM(fs.gross_profit) * 100.0
        / NULLIF(SUM(fs.revenue), 0), 2
    )                                         AS gross_margin_pct
FROM retail.fact_sales fs
JOIN retail.dim_product p ON fs.product_key = p.product_key
GROUP BY p.category
ORDER BY gross_margin_pct DESC;

--Query 12 — Create a Business View for Power BI
--This is the final and most important step of Phase 5. 
--We create a SQL View — a saved query that Power BI can connect
--to directly like a table.

CREATE OR REPLACE VIEW retail.vw_sales_summary AS
SELECT
    fs.sale_id,
    d.full_date,
    d.year,
    d.month_num,
    d.month_name,
    d.quarter,
    d.is_festival,
    d.festival_name,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.gst_slab,
    st.store_name,
    st.city,
    st.zone,
    st.manager_name,
    st.store_size_sqft,
    r.tier_level,
    c.loyalty_tier,
    c.acquisition_channel,
    fs.quantity,
    fs.unit_price,
    fs.discount_pct,
    fs.revenue,
    fs.cost,
    fs.gross_profit
FROM retail.fact_sales fs
JOIN retail.dim_date     d  ON fs.date_key     = d.date_key
JOIN retail.dim_product  p  ON fs.product_key  = p.product_key
JOIN retail.dim_store    st ON fs.store_key    = st.store_key
JOIN retail.dim_customer c  ON fs.customer_key = c.customer_key
JOIN retail.dim_region   r  ON st.region_key   = r.region_key;

SELECT * FROM retail.vw_sales_summary LIMIT 5;

