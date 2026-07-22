# 🏨 Hotel Bookings — End-to-End Data Engineering Project on Microsoft Fabric

A complete end-to-end data engineering project built on **Microsoft Fabric**, implementing Medallion Architecture (Bronze → Silver → Gold) with automated orchestration and Power BI reporting.

`Microsoft Fabric` · `Data Pipelines` · `Dataflow Gen2` · `Direct Lake` · `Star Schema` · `DAX`

---

## 🎯 Business Goal

Hotel management needs daily visibility into revenue, occupancy, cancellations, and guest satisfaction across multiple properties — without manually pulling and reconciling data from separate booking, guest, and review systems. This pipeline automates that end-to-end: raw booking data lands, gets cleaned and modeled overnight, and is ready in Power BI every morning with no manual intervention.

## 🏗️ Architecture

```
GitHub (CSV Source) → Copy Data (upsert) → Bronze Lakehouse
   → Dataflow Gen2 → Silver Lakehouse (OBT)
   → Dataflow Gen2 → Gold Lakehouse (Star Schema)
   → Semantic Model (Direct Lake) → Power BI Report
```

| Layer | What happens |
|---|---|
| **Bronze** | 5 CSVs (`bookings`, `guests`, `hotels`, `rooms`, `reviews`) ingested via Copy Data activity, upsert strategy, 1:1 with source |
| **Silver** | All 5 tables joined into one denormalized `Silver_OBT` (grain: 1 row = 1 booking); renamed columns, corrected types, calculated `nights_stayed` & `total_price` |
| **Gold** | Star schema: `fact_bookings`, `dim_guests`, `dim_hotels` (hotel+room combined), `dim_flags` (junk: status + is_reviewed), `dim_date` |

**Lineage:** each record carries `silver_processed_date` and `gold_processed_at` timestamps for traceability.

<img width="800" height="400" alt="semantic model" src="https://github.com/user-attachments/assets/5a17b51b-619b-4839-9621-65493fab1f5b" />

## ⚙️ Orchestration

Automated **Data Pipeline**, daily at 13:10 UTC+1: `Copy Data → Dataflow Silver → Dataflow Gold`, with on-success chaining and automatic Direct Lake refresh — no manual steps.

## 📊 Power BI Report

- **Page 1 — Bookings Analysis:** KPI cards (Revenue, Bookings, Avg Nights, Cancellation Rate), review rating gauge, revenue by hotel, revenue trend, field-parameter KPI slicer
- **Page 2 — Guests & Hotel Performance:** bookings by guest, avg rating by hotel, rating-vs-bookings correlation scatter plot

<details>
<summary><b>📐 DAX measures, repo structure & how to run (click to expand)</b></summary>

```dax
Total Revenue = SUM(FactBookings[total_price])
Avg Revenue = AVERAGE(FactBookings[total_price])
Total Bookings = COUNTROWS(FactBookings)
Avg Nights = AVERAGE(FactBookings[nights_stayed])
Avg Review Rating = AVERAGE(FactBookings[review_rating])
Cancellation Rate =
DIVIDE(
    CALCULATE(COUNTROWS(fact_bookings), KEEPFILTERS(dim_flags[booking_status] = "cancelled")),
    COUNTROWS(fact_bookings), 0
)
```

**Repository structure**
```
hotel-fabric-project/
  README.md
  /screenshots
  /dataflows      (bronze_to_silver.pq, silver_to_gold.pq)
  /datasets       (bookings, guests, hotels, rooms, reviews)
```

**How to run**
1. Upload CSVs to a GitHub repository
2. Create a Fabric workspace (Trial or Premium capacity)
3. Create Bronze, Silver, Gold Lakehouses
4. Configure Copy Data activity → your GitHub CSV source
5. Import Dataflow Gen2 queries from `/dataflows`
6. Create a Direct Lake Semantic Model from the Gold Lakehouse
7. Build the Power BI Report
8. Schedule the Data Pipeline trigger

</details>

---

*Built with Microsoft Fabric — Bronze to Power BI end-to-end.*
