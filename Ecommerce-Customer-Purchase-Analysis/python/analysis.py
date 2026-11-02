from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "dataset"
OUT = ROOT / "python" / "outputs"
OUT.mkdir(exist_ok=True)

customers = pd.read_csv(DATA / "customers.csv")
products = pd.read_csv(DATA / "products.csv")
orders = pd.read_csv(DATA / "orders.csv", parse_dates=["order_date"])
items = pd.read_csv(DATA / "order_items.csv")
payments = pd.read_csv(DATA / "payments.csv", parse_dates=["payment_date"])

# Basic quality checks
for name, df in {"customers": customers, "products": products, "orders": orders,
                 "order_items": items, "payments": payments}.items():
    print(f"\n{name}: {df.shape}")
    print("Duplicate rows:", df.duplicated().sum())
    print(df.isna().sum())

# Remove duplicate rows and invalid records
customers = customers.drop_duplicates(subset=["customer_id"])
products = products.drop_duplicates(subset=["product_id"])
orders = orders.drop_duplicates(subset=["order_id"])
items = items.drop_duplicates(subset=["order_item_id"])
payments = payments.drop_duplicates(subset=["payment_id"])
items = items[(items["quantity"] > 0) & (items["unit_price"] >= 0)]
items["line_total"] = items["quantity"] * items["unit_price"]

# Build an analysis table. Count revenue only for delivered orders with paid payments.
sales = (items.merge(orders, on="order_id", how="inner")
              .merge(products, on="product_id", how="left", suffixes=("_sold", "_master"))
              .merge(payments[["order_id", "payment_status", "payment_method"]], on="order_id", how="left")
              .merge(customers[["customer_id", "city", "state"]], on="customer_id", how="left",
                     suffixes=("", "_customer")))

valid_sales = sales[(sales["order_status"] == "Delivered") &
                    (sales["payment_status"] == "Paid")].copy()

valid_sales["order_month"] = valid_sales["order_date"].dt.to_period("M").astype(str)

print("\n--- Business KPIs ---")
revenue = valid_sales["line_total"].sum()
orders_count = valid_sales["order_id"].nunique()
units = valid_sales["quantity"].sum()
aov = revenue / orders_count if orders_count else 0
print(f"Revenue: {revenue:,.2f}")
print(f"Delivered paid orders: {orders_count:,}")
print(f"Units sold: {units:,}")
print(f"Average order value: {aov:,.2f}")

monthly = valid_sales.groupby("order_month", as_index=False)["line_total"].sum()
monthly.to_csv(OUT / "monthly_revenue.csv", index=False)

top_products = (valid_sales.groupby(["product_id", "product_name"], as_index=False)
                .agg(units_sold=("quantity", "sum"), revenue=("line_total", "sum"))
                .sort_values("revenue", ascending=False).head(10))
top_products.to_csv(OUT / "top_products.csv", index=False)

category = (valid_sales.groupby("category", as_index=False)["line_total"].sum()
            .rename(columns={"line_total": "revenue"})
            .sort_values("revenue", ascending=False))
category.to_csv(OUT / "category_revenue.csv", index=False)

# Simple chart for the project report
if not monthly.empty:
    plt.figure(figsize=(10, 5))
    plt.plot(monthly["order_month"], monthly["line_total"], marker="o")
    plt.title("Monthly Revenue - Delivered & Paid Orders")
    plt.xlabel("Month")
    plt.ylabel("Revenue")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(OUT / "monthly_revenue.png", dpi=150)
    plt.close()

print("\nOutputs saved in:", OUT)
