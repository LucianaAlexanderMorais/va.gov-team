/***************************************************************************************************
Name:               BQ - VAOS Scheduling Completion Rate by day 
URL:                https://va-gov.domo.com/datasources/df0acc2b-b035-4829-ab04-8f42ddc4721b/details/overview
Create Date:        2020-10-09
Author:             Brian Martin
Description:        This returns a daily conversion rate (session and user) for a funnel that starts with
                    'vaos-schedule-appointment-button-clicked' and ends with 'vaos-.*-submission-successful$'
 /***************************************************************************************************/
#standardSQL
WITH ga AS (
    SELECT
        -- date (dimension)
        PARSE_DATE("%Y%m%d", date) as date, 
        fullVisitorId,        
        CONCAT(fullVisitorId, CAST(visitStartTime AS STRING)) AS session_id,
        hits.eventInfo.eventLabel AS event_label,
        LEAD(hits.eventInfo.eventLabel, 1) OVER(
            PARTITION BY fullVisitorId
            ORDER BY
                hitNumber ASC
        ) AS next_event_label,     
        hits.hitNumber AS hitNumber
    FROM
        `vsp-analytics-and-insights.176188361.ga_sessions_*` AS ga,
        UNNEST(ga.hits) AS hits
    WHERE
        --_TABLE_SUFFIX BETWEEN "20200715" AND "20200920"
        _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d',DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
        AND REGEXP_CONTAINS(hits.eventInfo.eventLabel, '^vaos-(schedule-appointment-button-clicked|.*-submission-successful)$')
)
SELECT
    date,    
    -- year (dimension)
    FORMAT_DATE('%Y', date) AS year,
    -- month (dimension)
    FORMAT_DATE('%m', date) AS month,
    -- month_name (dimension)
    FORMAT_DATE('%B', date) AS month_name,
    -- day (dimension)
    FORMAT_DATE('%d', date) AS day,
    COUNT(DISTINCT(CASE WHEN REGEXP_CONTAINS(next_event_label, '^vaos-.*-submission-successful$') THEN fullVisitorId END))  
        / COUNT(DISTINCT(CASE WHEN event_label = 'vaos-schedule-appointment-button-clicked' THEN fullVisitorId END)) AS users_rate,
    COUNT(DISTINCT(CASE WHEN REGEXP_CONTAINS(next_event_label, '^vaos-.*-submission-successful$') THEN session_id END))  
        / COUNT(DISTINCT(CASE WHEN event_label = 'vaos-schedule-appointment-button-clicked' THEN session_id END)) AS sessions_rate
FROM
    ga
GROUP BY
    1