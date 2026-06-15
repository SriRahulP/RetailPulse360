

-- ══════════════════════════════════════════
-- RETAILPULSE 360 — TABLE CREATION SCRIPT
-- Schema: retail
-- ══════════════════════════════════════════


-- ─────────────────────────────
-- DIMENSION TABLE 1: dim_date
-- ─────────────────────────────
CREATE TABLE retail.dim_date (
    date_key        INT PRIMARY KEY,
    full_date       DATE NOT NULL,
    day_of_week     VARCHAR(10),
    day_num         INT,
    month_num       INT,
    month_name      VARCHAR(15),
    quarter         INT,
    year            INT,
    is_weekend      BOOLEAN,
    is_festival     BOOLEAN,
    festival_name   VARCHAR(50)
);


-- ─────────────────────────────
-- DIMENSION TABLE 2: dim_region
-- ─────────────────────────────
CREATE TABLE retail.dim_region (
    region_key      SERIAL PRIMARY KEY,
    region_name     VARCHAR(50) NOT NULL,
    city            VARCHAR(50) NOT NULL,
    state           VARCHAR(50),
    tier_level      VARCHAR(10)
);


-- ─────────────────────────────
-- DIMENSION TABLE 3: dim_store
-- ─────────────────────────────
CREATE TABLE retail.dim_store (
    store_key       SERIAL PRIMARY KEY,
    store_name      VARCHAR(100) NOT NULL,
    store_code      VARCHAR(20) UNIQUE,
    city            VARCHAR(50),
    zone            VARCHAR(50),
    manager_name    VARCHAR(100),
    opening_date    DATE,
    store_size_sqft INT,
    region_key      INT REFERENCES retail.dim_region(region_key)
);


-- ─────────────────────────────
-- DIMENSION TABLE 4: dim_product
-- ─────────────────────────────
CREATE TABLE retail.dim_product (
    product_key     SERIAL PRIMARY KEY,
    product_code    VARCHAR(30) UNIQUE,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(80),
    subcategory     VARCHAR(80),
    brand           VARCHAR(80),
    mrp             NUMERIC(10,2),
    gst_slab        NUMERIC(5,2),
    unit_of_measure VARCHAR(20)
);


-- ─────────────────────────────
-- DIMENSION TABLE 5: dim_customer
-- ─────────────────────────────
CREATE TABLE retail.dim_customer (
    customer_key        SERIAL PRIMARY KEY,
    customer_code       VARCHAR(30) UNIQUE,
    customer_name       VARCHAR(100),
    gender              VARCHAR(10),
    city                VARCHAR(50),
    loyalty_tier        VARCHAR(20),
    acquisition_channel VARCHAR(50),
    registration_date   DATE
);


-- ─────────────────────────────
-- DIMENSION TABLE 6: dim_supplier
-- ─────────────────────────────
CREATE TABLE retail.dim_supplier (
    supplier_key        SERIAL PRIMARY KEY,
    supplier_code       VARCHAR(30) UNIQUE,
    supplier_name       VARCHAR(100) NOT NULL,
    contact_person      VARCHAR(100),
    city                VARCHAR(50),
    avg_lead_time_days  INT,
    reliability_score   NUMERIC(3,1),
    payment_terms_days  INT
);


-- ─────────────────────────────
-- FACT TABLE 1: fact_sales
-- ─────────────────────────────
CREATE TABLE retail.fact_sales (
    sale_id         BIGSERIAL PRIMARY KEY,
    date_key        INT REFERENCES retail.dim_date(date_key),
    product_key     INT REFERENCES retail.dim_product(product_key),
    store_key       INT REFERENCES retail.dim_store(store_key),
    customer_key    INT REFERENCES retail.dim_customer(customer_key),
    quantity        INT NOT NULL,
    unit_price      NUMERIC(10,2),
    discount_pct    NUMERIC(5,2),
    revenue         NUMERIC(12,2),
    cost            NUMERIC(12,2),
    gross_profit    NUMERIC(12,2)
);


-- ─────────────────────────────
-- FACT TABLE 2: fact_inventory
-- ─────────────────────────────
CREATE TABLE retail.fact_inventory (
    inventory_id    BIGSERIAL PRIMARY KEY,
    date_key        INT REFERENCES retail.dim_date(date_key),
    product_key     INT REFERENCES retail.dim_product(product_key),
    store_key       INT REFERENCES retail.dim_store(store_key),
    units_on_hand   INT,
    units_received  INT,
    units_sold      INT,
    reorder_point   INT,
    is_stockout     BOOLEAN
);


-- ─────────────────────────────
-- FACT TABLE 3: fact_purchase_orders
-- ─────────────────────────────
CREATE TABLE retail.fact_purchase_orders (
    po_id               BIGSERIAL PRIMARY KEY,
    date_key            INT REFERENCES retail.dim_date(date_key),
    product_key         INT REFERENCES retail.dim_product(product_key),
    supplier_key        INT REFERENCES retail.dim_supplier(supplier_key),
    store_key           INT REFERENCES retail.dim_store(store_key),
    qty_ordered         INT,
    qty_received        INT,
    ordered_date        DATE,
    expected_date       DATE,
    actual_delivery_date DATE,
    unit_cost           NUMERIC(10,2),
    total_cost          NUMERIC(12,2),
    po_status           VARCHAR(20)
);

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'retail'
ORDER BY table_name;