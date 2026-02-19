-- Clean and standardize NYC Open Restaurant Applications data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Get all columns from source, except ones we're transforming below
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

        -- Identifiers
        CAST(unique_key AS STRING) AS application_id,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Location - address details
        CAST(bulding_number AS STRING) AS building_number,
        
        -- Location - clean zip code
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

        -- Location - standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Dimensions (Casting to Decimal for calculations)
        CAST(roadway_dimensions_area AS DECIMAL) AS roadway_area,
        CAST(roadway_dimensions_length AS DECIMAL) AS roadway_length,
        CAST(roadway_dimensions_width AS DECIMAL) AS roadway_width,
        CAST(sidewalk_dimensions_area AS DECIMAL) AS sidewalk_area,
        CAST(sidewalk_dimensions_length AS DECIMAL) AS sidewalk_length,
        CAST(sidewalk_dimensions_width AS DECIMAL) AS sidewalk_width,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    -- Note: WHERE can still see the original names because it runs BEFORE the SELECT
    WHERE unique_key IS NOT NULL
    AND time_of_submission IS NOT NULL
    AND CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    -- Deduplicate
    -- Note: QUALIFY must use the NEW ALIASES because it runs AFTER the SELECT
    QUALIFY ROW_NUMBER() OVER (PARTITION BY application_id ORDER BY submitted_at DESC) = 1
)

SELECT * FROM cleaned