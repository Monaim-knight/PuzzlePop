# =========================================================
# PuzzlePop - Synthetic Truth Layer Generation
# =========================================================
#
# Purpose:
# Build the clean synthetic business truth layer used by the
# PuzzlePop Marketing Analytics portfolio project.
#
# The generated data is entirely synthetic and is designed
# to simulate realistic mobile-game marketing, attribution,
# user-behavior, monetization, and experimentation data.
#
# Workflow:
# Synthetic Business Assumptions
# -> Clean Truth Objects
# -> data/truth/*.rds
#
# The truth layer is subsequently transformed into realistic
# source-style raw datasets containing controlled data-quality
# issues by 02_create_raw_business_data.R.
#
# =========================================================

#---------------------------------------
# Country Assumptions
#-----------------------------------------
# ---------------------------------------------------------
# 8. COUNTRY-LEVEL BUSINESS ASSUMPTIONS
# ---------------------------------------------------------

country_assumptions <- tibble(
  
  country_code = c(
    "DE", "US", "GB", "FR", "CA",
    "AU", "BR", "IN", "JP", "KR"
  ),
  
  country_name = c(
    "Germany",
    "United States",
    "United Kingdom",
    "France",
    "Canada",
    "Australia",
    "Brazil",
    "India",
    "Japan",
    "South Korea"
  ),
  
  traffic_weight = c(
    0.14,
    0.22,
    0.10,
    0.09,
    0.08,
    0.07,
    0.09,
    0.10,
    0.06,
    0.05
  ),
  
  cpm_modifier = c(
    1.05,
    1.30,
    1.15,
    1.00,
    1.10,
    1.20,
    0.65,
    0.45,
    1.10,
    0.95
  ),
  
  conversion_modifier = c(
    1.02,
    1.05,
    1.03,
    1.00,
    1.04,
    1.03,
    0.94,
    0.89,
    0.98,
    1.00
  ),
  
  revenue_modifier = c(
    1.05,
    1.25,
    1.15,
    1.00,
    1.10,
    1.15,
    0.62,
    0.45,
    1.12,
    1.02
  )
)
# Validate the weights 
sum(country_assumptions$traffic_weight)
# Platform assumptions 
#--------------------------------------------
# ---------------------------------------------------------
# 9. PLATFORM-LEVEL BUSINESS ASSUMPTIONS
# ---------------------------------------------------------

platform_assumptions <- tibble(
  
  platform = c(
    "Android",
    "iOS"
  ),
  
  traffic_weight = c(
    0.62,
    0.38
  ),
  
  cpm_modifier = c(
    0.90,
    1.20
  ),
  
  conversion_modifier = c(
    1.02,
    0.97
  ),
  
  revenue_modifier = c(
    0.88,
    1.20
  )
)
# Validation 
sum(platform_assumptions$traffic_weight)
#-----------------------------------------------
# Create the campaign data framework 
#--------------------------------------
# ---------------------------------------------------------
# 10. DAILY MARKETING CALENDAR
# ---------------------------------------------------------

marketing_dates <- tibble(
  date = seq(
    start_date,
    end_date,
    by = "day"
  )
)
# Validate 
nrow(marketing_dates)
#--------------------------------------------------
# Add caleder characteristics 
#################################################
marketing_dates <- marketing_dates |>
  mutate(
    
    weekday_name = weekdays(date),
    
    weekend_flag = if_else(
      weekday_name %in% c("Saturday", "Sunday"),
      1L,
      0L
    ),
    
    weekend_budget_modifier = if_else(
      weekend_flag == 1L,
      1.12,
      1.00
    ),
    
    month_number = as.integer(
      format(date, "%m")
    )
  )
#-----------------------------------------------
# Define strategy budget modifiers 
#------------------------------------------------
strategy_budget_assumptions <- tibble(
  
  strategy_code = c(
    "BROAD",
    "HIGH_VALUE",
    "LOW_COST",
    "RETENTION"
  ),
  
  budget_modifier = c(
    1.20,
    1.05,
    0.95,
    0.80
  )
)
# ----------------------------------------------
# Add channel and strategy assumptions to campaigns 
#-----------------------------------------------
campaign_delivery_config <- campaign_master |>
  
  left_join(
    channel_assumptions,
    by = "channel",
    suffix = c("_campaign", "_channel")
  ) |>
  
  left_join(
    strategy_budget_assumptions,
    by = "strategy_code"
  )
names(campaign_delivery_config)
#--------------------------------------
# Calcualte base campaign budger 
#------------------------------------------
total_daily_budget <- 600
# Campaign allocations
#--------------------------------------------
campaign_delivery_config <- campaign_delivery_config |>
  
  group_by(channel) |>
  
  mutate(
    normalized_strategy_weight =
      budget_modifier / sum(budget_modifier),
    
    base_daily_campaign_budget =
      total_daily_budget *
      budget_weight *
      normalized_strategy_weight
  ) |>
  
  ungroup()
# Validation- Campaign budgets 
sum(
  campaign_delivery_config$base_daily_campaign_budget
)
#---------------------------------------------
# Build acative creative0 date combinations 
#------------------------------------------
# Combine dates and creatives 
creative_daily <- crossing(
  date = marketing_dates$date,
  creative_master
)
# Vaidation 
nrow(creative_daily)
# Keeping only active creatives 
creative_daily <- creative_daily |>
  
  filter(
    date >= launch_date
  ) |>
  
  mutate(
    days_live = as.integer(
      date - launch_date
    )
  )
#------------------------------------------------
# Model Creative fatigue 
#-------------------------------------------------
creative_daily <- creative_daily |>
  mutate(
    fatigue_modifier = pmax(
      0.72,
      exp(-0.0025 * days_live)
    )
  )
#-----------------------------------------
# Attach campaign and date assumptions 
#------------------------------------------
creative_daily <- creative_daily |>
  
  left_join(
    campaign_delivery_config,
    by = c(
      "campaign_id",
      "campaign_name",
      "channel"
    )
  ) |>
  
  left_join(
    marketing_dates,
    by = "date"
  )
#-----------------------------------------------
# Allocate budget between active creatives
#----------------------------------------------
creative_daily <- creative_daily |>
  
  group_by(
    date,
    campaign_id
  ) |>
  
  mutate(
    creative_allocation_weight =
      pmax(creative_quality, 0.50) /
      sum(pmax(creative_quality, 0.50))
  ) |>
  
  ungroup()
names(creative_daily)

creative_daily |>
  select(
    date,
    campaign_id,
    creative_id,
    creative_quality,
    creative_allocation_weight
  ) |>
  head(10)
#--------------------------------------------------
# Validation - do the allocation equal 100%
#------------------------------------------------
creative_daily |>
  group_by(
    date,
    campaign_id
  ) |>
  summarise(
    total_allocation =
      sum(creative_allocation_weight),
    .groups = "drop"
  ) |>
  summarise(
    min_allocation =
      min(total_allocation),
    max_allocation =
      max(total_allocation)
  )
#----------------------------------------
# Expand countries and platforms 
#------------------------------------------
# ---------------------------------------------------------
# Expand across countries and platforms
# ---------------------------------------------------------

clean_ad_delivery_truth <- creative_daily |>
  crossing(
    country_code = country_assumptions$country_code,
    platform = platform_assumptions$platform
  )
# Attach countri assumptions 
clean_ad_delivery_truth <- clean_ad_delivery_truth |>
  left_join(
    country_assumptions,
    by = "country_code",
    suffix = c("", "_country")
  )
#----------------------------------------------------
# Attach platform assumptions 
#---------------------------------------------------
clean_ad_delivery_truth <- clean_ad_delivery_truth |>
  left_join(
    platform_assumptions,
    by = "platform",
    suffix = c("_country", "_platform")
  )
# Validation 
names(clean_ad_delivery_truth)

clean_ad_delivery_truth |>
  select(
    date,
    channel,
    campaign_id,
    creative_id,
    country_code,
    country_name,
    platform,
    traffic_weight_country,
    traffic_weight_platform,
    cpm_modifier_country,
    cpm_modifier_platform
  ) |>
  head(10)
# ---------------------------------------------------------
# Generate ad-delivery metrics
# Budget -> CPM -> Impressions -> CTR -> Clicks -> Spend
# ---------------------------------------------------------

clean_ad_delivery_truth <- clean_ad_delivery_truth |>
  mutate(
    
    # Daily performance variation around the channel baseline
    daily_noise = rnorm(
      n(),
      mean = 1,
      sd = volatility
    ),
    
    # Prevent unrealistic extreme daily variation
    daily_noise = pmax(
      0.65,
      pmin(1.40, daily_noise)
    ),
    
    # Allocate campaign budget across:
    # creative -> country -> platform
    allocated_budget =
      base_daily_campaign_budget *
      weekend_budget_modifier *
      creative_allocation_weight *
      traffic_weight_country *
      traffic_weight_platform,
    
    # Calculate a realistic CPM with country/platform effects
    actual_cpm =
      baseline_cpm *
      cpm_modifier_country *
      cpm_modifier_platform *
      pmax(
        0.75,
        pmin(
          1.30,
          rnorm(
            n(),
            mean = 1,
            sd = 0.08
          )
        )
      ),
    
    # Convert budget and CPM into impressions
    impressions = round(
      allocated_budget /
        actual_cpm *
        1000
    ),
    
    # Expected CTR comes from:
    # channel + campaign + creative + fatigue + daily variation
    expected_ctr =
      baseline_ctr *
      ctr_modifier *
      final_ctr_modifier *
      fatigue_modifier *
      daily_noise,
    
    # Keep CTR inside sensible simulation limits
    expected_ctr = pmax(
      0.002,
      pmin(
        0.12,
        expected_ctr
      )
    ),
    
    # Generate observed clicks from impressions
    clicks = rbinom(
      n = n(),
      size = impressions,
      prob = expected_ctr
    ),
    
    # Calculate actual spend implied by delivered impressions
    spend =
      impressions /
      1000 *
      actual_cpm
  )
# Validation - Check the generated columns 
clean_ad_delivery_truth |>
  select(
    date,
    channel,
    campaign_id,
    creative_id,
    country_code,
    platform,
    allocated_budget,
    actual_cpm,
    impressions,
    expected_ctr,
    clicks,
    spend
  ) |>
  head(10)
# Validation- Impossive clicks
sum(
  clean_ad_delivery_truth$clicks >
    clean_ad_delivery_truth$impressions
)
# Validation - Negative values 
clean_ad_delivery_truth |>
  summarise(
    negative_budget =
      sum(allocated_budget < 0, na.rm = TRUE),
    
    negative_spend =
      sum(spend < 0, na.rm = TRUE),
    
    negative_impressions =
      sum(impressions < 0, na.rm = TRUE),
    
    negative_clicks =
      sum(clicks < 0, na.rm = TRUE)
  )
# Validation - Calculate Observed  CTR range 
clean_ad_delivery_truth |>
  mutate(
    observed_ctr =
      clicks / impressions
  ) |>
  summarise(
    min_ctr =
      min(observed_ctr, na.rm = TRUE),
    
    avg_ctr =
      mean(observed_ctr, na.rm = TRUE),
    
    max_ctr =
      max(observed_ctr, na.rm = TRUE)
  )
#-----------------------------------------------
clean_ad_delivery_truth |>
  mutate(
    observed_ctr = clicks / impressions
  ) |>
  arrange(desc(observed_ctr)) |>
  select(
    impressions,
    clicks,
    expected_ctr,
    observed_ctr
  ) |>
  head(10) |>
  print(width = Inf)
#----------------------------------------------------
# Final validation 
#-------------------------------------------------
# =========================================================
# FINAL QA - CLEAN AD DELIVERY TRUTH
# =========================================================

ad_delivery_qa <- clean_ad_delivery_truth |>
  summarise(
    
    rows = n(),
    
    total_budget =
      sum(allocated_budget, na.rm = TRUE),
    
    total_spend =
      sum(spend, na.rm = TRUE),
    
    total_impressions =
      sum(impressions, na.rm = TRUE),
    
    total_clicks =
      sum(clicks, na.rm = TRUE),
    
    overall_ctr =
      total_clicks / total_impressions,
    
    impossible_click_rows =
      sum(clicks > impressions, na.rm = TRUE),
    
    negative_spend_rows =
      sum(spend < 0, na.rm = TRUE),
    
    negative_impression_rows =
      sum(impressions < 0, na.rm = TRUE),
    
    negative_click_rows =
      sum(clicks < 0, na.rm = TRUE),
    
    missing_campaign_ids =
      sum(is.na(campaign_id)),
    
    missing_creative_ids =
      sum(is.na(creative_id))
  )

ad_delivery_qa

ad_delivery_qa |>
  print(width = Inf)
sum(is.na(clean_ad_delivery_truth$creative_id))
channel_delivery_qa |>
  print(width = Inf)
####################################################
# =========================================================
# CHANNEL-LEVEL AD DELIVERY QA
# =========================================================

channel_delivery_qa <- clean_ad_delivery_truth |>
  
  group_by(channel) |>
  
  summarise(
    
    spend =
      sum(spend, na.rm = TRUE),
    
    impressions =
      sum(impressions, na.rm = TRUE),
    
    clicks =
      sum(clicks, na.rm = TRUE),
    
    ctr =
      clicks / impressions,
    
    cpm =
      spend / impressions * 1000,
    
    .groups = "drop"
  ) |>
  
  arrange(
    desc(spend)
  )
channel_delivery_qa |>
  print(width = Inf)
# =========================================================
# 6A.5.6 - INSTALL AND ATTRIBUTION GENERATION
# Clicks -> Installs -> Attribution
# =========================================================
# ---------------------------------------------------------
# 6A.5.6.1 - Generate installs from advertising clicks
# ---------------------------------------------------------

install_delivery_truth <- clean_ad_delivery_truth |>
  mutate(
    
    # Expected click-to-install conversion probability
    expected_install_cvr =
      baseline_install_cvr *
      cvr_modifier *
      final_cvr_modifier *
      conversion_modifier_country *
      conversion_modifier_platform,
    
    # Keep the synthetic CVR within reasonable
    # simulation boundaries
    expected_install_cvr = pmax(
      0.03,
      pmin(
        0.40,
        expected_install_cvr
      )
    ),
    
    # Generate observed installs from clicks
    installs = rbinom(
      n = n(),
      size = clicks,
      prob = expected_install_cvr
    )
  )
##-----------------------------------------------------------
# Validation =QA
#--------------------------------------------------------------
install_qa <- install_delivery_truth |>
  summarise(
    
    total_clicks = sum(clicks, na.rm = TRUE),
    
    total_installs = sum(installs, na.rm = TRUE),
    
    overall_install_cvr =
      total_installs / total_clicks,
    
    impossible_install_rows =
      sum(installs > clicks, na.rm = TRUE),
    
    negative_install_rows =
      sum(installs < 0, na.rm = TRUE),
    
    missing_install_values =
      sum(is.na(installs))
  )

install_qa |>
  print(width = Inf)
# Channel level install and CPI Validation 
# ---------------------------------------------------------
# 6A.5.6.2 - CHANNEL INSTALL & CPI QA
# ---------------------------------------------------------

install_channel_qa <- install_delivery_truth |>
  
  group_by(channel) |>
  
  summarise(
    
    spend =
      sum(spend, na.rm = TRUE),
    
    clicks =
      sum(clicks, na.rm = TRUE),
    
    installs =
      sum(installs, na.rm = TRUE),
    
    install_cvr =
      installs / clicks,
    
    cpi =
      spend / installs,
    
    .groups = "drop"
  ) |>
  
  arrange(
    desc(installs)
  )

install_channel_qa |>
  print(width = Inf)
#----------------------------------------
# Slecelct install-level source fields 
#--------------------------------------------
# ---------------------------------------------------------
# 6A.5.6.3 - Create individual paid-install records
# One install = one row
# ---------------------------------------------------------

paid_installs <- install_delivery_truth |>
  select(
    date,
    channel,
    campaign_id,
    campaign_name,
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    country_code,
    country_name,
    platform,
    strategy_code,
    strategy_name,
    retention_modifier,
    payer_modifier,
    baseline_install_cvr,
    d1_retention,
    d7_retention,
    d30_retention,
    payer_probability,
    ad_engagement_modifier,
    conversion_modifier_country,
    conversion_modifier_platform,
    revenue_modifier_country,
    revenue_modifier_platform,
    expected_install_cvr,
    installs
  )
# Expand install counts into rows 
paid_installs <- paid_installs |>
  uncount(
    weights = installs,
    .id = "install_sequence"
  )
# Create Unique ID 
paid_installs <- paid_installs |>
  mutate(
    
    appsflyer_id = sprintf(
      "AF_%09d",
      row_number()
    ),
    
    customer_user_id = sprintf(
      "PPU_%09d",
      row_number()
    )
  )
# Generate install timestamps 
paid_installs <- paid_installs |>
  mutate(
    
    install_time =
      as.POSIXct(
        date,
        tz = "UTC"
      ) +
      sample(
        0:86399,
        size = n(),
        replace = TRUE
      )
  )
# Create attributed-touch timestamps 
paid_installs <- paid_installs |>
  mutate(
    
    attributed_touch_type = "click",
    
    click_to_install_seconds = sample(
      60:259200,
      size = n(),
      replace = TRUE
    ),
    
    attributed_touch_time =
      install_time -
      click_to_install_seconds
  )
# Add attribution metadata 
paid_installs <- paid_installs |>
  mutate(
    
    acquisition_type = "Paid",
    
    campaign_type = "User Acquisition",
    
    is_organic = FALSE,
    
    is_retargeting = FALSE,
    
    attribution_provider = "AppsFlyer-style synthetic"
  )
#-----------------------------------------------------
# Validation 
#--------------------------------------
paid_install_qa <- paid_installs |>
  summarise(
    
    rows = n(),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_user_ids =
      n_distinct(customer_user_id),
    
    duplicate_appsflyer_ids =
      n() - n_distinct(appsflyer_id),
    
    missing_campaign_ids =
      sum(is.na(campaign_id)),
    
    missing_creative_ids =
      sum(is.na(creative_id)),
    
    touch_after_install =
      sum(
        attributed_touch_time >= install_time,
        na.rm = TRUE
      ),
    
    minimum_install_time =
      min(install_time),
    
    maximum_install_time =
      max(install_time)
  )

paid_install_qa |>
  print(width = Inf)
#------------------------------------------------------------
# Generate Orgnic Installs 
#-----------------------------------------------------------
# ---------------------------------------------------------
# 6A.5.6.4 - Generate organic installs
# ---------------------------------------------------------

n_organic_users <- 12000
# Generate Organic installs dates 
organic_installs <- tibble(
  
  date = sample(
    marketing_dates$date,
    size = n_organic_users,
    replace = TRUE
  )
)
#Give organic users country and platform 
organic_installs <- organic_installs |>
  mutate(
    
    country_code = sample(
      country_assumptions$country_code,
      size = n(),
      replace = TRUE,
      prob = country_assumptions$traffic_weight
    ),
    
    platform = sample(
      platform_assumptions$platform,
      size = n(),
      replace = TRUE,
      prob = platform_assumptions$traffic_weight
    )
  )
# Attach the country names 
organic_installs <- organic_installs |>
  left_join(
    country_assumptions |>
      select(
        country_code,
        country_name,
        conversion_modifier,
        revenue_modifier
      ),
    by = "country_code"
  )

organic_installs <- organic_installs |>
  left_join(
    country_assumptions |>
      select(
        country_code,
        country_name,
        conversion_modifier_country = conversion_modifier,
        revenue_modifier_country = revenue_modifier
      ),
    by = "country_code"
  ) |>
  
  left_join(
    platform_assumptions |>
      select(
        platform,
        conversion_modifier_platform = conversion_modifier,
        revenue_modifier_platform = revenue_modifier
      ),
    by = "platform"
  )
#--------------------------------------------------------------------
# Generate IDs 
#-----------------------------------------------------------------
organic_installs <- organic_installs |>
  mutate(
    
    user_sequence =
      nrow(paid_installs) +
      row_number(),
    
    appsflyer_id = sprintf(
      "AF_%09d",
      user_sequence
    ),
    
    customer_user_id = sprintf(
      "PPU_%09d",
      user_sequence
    )
  )
# Generate install timestamps 
organic_installs <- organic_installs |>
  mutate(
    
    install_time =
      as.POSIXct(
        date,
        tz = "UTC"
      ) +
      sample(
        0:86399,
        size = n(),
        replace = TRUE
      )
  )
# Define attribution fields 
organic_installs <- organic_installs |>
  mutate(
    
    channel = "Organic",
    
    campaign_id = NA_character_,
    
    campaign_name = NA_character_,
    
    creative_id = NA_character_,
    
    creative_name = NA_character_,
    
    creative_type = NA_character_,
    
    creative_concept = NA_character_,
    
    strategy_code = NA_character_,
    
    strategy_name = NA_character_,
    
    attributed_touch_type = NA_character_,
    
    attributed_touch_time =
      as.POSIXct(
        NA,
        origin = "1970-01-01",
        tz = "UTC"
      ),
    
    acquisition_type = "Organic",
    
    campaign_type = "Organic",
    
    is_organic = TRUE,
    
    is_retargeting = FALSE,
    
    attribution_provider =
      "AppsFlyer-style synthetic"
  )

# Add behavior assumptions for organic users 
organic_installs <- organic_installs |>
  mutate(
    
    retention_modifier = 1.05,
    
    payer_modifier = 1.05,
    
    d1_retention = 0.39,
    
    d7_retention = 0.19,
    
    d30_retention = 0.08,
    
    payer_probability = 0.045,
    
    ad_engagement_modifier = 1.00,
    
    expected_install_cvr = NA_real_
  )
# Align the paid and organic schemas 
paid_installs_final <- paid_installs |>
  select(
    appsflyer_id,
    customer_user_id,
    install_time,
    channel,
    campaign_id,
    campaign_name,
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    country_code,
    country_name,
    platform,
    strategy_code,
    strategy_name,
    retention_modifier,
    payer_modifier,
    d1_retention,
    d7_retention,
    d30_retention,
    payer_probability,
    ad_engagement_modifier,
    conversion_modifier_country,
    conversion_modifier_platform,
    revenue_modifier_country,
    revenue_modifier_platform,
    expected_install_cvr,
    attributed_touch_type,
    attributed_touch_time,
    acquisition_type,
    campaign_type,
    is_organic,
    is_retargeting,
    attribution_provider
  )

organic_installs_final <- organic_installs |>
  select(
    all_of(
      names(paid_installs_final)
    )
  )
# Removing the duplicated metadata columns 
organic_installs <- organic_installs |>
  select(
    -matches(
      "^country_name|^conversion_modifier|^revenue_modifier"
    )
  )
# Join each reference table exactly once 
organic_installs <- organic_installs |>
  left_join(
    country_assumptions |>
      transmute(
        country_code,
        country_name,
        conversion_modifier_country =
          conversion_modifier,
        revenue_modifier_country =
          revenue_modifier
      ),
    by = "country_code"
  )
# Attach modifiers exactly once 
organic_installs <- organic_installs |>
  left_join(
    platform_assumptions |>
      transmute(
        platform,
        conversion_modifier_platform =
          conversion_modifier,
        revenue_modifier_platform =
          revenue_modifier
      ),
    by = "platform"
  )
# Validation 
organic_installs |>
  select(
    country_code,
    country_name,
    platform,
    conversion_modifier_country,
    conversion_modifier_platform,
    revenue_modifier_country,
    revenue_modifier_platform
  ) |>
  head(10) |>
  print(width = Inf)

organic_metadata_qa <- organic_installs |>
  summarise(
    
    missing_country_name =
      sum(is.na(country_name)),
    
    missing_country_conversion =
      sum(is.na(conversion_modifier_country)),
    
    missing_platform_conversion =
      sum(is.na(conversion_modifier_platform)),
    
    missing_country_revenue =
      sum(is.na(revenue_modifier_country)),
    
    missing_platform_revenue =
      sum(is.na(revenue_modifier_platform))
  )

organic_metadata_qa |>
  print(width = Inf)

# Check specifically for duplicate fields 
names(organic_installs)[
  grepl(
    "\\.x$|\\.y$|\\.x\\.x$|\\.y\\.y$",
    names(organic_installs)
  )
]
#-----------------------------------------------------
# Final Schema alignment 
#--------------------------------------------------
# ---------------------------------------------------------
# Final paid-install schema
# ---------------------------------------------------------

paid_installs_final <- paid_installs |>
  select(
    appsflyer_id,
    customer_user_id,
    install_time,
    channel,
    campaign_id,
    campaign_name,
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    country_code,
    country_name,
    platform,
    strategy_code,
    strategy_name,
    retention_modifier,
    payer_modifier,
    d1_retention,
    d7_retention,
    d30_retention,
    payer_probability,
    ad_engagement_modifier,
    conversion_modifier_country,
    conversion_modifier_platform,
    revenue_modifier_country,
    revenue_modifier_platform,
    expected_install_cvr,
    attributed_touch_type,
    attributed_touch_time,
    acquisition_type,
    campaign_type,
    is_organic,
    is_retargeting,
    attribution_provider
  )

# ---------------------------------------------------------
# Align organic-install schema to paid-install schema
# ---------------------------------------------------------

organic_installs_final <- organic_installs |>
  select(
    all_of(
      names(paid_installs_final)
    )
  )
#------------------------------------------------------
# Validation
#------------------------------------------------------
identical(
  names(paid_installs_final),
  names(organic_installs_final)
)
#------------------------------------------------------------
# Combine paid + organic installs 
#------------------------------------------------------------
# ---------------------------------------------------------
# Combine paid and organic installs
# ---------------------------------------------------------

all_installs_truth <- bind_rows(
  paid_installs_final,
  organic_installs_final
)

# =========================================================
# PAID + ORGANIC ATTRIBUTION QA
# =========================================================

all_installs_qa <- all_installs_truth |>
  summarise(
    
    total_users =
      n(),
    
    unique_appsflyer_ids =
      n_distinct(appsflyer_id),
    
    unique_customer_user_ids =
      n_distinct(customer_user_id),
    
    duplicate_appsflyer_ids =
      n() - n_distinct(appsflyer_id),
    
    duplicate_customer_user_ids =
      n() - n_distinct(customer_user_id),
    
    paid_users =
      sum(
        acquisition_type == "Paid",
        na.rm = TRUE
      ),
    
    organic_users =
      sum(
        acquisition_type == "Organic",
        na.rm = TRUE
      ),
    
    organic_with_campaign =
      sum(
        acquisition_type == "Organic" &
          !is.na(campaign_id),
        na.rm = TRUE
      ),
    
    organic_with_creative =
      sum(
        acquisition_type == "Organic" &
          !is.na(creative_id),
        na.rm = TRUE
      ),
    
    paid_missing_campaign =
      sum(
        acquisition_type == "Paid" &
          is.na(campaign_id),
        na.rm = TRUE
      ),
    
    paid_missing_creative =
      sum(
        acquisition_type == "Paid" &
          is.na(creative_id),
        na.rm = TRUE
      ),
    
    paid_touch_after_install =
      sum(
        acquisition_type == "Paid" &
          attributed_touch_time >= install_time,
        na.rm = TRUE
      )
  )

all_installs_qa |>
  print(width = Inf)
# Check acquision mix 
all_installs_truth |>
  count(
    acquisition_type
  ) |>
  mutate(
    share =
      n / sum(n)
  )
#---------------------------------------------------------------
# Create User engagement propensity
#--------------------------------------------------------------
# =========================================================
# 6A.5.7 - USER ENGAGEMENT & RETENTION
# =========================================================

user_engagement_truth <- all_installs_truth |>
  mutate(
    
    # Individual user-level engagement variation
    engagement_score = rnorm(
      n(),
      mean = 1,
      sd = 0.15
    ),
    
    # Prevent unrealistic extreme values
    engagement_score = pmax(
      0.60,
      pmin(
        1.40,
        engagement_score
      )
    )
  )
# Generate session intensity 
user_engagement_truth <- user_engagement_truth |>
  mutate(
    
    sessions_first_7d = pmax(
      1L,
      round(
        rpois(
          n(),
          lambda = 5 * engagement_score
        )
      )
    )
  )
# Generate D1 retention
user_engagement_truth <- user_engagement_truth |>
  mutate(
    
    expected_d1_retention =
      d1_retention *
      retention_modifier *
      engagement_score,
    
    expected_d1_retention = pmax(
      0.05,
      pmin(
        0.80,
        expected_d1_retention
      )
    ),
    
    retained_d1 = rbinom(
      n = n(),
      size = 1,
      prob = expected_d1_retention
    )
  )
# Generate d7 retention
user_engagement_truth <- user_engagement_truth |>
  mutate(
    
    expected_d7_retention =
      d7_retention *
      retention_modifier *
      engagement_score,
    
    expected_d7_retention = pmax(
      0.02,
      pmin(
        0.55,
        expected_d7_retention
      )
    ),
    
    retained_d7 = if_else(
      retained_d1 == 1,
      
      rbinom(
        n = n(),
        size = 1,
        prob = expected_d7_retention
      ),
      
      0L
    )
  )
# Generate D30 retention 
user_engagement_truth <- user_engagement_truth |>
  mutate(
    
    expected_d30_retention =
      d30_retention *
      retention_modifier *
      engagement_score,
    
    expected_d30_retention = pmax(
      0.01,
      pmin(
        0.35,
        expected_d30_retention
      )
    ),
    
    retained_d30 = if_else(
      retained_d7 == 1,
      
      rbinom(
        n = n(),
        size = 1,
        prob = expected_d30_retention
      ),
      
      0L
    )
  )

# =========================================================
# 6A.5.7 - ENGAGEMENT & RETENTION
# Purpose:
# Evaluate post-install user quality by acquisition source
# =========================================================

user_behavior_truth <- all_installs_truth |>
  mutate(
    
    engagement_score = rnorm(
      n(),
      mean = 1,
      sd = 0.15
    ),
    
    engagement_score = pmax(
      0.60,
      pmin(
        1.40,
        engagement_score
      )
    )
  )
# Validation 
user_behavior_truth |>
  summarise(
    users = n(),
    min_engagement = min(engagement_score),
    avg_engagement = mean(engagement_score),
    max_engagement = max(engagement_score)
  )
# ---------------------------------------------------------
# Generate first-week session activity
# ---------------------------------------------------------

user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    sessions_first_7d = pmax(
      1L,
      rpois(
        n(),
        lambda = 5 * engagement_score
      )
    )
  )
# Validation 
user_behavior_truth |>
  summarise(
    
    users = n(),
    
    min_sessions =
      min(sessions_first_7d),
    
    avg_sessions =
      mean(sessions_first_7d),
    
    median_sessions =
      median(sessions_first_7d),
    
    max_sessions =
      max(sessions_first_7d),
    
    zero_session_users =
      sum(sessions_first_7d == 0)
  ) |>
  print(width = Inf)
# ---------------------------------------------------------
# Generate Day-N retention probabilities
# ---------------------------------------------------------

user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    # Day 1 return probability
    expected_d1 =
      d1_retention *
      retention_modifier *
      engagement_score,
    
    # Day 7 return probability
    expected_d7 =
      d7_retention *
      retention_modifier *
      engagement_score,
    
    # Day 30 return probability
    expected_d30 =
      d30_retention *
      retention_modifier *
      engagement_score,
    
    # Keep probabilities within controlled simulation limits
    expected_d1 = pmax(
      0.05,
      pmin(0.75, expected_d1)
    ),
    
    expected_d7 = pmax(
      0.01,
      pmin(0.45, expected_d7)
    ),
    
    expected_d30 = pmax(
      0.005,
      pmin(0.25, expected_d30)
    )
  )
# ---------------------------------------------------------
# Generate observed Day-N retention outcomes
# ---------------------------------------------------------

user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    retained_d1 = rbinom(
      n(),
      size = 1,
      prob = expected_d1
    ),
    
    retained_d7 = rbinom(
      n(),
      size = 1,
      prob = expected_d7
    ),
    
    retained_d30 = rbinom(
      n(),
      size = 1,
      prob = expected_d30
    )
  )
# Validaton 
retention_qa <- user_behavior_truth |>
  summarise(
    
    users = n(),
    
    d1_rate =
      mean(retained_d1),
    
    d7_rate =
      mean(retained_d7),
    
    d30_rate =
      mean(retained_d30),
    
    invalid_d1 =
      sum(!retained_d1 %in% c(0, 1)),
    
    invalid_d7 =
      sum(!retained_d7 %in% c(0, 1)),
    
    invalid_d30 =
      sum(!retained_d30 %in% c(0, 1)),
    
    missing_d1 =
      sum(is.na(retained_d1)),
    
    missing_d7 =
      sum(is.na(retained_d7)),
    
    missing_d30 =
      sum(is.na(retained_d30))
  )

## ---------------------------------------------------------
# Retention assumptions for the user-quality layer
# Synthetic values designed for the PuzzlePop scenario
# ---------------------------------------------------------

retention_reference <- tibble(
  
  channel = c(
    "Facebook Audience Network",
    "TikTok Ads",
    "Google App Campaigns",
    "Snapchat Ads",
    "Unity Ads",
    "Organic"
  ),
  
  d1_retention = c(
    0.28,
    0.26,
    0.31,
    0.24,
    0.27,
    0.29
  ),
  
  d7_retention = c(
    0.085,
    0.075,
    0.105,
    0.065,
    0.080,
    0.090
  ),
  
  d30_retention = c(
    0.032,
    0.026,
    0.043,
    0.021,
    0.028,
    0.035
  )
)

retention_qa |>
  print(width = Inf)

# Validation 
retention_reference |>
  summarise(
    channels = n(),
    missing_channels = sum(is.na(channel)),
    min_d1 = min(d1_retention),
    max_d1 = max(d1_retention),
    min_d7 = min(d7_retention),
    max_d7 = max(d7_retention),
    min_d30 = min(d30_retention),
    max_d30 = max(d30_retention)
  ) |>
  print(width = Inf)

all_installs_truth |>
  distinct(channel) |>
  anti_join(
    retention_reference,
    by = "channel"
  )
# ---------------------------------------------------------
# Reproducible behavioral simulation
# ---------------------------------------------------------

set.seed(202607)

# ---------------------------------------------------------
# Build final user-behavior truth
# ---------------------------------------------------------

user_behavior_truth <- all_installs_truth |>
  
  # Remove the old retention baseline fields
  select(
    -d1_retention,
    -d7_retention,
    -d30_retention
  ) |>
  
  # Attach the newly validated retention assumptions
  left_join(
    retention_reference,
    by = "channel"
  )
# Generate engagement propensity 
user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    engagement_score = rnorm(
      n(),
      mean = 1,
      sd = 0.15
    ),
    
    engagement_score = pmax(
      0.60,
      pmin(
        1.40,
        engagement_score
      )
    )
  )
# Generate First week sessions 
user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    sessions_first_7d = pmax(
      1L,
      rpois(
        n(),
        lambda = 5 * engagement_score
      )
    )
  )

# Calculate Day-N retention probabilities 
user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    expected_d1 =
      d1_retention *
      retention_modifier *
      engagement_score,
    
    expected_d7 =
      d7_retention *
      retention_modifier *
      engagement_score,
    
    expected_d30 =
      d30_retention *
      retention_modifier *
      engagement_score,
    
    expected_d1 = pmax(
      0.03,
      pmin(
        0.60,
        expected_d1
      )
    ),
    
    expected_d7 = pmax(
      0.01,
      pmin(
        0.30,
        expected_d7
      )
    ),
    
    expected_d30 = pmax(
      0.005,
      pmin(
        0.15,
        expected_d30
      )
    )
  )
# Generate observed D1/D7/D30 outcomes 
user_behavior_truth <- user_behavior_truth |>
  mutate(
    
    retained_d1 = rbinom(
      n(),
      size = 1,
      prob = expected_d1
    ),
    
    retained_d7 = rbinom(
      n(),
      size = 1,
      prob = expected_d7
    ),
    
    retained_d30 = rbinom(
      n(),
      size = 1,
      prob = expected_d30
    )
  )
# =========================================================
# FINAL RETENTION QA
# =========================================================

retention_qa <- user_behavior_truth |>
  summarise(
    
    users = n(),
    
    avg_sessions_7d =
      mean(sessions_first_7d),
    
    d1_rate =
      mean(retained_d1),
    
    d7_rate =
      mean(retained_d7),
    
    d30_rate =
      mean(retained_d30),
    
    invalid_d1 =
      sum(!retained_d1 %in% c(0, 1)),
    
    invalid_d7 =
      sum(!retained_d7 %in% c(0, 1)),
    
    invalid_d30 =
      sum(!retained_d30 %in% c(0, 1)),
    
    missing_d1 =
      sum(is.na(retained_d1)),
    
    missing_d7 =
      sum(is.na(retained_d7)),
    
    missing_d30 =
      sum(is.na(retained_d30))
  )

retention_qa |>
  print(width = Inf)

# Validation 
retention_channel_qa <- user_behavior_truth |>
  group_by(channel) |>
  summarise(
    users = n(),
    avg_sessions_7d = mean(sessions_first_7d),
    d1 = mean(retained_d1),
    d7 = mean(retained_d7),
    d30 = mean(retained_d30),
    .groups = "drop"
  ) |>
  arrange(desc(d7))

retention_channel_qa |>
  print(width = Inf)
#------------------------------------------------------------
# Genrate payer status 
#-----------------------------------------------------------
# =========================================================
# 6A.5.8 - MONETIZATION
# IAP Revenue + Advertising Revenue
# =========================================================

set.seed(202608)

user_monetization_truth <- user_behavior_truth |>
  mutate(
    
    # Probability that a user becomes an IAP payer
    expected_payer_probability =
      payer_probability *
      payer_modifier *
      engagement_score,
    
    # Keep payer probabilities inside reasonable
    # synthetic-business boundaries
    expected_payer_probability = pmax(
      0.005,
      pmin(
        0.15,
        expected_payer_probability
      )
    ),
    
    # Generate observed payer status
    is_payer = rbinom(
      n(),
      size = 1,
      prob = expected_payer_probability
    )
  )
# Validate payer generation 
payer_qa <- user_monetization_truth |>
  summarise(
    
    users = n(),
    
    payers =
      sum(is_payer),
    
    payer_rate =
      mean(is_payer),
    
    invalid_payer_values =
      sum(
        !is_payer %in% c(0, 1)
      ),
    
    missing_payer_values =
      sum(
        is.na(is_payer)
      ),
    
    min_expected_payer_probability =
      min(expected_payer_probability),
    
    avg_expected_payer_probability =
      mean(expected_payer_probability),
    
    max_expected_payer_probability =
      max(expected_payer_probability)
  )

payer_qa |>
  print(width = Inf)
# ---------------------------------------------------------
# 6A.5.8A - CHANNEL-LEVEL PAYER QA
# ---------------------------------------------------------

payer_channel_qa <- user_monetization_truth |>
  group_by(channel) |>
  summarise(
    
    users =
      n(),
    
    payers =
      sum(is_payer),
    
    payer_rate =
      mean(is_payer),
    
    .groups = "drop"
  ) |>
  arrange(
    desc(payer_rate)
  )

payer_channel_qa |>
  print(width = Inf)

#------------------------------------------
# Generate purchase count and IAP revenue 
#--------------------------------------------
# ---------------------------------------------------------
# 6A.5.8B - Generate IAP revenue
# ---------------------------------------------------------

user_monetization_truth <- user_monetization_truth |>
  mutate(
    
    # Non-payers make no purchases.
    # Payers make at least one purchase.
    purchase_count = if_else(
      is_payer == 1,
      
      1L + rpois(
        n(),
        lambda =
          0.60 * engagement_score
      ),
      
      0L
    ),
    
    # Generate a positively skewed base purchase value
    base_revenue_per_purchase = if_else(
      is_payer == 1,
      
      rgamma(
        n(),
        shape = 2,
        scale = 6
      ),
      
      0
    ),
    
    # Calculate total IAP revenue using:
    # purchase frequency
    # user engagement
    # country revenue characteristics
    # platform revenue characteristics
    iap_revenue =
      purchase_count *
      base_revenue_per_purchase *
      engagement_score *
      revenue_modifier_country *
      revenue_modifier_platform,
    
    iap_revenue =
      round(
        iap_revenue,
        2
      )
  )
# =========================================================
# IAP REVENUE QA
# =========================================================

iap_qa <- user_monetization_truth |>
  summarise(
    
    users =
      n(),
    
    payers =
      sum(is_payer),
    
    users_with_revenue =
      sum(iap_revenue > 0),
    
    total_purchases =
      sum(purchase_count),
    
    total_iap_revenue =
      sum(iap_revenue),
    
    arpu =
      total_iap_revenue / users,
    
    arppu =
      total_iap_revenue / payers,
    
    nonpayer_with_purchase =
      sum(
        is_payer == 0 &
          purchase_count > 0
      ),
    
    nonpayer_with_revenue =
      sum(
        is_payer == 0 &
          iap_revenue > 0
      ),
    
    payer_without_purchase =
      sum(
        is_payer == 1 &
          purchase_count == 0
      ),
    
    payer_without_revenue =
      sum(
        is_payer == 1 &
          iap_revenue <= 0
      ),
    
    negative_revenue =
      sum(iap_revenue < 0),
    
    missing_revenue =
      sum(is.na(iap_revenue))
  )

iap_qa |>
  print(width = Inf)

# ---------------------------------------------------------
# 6A.5.8C - Generate advertising revenue
# ---------------------------------------------------------

set.seed(202609)

user_monetization_truth <- user_monetization_truth |>
  mutate(
    
    # Estimate monetizable ad impressions from
    # first-week user engagement
    ad_impressions = rpois(
      n(),
      lambda =
        sessions_first_7d *
        2 *
        ad_engagement_modifier
    ),
    
    # Base synthetic ad eCPM
    base_ad_ecpm = 10,
    
    # Adjust ad value by country and platform
    user_ad_ecpm =
      base_ad_ecpm *
      revenue_modifier_country *
      revenue_modifier_platform,
    
    # Calculate user-level advertising revenue
    ad_revenue =
      ad_impressions /
      1000 *
      user_ad_ecpm,
    
    ad_revenue =
      round(
        ad_revenue,
        4
      )
  )

# =========================================================
# AD REVENUE QA
# =========================================================

ad_revenue_qa <- user_monetization_truth |>
  summarise(
    
    users =
      n(),
    
    total_ad_impressions =
      sum(ad_impressions),
    
    users_with_ad_revenue =
      sum(ad_revenue > 0),
    
    total_ad_revenue =
      sum(ad_revenue),
    
    ad_arpu =
      total_ad_revenue / users,
    
    negative_ad_impressions =
      sum(ad_impressions < 0),
    
    negative_ad_revenue =
      sum(ad_revenue < 0),
    
    missing_ad_revenue =
      sum(is.na(ad_revenue))
  )

ad_revenue_qa |>
  print(width = Inf)

# ---------------------------------------------------------

# 6A.5.8D - Total user monetization
# Total user revenue 
# ---------------------------------------------------------

user_monetization_truth <- user_monetization_truth |>
  mutate(
    
    total_revenue =
      iap_revenue +
      ad_revenue
  )
# Validation 
monetization_qa <- user_monetization_truth |>
  summarise(
    
    users = n(),
    
    total_iap_revenue =
      sum(iap_revenue),
    
    total_ad_revenue =
      sum(ad_revenue),
    
    total_revenue =
      sum(total_revenue),
    
    arpu =
      total_revenue / users,
    
    iap_revenue_share =
      total_iap_revenue /
      total_revenue,
    
    ad_revenue_share =
      total_ad_revenue /
      total_revenue,
    
    negative_total_revenue =
      sum(total_revenue < 0),
    
    missing_total_revenue =
      sum(is.na(total_revenue))
  )

monetization_qa |>
  print(width = Inf)
# ---------------------------------------------------------
# 6A.5.8E - Paid channel economics
# Marketing spend by paid channel 
# ---------------------------------------------------------

paid_channel_spend <- install_delivery_truth |>
  group_by(channel) |>
  summarise(
    spend = sum(spend, na.rm = TRUE),
    clicks = sum(clicks, na.rm = TRUE),
    installs = sum(installs, na.rm = TRUE),
    .groups = "drop"
  )

paid_channel_value <- user_monetization_truth |>
  filter(
    acquisition_type == "Paid"
  ) |>
  group_by(channel) |>
  summarise(
    users = n(),
    
    d7_retention =
      mean(retained_d7),
    
    payer_rate =
      mean(is_payer),
    
    iap_revenue =
      sum(iap_revenue, na.rm = TRUE),
    
    ad_revenue =
      sum(ad_revenue, na.rm = TRUE),
    
    total_revenue =
      sum(total_revenue, na.rm = TRUE),
    
    .groups = "drop"
  )

# Join cost and value
channel_economics <- paid_channel_spend |>
  left_join(
    paid_channel_value,
    by = "channel"
  ) |>
  mutate(
    cpi =
      spend / installs,
    
    arpu =
      total_revenue / users,
    
    roas =
      total_revenue / spend
  ) |>
  arrange(
    desc(roas)
  )
# Validation 
channel_economics |>
  select(
    channel,
    spend,
    installs,
    cpi,
    d7_retention,
    payer_rate,
    iap_revenue,
    ad_revenue,
    total_revenue,
    arpu,
    roas
  ) |>
  print(width = Inf)
# Validation - Consolidated economics 
# =========================================================
# CONSOLIDATED CHANNEL ECONOMICS QA
# =========================================================

channel_economics_qa <- channel_economics |>
  summarise(
    
    channels =
      n(),
    
    total_spend =
      sum(spend, na.rm = TRUE),
    
    total_installs =
      sum(installs, na.rm = TRUE),
    
    total_users =
      sum(users, na.rm = TRUE),
    
    total_iap_revenue =
      sum(iap_revenue, na.rm = TRUE),
    
    total_ad_revenue =
      sum(ad_revenue, na.rm = TRUE),
    
    total_revenue =
      sum(total_revenue, na.rm = TRUE),
    
    blended_cpi =
      total_spend / total_installs,
    
    blended_arpu =
      total_revenue / total_users,
    
    blended_roas =
      total_revenue / total_spend,
    
    missing_values =
      sum(is.na(channel_economics)),
    
    negative_values =
      sum(
        spend < 0 |
          installs < 0 |
          iap_revenue < 0 |
          ad_revenue < 0 |
          total_revenue < 0,
        na.rm = TRUE
      )
  )

channel_economics_qa |>
  print(width = Inf)

paid_revenue_reconciliation <- user_monetization_truth |>
  filter(
    acquisition_type == "Paid"
  ) |>
  summarise(
    
    user_level_paid_revenue =
      sum(total_revenue, na.rm = TRUE),
    
    channel_level_paid_revenue =
      sum(channel_economics$total_revenue),
    
    difference =
      user_level_paid_revenue -
      channel_level_paid_revenue
  )

paid_revenue_reconciliation |>
  print(width = Inf)
#-------------------------------------------
# Assign eligible users 
#------------------------------------------
# =========================================================
# 6A.5.9 - A/B EXPERIMENT
# Standard onboarding vs shorter onboarding
# =========================================================

set.seed(202610)

experiment_truth <- user_monetization_truth |>
  mutate(
    
    # Approximately 40% of users are eligible
    # for the onboarding experiment
    experiment_eligible = rbinom(
      n(),
      size = 1,
      prob = 0.40
    ),
    
    experiment_id = if_else(
      experiment_eligible == 1,
      "EXP_ONBOARDING_001",
      NA_character_
    ),
    
    experiment_variant = case_when(
      experiment_eligible == 0 ~ NA_character_,
      
      runif(n()) < 0.50 ~ "Control",
      
      TRUE ~ "Treatment"
    )
  )
# Validation 
experiment_assignment_qa <- experiment_truth |>
  summarise(
    
    total_users = n(),
    
    eligible_users =
      sum(experiment_eligible == 1),
    
    ineligible_users =
      sum(experiment_eligible == 0),
    
    control_users =
      sum(
        experiment_variant == "Control",
        na.rm = TRUE
      ),
    
    treatment_users =
      sum(
        experiment_variant == "Treatment",
        na.rm = TRUE
      ),
    
    eligible_without_experiment_id =
      sum(
        experiment_eligible == 1 &
          is.na(experiment_id)
      ),
    
    eligible_without_variant =
      sum(
        experiment_eligible == 1 &
          is.na(experiment_variant)
      ),
    
    ineligible_with_variant =
      sum(
        experiment_eligible == 0 &
          !is.na(experiment_variant)
      )
  )

experiment_assignment_qa |>
  print(width = Inf)
# ---------------------------------------------------------
# 6A.5.9B - Experiment primary outcome
# Tutorial completion
# ---------------------------------------------------------

experiment_participants <- experiment_truth |>
  filter(
    experiment_eligible == 1
  )

# Define completion probability 
experiment_participants <- experiment_participants |>
  mutate(
    
    expected_tutorial_completion =
      case_when(
        
        experiment_variant == "Control" ~
          0.72 * engagement_score,
        
        experiment_variant == "Treatment" ~
          0.75 * engagement_score,
        
        TRUE ~ NA_real_
      ),
    
    expected_tutorial_completion =
      pmax(
        0.30,
        pmin(
          0.95,
          expected_tutorial_completion
        )
      )
  )
# Generate observed tutorial completion 
experiment_participants <- experiment_participants |>
  mutate(
    
    tutorial_completed =
      rbinom(
        n(),
        size = 1,
        prob =
          expected_tutorial_completion
      )
  )
# Validation 
experiment_primary_qa <- experiment_participants |>
  group_by(
    experiment_variant
  ) |>
  summarise(
    
    users = n(),
    
    completed =
      sum(tutorial_completed),
    
    completion_rate =
      mean(tutorial_completed),
    
    invalid_values =
      sum(
        !tutorial_completed %in% c(0, 1)
      ),
    
    missing_values =
      sum(
        is.na(tutorial_completed)
      ),
    
    .groups = "drop"
  )

experiment_primary_qa |>
  print(width = Inf)
# =========================================================
# 6A.5.10 - RAW BUSINESS DATA PREPARATION
# Preserve clean synthetic truth before injecting messiness
# =========================================================

truth_ad_delivery <- clean_ad_delivery_truth

truth_installs <- all_installs_truth

truth_user_behavior <- user_behavior_truth

truth_monetization <- user_monetization_truth

truth_experiment <- experiment_participants

# Validation - all copies 
truth_layer_qa <- tibble(
  
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

truth_layer_qa
# =========================================================
# 6A.5.10B - SAVE CLEAN TRUTH OBJECTS
# =========================================================

dir.create(
  "data/truth",
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  truth_ad_delivery,
  "data/truth/truth_ad_delivery.rds"
)

saveRDS(
  truth_installs,
  "data/truth/truth_installs.rds"
)

saveRDS(
  truth_user_behavior,
  "data/truth/truth_user_behavior.rds"
)

saveRDS(
  truth_monetization,
  "data/truth/truth_monetization.rds"
)

saveRDS(
  truth_experiment,
  "data/truth/truth_experiment.rds"
)
list.files(
  "data/truth"
)