WITH source AS(
    SELECT * FROM {{source('raw', 'source_nyc_vehicle_collisions')}}
),
cleaned AS (
    SELECT
        * EXCEPT(
            collision_id,
            crash_date,
            crash_time,
            borough,
            zip_code,
            latitude,
            longitude,
            number_of_persons_injured,
            number_of_persons_killed,
            number_of_cyclist_injured,
            number_of_cyclist_killed,
            number_of_motorist_injured,
            number_of_motorist_killed,
            number_of_pedestrians_injured,
            number_of_pedestrians_killed
        ),

        CAST(collision_id AS STRING) AS collision_id,

        CAST(crash_date AS TIMESTAMP) AS crash_date,
        CAST(crash_time AS STRING) AS crash_time,

        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CASE
            WHEN LENGTH(REGEXP_EXTRACT(CAST(incident_zip AS STRING), r'^(\d{5})')) = 5
                THEN REGEXP_EXTRACT(CAST(incident_zip AS STRING), r'^(\d{5})')
            ELSE NULL
        END AS zip_code,

        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        SAFE_CAST(number_of_persons_injured AS INT64) AS count_persons_injured,
        SAFE_CAST(number_of_persons_killed AS INT64) AS count_persons_killed,
        SAFE_CAST(number_of_cyclist_injured AS INT64) AS count_cyclist_injured,
        SAFE_CAST(number_of_cyclist_killed AS INT64) AS count_cyclist_killed,
        SAFE_CAST(number_of_motorist_injured AS INT64) AS count_motorists_injured,
        SAFE_CAST(number_of_motorist_killed AS INT64) AS count_motorists_killed,
        SAFE_CAST(number_of_pedestrians_injured AS INT64) AS count_pedestrians_injured,
        SAFE_CAST(number of number_of_pedestrians_killed AS INT64) AS count_pedestrians_killed
        
        CURRENT_TIMESTAMP() AS _stg_loaded_at
        
    FROM source
    
    WHERE collision_id is NOT NULL
    AND crash_date is NOT NULL
    AND CAST (crash_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
    
    QUALIFY ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) = 1
)
SELECT * FROM CLEANED