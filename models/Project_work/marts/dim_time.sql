WITH all_times AS (
    SELECT DISTINCT
        EXTRACT(HOUR FROM created_date) AS hour_of_day
    FROM {{ ref('stg_nyc_service_request_from_2020')}}
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT 
        EXTRACT(HOUR FROM PARSE_TIME('%H:%M', crash_time)) AS hour_of_day
    FROM {{ ref('stg_source_nyc_vehicle_collisions')}}
    WHERE crash_time IS NOT NULL
),

time_dimension AS (
    SELECT
        {{dbt_utils.generate_surrogate_key(['hour_of_day'])}} AS time_key,
        hour_of_day AS hour,

    CASE
        WHEN hour_of_day BETWEEN 7 and 9 THEN TRUE
        WHEN hour_of_day BETWEEN 16 and 18 THEN TRUE
        ELSE FALSE
    END AS is_peak_time,

    CASE
        WHEN hour_of_day BETWEEN 5 and 11 THEN 'Morning'
        WHEN hour_of_day BETWEEN 12 and 16 THEN 'Afternoon'
        WHEN hour_of_day BETWEEN 17 and 21 THEN 'Evening'
        ELSE 'NIGHT'
    END AS time_of_day_bucket

FROM all_times
)

SELECT * FROM time_dimension
WHERE hour is NOT NULL