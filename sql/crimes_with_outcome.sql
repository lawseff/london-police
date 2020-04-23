WITH cte AS (
 SELECT DISTINCT
   s.id AS street_id,
   s.street_name AS street_name,
   outcome_category.code AS outcome_category_code,
   outcome_category.category_name AS outcome_category_name,
   COUNT(*) FILTER(WHERE cr.outcome_category_code=?) OVER(location_window) AS count_of_crimes,
   100.0 * (COUNT(*) FILTER(WHERE cr.outcome_category_code=?) OVER(location_window))/(COUNT(cr.outcome_category_code) OVER(location_window)) AS percentage
 FROM crime AS cr
 INNER JOIN crime_location AS l ON l.latitude=cr.location_latitude
   AND l.longitude=cr.location_longitude
 INNER JOIN street AS s ON s.id=l.street_id
 INNER JOIN outcome_category ON cr.outcome_category_code=outcome_category.code
 WHERE
   cr.crime_date>=?
   AND cr.crime_date<=?
 WINDOW location_window AS (PARTITION BY l.latitude, l.longitude)
)
SELECT * FROM cte WHERE outcome_category_code=?
LIMIT ?;