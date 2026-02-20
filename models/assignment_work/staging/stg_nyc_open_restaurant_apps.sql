-- Clean and standardize NYC Open Restaurant Applications data
WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- 1. Exclude the raw columns we are about to transform
        * EXCEPT (
            unique_key,
            time_of_submission,
            bulding_number,
            zip,
            borough,
            latitude,
            longitude,
            roadway_dimensions_area,
            roadway_dimensions_length,
            roadway_dimensions_width,
            sidewalk_dimensions_area,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width
        ),

        -- 2. Identifiers & Timestamps
        CAST(unique_key AS STRING) AS application_id,
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- 3. Location cleaning (Fixing the 'bulding' typo from source)
        CAST(bulding_number AS STRING) AS building_number,
        
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10 
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}') 
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- 4. Dimensions
        CAST(roadway_dimensions_area AS FLOAT64) AS roadway_area,
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_length,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_width,
        CAST(sidewalk_dimensions_area AS FLOAT64) AS sidewalk_area,
        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_length,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_width,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- WHERE runs BEFORE SELECT, so it still uses the original source names
    WHERE unique_key IS NOT NULL
      AND time_of_submission IS NOT NULL
      AND CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    -- QUALIFY runs AFTER SELECT, so it MUST use your new aliases
    QUALIFY ROW_NUMBER() OVER (PARTITION BY application_id ORDER BY submitted_at DESC) = 1
)

SELECT * FROM cleaned