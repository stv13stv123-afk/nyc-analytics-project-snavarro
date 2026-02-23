WITH source AS (
    SELECT * FROM {{ source('raw', 'nyc_service_request_from_2020') }}
),
cleaned AS (
    SELECT

        * EXCEPT (
            unique_key,
            created_date,
            closed_date,
            agency,
            agency_name,
            complaint_type,
            descriptor,
            status,
            incident_zip,
            borough,
            latitude,
            longitude,
            open_data_channel_type
        ),

        CAST(unique_key AS STRING) AS request_id,

        CAST(created_date AS TIMESTAMP) AS created_date,
        CAST(closed_date AS TIMESTAMP) AS closed_date,

        CAST(agency AS STRING) AS agency,
        CAST(agency_name AS STRING) AS agency_name,
        CAST(complaint_type AS STRING) AS complaint_type,
        CAST(descriptor AS STRING) AS descriptor,
        UPPER(TRIM(CAST(status AS STRING))) AS status,

        CASE
            WHEN LENGTH(REGEXP_EXTRACT(CAST(incident_zip AS STRING), r'^(\d{5})')) = 5
                THEN REGEXP_EXTRACT(CAST(incident_zip AS STRING), r'^(\d{5})')
            ELSE NULL
        END AS incident_zip,

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

        CAST(open_data_channel_type AS STRING) AS method_of_submission,

        CURRENT_TIMESTAMP() AS _stg_loaded_at
    FROM source

    WHERE unique_key IS NOT NULL
    AND created_date IS NOT NULL
    AND CAST(created_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    QUALIFY ROW_NUMBER() OVER (PARTITION BY unique_key ORDER BY created_date DESC) = 1
)
SELECT * FROM cleaned