SELECT
  s.id AS street_id, 
  s.street_name AS street_name, 
  CONCAT('from ', ?, ' till ', ?) AS crime_period,
  COUNT(*) AS crime_count
FROM crime AS cr 
INNER JOIN crime_location AS l ON l.latitude=cr.location_latitude 
  AND l.longitude=cr.location_longitude
INNER JOIN street AS s ON s.id=l.street_id 
WHERE
  cr.crime_date>=?
  AND cr.crime_date<=?
GROUP BY (s.id, s.street_name) ORDER BY crime_count DESC
LIMIT ?;
