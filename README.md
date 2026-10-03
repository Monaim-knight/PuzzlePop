# PuzzlePop
analyzes five paid user acquisition channels
# PuzzlePop Marketing Analytics Project

## 1. Business Context

### 1.1 Define the App
PuzzlePop is a fictional casual puzzle mobile game designed for this marketing analytics project. It is available on iOS and Android and monetizes through in-app purchases, rewarded video ads, and interstitial ads. The app relies heavily on paid user acquisition, making it ideal for analyzing marketing performance, attribution, and campaign optimization.

### 1.2 Marketing Channels
This project analyzes five paid user acquisition channels:
1. Facebook Audience Network
2. Snapchat Ads
3. TikTok Ads
4. Google App Campaigns
5. Unity Ads

### 1.3 Business Goals
The primary goal is to increase profitable user acquisition for PuzzlePop. Secondary goals include improving ROAS, optimizing creative performance, increasing retention, and maximizing LTV.

### 1.4 Key Performance Indicators (KPIs)
- Installs
- Cost
- Revenue
- ROAS
- CPI
- CTR
- CVR
- D1/D7 retention
- LTV
- Creative performance metrics

### 1.5 Project Scope
This project includes:
- Synthetic AppsFlyer-style dataset
- SQL analysis layer
- Tableau dashboards
- A/B test analysis
- Budget allocation recommendations
- Final PDF report
- GitHub repository with full documentation
- ## 2. Data Model & Schema
- 

### 2.1 Dimension Tables

#### dim_user
- user_id (PK)
- install_date
- country
- device_type
- attribution_channel
- attribution_campaign

#### dim_channel
- channel_id (PK)
- channel_name

#### dim_campaign
- campaign_id (PK)
- channel_id (FK)
- campaign_name
- creative_id (FK)

#### dim_creative
- creative_id (PK)
- creative_name
- creative_type (video, image)

#### dim_country
- country_code (PK)
- country_name

#### dim_device
- device_type (PK)
- os_version

### 2.2 Fact Tables

#### fact_installs
- install_id (PK)
- user_id (FK)
- campaign_id (FK)
- channel_id (FK)
- install_time
- cost
- impressions
- clicks

#### fact_marketing_spend
- spend_id (PK)
- channel_id (FK)
- campaign_id (FK)
- date
- cost

#### fact_events
- event_id (PK)
- user_id (FK)
- event_type
- event_time
- event_value

#### fact_revenue
- revenue_id (PK)
- user_id (FK)
- revenue_time
- revenue_amount
- revenue_type (IAP, Ad)

#### fact_retention
- retention_id (PK)
- user_id (FK)
- day_number (1, 7)
- retained (0/1)

#### fact_ab_tests
- test_id (PK)
- user_id (FK)
- variant (A/B)
- metric_value
- event_date


