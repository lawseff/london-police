-- stops
WITH stop_stats AS (
 SELECT 
   location_latitude AS latitude,
   location_longitude AS longitude,
   timestamp_to_yearmonth(stop_time) AS stop_month,
   object_of_search
 FROM street_stop
 WHERE timestamp_to_yearmonth(stop_time)>=?
   AND timestamp_to_yearmonth(stop_time)<=?
   AND outcome_object='Arrest'
   AND location_latitude IS NOT NULL
   AND location_longitude IS NOT NULL
), drug_stops_stats AS (
 SELECT
   latitude,
   longitude,
   stop_month,
   COUNT(*) AS drug_stops_count
 FROM stop_stats
 WHERE object_of_search='Controlled drugs'
 GROUP BY (latitude, longitude, stop_month)
), weapon_stops_stats AS (
 SELECT
   latitude,
   longitude,
   stop_month,
   COUNT(*) AS weapon_stops_count
 FROM stop_stats
 WHERE object_of_search IN ('Offensive weapons', 'Firearms')
 GROUP BY (latitude, longitude, stop_month)
), theft_stops_stats AS (
 SELECT
   latitude,
   longitude,
   stop_month,
   COUNT(*) AS theft_stops_count
 FROM stop_stats
 WHERE object_of_search='Stolen goods'
 GROUP BY (latitude, longitude, stop_month)
),
-- crimes
crime_stats AS (
 SELECT
   location_latitude AS latitude,
   location_longitude AS longitude,
   crime_date AS crime_month,
   crime_category_code
 FROM crime
 WHERE crime_date>=?
   AND crime_date<=?
   AND location_latitude IS NOT NULL
   AND location_longitude IS NOT NULL
), drug_crimes_stats AS (
 SELECT
   latitude,
   longitude,
   crime_month,
   COUNT(*) AS drug_crimes_count
 FROM crime_stats
 WHERE crime_category_code='drugs'
 GROUP BY (latitude, longitude, crime_month)
), weapon_crimes_stats AS (
 SELECT
   latitude,
   longitude,
   crime_month,
   COUNT(*) AS weapon_crimes_count
 FROM crime_stats
 WHERE crime_category_code='possession-of-weapons'
 GROUP BY (latitude, longitude, crime_month)
), theft_crimes_stats AS (
 SELECT
   latitude,
   longitude,
   crime_month,
   COUNT(*) AS theft_crimes_count
 FROM crime_stats
 WHERE crime_category_code IN ('theft-from-the-person', 'shoplifting')
 GROUP BY (latitude, longitude, crime_month)
),
-- locations with dates
dates AS (
 SELECT stop_month AS month_value from stop_stats
 UNION
 SELECT crime_date AS month_value from crime
), locations_with_dates AS (
 SELECT
   latitude,
   longitude,
   month_value
 FROM crime_location
 CROSS JOIN dates
 ORDER by latitude, longitude, month_value
)
-- result
SELECT
  street.id AS street_id, 
  street.street_name, 
  month_value,
  COALESCE(dc.drug_crimes_count, 0) AS drug_crimes_count,
  COALESCE(ds.drug_stops_count, 0) AS drug_stops_count,
  COALESCE(wc.weapon_crimes_count, 0) AS weapon_crimes_count,
  COALESCE(ws.weapon_stops_count, 0) AS weapon_stops_count,
  COALESCE(tc.theft_crimes_count, 0) AS theft_crimes_count,
  COALESCE(ts.theft_stops_count, 0) AS theft_stops_count
FROM locations_with_dates AS lwd
INNER JOIN crime_location AS l ON lwd.latitude=l.latitude 
  AND lwd.longitude=l.longitude
INNER JOIN street ON l.street_id=street.id
-- drugs
LEFT JOIN drug_crimes_stats AS dc ON lwd.latitude=dc.latitude
  AND lwd.longitude=dc.longitude
  AND lwd.month_value=dc.crime_month
LEFT JOIN drug_stops_stats AS ds ON lwd.latitude=ds.latitude
  AND lwd.longitude=ds.longitude
  AND lwd.month_value=ds.stop_month
-- weapons
LEFT JOIN weapon_crimes_stats AS wc ON lwd.latitude=wc.latitude
  AND lwd.longitude=wc.longitude
  AND lwd.month_value=wc.crime_month
LEFT JOIN weapon_stops_stats AS ws ON lwd.latitude=ws.latitude
  AND lwd.longitude=ws.longitude
  AND lwd.month_value=ws.stop_month
-- thefts
LEFT JOIN theft_crimes_stats AS tc ON lwd.latitude=tc.latitude
  AND lwd.longitude=tc.longitude
  AND lwd.month_value=tc.crime_month
LEFT JOIN theft_stops_stats AS ts ON lwd.latitude=ts.latitude
  AND lwd.longitude=ts.longitude
  AND lwd.month_value=ts.stop_month
LIMIT ?;

