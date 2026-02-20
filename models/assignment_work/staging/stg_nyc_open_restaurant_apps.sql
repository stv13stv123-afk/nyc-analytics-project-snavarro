-- Clean and standardize NYC Open Restaurant Applications data
WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Use EXCEPT to exclude columns we are manually transforming
        * EXCEPT (
            unique_key,
            time_of_submission,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            building_number, -- Changed from 'bulding' to 'building'
            street,
            borough,
            zip,
            latitude,
            longitude
        ),

        -- Identifiers
        CAST(unique_key AS STRING) AS request_id,

        -- Date/Time
        SAFE_CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Restaurant details
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,

        -- Location details
        CAST(building_number AS STRING) AS building_number,
        CAST(street AS STRING) AS street,

        -- Location - clean zip code
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(REGEXP_EXTRACT(CAST(zip AS STRING), r'^(\d{5})')) = 5 
                THEN REGEXP_EXTRACT(CAST(zip AS STRING), r'^(\d{5})')
            ELSE NULL
        END AS zip,

        -- Location - standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        SAFE_CAST(latitude AS FLOAT64) AS latitude,
        SAFE_CAST(longitude AS FLOAT64) AS longitude,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE unique_key IS NOT NULL
    AND time_of_submission IS NOT NULL
    -- Ensure we only pull the last 7 years of data
    AND SAFE_CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY unique_key ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned