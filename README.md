# 🏨 Hotel Bookings — End-to-End Data Engineering Project on Microsoft Fabric

A complete end-to-end data engineering project built on **Microsoft Fabric**, implementing Medallion Architecture (Bronze → Silver → Gold) with automated orchestration and Power BI reporting.

---

## 🏗️ Architecture

```
GitHub (CSV Source)
       ↓
  Copy Data Activity (upsert)
       ↓
 Bronze Lakehouse (raw Delta tables)
       ↓
  Dataflow Gen2 (transformations)
       ↓
 Silver Lakehouse (OBT - One Big Table)
       ↓
  Dataflow Gen2 (Star Schema modeling)
       ↓
 Gold Lakehouse (Star Schema)
       ↓
  Semantic Model (Direct Lake)
       ↓
  Power BI Report
```

---

## 📦 Tech Stack

- **Microsoft Fabric** — unified data platform
- **Data Factory** — Copy Data activity, Pipeline orchestration
- **Dataflow Gen2** — data transformations (Power Query M)
- **Lakehouse** — Delta Lake storage (Bronze, Silver, Gold)
- **Semantic Model** — Direct Lake connection
- **Power BI** — interactive reporting with DAX measures

---

## 🗂️ Dataset

5 CSV files representing a hotel booking system:

| Table | Description |
|---|---|
| `bookings` | Reservations with check-in, check-out, status |
| `guests` | Guest personal data and country |
| `hotels` | Hotel details, city, country, rating |
| `rooms` | Room type, price per night |
| `reviews` | Guest reviews per booking |

Source: [AnshLamba YouTube — FabricPipelines](https://github.com/anshlambagit/AnshLambaYoutube/tree/main/FabricPipelines)

---

## 🥉 Bronze Layer

- Raw data ingested from GitHub API using **Copy Data activity**
- Data loaded into **Lakehouse Tables** in Delta format
- **Upsert** strategy — existing records updated, new records inserted
- Preserves source data 1:1 without transformations

---

## 🥈 Silver Layer — One Big Table (OBT)

All 5 Bronze tables joined into a single denormalized table `Silver_OBT`:

```
bookings (base)
  ├── JOIN guests ON guest_id
  ├── JOIN rooms ON room_id
  ├── JOIN hotels ON hotel_id (via rooms)
  └── LEFT JOIN reviews ON booking_id (aggregated AVG rating)
```

**Transformations applied:**
- Column renaming for clarity (`name` → `guest_name`, `hotel_name` etc.)
- Data type corrections (dates, decimals)
- Calculated column: `nights_stayed = check_out - check_in`
- Calculated column: `total_price = nights_stayed * price_per_night`
- Metadata column: `silver_processed_date`

**Granularity:** 1 row = 1 booking

---

## 🥇 Gold Layer — Star Schema

Silver OBT transformed into a Star Schema optimized for Power BI:

<img width="800" height="537" alt="semnatic_model" src="https://github.com/user-attachments/assets/5a17b51b-619b-4839-9621-65493fab1f5b" />

| Table | Key | Description |
|---|---|---|
| `FactBookings` | booking_id | Measures: nights_stayed, total_price, review_rating |
| `DimGuest` | guest_key | Guest attributes |
| `DimHotelRoom` | hotel_room_key | Hotel and room attributes combined |
| `DimFlags` | flag_id | Junk dimension: booking_status + is_reviewed |
| `DimDate` | date | Date hierarchy for time intelligence |


**Lineage timestamps per record:**
- `silver_processed_date` — when Dataflow Gen2 processed to Silver
- `gold_processed_at` — when Dataflow Gen2 processed to Gold

---

## 📊 Power BI Report

### Page 1 — Bookings Analysis
- KPI Cards: Total Revenue, Avg Revenue, Total Bookings, Avg Nights, Cancellation Rate
- Gauge: Avg Review Rating (0–5 scale)
- Bar chart: Revenue by Hotel
- Line chart: Revenue trend by Year
- Field Parameter slicer: switch between Total Revenue / Avg Revenue / Total Bookings / Avg Nights / Cancellation Rate

### Page 2 — Guests & Hotel Performance
- Bar chart: Total Bookings by Guest
- Bar chart: Avg Hotel Rating by Hotel
- Scatter plot: Hotel Rating vs Total Bookings (correlation analysis)

### DAX Measures
```dax
Total Revenue = SUM(FactBookings[total_price])
Avg Revenue = AVERAGE(FactBookings[total_price])
Total Bookings = COUNTROWS(FactBookings)
Avg Nights = AVERAGE(FactBookings[nights_stayed])
Avg Review Rating = AVERAGE(FactBookings[review_rating])
Cancellation Rate = 
DIVIDE(
    CALCULATE(
        COUNTROWS(fact_bookings),
        KEEPFILTERS(dim_flags[booking_status] = "cancelled")
    ),
    COUNTROWS(fact_bookings),
    0
)
```

---

## ⚙️ Orchestration

Automated **Data Pipeline** in Fabric with daily schedule:

```
[Copy Data] →✅→ [Dataflow Silver] →✅→ [Dataflow Gold]
```

- Runs daily at 13:10 UTC+1
- On Success chaining — each activity runs only if previous succeeded
- Direct Lake Semantic Model refreshes automatically after Gold update
- No manual intervention required

---

## 📁 Repository Structure

```
hotel-fabric-project/
  README.md
  /screenshots
    page1_bookings_analysis.png
    page2_guest_hotel_performance.png
  /dataflows
    bronze_to_silver.pq
    silver_to_gold.pq
  /dax
    measures.dax
  /data
    bookings.csv
    guests.csv
    hotels.csv
    rooms.csv
    reviews.csv
```

---

## 🚀 How to Run

1. Upload CSV files to a GitHub repository
2. Create a Microsoft Fabric workspace with Trial or Premium capacity
3. Create Bronze, Silver, Gold Lakehouses
4. Configure Copy Data activity pointing to your GitHub CSV source
5. Import Dataflow Gen2 queries from `/dataflows` folder
6. Create Semantic Model from Gold Lakehouse using Direct Lake
7. Build Power BI Report from Semantic Model
8. Configure Data Pipeline with scheduled trigger

---

*Built with Microsoft Fabric — Bronze to Power BI end-to-end*
