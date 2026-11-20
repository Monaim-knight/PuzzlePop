# =========================================================
# PuzzlePop - Raw Business Data Creation
# =========================================================
#
# Purpose:
# Convert the clean synthetic PuzzlePop truth layer into
# realistic source-style raw datasets containing controlled
# data-quality issues.
#
# These datasets are synthetic and are designed for a
# Marketing Data Analyst portfolio project.
#
# =========================================================

library(tidyverse)

set.seed(202611)

# =========================================================
# LOAD CLEAN SYNTHETIC TRUTH DATA
# =========================================================

truth_ad_delivery <- readRDS(
  "data/truth/truth_ad_delivery.rds"
)

truth_installs <- readRDS(
  "data/truth/truth_installs.rds"
)

truth_user_behavior <- readRDS(
  "data/truth/truth_user_behavior.rds"
)

truth_monetization <- readRDS(
  "data/truth/truth_monetization.rds"
)

truth_experiment <- readRDS(
  "data/truth/truth_experiment.rds"
)
# Validation 
# ---------------------------------------------------------
# Validate loaded truth datasets
# ---------------------------------------------------------

loaded_truth_qa <- tibble(
  
  dataset = c(
    "ad_delivery",
    "installs",
    "user_behavior",
    "monetization",
    "experiment"
  ),
  
  rows = c(
    nrow(truth_ad_delivery),
    nrow(truth_installs),
    nrow(truth_user_behavior),
    nrow(truth_monetization),
    nrow(truth_experiment)
  )
)

loaded_truth_qa
loaded_truth_qa |>
  summarise(
    datasets_loaded = n(),
    missing_or_empty =
      sum(is.na(rows) | rows == 0)
  )

# =========================================================
# RAW AD-DELIVERY DATA
# =========================================================
#
# Purpose:
# Create the analyst-facing ad-platform dataset.
# Controlled real-world data-quality problems will be
# introduced into this copy only.
#
# The clean truth object remains unchanged.
# =========================================================

raw_ad_delivery <- truth_ad_delivery

# Validation 
raw_ad_delivery_qa <- tibble(
  
  truth_rows =
    nrow(truth_ad_delivery),
  
  raw_rows =
    nrow(raw_ad_delivery),
  
  identical_before_messiness =
    identical(
      truth_ad_delivery,
      raw_ad_delivery
    )
)

raw_ad_delivery_qa

# ---------------------------------------------------------
# ISSUE 1 - Inconsistent channel naming
# ---------------------------------------------------------

raw_ad_delivery <- raw_ad_delivery |>
  mutate(
    channel_original = channel
  )
# a small subset to corrupt 
set.seed(202612)

channel_issue_rows <- sample(
  seq_len(nrow(raw_ad_delivery)),
  size = round(
    nrow(raw_ad_delivery) * 0.015
  ),
  replace = FALSE
)
# Create Naming variations 
raw_ad_delivery$channel[
  channel_issue_rows
] <- case_when(
  
  raw_ad_delivery$channel[
    channel_issue_rows
  ] == "Facebook Audience Network" ~
    sample(
      c(
        "facebook",
        "Facebook Ads",
        "FB Audience Network",
        "FACEBOOK"
      ),
      length(channel_issue_rows),
      replace = TRUE
    ),
  
  raw_ad_delivery$channel[
    channel_issue_rows
  ] == "TikTok Ads" ~
    sample(
      c(
        "tiktok",
        "Tik Tok Ads",
        "TIKTOK",
        "TikTok"
      ),
      length(channel_issue_rows),
      replace = TRUE
    ),
  
  raw_ad_delivery$channel[
    channel_issue_rows
  ] == "Google App Campaigns" ~
    sample(
      c(
        "google",
        "Google Ads",
        "GGL App Campaigns",
        "GOOGLE"
      ),
      length(channel_issue_rows),
      replace = TRUE
    ),
  
  raw_ad_delivery$channel[
    channel_issue_rows
  ] == "Snapchat Ads" ~
    sample(
      c(
        "snapchat",
        "Snap Ads",
        "SNAPCHAT",
        "Snapchat"
      ),
      length(channel_issue_rows),
      replace = TRUE
    ),
  
  raw_ad_delivery$channel[
    channel_issue_rows
  ] == "Unity Ads" ~
    sample(
      c(
        "unity",
        "Unity",
        "UNITY ADS",
        "UnityAds"
      ),
      length(channel_issue_rows),
      replace = TRUE
    ),
  
  TRUE ~
    raw_ad_delivery$channel[
      channel_issue_rows
    ]
)
# Validation- the injected issue 
channel_issue_qa <- raw_ad_delivery |>
  summarise(
    
    total_rows = n(),
    
    changed_channel_rows =
      sum(
        channel != channel_original
      ),
    
    changed_share =
      mean(
        channel != channel_original
      )
  )

channel_issue_qa |>
  print(width = Inf)

# Inspect the messey channel values 
raw_ad_delivery |>
  filter(
    channel != channel_original
  ) |>
  count(
    channel_original,
    channel,
    sort = TRUE
  ) |>
  print(
    n = Inf
  )

# =========================================================
# ISSUE 2 - INCONSISTENT CAMPAIGN NAMING
# =========================================================

raw_ad_delivery <- raw_ad_delivery |>
  mutate(
    campaign_name_original =
      campaign_name
  )
# Select (1%) of records 
set.seed(202613)

campaign_issue_rows <- sample(
  
  seq_len(
    nrow(raw_ad_delivery)
  ),
  
  size = round(
    nrow(raw_ad_delivery) * 0.01
  ),
  
  replace = FALSE
)
# Chossing different inconsistency types 
campaign_issue_type <- sample(
  
  c(
    "lowercase",
    "hyphenated",
    "version_suffix"
  ),
  
  size =
    length(campaign_issue_rows),
  
  replace = TRUE
)
# Appy the campaign name variations 
current_campaign_names <-
  raw_ad_delivery$campaign_name[
    campaign_issue_rows
  ]

raw_ad_delivery$campaign_name[
  campaign_issue_rows
] <- case_when(
  
  campaign_issue_type ==
    "lowercase" ~
    
    str_to_lower(
      current_campaign_names
    ),
  
  campaign_issue_type ==
    "hyphenated" ~
    
    str_replace_all(
      current_campaign_names,
      "_",
      "-"
    ),
  
  campaign_issue_type ==
    "version_suffix" ~
    
    paste0(
      current_campaign_names,
      "_v2"
    )
)

# Validation 
campaign_issue_qa <- raw_ad_delivery |>
  summarise(
    
    total_rows =
      n(),
    
    changed_campaign_rows =
      sum(
        campaign_name !=
          campaign_name_original
      ),
    
    changed_share =
      mean(
        campaign_name !=
          campaign_name_original
      )
  )

campaign_issue_qa |>
  print(width = Inf)
# Inspect the actual variations 
raw_ad_delivery |>
  filter(
    campaign_name !=
      campaign_name_original
  ) |>
  count(
    campaign_name_original,
    campaign_name,
    sort = TRUE
  ) |>
  head(20) |>
  print(
    width = Inf
  )
# =========================================================
# ISSUE 3 - MISSING CREATIVE IDENTIFIERS
# =========================================================

raw_ad_delivery <- raw_ad_delivery |>
  mutate(
    creative_id_original =
      creative_id
  )
# Select (0.50%) of rows 
set.seed(202614)

creative_missing_rows <- sample(
  seq_len(
    nrow(raw_ad_delivery)
  ),
  size = round(
    nrow(raw_ad_delivery) * 0.005
  ),
  replace = FALSE
)
# Remove those creative IDs
raw_ad_delivery$creative_id[
  creative_missing_rows
] <- NA_character_

# Validation
creative_missing_qa <- raw_ad_delivery |>
  summarise(
    
    total_rows =
      n(),
    
    missing_creative_ids =
      sum(
        is.na(creative_id)
      ),
    
    missing_share =
      mean(
        is.na(creative_id)
      ),
    
    original_missing_creative_ids =
      sum(
        is.na(creative_id_original)
      )
  )

creative_missing_qa |>
  print(width = Inf)


# =========================================================
# ISSUE 4 - DUPLICATE AD-DELIVERY RECORDS
# =========================================================

raw_ad_delivery <- raw_ad_delivery |>
  mutate(
    raw_row_id = sprintf(
      "AD_%07d",
      row_number()
    )
  )

set.seed(202615)

duplicate_source_rows <- sample(
  seq_len(
    nrow(raw_ad_delivery)
  ),
  size = round(
    nrow(raw_ad_delivery) * 0.003
  ),
  replace = FALSE
)


duplicate_records <- raw_ad_delivery[
  duplicate_source_rows,
]

raw_ad_delivery <- bind_rows(
  raw_ad_delivery,
  duplicate_records
)
# Validation 
duplicate_issue_qa <- raw_ad_delivery |>
  summarise(
    
    total_rows_after_duplicates =
      n(),
    
    unique_raw_row_ids =
      n_distinct(raw_row_id),
    
    duplicate_rows =
      n() -
      n_distinct(raw_row_id),
    
    duplicate_share =
      duplicate_rows /
      n()
  )

duplicate_issue_qa |>
  print(width = Inf)
# Inspect some actual duplicates 
raw_ad_delivery |>
  count(
    raw_row_id,
    sort = TRUE
  ) |>
  filter(
    n > 1
  ) |>
  head(10) |>
  print(width = Inf)

# =========================================================
# ISSUE 5 - INCONSISTENT SPEND FORMATTING
# =========================================================

raw_ad_delivery <- raw_ad_delivery |>
  mutate(
    
    spend_raw = sprintf(
      "%.2f",
      spend
    )
  )

set.seed(202616)

spend_issue_rows <- sample(
  
  seq_len(
    nrow(raw_ad_delivery)
  ),
  
  size = round(
    nrow(raw_ad_delivery) * 0.004
  ),
  
  replace = FALSE
)

spend_issue_type <- sample(
  
  c(
    "currency_symbol",
    "decimal_comma",
    "trailing_space"
  ),
  
  size =
    length(spend_issue_rows),
  
  replace = TRUE
)
# Apply the formatting issues 
current_spend_values <-
  raw_ad_delivery$spend_raw[
    spend_issue_rows
  ]

raw_ad_delivery$spend_raw[
  spend_issue_rows
] <- case_when(
  
  spend_issue_type ==
    "currency_symbol" ~
    
    paste0(
      "€",
      current_spend_values
    ),
  
  spend_issue_type ==
    "decimal_comma" ~
    
    str_replace(
      current_spend_values,
      "\\.",
      ","
    ),
  
  spend_issue_type ==
    "trailing_space" ~
    
    paste0(
      current_spend_values,
      " "
    )
)
# Validation 
spend_format_qa <- tibble(
  
  total_rows =
    nrow(raw_ad_delivery),
  
  injected_spend_issues =
    length(spend_issue_rows),
  
  injected_share =
    length(spend_issue_rows) /
    nrow(raw_ad_delivery)
)

spend_format_qa |>
  print(width = Inf)

raw_ad_delivery |>
  slice(
    spend_issue_rows
  ) |>
  select(
    raw_row_id,
    spend,
    spend_raw
  ) |>
  head(20) |>
  print(width = Inf)
# =========================================================
# BUILD ANALYST-FACING RAW AD-DELIVERY EXPORT
# =========================================================

raw_ad_delivery_export <- raw_ad_delivery |>
  select(
    -channel_original,
    -campaign_name_original,
    -creative_id_original,
    -spend
  )

raw_export_qa <- tibble(
  
  rows =
    nrow(raw_ad_delivery_export),
  
  has_channel_original =
    "channel_original" %in%
    names(raw_ad_delivery_export),
  
  has_campaign_original =
    "campaign_name_original" %in%
    names(raw_ad_delivery_export),
  
  has_creative_original =
    "creative_id_original" %in%
    names(raw_ad_delivery_export),
  
  has_clean_spend =
    "spend" %in%
    names(raw_ad_delivery_export),
  
  has_raw_spend =
    "spend_raw" %in%
    names(raw_ad_delivery_export)
)

raw_export_qa |>
  print(width = Inf)
# =========================================================
# EXPORT ANALYST-FACING RAW AD-DELIVERY DATA
# =========================================================

dir.create(
  "data/raw",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  raw_ad_delivery_export,
  "data/raw/raw_ad_delivery.csv"
)

# Validation 
raw_ad_delivery_check <- read_csv(
  "data/raw/raw_ad_delivery.csv",
  show_col_types = FALSE
)


raw_ad_delivery_export_qa <- tibble(
  
  expected_rows =
    nrow(raw_ad_delivery_export),
  
  exported_rows =
    nrow(raw_ad_delivery_check),
  
  expected_columns =
    ncol(raw_ad_delivery_export),
  
  exported_columns =
    ncol(raw_ad_delivery_check),
  
  file_exists =
    file.exists(
      "data/raw/raw_ad_delivery.csv"
    )
)

raw_ad_delivery_export_qa |>
  print(width = Inf)

raw_ad_delivery_check |>
  summarise(
    
    missing_creative_ids =
      sum(is.na(creative_id)),
    
    duplicate_raw_ids =
      n() - n_distinct(raw_row_id),
    
    messy_spend_rows =
      sum(
        str_detect(
          spend_raw,
          "€|,|\\s$"
        ),
        na.rm = TRUE
      )
  ) |>
  print(width = Inf)

raw_ad_delivery_check_no_trim <- read_csv(
  "data/raw/raw_ad_delivery.csv",
  show_col_types = FALSE,
  trim_ws = FALSE
)

raw_ad_delivery_check_no_trim |>
  summarise(
    
    messy_spend_rows =
      sum(
        str_detect(
          spend_raw,
          "€|,|\\s$"
        ),
        na.rm = TRUE
      )
  )

# =========================================================
# 6A.5.10D - RAW INSTALL & ATTRIBUTION DATA
# =========================================================
#
# Purpose:
# Create an analyst-facing mobile attribution dataset
# from the validated synthetic install truth.
#
# Controlled attribution-quality issues will be added
# only to this copy.
# =========================================================

raw_installs <- truth_installs
# Validation 
raw_installs_baseline_qa <- tibble(
  
  truth_rows =
    nrow(truth_installs),
  
  raw_rows =
    nrow(raw_installs),
  
  identical_before_messiness =
    identical(
      truth_installs,
      raw_installs
    )
)

raw_installs_baseline_qa |>
  print(width = Inf)

# =========================================================
# ISSUE 1 - MISSING PAID ATTRIBUTION
# =========================================================

raw_installs <- raw_installs |>
  mutate(
    campaign_id_original = campaign_id,
    creative_id_original = creative_id
  )

# Only paid users 
paid_install_rows <- which(
  raw_installs$acquisition_type == "Paid"
)

set.seed(202617)

missing_attribution_rows <- sample(
  paid_install_rows,
  size = round(
    length(paid_install_rows) * 0.005
  ),
  replace = FALSE
)

raw_installs$campaign_id[
  missing_attribution_rows
] <- NA_character_

raw_installs$creative_id[
  missing_attribution_rows
] <- NA_character_

###########################################
paid_attribution_issue_qa <- raw_installs |>
  summarise(
    
    paid_users =
      sum(
        acquisition_type == "Paid"
      ),
    
    paid_missing_campaign =
      sum(
        acquisition_type == "Paid" &
          is.na(campaign_id)
      ),
    
    paid_missing_creative =
      sum(
        acquisition_type == "Paid" &
          is.na(creative_id)
      ),
    
    organic_missing_campaign =
      sum(
        acquisition_type == "Organic" &
          is.na(campaign_id)
      ),
    
    original_paid_missing_campaign =
      sum(
        acquisition_type == "Paid" &
          is.na(campaign_id_original)
      )
  )

paid_attribution_issue_qa |>
  print(width = Inf)

# =========================================================
# ISSUE 2 - DUPLICATE INSTALL / POSTBACK RECORDS
# =========================================================

raw_installs <- raw_installs |>
  mutate(
    raw_install_row_id = sprintf(
      "INS_%07d",
      row_number()
    )
  )
# Select 0.25%
set.seed(202618)

duplicate_install_rows <- sample(
  seq_len(
    nrow(raw_installs)
  ),
  
  size = round(
    nrow(raw_installs) * 0.0025
  ),
  
  replace = FALSE
)
# Extract these records 

duplicate_install_records <- raw_installs[
  duplicate_install_rows,
]
# Append 
raw_installs <- bind_rows(
  raw_installs,
  duplicate_install_records
)
# Validation 
duplicate_install_qa <- raw_installs |>
  summarise(
    
    total_rows =
      n(),
    
    unique_raw_install_ids =
      n_distinct(
        raw_install_row_id
      ),
    
    duplicate_records =
      n() -
      n_distinct(
        raw_install_row_id
      ),
    
    duplicate_share =
      duplicate_records /
      n()
  )

duplicate_install_qa |>
  print(width = Inf)
# Inspect a few 
raw_installs |>
  count(
    raw_install_row_id,
    sort = TRUE
  ) |>
  filter(
    n > 1
  ) |>
  head(10) |>
  print(width = Inf)

duplicate_install_distribution <- raw_installs |>
  count(
    raw_install_row_id,
    name = "record_count"
  ) |>
  count(
    record_count,
    name = "install_id_count"
  ) |>
  arrange(
    record_count
  )

duplicate_install_distribution |>
  print(width = Inf)

# =========================================================
# 6A.5.10D.3 - BUILD ANALYST-FACING ATTRIBUTION EXPORT
# =========================================================

raw_installs_export <- raw_installs |>
  select(
    
    # Raw source record
    raw_install_row_id,
    
    # User identifiers
    appsflyer_id,
    customer_user_id,
    
    # Attribution timing
    install_time,
    attributed_touch_time,
    attributed_touch_type,
    
    # Acquisition source
    acquisition_type,
    channel,
    
    # Campaign attribution
    campaign_id,
    campaign_name,
    
    # Creative attribution
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    
    # Market context
    country_code,
    country_name,
    platform,
    
    # Attribution context
    campaign_type,
    is_organic,
    is_retargeting,
    attribution_provider
  )

# Check that hidden files did not leak 
raw_installs_export_qa <- tibble(
  
  rows =
    nrow(raw_installs_export),
  
  columns =
    ncol(raw_installs_export),
  
  has_campaign_original =
    "campaign_id_original" %in%
    names(raw_installs_export),
  
  has_creative_original =
    "creative_id_original" %in%
    names(raw_installs_export),
  
  has_retention_modifier =
    "retention_modifier" %in%
    names(raw_installs_export),
  
  has_payer_probability =
    "payer_probability" %in%
    names(raw_installs_export),
  
  has_expected_install_cvr =
    "expected_install_cvr" %in%
    names(raw_installs_export)
)

raw_installs_export_qa |>
  print(width = Inf)
# Confirm  problems survived 
raw_installs_integrity_qa <- raw_installs_export |>
  summarise(
    
    total_rows =
      n(),
    
    unique_source_records =
      n_distinct(raw_install_row_id),
    
    duplicate_source_records =
      n() -
      n_distinct(raw_install_row_id),
    
    paid_missing_campaign =
      sum(
        acquisition_type == "Paid" &
          is.na(campaign_id)
      ),
    
    paid_missing_creative =
      sum(
        acquisition_type == "Paid" &
          is.na(creative_id)
      ),
    
    organic_missing_campaign =
      sum(
        acquisition_type == "Organic" &
          is.na(campaign_id)
      )
  )

raw_installs_integrity_qa |>
  print(width = Inf)
# =========================================================
# 6A.5.10D.4 - EXPORT RAW INSTALL / ATTRIBUTION DATA
# =========================================================

write_csv(
  raw_installs_export,
  "data/raw/raw_installs.csv"
)
file.exists(
  "data/raw/raw_installs.csv"
)
list.files(
  "data/raw"
)
raw_installs_check <- read_csv(
  "data/raw/raw_installs.csv",
  show_col_types = FALSE
)
# Vaidation 
raw_installs_file_qa <- tibble(
  
  expected_rows =
    nrow(raw_installs_export),
  
  exported_rows =
    nrow(raw_installs_check),
  
  expected_columns =
    ncol(raw_installs_export),
  
  exported_columns =
    ncol(raw_installs_check),
  
  file_exists =
    file.exists(
      "data/raw/raw_installs.csv"
    )
)

raw_installs_file_qa |>
  print(width = Inf)
# Data quality 
raw_installs_file_integrity_qa <- raw_installs_check |>
  summarise(
    
    duplicate_source_records =
      n() -
      n_distinct(raw_install_row_id),
    
    paid_missing_campaign =
      sum(
        acquisition_type == "Paid" &
          is.na(campaign_id)
      ),
    
    paid_missing_creative =
      sum(
        acquisition_type == "Paid" &
          is.na(creative_id)
      ),
    
    organic_missing_campaign =
      sum(
        acquisition_type == "Organic" &
          is.na(campaign_id)
      )
  )

raw_installs_file_integrity_qa |>
  print(width = Inf)
# =========================================================
# 6A.5.10E - RAW USER PERFORMANCE DATA
# =========================================================
#
# Purpose:
# Create an analyst-facing player-quality and monetization
# dataset for retention, engagement, revenue, and LTV/ROAS
# analysis.
# =========================================================

raw_user_performance <- truth_monetization

# Validate baseline only 
raw_user_performance_baseline_qa <- tibble(
  
  truth_rows =
    nrow(truth_monetization),
  
  raw_rows =
    nrow(raw_user_performance),
  
  identical_before_messiness =
    identical(
      truth_monetization,
      raw_user_performance
    )
)

raw_user_performance_baseline_qa |>
  print(width = Inf)
# =========================================================
# ISSUE 1 - MISSING USER IDENTIFIERS
# =========================================================

raw_user_performance <- raw_user_performance |>
  mutate(
    customer_user_id_original =
      customer_user_id
  )
# Select 0.30% of users 
set.seed(202619)

missing_user_id_rows <- sample(
  seq_len(
    nrow(raw_user_performance)
  ),
  
  size = round(
    nrow(raw_user_performance) * 0.003
  ),
  
  replace = FALSE
)
# Removing their Business ID 
raw_user_performance$customer_user_id[
  missing_user_id_rows
] <- NA_character_
# Validation 
user_id_issue_qa <- raw_user_performance |>
  summarise(
    
    total_rows =
      n(),
    
    missing_customer_user_ids =
      sum(
        is.na(customer_user_id)
      ),
    
    missing_share =
      mean(
        is.na(customer_user_id)
      ),
    
    original_missing_ids =
      sum(
        is.na(customer_user_id_original)
      )
  )

user_id_issue_qa |>
  print(width = Inf)

# =========================================================
# ISSUE 2 - INCONSISTENT IAP REVENUE FORMATTING
# =========================================================

raw_user_performance <- raw_user_performance |>
  mutate(
    iap_revenue_raw =
      sprintf(
        "%.2f",
        iap_revenue
      )
  )
# First identify users with revenue
positive_iap_rows <- which(
  raw_user_performance$iap_revenue > 0
)

# Select 2% of revenue records 
set.seed(202620)

iap_format_issue_rows <- sample(
  positive_iap_rows,
  
  size = round(
    length(positive_iap_rows) * 0.02
  ),
  
  replace = FALSE
)
# Defining the formatting problems 
iap_format_issue_type <- sample(
  c(
    "currency_symbol",
    "decimal_comma",
    "trailing_space"
  ),
  
  size =
    length(iap_format_issue_rows),
  
  replace = TRUE
)
# Applying the formating problems 
current_iap_values <-
  raw_user_performance$iap_revenue_raw[
    iap_format_issue_rows
  ]

raw_user_performance$iap_revenue_raw[
  iap_format_issue_rows
] <- case_when(
  
  iap_format_issue_type ==
    "currency_symbol" ~
    
    paste0(
      "€",
      current_iap_values
    ),
  
  iap_format_issue_type ==
    "decimal_comma" ~
    
    str_replace(
      current_iap_values,
      "\\.",
      ","
    ),
  
  iap_format_issue_type ==
    "trailing_space" ~
    
    paste0(
      current_iap_values,
      " "
    )
)
# Validation 
iap_format_issue_qa <- tibble(
  
  revenue_users =
    length(positive_iap_rows),
  
  injected_iap_issues =
    length(iap_format_issue_rows),
  
  issue_share_of_revenue_users =
    length(iap_format_issue_rows) /
    length(positive_iap_rows)
)

iap_format_issue_qa |>
  print(width = Inf)
# Inspect the 88 malformed IAP values 
raw_user_performance |>
  slice(
    iap_format_issue_rows
  ) |>
  select(
    customer_user_id,
    iap_revenue,
    iap_revenue_raw
  ) |>
  head(15) |>
  print(width = Inf)

# =========================================================
# BUILD ANALYST-FACING RAW USER PERFORMANCE EXPORT
# =========================================================

raw_user_performance_export <- raw_user_performance |>
  select(
    appsflyer_id,
    customer_user_id,
    
    # Engagement
    sessions_first_7d,
    
    # Retention
    retained_d1,
    retained_d7,
    retained_d30,
    
    # Monetization
    is_payer,
    purchase_count,
    iap_revenue_raw,
    ad_impressions,
    ad_revenue,
    total_revenue
  )
# Validation 
user_performance_export_qa <- tibble(
  
  rows =
    nrow(raw_user_performance_export),
  
  columns =
    ncol(raw_user_performance_export),
  
  has_original_user_id =
    "customer_user_id_original" %in%
    names(raw_user_performance_export),
  
  has_clean_iap_revenue =
    "iap_revenue" %in%
    names(raw_user_performance_export),
  
  has_raw_iap_revenue =
    "iap_revenue_raw" %in%
    names(raw_user_performance_export),
  
  has_hidden_engagement_score =
    "engagement_score" %in%
    names(raw_user_performance_export)
)

user_performance_export_qa |>
  print(width = Inf)
# Export Raw_user_performance.csv
write_csv(
  raw_user_performance_export,
  "data/raw/raw_user_performance.csv"
)
file.exists(
  "data/raw/raw_user_performance.csv"
)
raw_user_performance_check <- read_csv(
  "data/raw/raw_user_performance.csv",
  show_col_types = FALSE,
  trim_ws = FALSE
)
# Inspecting the parsing problems 
problems(
  raw_user_performance_check
) |>
  print(
    n = 30,
    width = Inf
  )
# Fixing 
raw_user_performance_check <- read_csv(
  "data/raw/raw_user_performance.csv",
  col_types = cols(
    iap_revenue_raw = col_character()
  ),
  trim_ws = FALSE
)
# Validate the corrupt import 
problems(
  raw_user_performance_check
)

raw_user_performance_file_qa <- tibble(
  
  expected_rows =
    nrow(raw_user_performance_export),
  
  exported_rows =
    nrow(raw_user_performance_check),
  
  expected_columns =
    ncol(raw_user_performance_export),
  
  exported_columns =
    ncol(raw_user_performance_check),
  
  file_exists =
    file.exists(
      "data/raw/raw_user_performance.csv"
    )
)

raw_user_performance_file_qa |>
  print(width = Inf)

raw_user_performance_file_integrity_qa <-
  raw_user_performance_check |>
  summarise(
    
    missing_customer_user_ids =
      sum(
        is.na(customer_user_id)
      ),
    
    messy_iap_revenue_rows =
      sum(
        str_detect(
          iap_revenue_raw,
          "€|,|\\s$"
        ),
        na.rm = TRUE
      )
  )

raw_user_performance_file_integrity_qa |>
  print(width = Inf)

# =========================================================
# 6A.5.10F - RAW EXPERIMENT DATA
# FINAL RAW SOURCE
# =========================================================

raw_experiment <- truth_experiment
# Baseline validation 
raw_experiment_baseline_qa <- tibble(
  
  truth_rows =
    nrow(truth_experiment),
  
  raw_rows =
    nrow(raw_experiment),
  
  identical =
    identical(
      truth_experiment,
      raw_experiment
    )
)

raw_experiment_baseline_qa |>
  print(width = Inf)
# Building the analyst-facing schema 
raw_experiment_export <- raw_experiment |>
  select(
    
    # User identifier
    customer_user_id,
    
    # Experiment
    experiment_id,
    experiment_variant,
    
    # Primary experiment outcome
    tutorial_completed,
    
    # Secondary business outcomes
    retained_d1,
    retained_d7,
    retained_d30,
    is_payer,
    
    # Monetization
    total_revenue
  )
# Validation- THe experiment schema 
experiment_export_qa <- raw_experiment_export |>
  summarise(
    
    rows =
      n(),
    
    unique_users =
      n_distinct(customer_user_id),
    
    missing_user_ids =
      sum(is.na(customer_user_id)),
    
    missing_experiment_ids =
      sum(is.na(experiment_id)),
    
    missing_variants =
      sum(is.na(experiment_variant)),
    
    missing_primary_outcome =
      sum(is.na(tutorial_completed)),
    
    invalid_primary_outcome =
      sum(
        !tutorial_completed %in%
          c(0, 1)
      )
  )

experiment_export_qa |>
  print(width = Inf)
# Verify randomization and primary outcome survived 
raw_experiment_export |>
  group_by(
    experiment_variant
  ) |>
  summarise(
    
    users =
      n(),
    
    tutorial_completion_rate =
      mean(tutorial_completed),
    
    .groups = "drop"
  ) |>
  print(width = Inf)
# =========================================================
# EXPORT FINAL RAW SOURCE - EXPERIMENT DATA
# =========================================================

write_csv(
  raw_experiment_export,
  "data/raw/raw_experiment.csv"
)
file.exists(
  "data/raw/raw_experiment.csv"
)
raw_experiment_check <- read_csv(
  "data/raw/raw_experiment.csv",
  show_col_types = FALSE
)

raw_experiment_file_qa <- raw_experiment_check |>
  summarise(
    
    rows = n(),
    
    unique_users =
      n_distinct(customer_user_id),
    
    control_users =
      sum(experiment_variant == "Control"),
    
    treatment_users =
      sum(experiment_variant == "Treatment"),
    
    control_completion_rate =
      mean(
        tutorial_completed[
          experiment_variant == "Control"
        ]
      ),
    
    treatment_completion_rate =
      mean(
        tutorial_completed[
          experiment_variant == "Treatment"
        ]
      ),
    
    missing_values =
      sum(is.na(raw_experiment_check))
  )

raw_experiment_file_qa |>
  print(width = Inf)

list.files(
  "data/raw"
)