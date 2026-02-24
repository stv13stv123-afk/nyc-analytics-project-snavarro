WITH all_complaint_types AS (
    SELECT DISTINCT
        agency,
        complaint_type,
        descriptor
    FROM {{ref ('stg_nyc_service_request_from_2020')}}
    WHERE complaint_type IS NOT NULL
),
complaint_dimension AS (
    SELECT
        {{dbt_utils.generate_surrogate_key(['agency', 'complaint_type', 'descriptor'])}} AS complaint_type_key,
        agency,
        complaint_type,
        descriptor

    FROM all_complaint_types
)
SELECT * FROM complaint_dimension