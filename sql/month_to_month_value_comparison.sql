WITH month_data AS (
 SELECT DISTINCT
   cr.crime_category_code AS category_code,
   crime_category.category_name AS category_name,
   cr.crime_date,
   COUNT(*) OVER (PARTITION BY cr.crime_category_code, cr.crime_date)
 FROM crime AS cr
 INNER JOIN crime_category ON cr.crime_category_code=crime_category.code
 WHERE
   cr.crime_date>=?
   AND cr.crime_date<=?
 ORDER BY category_code, cr.crime_date
)
SELECT
  month_data.category_code,
  month_data.category_name,
  month_data.crime_date,
  prev_month_data.count AS previous_count,
  month_data.count AS current_count,
  month_data.count - prev_month_data.count AS delta,
  100.0 * (month_data.count - prev_month_data.count) / prev_month_data.count AS growth_rate
FROM month_data
LEFT JOIN month_data AS prev_month_data ON month_data.category_code=prev_month_data.category_code
  AND prev_month_data.crime_date=get_previous_date(month_data.crime_date)
LIMIT ?;