USE ecommerce_analytics;

-- 1. Table row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments;

-- 2. Overall business KPIs (completed sales = Delivered orders with Paid payments)
SELECT
    COUNT(DISTINCT o.order_id) AS delivered_paid_orders,
    ROUND(SUM(oi.line_total),2) AS gross_revenue,
    ROUND(SUM(oi.quantity),0) AS units_sold,
    ROUND(SUM(oi.line_total) / NULLIF(COUNT(DISTINCT o.order_id),0),2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'Delivered' AND p.payment_status = 'Paid';

-- 3. Monthly revenue trend
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS order_month,
       ROUND(SUM(oi.line_total),2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id=oi.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY DATE_FORMAT(o.order_date,'%Y-%m')
ORDER BY order_month;

-- 4. Top 10 customers by revenue
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       COUNT(DISTINCT o.order_id) AS orders_count,
       ROUND(SUM(oi.line_total),2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY c.customer_id, customer_name
ORDER BY revenue DESC
LIMIT 10;

-- 5. Category performance
SELECT pr.category, SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.line_total),2) AS revenue
FROM products pr
JOIN order_items oi ON pr.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY pr.category
ORDER BY revenue DESC;

-- 6. Top 10 products
SELECT pr.product_id, pr.product_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.line_total),2) AS revenue
FROM products pr
JOIN order_items oi ON pr.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY pr.product_id, pr.product_name
ORDER BY revenue DESC
LIMIT 10;

-- 7. Repeat purchase customers
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT o.customer_id
    FROM orders o JOIN payments p ON o.order_id=p.order_id
    WHERE o.order_status='Delivered' AND p.payment_status='Paid'
    GROUP BY o.customer_id
    HAVING COUNT(DISTINCT o.order_id)>1
) x;

-- 8. Payment method popularity
SELECT p.payment_method, COUNT(*) AS payment_count,
       ROUND(SUM(p.amount),2) AS payment_amount
FROM payments p
JOIN orders o ON p.order_id=o.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY p.payment_method
ORDER BY payment_count DESC;

-- 9. City-wise revenue
SELECT c.city, COUNT(DISTINCT o.order_id) AS orders_count,
       ROUND(SUM(oi.line_total),2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY c.city
ORDER BY revenue DESC;

-- 10. Customers with no delivered paid purchase
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id=o.customer_id
LEFT JOIN payments p ON o.order_id=p.order_id
GROUP BY c.customer_id, customer_name
HAVING SUM(CASE WHEN o.order_status='Delivered' AND p.payment_status='Paid' THEN 1 ELSE 0 END)=0;

-- 11. Order value ranking using a window function
WITH order_revenue AS (
    SELECT o.order_id, o.customer_id, SUM(oi.line_total) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id=oi.order_id
    JOIN payments p ON o.order_id=p.order_id
    WHERE o.order_status='Delivered' AND p.payment_status='Paid'
    GROUP BY o.order_id, o.customer_id
)
SELECT order_id, customer_id, ROUND(order_value,2) AS order_value,
       DENSE_RANK() OVER (ORDER BY order_value DESC) AS order_rank
FROM order_revenue;

-- 12. Customer lifetime revenue ranking using CTE + window function
WITH customer_revenue AS (
    SELECT o.customer_id, SUM(oi.line_total) AS lifetime_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id=oi.order_id
    JOIN payments p ON o.order_id=p.order_id
    WHERE o.order_status='Delivered' AND p.payment_status='Paid'
    GROUP BY o.customer_id
)
SELECT customer_id, ROUND(lifetime_revenue,2) AS lifetime_revenue,
       RANK() OVER (ORDER BY lifetime_revenue DESC) AS revenue_rank
FROM customer_revenue;

-- 13. Cancellation and return rate
SELECT order_status, COUNT(*) AS orders_count,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM orders),2) AS pct_of_all_orders
FROM orders
GROUP BY order_status;

-- 14. Product gross margin (based on product master cost)
SELECT pr.product_id, pr.product_name,
       ROUND(SUM(oi.line_total),2) AS revenue,
       ROUND(SUM(oi.quantity * pr.cost_price),2) AS estimated_cost,
       ROUND(SUM(oi.line_total - oi.quantity * pr.cost_price),2) AS estimated_gross_profit
FROM products pr
JOIN order_items oi ON pr.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
JOIN payments p ON o.order_id=p.order_id
WHERE o.order_status='Delivered' AND p.payment_status='Paid'
GROUP BY pr.product_id, pr.product_name
ORDER BY estimated_gross_profit DESC;
