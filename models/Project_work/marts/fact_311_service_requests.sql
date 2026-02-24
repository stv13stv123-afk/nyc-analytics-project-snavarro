WITH service_request_source AS(
    SELECT * FROM {{ ref('stg_nyc_service_request_from_2020')}}
),
fact_311 AS (
    SELECT
        {{dbt_utils.generate_surrogate_key(['request_id'])}} AS service_request_pk,
        {{dbt_utils.generate_surrogate_key(['CAST(created_date AS DATE)'])}} AS date_fk,
        {{dbt_utils.generate_surrogate_key(['borough', 'incident_zip'])}} AS location_fk,
        {{dbt_utils.generate_surrogate_key(['agency', 'complaint_type', 'descriptor'])}} AS complaint_type_fk,
        {{dbt_utils.generate_surrogate_key(['EXTRACT(HOUR FROM created_date)']) }} as time_fk,

        request_id,

        1 AS complaint_count,
        latitude,
        longitude,
        
        created_date,
        closed_date
    FROM service_request_source
)
SELECT * FROM fact_311