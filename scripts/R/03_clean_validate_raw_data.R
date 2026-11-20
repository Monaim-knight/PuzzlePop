# =========================================================
# PuzzlePop - Raw Data Profiling & Cleaning
# =========================================================
#
# Purpose:
# Profile, investigate, clean, and validate the synthetic
# raw business datasets used in the PuzzlePop Marketing

# Workflow:
# Raw -> Profile -> Investigate -> Clean -> Validate

# =========================================================

library(tidyverse)
###########################################################
#  What data did I receive?
########################################################
# =========================================================
# 6B.2 - RAW SOURCE INVENTORY
# =========================================================

raw_files <- list.files(
  "data/raw",
  pattern = "\\.csv$",
  full.names = TRUE
)

raw_files
# Vfalidate the inventory 
length(raw_files)
basename(raw_files)

#---------------------------------------------------------
# Load datasets
#------------------------------------------------------
# =========================================================
# 6B.2B - CONTROLLED RAW DATA INGESTION
# =========================================================

raw_ad_delivery <- read_csv(
  "data/raw/raw_ad_delivery.csv",
  col_types = cols(
    spend_raw = col_character()
  ),
  trim_ws = FALSE
)

raw_installs <- read_csv(
  "data/raw/raw_installs.csv",
  show_col_types = FALSE
)

raw_user_performance <- read_csv(
  "data/raw/raw_user_performance.csv",
  col_types = cols(
    iap_revenue_raw = col_character()
  ),
  trim_ws = FALSE
)

raw_experiment <- read_csv(
  "data/raw/raw_experiment.csv",
  show_col_types = FALSE
)
# Validation - Ingestion 
ingestion_qa <- tibble(
  
  dataset = c(
    "ad_delivery",
    "installs",
    "user_performance",
    "experiment"
  ),
  
  rows = c(
    nrow(raw_ad_delivery),
    nrow(raw_installs),
    nrow(raw_user_performance),
    nrow(raw_experiment)
  ),
  
  columns = c(
    ncol(raw_ad_delivery),
    ncol(raw_installs),
    ncol(raw_user_performance),
    ncol(raw_experiment)
  )
)

ingestion_qa

# Check parsing problems 
tibble(
  dataset = c(
    "ad_delivery",
    "installs",
    "user_performance",
    "experiment"
  ),
  
  parsing_problems = c(
    nrow(problems(raw_ad_delivery)),
    nrow(problems(raw_installs)),
    nrow(problems(raw_user_performance)),
    nrow(problems(raw_experiment))
  )
)

# =========================================================
# 6B.3 - SOURCE GRAIN & KEY PROFILING
# =========================================================

names(raw_ad_delivery)
names(raw_installs)
names(raw_user_performance)
names(raw_experiment)


#---------------------------------------
# Candidate-key uniqueness
#-----------------------------------------
raw_ad_delivery |>
  summarise(
    rows = n(),
    unique_raw_row_ids = n_distinct(raw_row_id)
  )

raw_installs |>
  summarise(
    rows = n(),
    unique_raw_install_ids =
      n_distinct(raw_install_row_id),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_user_ids =
      n_distinct(customer_user_id)
  )

raw_user_performance |>
  summarise(
    rows = n(),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_user_ids =
      n_distinct(customer_user_id),
    
    missing_customer_user_ids =
      sum(is.na(customer_user_id))
  )

# Experiement 
raw_experiment |>
  summarise(
    rows = n(),
    
    unique_users =
      n_distinct(customer_user_id),
    
    unique_experiments =
      n_distinct(experiment_id)
  )

# =========================================================
# 6B.4 - USER-KEY RELATIONSHIP PROFILING
# =========================================================

install_user_key_map <- raw_installs |>
  select(
    appsflyer_id,
    customer_user_id
  ) |>
  distinct()
# Test both directions 
appsflyer_to_customer_qa <- install_user_key_map |>
  group_by(
    appsflyer_id
  ) |>
  summarise(
    customer_ids =
      n_distinct(
        customer_user_id,
        na.rm = TRUE
      ),
    .groups = "drop"
  ) |>
  summarise(
    appsflyer_ids = n(),
    appsflyer_ids_without_customer =
      sum(customer_ids == 0),
    appsflyer_ids_with_multiple_customers =
      sum(customer_ids > 1)
  )

appsflyer_to_customer_qa |>
  print(width = Inf)

# The reverse relationship 
customer_to_appsflyer_qa <- install_user_key_map |>
  group_by(
    customer_user_id
  ) |>
  summarise(
    appsflyer_ids =
      n_distinct(
        appsflyer_id,
        na.rm = TRUE
      ),
    .groups = "drop"
  ) |>
  summarise(
    customer_ids = n(),
    customer_ids_without_appsflyer =
      sum(appsflyer_ids == 0),
    customer_ids_with_multiple_appsflyer =
      sum(appsflyer_ids > 1)
  )

customer_to_appsflyer_qa |>
  print(width = Inf)

# Test user-performance coverage 
user_performance_key_coverage <- raw_user_performance |>
  summarise(
    performance_rows = n(),
    
    missing_customer_user_ids =
      sum(
        is.na(customer_user_id)
      ),
    
    appsflyer_ids_not_in_installs =
      sum(
        !appsflyer_id %in%
          install_user_key_map$appsflyer_id
      )
  )

user_performance_key_coverage |>
  print(width = Inf)

# =========================================================
# 6B.5 - MISSINGNESS PROFILING
# Profile missingness across the four sources
# =========================================================

profile_missingness <- function(data, dataset_name) {
  
  tibble(
    dataset = dataset_name,
    column = names(data),
    rows = nrow(data),
    missing_count = map_int(
      data,
      ~ sum(is.na(.x))
    )
  ) |>
    mutate(
      missing_share =
        missing_count / rows
    ) |>
    filter(
      missing_count > 0
    ) |>
    arrange(
      desc(missing_count)
    )
}

# Profiling 
missingness_profile <- bind_rows(
  
  profile_missingness(
    raw_ad_delivery,
    "ad_delivery"
  ),
  
  profile_missingness(
    raw_installs,
    "installs"
  ),
  
  profile_missingness(
    raw_user_performance,
    "user_performance"
  ),
  
  profile_missingness(
    raw_experiment,
    "experiment"
  )
)

missingness_profile |>
  print(
    n = Inf,
    width = Inf
  )

# =========================================================
# 6B.5A - PROFILE RECOVERABILITY OF PAID ATTRIBUTION NULLS
# =========================================================

paid_missing_attribution <- raw_installs |>
  filter(
    acquisition_type == "Paid",
    is.na(campaign_id) |
      is.na(creative_id)
  )


paid_missing_attribution |>
  summarise(
    rows = n(),
    
    missing_campaign_id =
      sum(is.na(campaign_id)),
    
    missing_creative_id =
      sum(is.na(creative_id)),
    
    available_campaign_name =
      sum(!is.na(campaign_name)),
    
    available_creative_name =
      sum(!is.na(creative_name))
  ) |>
  print(width = Inf)

# Validation - name- to ID mappings 
campaign_name_mapping_qa <- raw_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(campaign_id),
    !is.na(campaign_name)
  ) |>
  distinct(
    campaign_name,
    campaign_id
  ) |>
  count(
    campaign_name,
    name = "mapped_campaign_ids"
  ) |>
  summarise(
    campaign_names = n(),
    
    ambiguous_campaign_names =
      sum(mapped_campaign_ids > 1)
  )

campaign_name_mapping_qa |>
  print(width = Inf)


creative_name_mapping_qa <- raw_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(creative_id),
    !is.na(creative_name)
  ) |>
  distinct(
    creative_name,
    creative_id
  ) |>
  count(
    creative_name,
    name = "mapped_creative_ids"
  ) |>
  summarise(
    creative_names = n(),
    
    ambiguous_creative_names =
      sum(mapped_creative_ids > 1)
  )

creative_name_mapping_qa |>
  print(width = Inf)

# =========================================================
# 6B.5B - VALIDATE ATTRIBUTION-MAPPING COVERAGE
# =========================================================

campaign_id_map <- raw_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(campaign_id),
    !is.na(campaign_name)
  ) |>
  distinct(
    campaign_name,
    campaign_id
  )

creative_id_map <- raw_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(creative_id),
    !is.na(creative_name)
  ) |>
  distinct(
    creative_name,
    creative_id
  )
unmatched_campaign_names <- paid_missing_attribution |>
  distinct(
    campaign_name
  ) |>
  anti_join(
    campaign_id_map,
    by = "campaign_name"
  )

unmatched_campaign_names


unmatched_creative_names <- paid_missing_attribution |>
  distinct(
    creative_name
  ) |>
  anti_join(
    creative_id_map,
    by = "creative_name"
  )

unmatched_creative_names

# Quantify recoverable rows 
attribution_recovery_coverage <- paid_missing_attribution |>
  left_join(
    campaign_id_map |>
      rename(
        recovered_campaign_id =
          campaign_id
      ),
    by = "campaign_name"
  ) |>
  left_join(
    creative_id_map |>
      rename(
        recovered_creative_id =
          creative_id
      ),
    by = "creative_name"
  ) |>
  summarise(
    affected_paid_rows = n(),
    
    recoverable_campaign_ids =
      sum(
        !is.na(recovered_campaign_id)
      ),
    
    recoverable_creative_ids =
      sum(
        !is.na(recovered_creative_id)
      ),
    
    unrecoverable_campaign_ids =
      sum(
        is.na(recovered_campaign_id)
      ),
    
    unrecoverable_creative_ids =
      sum(
        is.na(recovered_creative_id)
      )
  )

attribution_recovery_coverage |>
  print(width = Inf)

# =========================================================
# 6B.6 - CONTROLLED CLEANING
# 6B.6A - DEDUPLICATE INSTALL POSTBACKS
# =========================================================

clean_installs <- raw_installs |>
  distinct(
    raw_install_row_id,
    .keep_all = TRUE
  )
# Validation 
install_dedup_qa <- tibble(
  
  raw_rows =
    nrow(raw_installs),
  
  clean_rows =
    nrow(clean_installs),
  
  rows_removed =
    nrow(raw_installs) -
    nrow(clean_installs),
  
  unique_clean_ids =
    n_distinct(
      clean_installs$raw_install_row_id
    ),
  
  remaining_duplicates =
    nrow(clean_installs) -
    n_distinct(
      clean_installs$raw_install_row_id
    )
)

install_dedup_qa |>
  print(width = Inf)

#  User-preservation check 
clean_installs |>
  summarise(
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_user_ids =
      n_distinct(
        customer_user_id,
        na.rm = TRUE
      ),
    
    missing_customer_user_ids =
      sum(is.na(customer_user_id))
  ) |>
  print(width = Inf)

# =========================================================
# 6B.6B - RECOVER MISSING PAID ATTRIBUTION IDS
# Create clean lookup tables 
# =========================================================

campaign_id_map_clean <- clean_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(campaign_id),
    !is.na(campaign_name)
  ) |>
  distinct(
    campaign_name,
    campaign_id
  )

creative_id_map_clean <- clean_installs |>
  filter(
    acquisition_type == "Paid",
    !is.na(creative_id),
    !is.na(creative_name)
  ) |>
  distinct(
    creative_name,
    creative_id
  )
# Join the validated mappings 
clean_installs <- clean_installs |>
  left_join(
    campaign_id_map_clean |>
      rename(
        mapped_campaign_id = campaign_id
      ),
    by = "campaign_name"
  ) |>
  left_join(
    creative_id_map_clean |>
      rename(
        mapped_creative_id = creative_id
      ),
    by = "creative_name"
  )
# Recover only missing Paid IDs 
clean_installs <- clean_installs |>
  mutate(
    
    campaign_id = if_else(
      acquisition_type == "Paid" &
        is.na(campaign_id),
      mapped_campaign_id,
      campaign_id
    ),
    
    creative_id = if_else(
      acquisition_type == "Paid" &
        is.na(creative_id),
      mapped_creative_id,
      creative_id
    )
  ) |>
  select(
    -mapped_campaign_id,
    -mapped_creative_id
  )
# Validation 
attribution_recovery_qa <- clean_installs |>
  summarise(
    
    paid_users =
      sum(acquisition_type == "Paid"),
    
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
    
    organic_users =
      sum(acquisition_type == "Organic"),
    
    organic_missing_campaign =
      sum(
        acquisition_type == "Organic" &
          is.na(campaign_id)
      ),
    
    organic_missing_creative =
      sum(
        acquisition_type == "Organic" &
          is.na(creative_id)
      )
  )

attribution_recovery_qa |>
  print(width = Inf)

# =========================================================
# 6B.6C - RECOVER MISSING USER-PERFORMANCE IDS
# =========================================================

clean_user_key_map <- clean_installs |>
  select(
    appsflyer_id,
    customer_user_id
  ) |>
  distinct()
# Create the cleaned user-performance object 
clean_user_performance <- raw_user_performance |>
  left_join(
    clean_user_key_map |>
      rename(
        mapped_customer_user_id =
          customer_user_id
      ),
    by = "appsflyer_id"
  )
# Recover only missing customer IDs 
clean_user_performance <- clean_user_performance |>
  mutate(
    
    customer_user_id = if_else(
      is.na(customer_user_id),
      mapped_customer_user_id,
      customer_user_id
    )
    
  ) |>
  select(
    -mapped_customer_user_id
  )
# Validation 
user_id_recovery_qa <- tibble(
  
  raw_rows =
    nrow(raw_user_performance),
  
  clean_rows =
    nrow(clean_user_performance),
  
  raw_missing_customer_ids =
    sum(
      is.na(
        raw_user_performance$customer_user_id
      )
    ),
  
  clean_missing_customer_ids =
    sum(
      is.na(
        clean_user_performance$customer_user_id
      )
    ),
  
  recovered_customer_ids =
    sum(
      is.na(
        raw_user_performance$customer_user_id
      )
    ) -
    sum(
      is.na(
        clean_user_performance$customer_user_id
      )
    ),
  
  unique_appsflyer_ids =
    n_distinct(
      clean_user_performance$appsflyer_id
    ),
  
  unique_customer_user_ids =
    n_distinct(
      clean_user_performance$customer_user_id,
      na.rm = TRUE
    )
)

user_id_recovery_qa |>
  print(width = Inf)

# =========================================================
# 6B.6D - CLEAN IAP REVENUE
# =========================================================

clean_user_performance <- clean_user_performance |>
  mutate(
    
    iap_revenue_clean =
      iap_revenue_raw |>
      str_trim() |>
      str_remove("^€") |>
      str_replace(",", ".") |>
      as.numeric()
  )
# Validation 
iap_cleaning_qa <- clean_user_performance |>
  summarise(
    
    rows = n(),
    
    raw_missing =
      sum(is.na(iap_revenue_raw)),
    
    clean_missing =
      sum(is.na(iap_revenue_clean)),
    
    parsing_failures =
      sum(
        !is.na(iap_revenue_raw) &
          is.na(iap_revenue_clean)
      ),
    
    negative_revenue =
      sum(
        iap_revenue_clean < 0,
        na.rm = TRUE
      ),
    
    total_clean_iap_revenue =
      sum(
        iap_revenue_clean,
        na.rm = TRUE
      )
  )

iap_cleaning_qa |>
  print(width = Inf)

clean_user_performance |>
  filter(
    str_detect(
      iap_revenue_raw,
      "€|,|\\s$"
    )
  ) |>
  select(
    customer_user_id,
    iap_revenue_raw,
    iap_revenue_clean
  ) |>
  head(15) |>
  print(width = Inf)

clean_user_performance |>
  filter(
    str_detect(
      iap_revenue_raw,
      "€|,|\\s$"
    )
  ) |>
  select(
    customer_user_id,
    iap_revenue_raw,
    iap_revenue_clean
  ) |>
  head(15) |>
  print(width = Inf)

# =========================================================
# 6B.7 - CLEAN AD-DELIVERY DATA
# 6B.7A - DEDUPLICATE DELIVERY RECORDS
# =========================================================

clean_ad_delivery <- raw_ad_delivery |>
  distinct(
    raw_row_id,
    .keep_all = TRUE
  )
# Validation 
ad_delivery_dedup_qa <- tibble(
  
  raw_rows =
    nrow(raw_ad_delivery),
  
  clean_rows =
    nrow(clean_ad_delivery),
  
  rows_removed =
    nrow(raw_ad_delivery) -
    nrow(clean_ad_delivery),
  
  unique_clean_ids =
    n_distinct(
      clean_ad_delivery$raw_row_id
    ),
  
  remaining_duplicates =
    nrow(clean_ad_delivery) -
    n_distinct(
      clean_ad_delivery$raw_row_id
    )
)

ad_delivery_dedup_qa |>
  print(width = Inf)

# =========================================================
# 6B.7B - VALIDATE CHANNEL REFERENCE KEY
# =========================================================

channel_code_qa <- clean_ad_delivery |>
  distinct(
    channel_code,
    channel
  ) |>
  count(
    channel_code,
    name = "channel_labels"
  ) |>
  summarise(
    channel_codes =
      n(),
    
    missing_channel_codes =
      sum(
        is.na(channel_code)
      ),
    
    codes_with_multiple_labels =
      sum(
        channel_labels > 1
      )
  )

channel_code_qa |>
  print(width = Inf)
# Inspect the mapping 
clean_ad_delivery |>
  count(
    channel_code,
    channel,
    sort = TRUE
  ) |>
  print(
    n = Inf,
    width = Inf
  )

# ---------------------------------------------------------
# Canonical channel mapping
# Stable channel_code -> approved business label
# ---------------------------------------------------------

channel_mapping <- tibble(
  
  channel_code = c(
    "FB",
    "GGL",
    "TT",
    "SNAP",
    "UNITY"
  ),
  
  channel_canonical = c(
    "Facebook Audience Network",
    "Google App Campaigns",
    "TikTok Ads",
    "Snapchat Ads",
    "Unity Ads"
  )
)

# Preserve the raw lable and apply the mapping 

clean_ad_delivery <- clean_ad_delivery |>
  
  rename(
    channel_raw = channel
  ) |>
  
  left_join(
    channel_mapping,
    by = "channel_code"
  ) |>
  
  mutate(
    channel = channel_canonical
  )

# Validate the normalization 
channel_normalization_qa <- clean_ad_delivery |>
  summarise(
    
    rows = n(),
    
    distinct_raw_labels =
      n_distinct(channel_raw),
    
    distinct_clean_labels =
      n_distinct(channel),
    
    missing_clean_labels =
      sum(is.na(channel)),
    
    unmapped_channel_codes =
      sum(is.na(channel_canonical))
  )

channel_normalization_qa |>
  print(width = Inf)
# Validate one code maps to one clean label 
channel_code_postclean_qa <- clean_ad_delivery |>
  distinct(
    channel_code,
    channel
  ) |>
  count(
    channel_code,
    name = "clean_labels_per_code"
  ) |>
  summarise(
    
    channel_codes =
      n(),
    
    codes_with_multiple_clean_labels =
      sum(clean_labels_per_code > 1),
    
    codes_without_clean_labels =
      sum(clean_labels_per_code == 0)
  )

channel_code_postclean_qa |>
  print(width = Inf)

# =========================================================
# 6B.7C - STANDARDIZE CAMPAIGN NAMES
# =========================================================

campaign_mapping <- clean_ad_delivery |>
  filter(
    str_detect(
      campaign_name,
      "^[A-Z]+_(BROAD|HIGH_VALUE|LOW_COST|RETENTION)_PUZZLEPOP$"
    )
  ) |>
  distinct(
    campaign_id,
    campaign_name
  ) |>
  rename(
    campaign_canonical =
      campaign_name
  )
# Validate the reference mapping before applying it 
campaign_mapping_qa <- campaign_mapping |>
  count(
    campaign_id,
    name = "canonical_names_per_id"
  ) |>
  summarise(
    
    mapped_campaign_ids =
      n(),
    
    ids_with_multiple_canonical_names =
      sum(
        canonical_names_per_id > 1
      )
  )

campaign_mapping_qa |>
  print(width = Inf)


# Deivey source is covered 
unmapped_campaign_ids <- clean_ad_delivery |>
  distinct(
    campaign_id
  ) |>
  anti_join(
    campaign_mapping,
    by = "campaign_id"
  )

unmapped_campaign_ids

# ---------------------------------------------------------
# Apply canonical campaign names
# ---------------------------------------------------------

clean_ad_delivery <- clean_ad_delivery |>
  
  rename(
    campaign_name_raw =
      campaign_name
  ) |>
  
  left_join(
    campaign_mapping,
    by = "campaign_id"
  ) |>
  
  mutate(
    campaign_name =
      campaign_canonical
  )
# Validation 
campaign_normalization_qa <- clean_ad_delivery |>
  summarise(
    
    rows =
      n(),
    
    distinct_raw_campaign_labels =
      n_distinct(
        campaign_name_raw
      ),
    
    distinct_clean_campaigns =
      n_distinct(
        campaign_name
      ),
    
    distinct_campaign_ids =
      n_distinct(
        campaign_id
      ),
    
    missing_clean_campaign_names =
      sum(
        is.na(campaign_name)
      ),
    
    unmapped_campaign_ids =
      sum(
        is.na(campaign_canonical)
      )
  )

campaign_normalization_qa |>
  print(width = Inf)

# One-to-one post-clean check 
campaign_id_postclean_qa <- clean_ad_delivery |>
  distinct(
    campaign_id,
    campaign_name
  ) |>
  count(
    campaign_id,
    name = "clean_names_per_id"
  ) |>
  summarise(
    
    campaign_ids =
      n(),
    
    ids_with_multiple_clean_names =
      sum(
        clean_names_per_id > 1
      )
  )

campaign_id_postclean_qa |>
  print(width = Inf)

# =========================================================
# 6B.7D - PROFILE RECOVERY OF MISSING CREATIVE IDS
# =========================================================

ad_delivery_missing_creative <- clean_ad_delivery |>
  filter(
    is.na(creative_id)
  )
# Validation 
ad_delivery_missing_creative |>
  summarise(
    
    affected_rows =
      n(),
    
    available_creative_names =
      sum(
        !is.na(creative_name)
      ),
    
    missing_creative_names =
      sum(
        is.na(creative_name)
      )
  ) |>
  print(width = Inf)

# Creative mapping safety 
ad_creative_id_map <- clean_ad_delivery |>
  filter(
    !is.na(creative_id),
    !is.na(creative_name)
  ) |>
  distinct(
    creative_name,
    creative_id
  )
# Uniqueness 
ad_creative_mapping_qa <- ad_creative_id_map |>
  count(
    creative_name,
    name = "creative_ids_per_name"
  ) |>
  summarise(
    
    creative_names =
      n(),
    
    ambiguous_creative_names =
      sum(
        creative_ids_per_name > 1
      )
  )

ad_creative_mapping_qa |>
  print(width = Inf)

# Verify coverage 
unmatched_ad_creative_names <-
  ad_delivery_missing_creative |>
  distinct(
    creative_name
  ) |>
  anti_join(
    ad_creative_id_map,
    by = "creative_name"
  )

unmatched_ad_creative_names

# ---------------------------------------------------------
# Recover missing creative IDs
# ---------------------------------------------------------

clean_ad_delivery <- clean_ad_delivery |>
  left_join(
    ad_creative_id_map |>
      rename(
        mapped_creative_id =
          creative_id
      ),
    by = "creative_name"
  ) |>
  mutate(
    creative_id = if_else(
      is.na(creative_id),
      mapped_creative_id,
      creative_id
    )
  ) |>
  select(
    -mapped_creative_id
  )
# Validation 
creative_id_recovery_qa <- clean_ad_delivery |>
  summarise(
    
    rows =
      n(),
    
    distinct_creative_ids =
      n_distinct(
        creative_id,
        na.rm = TRUE
      ),
    
    missing_creative_ids =
      sum(
        is.na(creative_id)
      ),
    
    distinct_creative_names =
      n_distinct(
        creative_name
      )
  )

creative_id_recovery_qa |>
  print(width = Inf)

# =========================================================
# 6B.7E - CLEAN MARKETING SPEND
# =========================================================

clean_ad_delivery <- clean_ad_delivery |>
  mutate(
    
    spend_clean =
      spend_raw |>
      str_trim() |>
      str_remove("^€") |>
      str_replace(",", ".") |>
      as.numeric()
  )
# Validation 
spend_cleaning_qa <- clean_ad_delivery |>
  summarise(
    
    rows = n(),
    
    raw_missing =
      sum(is.na(spend_raw)),
    
    clean_missing =
      sum(is.na(spend_clean)),
    
    parsing_failures =
      sum(
        !is.na(spend_raw) &
          is.na(spend_clean)
      ),
    
    negative_spend =
      sum(
        spend_clean < 0,
        na.rm = TRUE
      ),
    
    zero_spend =
      sum(
        spend_clean == 0,
        na.rm = TRUE
      ),
    
    total_clean_spend =
      sum(
        spend_clean,
        na.rm = TRUE
      )
  )

spend_cleaning_qa |>
  print(width = Inf)

# Values that needed formatting correction 
clean_ad_delivery |>
  filter(
    str_detect(
      spend_raw,
      "€|,|\\s$"
    )
  ) |>
  select(
    raw_row_id,
    spend_raw,
    spend_clean
  ) |>
  head(15) |>
  print(width = Inf)
# ---------------------------------------------------------
# Reconcile cleaned spend with the expected numeric value
# ---------------------------------------------------------

spend_reconciliation_qa <- clean_ad_delivery |>
  mutate(
    
    spend_expected =
      spend_raw |>
      str_trim() |>
      str_remove("^€") |>
      str_replace(",", ".") |>
      as.numeric(),
    
    spend_difference =
      abs(
        spend_clean -
          spend_expected
      )
  ) |>
  summarise(
    
    rows = n(),
    
    mismatched_rows =
      sum(
        spend_difference > 0.000001,
        na.rm = TRUE
      ),
    
    maximum_difference =
      max(
        spend_difference,
        na.rm = TRUE
      ),
    
    total_clean_spend =
      sum(
        spend_clean,
        na.rm = TRUE
      ),
    
    total_expected_spend =
      sum(
        spend_expected,
        na.rm = TRUE
      )
  )

spend_reconciliation_qa |>
  print(width = Inf)
# =========================================================
# 6B.7F - AD-DELIVERY BUSINESS-RULE QA
# =========================================================

ad_delivery_business_qa <- clean_ad_delivery |>
  summarise(
    
    rows =
      n(),
    
    missing_channel =
      sum(is.na(channel)),
    
    missing_campaign_id =
      sum(is.na(campaign_id)),
    
    missing_campaign_name =
      sum(is.na(campaign_name)),
    
    missing_creative_id =
      sum(is.na(creative_id)),
    
    missing_spend =
      sum(is.na(spend_clean)),
    
    negative_spend =
      sum(
        spend_clean < 0,
        na.rm = TRUE
      ),
    
    negative_impressions =
      sum(
        impressions < 0,
        na.rm = TRUE
      ),
    
    negative_clicks =
      sum(
        clicks < 0,
        na.rm = TRUE
      ),
    
    clicks_above_impressions =
      sum(
        clicks > impressions,
        na.rm = TRUE
      )
  )

ad_delivery_business_qa |>
  print(width = Inf)

# =========================================================
# 6B.8 - BUILD ANALYSIS-READY SCHEMAS
# 6B.8A - AD DELIVERY
# =========================================================

analytics_ad_delivery <- clean_ad_delivery |>
  select(
    
    # Record and time
    raw_row_id,
    date,
    
    # Marketing channel
    channel_code,
    channel,
    
    # Campaign
    campaign_id,
    campaign_name,
    strategy_code,
    strategy_name,
    
    # Creative
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    
    # Market dimensions
    country_code,
    country_name,
    platform,
    
    # Delivery facts
    spend = spend_clean,
    impressions,
    clicks
  )

# Validate only the final schema 
analytics_ad_delivery_qa <- analytics_ad_delivery |>
  summarise(
    
    rows =
      n(),
    
    columns =
      ncol(analytics_ad_delivery),
    
    unique_row_ids =
      n_distinct(raw_row_id),
    
    missing_channel =
      sum(is.na(channel)),
    
    missing_campaign =
      sum(is.na(campaign_id)),
    
    missing_creative =
      sum(is.na(creative_id)),
    
    missing_spend =
      sum(is.na(spend)),
    
    negative_spend =
      sum(
        spend < 0,
        na.rm = TRUE
      ),
    
    impossible_click_rows =
      sum(
        clicks > impressions,
        na.rm = TRUE
      )
  )

analytics_ad_delivery_qa |>
  print(width = Inf)

# =========================================================
# 6B.8B - ANALYSIS-READY INSTALL / ATTRIBUTION SCHEMA
# =========================================================

analytics_installs <- clean_installs |>
  select(
    
    # User identifiers
    appsflyer_id,
    customer_user_id,
    
    # Acquisition timing
    install_time,
    attributed_touch_time,
    attributed_touch_type,
    
    # Acquisition classification
    acquisition_type,
    is_organic,
    is_retargeting,
    
    # Channel
    channel,
    
    # Campaign
    campaign_id,
    campaign_name,
    
    # Creative
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    
    # Market
    country_code,
    country_name,
    platform
  )
# Validate the analytical grain 
analytics_installs_qa <- analytics_installs |>
  summarise(
    
    rows =
      n(),
    
    columns =
      ncol(analytics_installs),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_ids =
      n_distinct(customer_user_id),
    
    missing_appsflyer_ids =
      sum(is.na(appsflyer_id)),
    
    missing_customer_ids =
      sum(is.na(customer_user_id)),
    
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
    
    organic_users =
      sum(
        acquisition_type == "Organic"
      ),
    
    organic_with_campaign =
      sum(
        acquisition_type == "Organic" &
          !is.na(campaign_id)
      )
  )

analytics_installs_qa |>
  print(width = Inf)
# =========================================================
# 6B.8C - ANALYSIS-READY USER PERFORMANCE SCHEMA
# =========================================================

analytics_user_performance <- clean_user_performance |>
  select(
    
    # User identifiers
    appsflyer_id,
    customer_user_id,
    
    # Engagement
    sessions_first_7d,
    
    # Retention
    retained_d1,
    retained_d7,
    retained_d30,
    
    # Payer behaviour
    is_payer,
    purchase_count,
    
    # Monetization
    iap_revenue =
      iap_revenue_clean,
    
    ad_impressions,
    ad_revenue,
    total_revenue
  )
# Validation 
analytics_user_performance_qa <-
  analytics_user_performance |>
  summarise(
    
    rows =
      n(),
    
    columns =
      ncol(analytics_user_performance),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_ids =
      n_distinct(customer_user_id),
    
    missing_appsflyer_ids =
      sum(is.na(appsflyer_id)),
    
    missing_customer_ids =
      sum(is.na(customer_user_id)),
    
    invalid_d1 =
      sum(
        !retained_d1 %in% c(0, 1)
      ),
    
    invalid_d7 =
      sum(
        !retained_d7 %in% c(0, 1)
      ),
    
    invalid_d30 =
      sum(
        !retained_d30 %in% c(0, 1)
      ),
    
    invalid_payer =
      sum(
        !is_payer %in% c(0, 1)
      ),
    
    negative_iap_revenue =
      sum(
        iap_revenue < 0,
        na.rm = TRUE
      ),
    
    negative_ad_revenue =
      sum(
        ad_revenue < 0,
        na.rm = TRUE
      ),
    
    negative_total_revenue =
      sum(
        total_revenue < 0,
        na.rm = TRUE
      )
  )

analytics_user_performance_qa |>
  print(width = Inf)
# =========================================================
# 6B.8D - ANALYSIS-READY EXPERIMENT SCHEMA
# =========================================================

analytics_experiment <- raw_experiment |>
  select(
    
    # Experiment grain
    customer_user_id,
    experiment_id,
    experiment_variant,
    
    # Primary KPI
    tutorial_completed,
    
    # Secondary outcomes
    retained_d1,
    retained_d7,
    retained_d30,
    is_payer,
    
    # Business outcome
    total_revenue
  )
# Validation 
analytics_experiment_qa <- analytics_experiment |>
  summarise(
    
    rows =
      n(),
    
    columns =
      ncol(analytics_experiment),
    
    unique_users =
      n_distinct(customer_user_id),
    
    experiment_count =
      n_distinct(experiment_id),
    
    missing_user_ids =
      sum(is.na(customer_user_id)),
    
    missing_variants =
      sum(is.na(experiment_variant)),
    
    invalid_tutorial_outcomes =
      sum(
        !tutorial_completed %in% c(0, 1)
      ),
    
    invalid_d1 =
      sum(
        !retained_d1 %in% c(0, 1)
      ),
    
    invalid_d7 =
      sum(
        !retained_d7 %in% c(0, 1)
      ),
    
    invalid_d30 =
      sum(
        !retained_d30 %in% c(0, 1)
      ),
    
    invalid_payer =
      sum(
        !is_payer %in% c(0, 1)
      ),
    
    negative_revenue =
      sum(
        total_revenue < 0,
        na.rm = TRUE
      )
  )

analytics_experiment_qa |>
  print(width = Inf)
# =========================================================
# 6B.9 - CROSS-SOURCE INTEGRITY
# 6B.9A - INSTALL <-> USER PERFORMANCE COVERAGE
# =========================================================

installs_without_performance <- analytics_installs |>
  select(
    appsflyer_id
  ) |>
  anti_join(
    analytics_user_performance |>
      select(
        appsflyer_id
      ),
    by = "appsflyer_id"
  )
# Performance records that cannot find an install
performance_without_installs <- analytics_user_performance |>
  select(
    appsflyer_id
  ) |>
  anti_join(
    analytics_installs |>
      select(
        appsflyer_id
      ),
    by = "appsflyer_id"
  )
# Consolidated QA 
user_source_coverage_qa <- tibble(
  
  install_users =
    n_distinct(
      analytics_installs$appsflyer_id
    ),
  
  performance_users =
    n_distinct(
      analytics_user_performance$appsflyer_id
    ),
  
  installs_without_performance =
    nrow(installs_without_performance),
  
  performance_without_installs =
    nrow(performance_without_installs)
)

user_source_coverage_qa |>
  print(width = Inf)
# =========================================================
# 6B.9B - EXPERIMENT TO USER PERFORMANCE COVERAGE
# =========================================================

experiment_without_performance <- analytics_experiment |>
  select(
    customer_user_id
  ) |>
  anti_join(
    analytics_user_performance |>
      select(
        customer_user_id
      ),
    by = "customer_user_id"
  )


# Create the consolidated QA
experiment_source_coverage_qa <- tibble(
  
  experiment_users =
    n_distinct(
      analytics_experiment$customer_user_id
    ),
  
  performance_users =
    n_distinct(
      analytics_user_performance$customer_user_id
    ),
  
  experiment_users_without_performance =
    nrow(
      experiment_without_performance
    )
)

experiment_source_coverage_qa |>
  print(width = Inf)

# =========================================================
# 6B.9C - PAID DELIVERY <-> PAID ATTRIBUTION KEY COVERAGE
# =========================================================

paid_install_campaigns <- analytics_installs |>
  filter(
    acquisition_type == "Paid"
  ) |>
  distinct(
    campaign_id
  )

delivery_campaigns <- analytics_ad_delivery |>
  distinct(
    campaign_id
  )

campaigns_missing_from_delivery <-
  paid_install_campaigns |>
  anti_join(
    delivery_campaigns,
    by = "campaign_id"
  )

campaigns_missing_from_installs <-
  delivery_campaigns |>
  anti_join(
    paid_install_campaigns,
    by = "campaign_id"
  )
# Check creative coverage 
paid_install_creatives <- analytics_installs |>
  filter(
    acquisition_type == "Paid"
  ) |>
  distinct(
    creative_id
  )

delivery_creatives <- analytics_ad_delivery |>
  distinct(
    creative_id
  )

creatives_missing_from_delivery <-
  paid_install_creatives |>
  anti_join(
    delivery_creatives,
    by = "creative_id"
  )

creatives_missing_from_installs <-
  delivery_creatives |>
  anti_join(
    paid_install_creatives,
    by = "creative_id"
  )
# Consolidated QA 
marketing_key_coverage_qa <- tibble(
  
  delivery_campaigns =
    nrow(delivery_campaigns),
  
  paid_install_campaigns =
    nrow(paid_install_campaigns),
  
  campaigns_missing_from_delivery =
    nrow(campaigns_missing_from_delivery),
  
  campaigns_missing_from_installs =
    nrow(campaigns_missing_from_installs),
  
  delivery_creatives =
    nrow(delivery_creatives),
  
  paid_install_creatives =
    nrow(paid_install_creatives),
  
  creatives_missing_from_delivery =
    nrow(creatives_missing_from_delivery),
  
  creatives_missing_from_installs =
    nrow(creatives_missing_from_installs)
)

marketing_key_coverage_qa |>
  print(width = Inf)

# =========================================================
# 6B.10 - EXPORT PROCESSED ANALYTICAL DATA
# 6B.10A - CREATE PROCESSED DATA DIRECTORY
# =========================================================

dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE
)
# Export the four analytical datasets 
write_csv(
  analytics_ad_delivery,
  "data/processed/analytics_ad_delivery.csv"
)

write_csv(
  analytics_installs,
  "data/processed/analytics_installs.csv"
)

write_csv(
  analytics_user_performance,
  "data/processed/analytics_user_performance.csv"
)

write_csv(
  analytics_experiment,
  "data/processed/analytics_experiment.csv"
)
# =========================================================
# 6B.10B - FINAL PROCESSED FILE VALIDATION
# =========================================================

check_ad_delivery <- read_csv(
  "data/processed/analytics_ad_delivery.csv",
  show_col_types = FALSE
)

check_installs <- read_csv(
  "data/processed/analytics_installs.csv",
  show_col_types = FALSE
)

check_user_performance <- read_csv(
  "data/processed/analytics_user_performance.csv",
  show_col_types = FALSE
)

check_experiment <- read_csv(
  "data/processed/analytics_experiment.csv",
  show_col_types = FALSE
)
# Reconcile rows and columns 
processed_file_qa <- tibble(
  
  dataset = c(
    "ad_delivery",
    "installs",
    "user_performance",
    "experiment"
  ),
  
  expected_rows = c(
    nrow(analytics_ad_delivery),
    nrow(analytics_installs),
    nrow(analytics_user_performance),
    nrow(analytics_experiment)
  ),
  
  exported_rows = c(
    nrow(check_ad_delivery),
    nrow(check_installs),
    nrow(check_user_performance),
    nrow(check_experiment)
  ),
  
  expected_columns = c(
    ncol(analytics_ad_delivery),
    ncol(analytics_installs),
    ncol(analytics_user_performance),
    ncol(analytics_experiment)
  ),
  
  exported_columns = c(
    ncol(check_ad_delivery),
    ncol(check_installs),
    ncol(check_user_performance),
    ncol(check_experiment)
  )
) |>
  mutate(
    
    row_match =
      expected_rows == exported_rows,
    
    column_match =
      expected_columns == exported_columns
  )

processed_file_qa |>
  print(width = Inf)
