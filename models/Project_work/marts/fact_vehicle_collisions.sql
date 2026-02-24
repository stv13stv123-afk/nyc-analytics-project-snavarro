WITH collisions_source AS (
    SELECT * FROM {{ref('stg_source_nyc_vehicle_collisions')}}
),

fact_collisions AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['collision_id'])}} AS collision_pk,

        {{ dbt_utils.generate_surrogate_key(['CAST(crash_date AS DATE)'])}} AS date_fk,
        {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code'])}} AS location_fk,
        {{ dbt_utils.generate_surrogate_key(["EXTRACT(HOUR FROM PARSE_TIME('%H:%M', crash_time))"])}} AS time_fk,
        {{ dbt_utils.generate_surrogate_key(['contributing_factor_vehicle_1', 'vehicle_type_code1'])}} AS collision_detail_fk,

        collision_id,

        CAST(count_persons_injured AS INT64) AS number_of_persons_injured,
        CAST(count_persons_killed AS INT64) AS number_of_persons_killed,

        latitude,
        longitude,

        crash_date,
        crash_time
    FROM collisions_source
)
SELECT * FROM fact_collisions