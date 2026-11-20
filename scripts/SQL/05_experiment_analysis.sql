-- =========================================================
-- PuzzlePop Marketing Analytics
-- 05 - A/B Experiment Analysis
-- =========================================================
--
-- Purpose:
-- Evaluate the PuzzlePop onboarding experiment from both
-- statistical and business perspectives.
--
-- Analytical sequence:
-- 1. Control vs Treatment baseline
-- 2. Absolute and relative uplift
-- 3. Statistical significance
-- 4. Two-proportion z-test
-- 5. 95% confidence interval
-- 6. Retention and monetization guardrails
--
-- Primary KPI:
-- Tutorial completion
--
-- Secondary / guardrail metrics:
-- D1 retention
-- D7 retention
-- D30 retention
-- Payer rate
-- Revenue per participant
--
-- Important:
-- Statistical significance of the primary KPI does not by
-- itself justify rollout. Downstream business guardrails
-- must also be considered.
--
-- Prerequisites:
-- 01_schema.sql
-- 02_load_data.sql
-- 03_validation_constraints.sql
--
-- All project data is synthetic.
-- =========================================================

USE puzzlepop_marketing;

-- =========================================================
-- 1. EXPERIMENT BASELINE AND OUTCOME SUMMARY
-- ========================================================= 
SELECT
    experiment_id,
    experiment_variant,

    COUNT(*) AS participants,

    SUM(tutorial_completed = 1) AS tutorial_completions,

    ROUND(
        100.0 * AVG(tutorial_completed),
        2
    ) AS tutorial_completion_pct,

    ROUND(
        100.0 * AVG(retained_d1),
        2
    ) AS d1_retention_pct,

    ROUND(
        100.0 * AVG(retained_d7),
        2
    ) AS d7_retention_pct,

    ROUND(
        100.0 * AVG(retained_d30),
        2
    ) AS d30_retention_pct,

    ROUND(
        100.0 * AVG(is_payer),
        2
    ) AS payer_rate_pct,

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_revenue),
        4
    ) AS revenue_per_participant

FROM analytics_experiment

GROUP BY
    experiment_id,
    experiment_variant

ORDER BY
    experiment_id,
    experiment_variant;
    
# Calculate absolute and Relative Uplift 
WITH variant_summary AS (

    SELECT
        experiment_id,
        experiment_variant,
        COUNT(*) AS participants,
        SUM(tutorial_completed = 1) AS tutorial_completions,
        AVG(tutorial_completed) AS completion_rate

    FROM analytics_experiment

    GROUP BY
        experiment_id,
        experiment_variant
),

control_treatment AS (

    SELECT
        experiment_id,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN participants
            END
        ) AS control_participants,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN participants
            END
        ) AS treatment_participants,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN tutorial_completions
            END
        ) AS control_completions,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN tutorial_completions
            END
        ) AS treatment_completions,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN completion_rate
            END
        ) AS control_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN completion_rate
            END
        ) AS treatment_rate

    FROM variant_summary

    GROUP BY
        experiment_id
)

SELECT
    experiment_id,

    control_participants,
    treatment_participants,

    control_completions,
    treatment_completions,

    ROUND(
        100.0 * control_rate,
        2
    ) AS control_completion_pct,

    ROUND(
        100.0 * treatment_rate,
        2
    ) AS treatment_completion_pct,

    ROUND(
        100.0 * (
            treatment_rate - control_rate
        ),
        2
    ) AS absolute_uplift_percentage_points,

    ROUND(
        100.0 * (
            treatment_rate - control_rate
        ) / NULLIF(control_rate, 0),
        2
    ) AS relative_uplift_pct,

    ROUND(
        treatment_participants
        * (
            treatment_rate - control_rate
        ),
        0
    ) AS incremental_tutorial_completions

FROM control_treatment;

# Statistical Significance + 95% Confidence Interval 
WITH variant_stats AS (

    SELECT
        experiment_variant,
        COUNT(*) AS n,
        SUM(tutorial_completed = 1) AS successes,
        AVG(tutorial_completed) AS p

    FROM analytics_experiment

    GROUP BY
        experiment_variant
),

experiment_stats AS (

    SELECT

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN n
            END
        ) AS n_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN n
            END
        ) AS n_treatment,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN successes
            END
        ) AS x_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN successes
            END
        ) AS x_treatment,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN p
            END
        ) AS p_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN p
            END
        ) AS p_treatment

    FROM variant_stats
)

SELECT
    n_control,
    n_treatment,
    x_control,
    x_treatment,

    ROUND(
        p_control,
        6
    ) AS p_control,

    ROUND(
        p_treatment,
        6
    ) AS p_treatment,

    ROUND(
        p_treatment - p_control,
        6
    ) AS rate_difference,

    ROUND(
        (x_control + x_treatment)
        /
        (n_control + n_treatment),
        6
    ) AS pooled_rate

FROM experiment_stats;

# Z-Test and 95% Confidence Interval 
WITH variant_stats AS (

    SELECT
        experiment_variant,
        COUNT(*) AS n,
        SUM(tutorial_completed = 1) AS successes,
        AVG(tutorial_completed) AS p

    FROM analytics_experiment

    GROUP BY
        experiment_variant
),

experiment_inputs AS (

    SELECT
        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN n
            END
        ) AS n_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN n
            END
        ) AS n_treatment,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN successes
            END
        ) AS x_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN successes
            END
        ) AS x_treatment,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN p
            END
        ) AS p_control,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN p
            END
        ) AS p_treatment

    FROM variant_stats
),

test_components AS (

    SELECT
        n_control,
        n_treatment,
        x_control,
        x_treatment,
        p_control,
        p_treatment,

        p_treatment - p_control
            AS rate_difference,

        (x_control + x_treatment)
        / (n_control + n_treatment)
            AS pooled_rate

    FROM experiment_inputs
),

standard_errors AS (

    SELECT
        n_control,
        n_treatment,
        x_control,
        x_treatment,
        p_control,
        p_treatment,
        rate_difference,
        pooled_rate,

        SQRT(
            pooled_rate
            * (1 - pooled_rate)
            * (
                1.0 / n_control
                + 1.0 / n_treatment
            )
        ) AS pooled_standard_error,

        SQRT(
            p_control
            * (1 - p_control)
            / n_control

            +

            p_treatment
            * (1 - p_treatment)
            / n_treatment
        ) AS unpooled_standard_error

    FROM test_components
),

test_results AS (

    SELECT
        n_control,
        n_treatment,
        x_control,
        x_treatment,
        p_control,
        p_treatment,
        rate_difference,
        pooled_rate,
        pooled_standard_error,
        unpooled_standard_error,

        rate_difference
        / NULLIF(pooled_standard_error, 0)
            AS z_statistic,

        rate_difference
        - 1.96 * unpooled_standard_error
            AS ci_lower,

        rate_difference
        + 1.96 * unpooled_standard_error
            AS ci_upper

    FROM standard_errors
)

SELECT
    n_control,
    n_treatment,
    x_control,
    x_treatment,

    ROUND(
        100.0 * p_control,
        2
    ) AS control_completion_pct,

    ROUND(
        100.0 * p_treatment,
        2
    ) AS treatment_completion_pct,

    ROUND(
        100.0 * rate_difference,
        2
    ) AS uplift_percentage_points,

    ROUND(
        pooled_standard_error,
        6
    ) AS pooled_standard_error,

    ROUND(
        unpooled_standard_error,
        6
    ) AS unpooled_standard_error,

    ROUND(
        z_statistic,
        4
    ) AS z_statistic,

    ROUND(
        100.0 * ci_lower,
        2
    ) AS ci_lower_percentage_points,

    ROUND(
        100.0 * ci_upper,
        2
    ) AS ci_upper_percentage_points,

    CASE
        WHEN ABS(z_statistic) > 1.96
        THEN 'Statistically significant at 5%'

        ELSE 'Not statistically significant at 5%'
    END AS significance_decision

FROM test_results;

# Integrated Secondary-Outcome and Guardrail Diagnostic 
WITH variant_outcomes AS (

    SELECT
        experiment_id,
        experiment_variant,

        COUNT(*) AS participants,

        AVG(retained_d1) AS d1_rate,
        AVG(retained_d7) AS d7_rate,
        AVG(retained_d30) AS d30_rate,
        AVG(is_payer) AS payer_rate,
        AVG(total_revenue) AS revenue_per_participant

    FROM analytics_experiment

    GROUP BY
        experiment_id,
        experiment_variant
),

experiment_comparison AS (

    SELECT
        experiment_id,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN participants
            END
        ) AS control_participants,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN participants
            END
        ) AS treatment_participants,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN d1_rate
            END
        ) AS control_d1_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN d1_rate
            END
        ) AS treatment_d1_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN d7_rate
            END
        ) AS control_d7_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN d7_rate
            END
        ) AS treatment_d7_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN d30_rate
            END
        ) AS control_d30_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN d30_rate
            END
        ) AS treatment_d30_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN payer_rate
            END
        ) AS control_payer_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN payer_rate
            END
        ) AS treatment_payer_rate,

        MAX(
            CASE
                WHEN experiment_variant = 'Control'
                THEN revenue_per_participant
            END
        ) AS control_revenue_per_participant,

        MAX(
            CASE
                WHEN experiment_variant = 'Treatment'
                THEN revenue_per_participant
            END
        ) AS treatment_revenue_per_participant

    FROM variant_outcomes

    GROUP BY
        experiment_id
)

SELECT
    experiment_id,

    control_participants,
    treatment_participants,

    ROUND(
        100.0 * control_d1_rate,
        2
    ) AS control_d1_pct,

    ROUND(
        100.0 * treatment_d1_rate,
        2
    ) AS treatment_d1_pct,

    ROUND(
        100.0 * (
            treatment_d1_rate - control_d1_rate
        ),
        2
    ) AS d1_absolute_difference_pp,

    ROUND(
        100.0 * (
            treatment_d1_rate - control_d1_rate
        ) / NULLIF(control_d1_rate, 0),
        2
    ) AS d1_relative_difference_pct,

    ROUND(
        100.0 * control_d7_rate,
        2
    ) AS control_d7_pct,

    ROUND(
        100.0 * treatment_d7_rate,
        2
    ) AS treatment_d7_pct,

    ROUND(
        100.0 * (
            treatment_d7_rate - control_d7_rate
        ),
        2
    ) AS d7_absolute_difference_pp,

    ROUND(
        100.0 * (
            treatment_d7_rate - control_d7_rate
        ) / NULLIF(control_d7_rate, 0),
        2
    ) AS d7_relative_difference_pct,

    ROUND(
        100.0 * control_d30_rate,
        2
    ) AS control_d30_pct,

    ROUND(
        100.0 * treatment_d30_rate,
        2
    ) AS treatment_d30_pct,

    ROUND(
        100.0 * (
            treatment_d30_rate - control_d30_rate
        ),
        2
    ) AS d30_absolute_difference_pp,

    ROUND(
        100.0 * (
            treatment_d30_rate - control_d30_rate
        ) / NULLIF(control_d30_rate, 0),
        2
    ) AS d30_relative_difference_pct,

    ROUND(
        100.0 * control_payer_rate,
        2
    ) AS control_payer_rate_pct,

    ROUND(
        100.0 * treatment_payer_rate,
        2
    ) AS treatment_payer_rate_pct,

    ROUND(
        100.0 * (
            treatment_payer_rate - control_payer_rate
        ),
        2
    ) AS payer_absolute_difference_pp,

    ROUND(
        100.0 * (
            treatment_payer_rate - control_payer_rate
        ) / NULLIF(control_payer_rate, 0),
        2
    ) AS payer_relative_difference_pct,

    ROUND(
        control_revenue_per_participant,
        4
    ) AS control_revenue_per_participant,

    ROUND(
        treatment_revenue_per_participant,
        4
    ) AS treatment_revenue_per_participant,

    ROUND(
        treatment_revenue_per_participant
        - control_revenue_per_participant,
        4
    ) AS revenue_absolute_difference,

    ROUND(
        100.0 * (
            treatment_revenue_per_participant
            - control_revenue_per_participant
        )
        / NULLIF(
            control_revenue_per_participant,
            0
        ),
        2
    ) AS revenue_relative_difference_pct,

    CASE
        WHEN treatment_payer_rate
             < control_payer_rate

         AND treatment_revenue_per_participant
             < control_revenue_per_participant

        THEN 'Primary KPI improved, but monetization guardrails declined'

        WHEN treatment_payer_rate
             >= control_payer_rate

         AND treatment_revenue_per_participant
             >= control_revenue_per_participant

        THEN 'Primary KPI and monetization outcomes improved'

        ELSE 'Mixed monetization results'
    END AS guardrail_assessment

FROM experiment_comparison;

