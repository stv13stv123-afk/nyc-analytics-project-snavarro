WITH collision_details_source AS (
    SELECT DISTINCT
        contributing_factor_vehicle_1 AS contributing_factor,
        vehicle_type_code1 AS vehicle_type_1,
        vehicle_type_code2 AS vehicle_type_2,
    FROM {{ ref('stg_source_nyc_vehicle_collisions')}}
    WHERE contributing_factor_vehicle_1 IS NOT NULL
        OR vehicle_type_code1 IS NOT NULL
),

collision_details_dimension AS (
    SELECT

        {{dbt_utils.generate_surrogate_key([ 'contributing_factor', 'vehicle_type_1', 'vehicle_type_2'
        ])}} AS collision_detail_key,

        contributing_factor, vehicle_type_1, vehicle_type_2

        FROM collision_details_source
)

SELECT * FROM collision_details_dimension