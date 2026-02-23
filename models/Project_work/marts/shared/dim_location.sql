WITH all_locations AS(
    SELECT DISTINCT
        borough,
        zip_code
    FROM {{ref('stg_nyc_service_requests_2020')}}
    WHERE borough IS NOT NULL or zip_code IS NOT NULL
    UNION DISTINCT

    SELECT DISTINCT
        borough,
        zip_code
    FROM {{ref('stg_source_nyc_vehicle_collisions')}}
    WHERE borough IS NOT NULL or zip_code IS NOT NULL
),

location_dimension AS (
    SELECT
        {{dbt_utils.generate_surrogate_key(['borough', 'zip_code'])}} AS location_key,
        borough,
        zip_code,

        CASE
            WHEN borough IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS is_valid_borough
    FROM all_locations
)
SELECT * FROM location_dimension