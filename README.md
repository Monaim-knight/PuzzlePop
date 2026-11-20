# PuzzlePop Marketing Analytics



## End-to-End Mobile Game User Acquisition, Campaign Optimization & Experimentation



**R | MySQL | SQL | Tableau | Attribution Analytics | A/B Testing**

---



## Project Overview



PuzzlePop Marketing Analytics is an end-to-end portfolio project that simulates the analytical environment of a mobile-game performance marketing team.



The project connects advertising delivery, user acquisition, attribution, player behavior, retention, monetization, campaign performance, creative performance, and experimentation to answer one central business question:



> How should Marketing allocate acquisition budget while balancing acquisition efficiency, player quality, monetization, and product-experiment outcomes?



The analytical workflow covers the full path from realistic messy source data to business recommendations:



Synthetic Business Truth

&#x20;       ↓

Realistic Raw Data

&#x20;       ↓

R Profiling, Cleaning & Validation

&#x20;       ↓

Processed Analytical Data

&#x20;       ↓

MySQL Analytical Model

&#x20;       ↓

SQL Business Analysis

&#x20;       ↓

Governed Tableau Views

&#x20;       ↓

Interactive Dashboards

&#x20;       ↓

Business Recommendations



---



## Important Data Disclaimer



**All data used in this project is synthetic.**



The dataset was intentionally created to resemble realistic mobile-game marketing, attribution, user-behavior, monetization, and experimentation data.



No confidential company information, proprietary production data, or real player-level data is included.



The synthetic pipeline intentionally introduces realistic analytical challenges, including:



- duplicate records;

- missing identifiers;

- Paid and Organic acquisition;

- structural attribution nulls;

- inconsistent monetary representations;

- Boolean-format differences;

- multiple analytical grains;

- high-precision revenue values;

- campaign and creative performance variation.



These issues are retained in the raw layer and resolved through a controlled cleaning, validation, database, and analytical workflow.



---



## Business Context



PuzzlePop is modeled as a free-to-play mobile game acquiring players through five Paid acquisition channels:



- Facebook Audience Network

- Google App Campaigns

- TikTok Ads

- Snapchat Ads

- Unity Ads



Marketing activity is organized into campaigns, acquisition strategies, and creatives.



The project evaluates the funnel from media delivery through downstream player value:



Impressions

&#x20;   ↓

Clicks

&#x20;   ↓

Installs

&#x20;   ↓

Engagement

&#x20;   ↓

Retention

&#x20;   ↓

Payer Conversion

&#x20;   ↓

Revenue

&#x20;   ↓

ROAS



A separate onboarding A/B test evaluates whether a shorter onboarding experience increases tutorial completion without creating unacceptable downstream retention or monetization trade-offs.



---



## Business Questions



### Marketing Portfolio



- How much is being invested across Paid acquisition channels?

- Which channels generate installs most efficiently?

- Which channels acquire the highest-quality players?

- Does low CPI translate into strong retention and monetization?

- Which channels generate the strongest observed ROAS?



### Campaign Performance



- Which campaigns strengthen or weaken channel-level performance?

- Which campaigns combine efficient acquisition with valuable users?

- Where should Marketing scale, maintain, optimize, or reduce investment?



### Creative Performance



- Which creatives generate the strongest ROAS?

- Do campaign averages conceal particularly strong or weak creatives?

- Is spend aligned with creative-level performance?

- Which creatives warrant controlled scaling?

- Which high-spend creatives represent budget risk?



### Experimentation



- Does shorter onboarding increase tutorial completion?

- What is the absolute uplift?

- What is the relative uplift?

- Is the primary result statistically significant?

- What is the 95% confidence interval?

- How do retention outcomes move?

- How do payer conversion and revenue move?

- Should the Treatment be rolled out?



---



## Technology Stack



### R



Used for:



- synthetic business-truth generation;

- realistic raw-data generation;

- data profiling;

- missingness investigation;

- duplicate validation;

- identifier recovery;

- attribution repair;

- monetary parsing;

- transformations;

- data-quality validation;

- creation of final analytical datasets.



### MySQL



Used for:



- analytical schema design;

- controlled bulk ingestion;

- data-type enforcement;

- primary and unique keys;

- referential integrity;

- analytical querying;

- governed Tableau-facing views.



### SQL



Used for:



- CTEs;

- joins;

- conditional aggregation;

- weighted KPI calculations;

- channel economics;

- campaign diagnostics;

- creative diagnostics;

- retention analysis;

- monetization analysis;

- experiment analysis;

- statistical testing;

- confidence intervals;

- reusable Tableau semantic views.



### Tableau



Used to build three connected decision-oriented dashboards:



1\. Marketing Performance Overview

2\. Campaign & Creative Optimization

3\. Onboarding Experiment Decision



---



## Data Architecture



The project separates data generation, data quality, storage, business logic, and presentation responsibilities.



Synthetic Truth Layer

&#x20;       ↓

Controlled Raw-Data Simulation

&#x20;       ↓

R Profiling / Investigation

&#x20;       ↓

Cleaning / Repair / Validation

&#x20;       ↓

Processed Analytical CSVs

&#x20;       ↓

MySQL

&#x20;       ↓

SQL Business Logic

&#x20;       ↓

Tableau Semantic Views

&#x20;       ↓

Dashboards

&#x20;       ↓

Business Decisions



This prevents Tableau from becoming responsible for source-level cleaning or complex analytical transformations.



---



## R Pipeline



The publication pipeline is organized sequentially:



scripts/R/

├── 01_build_synthetic_truth_layer.R

├── 02_create_raw_business_data.R

└── 03_clean_validate_raw_data.R



### 01 — Build Synthetic Truth Layer



Creates the clean underlying synthetic business reality for:



- advertising delivery;

- installs;

- player behavior;

- monetization;

- experimentation.



Outputs are generated locally in:



data/truth/



### 02 — Create Raw Business Data



Transforms the truth layer into analyst-facing datasets containing controlled, realistic data-quality problems.



Outputs:



data/raw/



### 03 — Clean & Validate Raw Data



Profiles, investigates, repairs, cleans, validates, and exports the final analytical datasets.



Raw

→ Profile

→ Investigate

→ Clean

→ Validate

→ Export



Outputs:



data/processed/



Large generated datasets are intentionally excluded from Git version control because they can be reproduced through the included R workflow.



---



## Final Analytical Datasets



### analytics_ad_delivery



Grain: one advertising-delivery observation.



Used for:



- spend;

- impressions;

- clicks;

- channel analysis;

- campaign analysis;

- creative media performance.



Validated rows: 188,820



### analytics_installs



Grain: one installation/user.



Used for:



- Paid vs Organic acquisition;

- AppsFlyer-style attribution;

- channel attribution;

- campaign attribution;

- creative attribution;

- install volume.



Validated rows: 102,941



### analytics_user_performance



Grain: one user.



Used for:



- early engagement;

- D1 retention;

- D7 retention;

- D30 retention;

- payer status;

- purchase revenue;

- advertising revenue;

- total revenue.



Validated rows: 102,941



### analytics_experiment



Grain: one user per experiment.



Used for:



- Control/Treatment assignment;

- tutorial completion;

- retention outcomes;

- payer conversion;

- revenue outcomes.



Validated rows: 40,988



---



## Data Quality Challenges & Solutions



### Duplicate Records



Potential duplicates were investigated against the intended business grain and stable identifiers.



Records were not blindly removed with DISTINCT.



Analytical lesson:



Understand the business grain before deduplication.



### Missing Paid Attribution IDs



Some Paid acquisition records contained missing attribution identifiers.



Identifier recovery was performed only after validating mapping uniqueness and coverage.



Analytical lesson:



Validate relationships before using them to repair identifiers.



### Organic Attribution Nulls



Organic users naturally lack Paid campaign and creative attribution.



Those values were preserved as legitimate structural NULL values rather than replaced with artificial labels.



Analytical lesson:



Missingness must be interpreted in business context.



### Customer Identity Recovery



Missing customer identifiers were recovered through validated identity relationships where sufficient evidence existed.



Analytical lesson:



Referential evidence is safer than arbitrary imputation.



### Boolean Conversion



R-exported Boolean fields required deliberate MySQL conversion.



The SQL ingestion process accepts:



TRUE / FALSE

1 / 0



and converts them to the analytical binary representation used by MySQL.



### Structural NA Handling



Exported NA and blank attribution fields were explicitly converted to SQL NULL where the missingness was structurally valid.



### Revenue Precision



High-precision revenue values initially exposed database precision issues.



The final implementation uses explicit casting and rounding before storing analytical revenue fields with six-decimal precision.



Analytical lesson:



A successful row count does not prove a successful data load.

---



## MySQL Analytical Model



The validated relational structure includes:



analytics_installs

&#x20;       1

&#x20;       │ appsflyer_id

&#x20;       │

&#x20;       1

analytics_user_performance



and:



analytics_user_performance

&#x20;       1

&#x20;       │ customer_user_id

&#x20;       │

&#x20;       0..1

analytics_experiment



Foreign-key relationships were introduced only after relationship coverage had been validated.



No artificial row-level foreign key was created between analytics_ad_delivery and analytics_installs because those tables operate at different analytical grains.



---



## Analytical Grain Management



One of the most important modeling principles in this project is:



**Aggregate first, join second when fact tables have different grains.**



Advertising-delivery data contains observations across:



- date;

- channel;

- campaign;

- creative;

- country;

- platform.



Installs and user-performance data operate at user grain.



A direct row-level fact-to-fact join could multiply:



- spend;

- impressions;

- installs;

- revenue.



Therefore:



1\. Delivery metrics are aggregated to the required business grain.

2\. User outcomes are independently aggregated to that same grain.

3\. The aggregated results are joined afterward.



This approach is used throughout channel, campaign, and creative analysis.



---



## SQL Publication Structure



scripts/SQL/
├── 01_schema.sql
├── 02_load_data.sql
├── 03_validation_constraints.sql
├── 04_marketing_analysis.sql
├── 05_experiment_analysis.sql
└── 06_tableau_views.sql


### 01_schema.sql



Defines the final analytical tables, data types, precision, keys, and relationships.



### 02_load_data.sql



Contains the clean ingestion workflow for the four processed analytical datasets, including:



- date and datetime conversion;

- Boolean normalization;

- structural-null handling;

- revenue precision management.



Machine-specific file paths are replaced by portable placeholders.



### 03_validation_constraints.sql



Contains:



- grain validation;

- uniqueness validation;

- Paid vs Organic attribution QA;

- relationship coverage validation;

- foreign-key enforcement;

- foreign-key verification.



### 04_marketing_analysis.sql



Contains the main marketing analysis:



- channel delivery analysis;

- acquisition efficiency;

- acquisition quality;

- retention;

- monetization;

- marketing economics;

- campaign diagnostics;

- creative diagnostics.



### 05_experiment_analysis.sql



Contains:



- experiment baseline;

- absolute uplift;

- relative uplift;

- statistical-significance analysis;

- z-statistic;

- 95% confidence interval;

- retention outcomes;

- monetization guardrails.



### 06_tableau_views.sql



Creates the governed Tableau semantic layer used by the final dashboards.





---



## Marketing KPI Framework



### Click-Through Rate (CTR)



CTR = Clicks / Impressions



### Cost per Thousand Impressions (CPM)



CPM = Spend / Impressions × 1,000



### Cost per Install (CPI)



CPI = Spend / Paid Installs



### Retention Rate



Retention Rate = Retained Users / Acquired Users



### Payer Rate



Payer Rate = Payers / Acquired Users



### Average Revenue per User (ARPU)



ARPU = Total Revenue / Acquired Users



### Average Revenue per Paying User (ARPPU)



ARPPU = IAP Revenue / Payers



### Return on Advertising Spend (ROAS)



ROAS = Attributed Revenue / Advertising Spend



Ratio KPIs are calculated from aggregated numerators and denominators rather than by averaging row-level ratios.



---



## Key Marketing Results



### Portfolio Performance



Across Paid acquisition:



- Media Spend: **$105.02K**

- Paid Installs: **90,941**

- Blended CPI: **$1.15**

- Paid-Attributed Revenue: **$77.3K**

- Observed ROAS: **73.65%**



Observed ROAS represents revenue recovered within the available analytical measurement window and should not be interpreted as complete lifetime profitability.



---



## Channel Performance



### TikTok Ads



- CPI: **$0.96**

- Paid Installs: **24,080**

- Revenue: **$20,397.67**

- ARPU: **$0.85**

- ROAS: **88.58%**



Interpretation:



TikTok provides the strongest overall balance of acquisition scale, acquisition efficiency, and observed return.



Recommendation:



**Protect and selectively scale the strongest TikTok campaign and creative combinations while monitoring marginal CPI and ROAS as spend increases.**



### Google App Campaigns



- CPI: **$1.52**

- D1 Retention: **32.10%**

- D7 Retention: **11.44%**

- D30 Retention: **4.64%**

- Payer Rate: **6.01%**

- ARPU: **$1.17**

- ROAS: **76.77%**



Interpretation:



Google has the highest acquisition cost but acquires the strongest downstream users.



**High CPI does not automatically mean poor acquisition quality.**



Recommendation:



**Protect strong Google acquisition and optimize weaker internal campaign combinations rather than reducing the entire channel based only on CPI.**



### Unity Ads



- CPI: **$0.79**

- Payer Rate: **2.98%**

- ARPU: **$0.58**

- ROAS: **73.73%**



Interpretation:



Unity produces inexpensive acquisition but weaker downstream monetization.



Recommendation:



**Use Unity selectively for efficient acquisition volume without assuming that low CPI alone justifies aggressive scaling.**



### Facebook Audience Network



- Spend: **$26,628.83**

- CPI: **$1.48**

- ARPU: **$0.98**

- ROAS: **66.53%**

- Revenue Gap: **−$8,913.92**



Interpretation:



Facebook acquires comparatively valuable users, but acquisition cost reduces economic performance.



Recommendation:



**Reallocate budget toward stronger Facebook campaign and creative combinations before considering channel-wide reductions.**



### Snapchat Ads



- CPI: **$1.16**

- D7 Retention: **6.91%**

- D30 Retention: **2.22%**

- Payer Rate: **3.05%**

- ARPU: **$0.68**

- ROAS: **58.93%**



Interpretation:



Snapchat shows acceptable acquisition-stage performance but substantially weaker downstream retention and monetization.



Recommendation:



**Reduce or restructure inefficient Snapchat activity while preserving controlled investment in stronger combinations for further testing.**

---



## Campaign Analysis



Channel averages concealed substantial internal campaign variation.



Selected stronger campaigns included:



| Campaign | Observed ROAS |

|---|---:|

| TT_HIGH_VALUE_PUZZLEPOP | 94.90% |

| TT_BROAD_PUZZLEPOP | 91.60% |

| GGL_HIGH_VALUE_PUZZLEPOP | 85.92% |

| TT_LOW_COST_PUZZLEPOP | 83.54% |

| TT_RETENTION_PUZZLEPOP | 81.46% |



One of the weakest observed campaigns was:



**SNAP_BROAD_PUZZLEPOP — approximately 41.81% ROAS**



### Recommendation



**Reallocate incrementally from weaker combinations toward stronger campaigns instead of making channel-wide budget decisions.**



Historical ROAS should not be assumed to remain constant when budgets increase.



---



## Creative Analysis



Creative-level analysis produced even greater performance dispersion.



Several individual creatives exceeded **100% observed ROAS** while their overall campaigns remained below 100%.



Examples included:



- TikTok Low Cost Playable: approximately **131%**

- TikTok Broad Playable: approximately **115%**

- Facebook Retention Playable: approximately **114%**

- TikTok High Value Playable: approximately **112%**

- Google Low Cost Playable: approximately **112%**



Playable creatives frequently appeared among stronger combinations.



However, this is observational evidence and does not prove that Playable format itself causes higher ROAS.



Creative performance may also vary because of:



- channel;

- audience;

- campaign strategy;

- creative concept;

- spend level.



### Recommendation



**Prioritize high-performing Playable creatives for controlled scaling tests and refresh weaker creative concepts, especially where high spend coincides with weak observed ROAS.**



---



## A/B Experiment Analysis



### Experiment



**EXP_ONBOARDING_001**



### Sample Size



- Control: **20,493 participants**

- Treatment: **20,495 participants**



The experiment groups were effectively balanced in size.



---



### Primary Outcome



Tutorial completion:



| Variant | Tutorial Completion |

|---|---:|

| Control | 72.41% |

| Treatment | 74.89% |



Absolute uplift:



**+2.48 percentage points**



Relative uplift:



**+3.42%**



Estimated additional tutorial completions within the Treatment sample:



**approximately 508**



---



### Statistical Analysis



The primary tutorial-completion outcome was evaluated using a two-proportion comparison.



Results:



- Z-statistic: approximately **5.70**

- 95% confidence interval: **+1.63 to +3.33 percentage points**

- Result: **statistically significant at the 5% level**



The confidence interval remains above zero, supporting evidence of a positive Treatment effect on tutorial completion.



---



### Secondary Outcomes



Observed retention movements were:



| Metric | Control | Treatment | Difference |

|---|---:|---:|---:|

| D1 Retention | 28.13% | 28.28% | +0.15 pp |

| D7 Retention | 8.45% | 8.70% | +0.25 pp |

| D30 Retention | 3.20% | 3.30% | +0.10 pp |



These are reported as observed directional movements and are not described as independently statistically significant.



---



### Monetization Guardrails



#### Payer Rate



| Variant | Payer Rate |

|---|---:|

| Control | 4.35% |

| Treatment | 4.10% |



Observed difference:



**−0.25 percentage points**



#### Revenue per Participant



| Variant | Revenue per Participant |

|---|---:|

| Control | $0.9253 |

| Treatment | $0.8395 |



Observed relative difference:



**−9.28%**



These are treated as observed negative monetization movements rather than statistically established declines.



---



### Experiment Recommendation



**Continue controlled testing rather than proceed directly to full rollout.**



The shorter onboarding experience improves tutorial completion, and the primary effect is statistically significant.



However, the observed negative movements in payer conversion and revenue per participant create sufficient commercial concern that optimizing only the primary KPI would be inappropriate.



A follow-up experiment should investigate whether shorter onboarding removes exposure to:



- monetization-relevant mechanics;

- purchase education;

- progression systems;

- important product features;

- rewards or other commercially relevant functionality.



Future experiment design should predefine:



#### Primary KPI



- Tutorial completion



#### Guardrail Metrics



- D1/D7/D30 retention

- payer conversion

- revenue per participant



---



## Senior-Analyst Experiment Principle



The experiment illustrates an important distinction:



**Statistical significance is not the same as business significance.**



A statistically significant improvement in an intermediate product KPI does not automatically justify rollout when downstream commercial guardrails move unfavorably.



The decision therefore combines:



Primary Statistical Effect

&#x20;       +

Retention Outcomes

&#x20;       +

Monetization Guardrails

&#x20;       +

Business Context

&#x20;       ↓

Rollout Decision

---



## Tableau Semantic Layer



Three governed MySQL views support the final Tableau workbook:



vw_tableau_channel_performance

vw_tableau_campaign_creative_performance

vw_tableau_experiment_performance



Critical KPI logic is centralized in SQL rather than independently rebuilt inside individual Tableau worksheets.



---



## Tableau Dashboard Architecture



The final Tableau solution contains three connected dashboards designed around a simple analytical progression:



MONITOR

&#x20;   ↓

DIAGNOSE

&#x20;   ↓

DECIDE



---



### Dashboard 1 — Marketing Performance Overview



!\[Marketing Performance Overview](dashboards/dashboard_marketing_overview.png)



Business question:



**Where is Paid marketing working, and which channels require deeper investigation?**



Key components:



- Total Spend

- Paid Installs

- CPI

- Revenue

- ROAS

- Channel ROAS

- CPI vs ARPU

- D7 Retention by Channel



Purpose:



This dashboard provides the executive-level view of Paid acquisition performance and allows Marketing to compare acquisition efficiency with downstream player value.



---



### Dashboard 2 — Campaign & Creative Optimization



!\[Campaign & Creative Optimization](dashboards/dashboard_campaign_creative.png)



Business question:



**Which campaigns and creatives drive performance, and where should Marketing reallocate budget?**



Key components:



- Campaign Performance

- Campaign Creative Performance

- dynamic Top-N creative parameter

- dynamic creative set

- campaign-to-creative filtering

- Spend vs ROAS Opportunity Map

- Creative Type encoding

- 100% ROAS benchmark

- Average Spend benchmark



Purpose:



This dashboard moves below channel averages to identify campaign- and creative-level opportunities that Marketing can act on.



---



### Dashboard 3 — Onboarding Experiment Decision



!\[Onboarding Experiment Decision](dashboards/dashboard_experiment_decision.png)



Business question:



**Does shorter onboarding improve the primary KPI without creating unacceptable downstream business trade-offs?**



Key components:



- rollout recommendation

- absolute uplift

- relative uplift

- 95% confidence interval

- statistical-significance statement

- Tutorial Completion

- Retention Comparison

- Monetization Guardrails



Purpose:



This dashboard combines statistical evidence with downstream business outcomes to support a rollout decision rather than simply reporting whether the primary metric increased.



---



## Analytical Story



Together, the three dashboards form one decision-oriented analytical product:



Marketing Performance Overview

&#x20;       ↓

MONITOR

What is happening?



&#x20;       ↓



Campaign & Creative Optimization

&#x20;       ↓

DIAGNOSE

Why is it happening and where can Marketing act?



&#x20;       ↓



Onboarding Experiment Decision

&#x20;       ↓

DECIDE

Should the Treatment be rolled out?



---



## Final Business Recommendations



### 1. Selectively Scale Strong TikTok Combinations



TikTok currently provides the strongest overall balance of acquisition efficiency, scale, and observed ROAS.



Scaling should remain incremental because marginal performance may change as investment increases.



---



### 2. Protect High-Quality Google Acquisition



Google has comparatively high CPI but acquires users with stronger retention, payer conversion, and ARPU.



Avoid broad channel-level budget cuts based only on acquisition cost.



---



### 3. Use Unity Selectively for Efficient Volume



Unity demonstrates that cheap acquisition is not automatically valuable acquisition.



Low CPI should be evaluated alongside downstream retention and monetization before scaling decisions are made.



---



### 4. Reallocate Weaker Facebook and Snapchat Investment



Focus optimization on high-spend, weak-return campaign and creative combinations rather than applying blanket channel-level reductions.



Snapchat Broad and other weak combinations represent stronger optimization candidates than the entire channel.



---



### 5. Scale Creative Winners Through Controlled Tests



Individual creatives can materially outperform their parent campaigns.



Budget allocation should therefore occur at the most actionable grain supported by the evidence.



Creative-format patterns should be tested rather than treated as causal conclusions.



---



### 6. Continue Controlled Onboarding Experimentation



The primary Treatment outcome is statistically significant, but weaker observed monetization guardrails make immediate full rollout inappropriate.



The appropriate decision is:



**Continue controlled testing rather than proceed directly to full rollout.**



---



## Key Analytical Lessons



### Cheap Acquisition Is Not the Same as Valuable Acquisition



Unity produces the lowest CPI, while Google acquires stronger downstream users.



Acquisition cost therefore cannotry



Strong CTR, CPM, or CPI performance does not necessarily produce:



- retention;

- payer conversion;

- revenue;

- ROAS.



Marketing optimization therefore needs to connect advertising delivery with downstream user behavior.



### Analytical Grain Matters



Joining fact tables at incompatible grains can multiply business metrics.



The project therefore follows:



**Aggregate first → join second**



when integrating delivery and user-level datasets.



### Ratio Metrics Require Careful Aggregation



Metrics such as:



- CTR

- CPI

- ARPU

- ROAS



are calculated using aggregated numerators and denominators rather than averages of row-level ratios.



### Statistical Significance Is Not Business Significance



The onboarding Treatment significantly improves tutorial completion.



That result alone is insufficient for rollout because downstream monetization guardrails move negatively.



### Channel Averages Can Hide Actionable Opportunities



Campaign- and creative-level results can differ substantially from overall channel performance.



Marketing decisions should therefore occur at the most actionable grain supported by reliable data.



---



## Senior-Analyst Decision Framework



The overall project follows this decision model:



Marketing Spend

&#x20;       ↓

Acquisition Efficiency

&#x20;       ↓

Player Quality

&#x20;       ↓

Retention

&#x20;       ↓

Monetization

&#x20;       ↓

ROAS

&#x20;       ↓

Campaign / Creative Diagnosis

&#x20;       ↓

Business Recommendation



The experiment follows a parallel framework:



Primary Statistical Effect

&#x20;       +

Secondary Outcomes

&#x20;       +

Commercial Guardrails

&#x20;       +

Business Context

&#x20;       ↓

Rollout Decision



---



## Portfolio Skills Demonstrated



### Analytics Engineering & Data Quality



- analytical grain definition

- data profiling

- duplicate validation

- missing-data interpretation

- attribution repair

- identifier recovery

- controlled transformations

- reproducibility

- source-to-output reconciliation



### R



- synthetic-data generation

- realistic raw-data simulation

- tidyverse

- data cleaning

- validation

- transformation

- analytical dataset creation



### MySQL / SQL



- schema design

- bulk ingestion

- data-type handling

- NULL handling

- Boolean conversion

- precision management

- primary and unique keys

- foreign keys

- CTEs

- joins

- conditional aggregation

- window functions

- KPI governance

- statistical calculations

- reusable semantic views



### Marketing Analytics



- CTR

- CPM

- CPI

- retention

- payer conversion

- ARPU

- ARPPU

- ROAS

- revenue gap

- channel performance

- campaign performance

- creative diagnostics

- budget-allocation reasoning



### Experimentation



- experiment baseline validation

- absolute uplift

- relative uplift

- two-proportion comparison

- pooled and unpooled standard errors

- z-statistic

- 95% confidence interval

- statistical significance

- practical/business significance

- retention guardrails

- monetization guardrails



### Tableau



- executive KPI dashboards

- campaign and creative diagnostics

- scatterplots

- reference lines

- parameters

- dynamic sets

- dashboard filter actions

- tooltips

- cross-dashboard navigation

- decision-oriented storytelling



---



## Repository Structure



PuzzlePop/

│

├── README.md

├── .gitignore

├── PuzzlePop.Rproj

│

├── scripts/

│   │

│   ├── R/

│   │   ├── 01_build_synthetic_truth_layer.R

│   │   ├── 02_create_raw_business_data.R

│   │   └── 03_clean_validate_raw_data.R

│   │

│   └── SQL/

│      ├── 01_schema.sql
       ├── 02_load_data.sql
       ├── 03_validation_constraints.sql
       ├── 04_marketing_analysis.sql
       ├── 05_experiment_analysis.sql
       └── 06_tableau_views.sql│

├── tableau/

│   └── PuzzlePop_Marketing_Analytics.twb

│

├── dashboards/

│   ├── dashboard_marketing_overview.png

│   ├── dashboard_campaign_creative.png

│   └── dashboard_experiment_decision.png

│

└── data/

&#x20;   ├── truth/

&#x20;   ├── raw/

&#x20;   └── processed/



The generated data/truth, data/raw, and data/processed artifacts are retained locally but excluded from Git through .gitignore because the synthetic datasets can be reproduced from the included R pipeline.



---



## Reproducing the Project



### Step 1 — Generate the Synthetic Truth Layer



Run:



scripts/R/01_build_synthetic_truth_layer.R



### Step 2 — Generate Realistic Raw Business Data



Run:



scripts/R/02_create_raw_business_data.R



### Step 3 — Clean and Validate the Raw Data



Run:



scripts/R/03_clean_validate_raw_data.R



This produces the final analytical datasets used by MySQL.



### Step 4 — Create the MySQL Analytical Schema



Run:



scripts/SQL/01_schema.sql



### Step 5 — Configure Local Data Paths



Before running:



scripts/SQL/02_load_data.sql



replace:



/ABSOLUTE/PATH/TO/PuzzlePop



with the absolute location of the project on the local machine.



### Step 6 — Load the Analytical Datasets



Run:



scripts/SQL/02_load_data.sql



### Step 7 — Validate the Database



Run:



scripts/SQL/03_validation_constraints.sql



Review:



- row grain;

- uniqueness;

- attribution logic;

- relationship coverage.



Then enforce the validated relational constraints.



### Step 8 — Run the Marketing Analysis



Run:



scripts/SQL/04_marketing_analysis.sql



This covers:



Channel

→ Campaign

→ Creative



and connects acquisition efficiency with downstream player quality and marketing economics.



### Step 9 — Run the Experiment Analysis



Run:



scripts/SQL/05_experiment_analysis.sql



This evaluates:



- Control vs Treatment;

- absolute uplift;

- relative uplift;

- statistical significance;

- confidence interval;

- retention outcomes;

- monetization guardrails.



### Step 10 — Create the Tableau Semantic Views



Run:



scripts/SQL/06_tableau_views.sql



This creates:



vw_tableau_channel_performance



vw_tableau_campaign_creative_performance



vw_tableau_experiment_performance



### Step 11 — Open the Tableau Workbook



Open:



tableau/PuzzlePop_Marketing_Analytics.twb



The workbook contains the final three-dashboard analytical product.



---



## Project Limitations



### Synthetic Data



All project data is synthetic and exists solely for portfolio and educational purposes.



The results do not represent the performance of a real company or mobile game.



### Measurement Window



ROAS represents revenue observed within the available synthetic analytical window.



It should not be interpreted as full customer lifetime profitability.



### Attribution



The project simulates an AppsFlyer-style attribution environment but does not reproduce every complexity present in a production mobile-measurement system.



### Creative Analysis



Creative-format findings are observational.



The analysis does not establish that a particular creative format causes higher ROAS.



Observed creative performance may also reflect:



- audience;

- campaign strategy;

- channel;

- concept;

- spend level.



### Experiment Secondary Outcomes



Statistical significance was established for the primary tutorial-completion outcome.



Secondary retention and monetization movements are presented as observed guardrails unless separately tested.



### Profitability



Revenue minus media spend is described as a revenue gap rather than accounting profit.



The project does not model every operating, product, platform, personnel, or infrastructure cost associated with a real mobile-game business.



---



## Executive Takeaway



The central analytical lesson from PuzzlePop is:



**The cheapest acquisition source is not necessarily the strongest source of business value, and the statistically strongest product KPI is not necessarily sufficient for a rollout decision.**



Strong marketing decisions require connecting:



Media Spend

&#x20;   ↓

Acquisition

&#x20;   ↓

Player Quality

&#x20;   ↓

Retention

&#x20;   ↓

Monetization

&#x20;   ↓

ROAS

&#x20;   ↓

Business Decision



Experiment decisions require the same discipline:



Primary Statistical Effect

&#x20;       +

Secondary Outcomes

&#x20;       +

Commercial Guardrails

&#x20;       +

Business Context

&#x20;       ↓

Rollout Decision



The project demonstrates an end-to-end analytical workflow in which R, MySQL, SQL, statistics, Tableau, and business judgment work together to support marketing decisions.



---



## Author



**Monaim**



Data Analytics Portfolio Project



R | MySQL | SQL | Tableau | Git | GitHub



---



## Usage



This repository is intended for educational and portfolio purposes.



All datasets are synthetic and should not be represented as real customer, player, advertising-platform, or company data.





