WITH stops_with_month AS (
 SELECT
   outcome_object,
   object_of_search,
   officer_defined_ethnicity AS ethnicity,
   timestamp_to_yearmonth(stop_time) AS stop_month
 FROM street_stop
 WHERE timestamp_to_yearmonth(stop_time)>=?
   AND timestamp_to_yearmonth(stop_time)<=?
), total_info AS (
 SELECT 
   ethnicity,
   stop_month,
   COUNT(*) AS total_occurences
 FROM stops_with_month
 GROUP BY ethnicity, stop_month
), object_count AS (
 SELECT
   ethnicity,
   object_of_search,
   stop_month,
 COUNT(*) AS amount
 FROM stops_with_month
 GROUP BY ethnicity, object_of_search, stop_month
), most_popular_object AS (
 SELECT
    ethnicity, 
	object_of_search AS most_popular_object_of_search, 
	stop_month 
 FROM (
  SELECT DISTINCT 
    *, 
	RANK() OVER (PARTITION BY ethnicity, stop_month ORDER BY amount DESC) AS rank_by_amount
  FROM object_count
 ) AS tt1
 WHERE rank_by_amount=1
), rates AS (
 SELECT DISTINCT
   stops_with_month.ethnicity,
   stops_with_month.stop_month,
   COUNT(*) FILTER (WHERE outcome_object='Arrest') OVER(win) AS with_arrest,
   100.0 * (COUNT(*) FILTER (WHERE outcome_object='Arrest') OVER(win)) / total_info.total_occurences AS arrest_rate,
   100.0 * (COUNT(*) FILTER (WHERE outcome_object='A no further action disposal') OVER(win)) / total_info.total_occurences AS no_action_rate,
   100.0 * (COUNT(*) FILTER (WHERE outcome_object NOT IN('Arrest', 'A no further action disposal')) OVER(win)) / total_info.total_occurences AS other_outcome_rate
 FROM stops_with_month
 INNER JOIN total_info ON stops_with_month.ethnicity=total_info.ethnicity
   AND stops_with_month.stop_month=total_info.stop_month
 WINDOW win AS (PARTITION BY stops_with_month.ethnicity, stops_with_month.stop_month)
)
SELECT 
  most_popular_object.ethnicity,
  most_popular_object.stop_month,
  total_info.total_occurences,
  rates.arrest_rate,
  rates.no_action_rate,
  rates.other_outcome_rate,
  most_popular_object.most_popular_object_of_search
FROM most_popular_object 
INNER JOIN total_info ON most_popular_object.ethnicity=total_info.ethnicity 
  AND most_popular_object.stop_month=total_info.stop_month
INNER JOIN rates ON most_popular_object.ethnicity=rates.ethnicity 
  AND most_popular_object.stop_month=rates.stop_month
ORDER BY ethnicity, stop_month
LIMIT ?;