# AdventureWorks — SQL Business Analysis Portfolio

End-to-end analytics project using **Microsoft SQL Server** on **AdventureWorksDW2022**: SQL for metric definitions and extracts, **Tableau** for dashboards, and this repository for documentation and reproducibility.

## What this project demonstrates

- Translating business questions into **SQL** (CTEs, window functions, cohort logic, segmentation).
- Building **decision-ready visuals** (trends, concentration, retention, segmentation, SKU economics).
- Communicating **what the chart proves** and **what you would recommend** next in a real business review.

## Tech stack

| Layer | Tools |
|--------|--------|
| Data | **AdventureWorksDW2022** (warehouse / analytical model) |
| Database | **SQL Server 2022** (local via **Docker Desktop**) |
| SQL & export | **DBeaver** (queries → CSV for Tableau) |
| Visualization | **Tableau** |

> **Note:** The `.bak` database backup is large; it is usually **not** committed to GitHub. Document the restore steps (or link to Microsoft’s official sample) instead of uploading the file unless your course explicitly requires it.

## Repository layout (recommended)

```text
├── README.md                 ← you are here
├── sql/                      ← one .sql file per question (optional but strong for portfolios)
├── outputs/                  ← CSV exports from DBeaver (optional; consider gitignoring large files)
└── docs/
    └── images/               ← Tableau screenshots (PNG) referenced below
```

Add your Tableau exports under `docs/images/` and keep filenames stable so links in this README do not break. Example names:

- `docs/images/q01_monthly_revenue_mom.png`
- `docs/images/q02_yoy_growth.png`
- `docs/images/q03_country_share.png`
- `docs/images/q04_category_subcategory.png`
- `docs/images/q05_top10_concentration.png`
- `docs/images/q06_declining_vs_category.png`
- `docs/images/q07_new_vs_returning.png`
- `docs/images/q08_cohort_retention.png`
- `docs/images/q09_aov_frequency.png`
- `docs/images/q10_sku_volume_vs_margin.png`

## The 10 business questions (and what each visual answers)

### Q1 — Monthly revenue and short-term momentum

**Question:** How does monthly revenue trend, and how volatile is month-over-month (MoM) growth?

**Charts:** Monthly revenue line + MoM growth % (with a **0%** reference baseline).

**Takeaway to narrate:** Use revenue for the “level” story and MoM for **near-term volatility** (MoM will look noisy—that is expected).

---

### Q2 — Year-over-year (YoY) growth by month

**Question:** After controlling for seasonality (same calendar month vs last year), how strong is revenue growth?

**Chart:** YoY growth % by month with a **0%** reference line.

**Takeaway to narrate:** YoY highlights **sustained acceleration or deceleration** better than MoM when sales are seasonal.

---

### Q3 — Revenue concentration by country

**Question:** Which countries drive revenue, and what share of total does each country contribute?

**Chart:** Horizontal bars (revenue) + **percent-of-total** labels.

**Takeaway to narrate:** Call out **dependency risk** if a small set of countries dominates.

---

### Q4 — Category and subcategory profitability

**Question:** Which categories/subcategories drive revenue *and* gross profit? Where is margin strong vs weak?

**Tables/charts:** Category roll-up + subcategory detail (revenue, gross profit, gross margin %).

**Takeaway to narrate:** Separate **scale** (bikes may dominate revenue) from **efficiency** (accessories may show higher margin %).

---

### Q5 — Top products and revenue concentration

**Question:** What are the top products by revenue, and how concentrated is revenue in the top 1 / 3 / 5 / 10?

**Chart + summary:** Top 10 bars + a small **concentration** panel.

**Takeaway to narrate:** This is your “**portfolio concentration risk**” story—great products can still create operational dependency.

---

### Q6 — Category growth vs declining SKUs

**Question:** Are broad categories growing while specific SKUs deteriorate?

**Charts:** Category revenue change % + a short list of **largest-declining** products.

**Takeaway to narrate:** A healthy category headline can hide **SKU-level problems** (mix shift, assortment aging, pricing).

---

### Q7 — New vs returning customers by month

**Question:** How many customers are new vs returning each month?

**Chart:** Stacked bars (new + returning).

**Takeaway to narrate:** Early months often show **no returning customers** by definition—explain cohort mechanics briefly so reviewers do not misread it.

---

### Q8 — Cohort retention (M+1, M+3, M+6) + heatmap

**Question:** What share of each acquisition cohort returns after 1, 3, and 6 months—and what does the full post-acquisition curve look like?

**Dashboard:** Line charts (full scale + zoom) + **cohort × month-offset** heatmap.

**Takeaway to narrate:** Be explicit about **definition** (what counts as “active”), and call out any **late spikes** (calendar effects, annual purchases, data quirks).

---

### Q9 — AOV and purchase frequency by region and segment

**Question:** How do **average order value** and **orders per customer** differ across regions and customer segments?

**Dashboard:** Segment-level comparison + heatmaps/tables for AOV and frequency.

**Takeaway to narrate:** Watch for **tradeoffs** (high frequency vs low AOV, or the reverse)—that is often more actionable than either metric alone.

---

### Q10 — “High volume, low margin” SKUs (SKU economics)

**Question:** Which products sell a lot but contribute weaker gross profit or weaker margin %?

**Dashboard:** Two aligned scatter plots—**revenue vs gross profit ($)** and **revenue vs gross margin (%)**—with unit volume on size and a SKU flag for interpretation.

**Takeaway to narrate:** Use the top chart for **dollar contribution** and the bottom chart for **margin efficiency**; use flags/tooltips to name the SKUs you would prioritize for pricing, cost, or assortment actions.

## How to reproduce (high level)

1. Restore **AdventureWorksDW2022** into SQL Server (Docker is fine).
2. Connect with **DBeaver**, run your analysis queries, export result sets to **CSV**.
3. Connect **Tableau** to the CSVs (or to SQL Server directly if you prefer).
4. Export dashboard images to **`docs/images/`** and keep this README updated with your final definitions.

## License / attribution

**AdventureWorks** sample databases are provided by Microsoft for learning and demonstration. Keep attribution in your README if you publish publicly.
