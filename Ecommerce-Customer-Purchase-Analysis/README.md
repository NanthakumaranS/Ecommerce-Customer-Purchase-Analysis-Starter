# E-Commerce Customer Purchase Analysis

## Project objective
Analyse a synthetic e-commerce dataset to understand revenue, customer purchase behaviour, product/category performance and payment patterns.

## Tools
- MySQL: relational database and business queries
- Python (Pandas, NumPy, Matplotlib): data quality checks, cleaning and exploratory analysis
- Power BI: interactive business dashboard

## Dataset
The `dataset/` folder contains five synthetic CSV files:
- customers.csv (500 customers)
- products.csv (50 products)
- orders.csv (2,000 orders)
- order_items.csv (line-level items)
- payments.csv (2,000 payments)

All names and transactions are fictional. Do not present this as real company data.

## Project workflow
1. Inspect CSVs and run `python/analysis.py`.
2. In MySQL Workbench, run `sql/01_create_database_tables.sql`.
3. Import the five CSVs into their matching tables using Table Data Import Wizard. Import parent tables first: customers, products, orders, then order_items and payments.
4. Run `sql/02_business_analysis_queries.sql`.
5. Connect Power BI Desktop to MySQL and load the five tables.
6. Create relationships and measures using `powerbi/DAX_measures.txt`.
7. Build the report pages described below.

## Power BI report pages
1. Executive Overview: Total Revenue, Total Orders, Units Sold, Average Order Value; monthly revenue trend.
2. Product & Category: revenue by category, top 10 products, units sold.
3. Customer Insights: top customers, repeat purchase rate, city/state analysis.
4. Payments & Orders: payment method split, order status distribution.

## Important metric definition
For consistency, this starter project defines recognised sales as order status `Delivered` AND payment status `Paid`. Revenue is calculated from order item line totals. Payment amount is retained for payment analysis. In a production project, refunds, discounts, taxes, shipping, and partial payments would require more detailed accounting rules.

## Python setup
```bash
pip install -r requirements.txt
python python/analysis.py
```

## Repository structure
- `dataset/`: source CSV files
- `sql/`: database schema and analysis queries
- `python/`: cleaning and analysis script
- `powerbi/`: DAX measures and dashboard guidance

## Limitations
This is a synthetic portfolio dataset created for learning. It is not a predictive model. A demand or churn prediction model would be a separate extension.
