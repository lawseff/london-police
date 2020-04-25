WITH stats AS (
 SELECT DISTINCT
   location_latitude AS latitude,
   location_longitude AS longitude,
   age_range,
   COUNT(age_range) OVER(PARTITION BY location_latitude, location_longitude, age_range) age_range_count,
   gender,
   COUNT(gender) OVER(PARTITION BY location_latitude, location_longitude, gender) gender_count,
   officer_defined_ethnicity AS officer_ethnicity,
   COUNT(officer_defined_ethnicity) OVER(PARTITION BY location_latitude, location_longitude, officer_defined_ethnicity) officer_ethnicity_count,
   self_defined_ethnicity AS self_ethnicity,
   COUNT(self_defined_ethnicity) OVER(PARTITION BY location_latitude, location_longitude, self_defined_ethnicity) self_ethnicity_count,
   object_of_search,
   COUNT(object_of_search) OVER(PARTITION BY location_latitude, location_longitude, object_of_search) object_of_search_count,
   outcome_object,
   COUNT(outcome_object) OVER(PARTITION BY location_latitude, location_longitude, outcome_object) outcome_object_count
 FROM street_stop
 WHERE timestamp_to_yearmonth(stop_time)>=?
   AND timestamp_to_yearmonth(stop_time)<=?
   AND location_latitude IS NOT NULL
   AND location_longitude IS NOT NULL
), ranks AS (
 SELECT DISTINCT
   latitude,
   longitude,
   age_range,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY age_range_count DESC) AS age_range_rank,
   gender,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY gender_count DESC) AS gender_rank,
   officer_ethnicity,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY officer_ethnicity_count DESC) AS officer_ethnicity_rank,
   self_ethnicity,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY self_ethnicity_count DESC) AS self_ethnicity_rank,
   object_of_search,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY object_of_search_count DESC) AS object_of_search_rank,
   outcome_object,
   DENSE_RANK() OVER(PARTITION BY latitude, longitude ORDER BY outcome_object_count DESC) AS outcome_object_rank
 FROM stats
), ages AS (
 SELECT DISTINCT
   latitude,
   longitude,
   age_range
 FROM ranks WHERE age_range_rank=1
), genders AS (
 SELECT DISTINCT
   latitude,
   longitude,
   gender
 FROM ranks WHERE gender_rank=1
), officer_ethnicities AS (
 SELECT DISTINCT
   latitude,
   longitude,
   officer_ethnicity
 FROM ranks WHERE officer_ethnicity_rank=1
), self_ethnicities AS (
 SELECT DISTINCT
   latitude,
   longitude,
   self_ethnicity
 FROM ranks WHERE self_ethnicity_rank=1
), objects_of_search AS (
 SELECT DISTINCT
   latitude,
   longitude,
   object_of_search
 FROM ranks WHERE object_of_search_rank=1
), outcome_objects AS (
 SELECT DISTINCT
   latitude,
   longitude,
   outcome_object
 FROM ranks WHERE outcome_object_rank=1
)
SELECT DISTINCT
  street.id AS street_id,
  street.street_name,
  age_range,
  gender,
  officer_ethnicity,
  self_ethnicity,
  object_of_search,
  outcome_object
FROM crime_location AS l
INNER JOIN street ON l.street_id=street.id
INNER JOIN ages ON l.latitude=ages.latitude
  AND l.longitude=ages.longitude
INNER JOIN genders ON l.latitude=genders.latitude
  AND l.longitude=genders.longitude
INNER JOIN officer_ethnicities AS oe ON l.latitude=oe.latitude
  AND l.longitude=oe.longitude
INNER JOIN self_ethnicities AS se ON l.latitude=se.latitude
  AND l.longitude=se.longitude
INNER JOIN objects_of_search AS os ON l.latitude=os.latitude
  AND l.longitude=os.longitude
INNER JOIN outcome_objects AS oo ON l.latitude=oo.latitude
  AND l.longitude=oo.longitude
LIMIT ?;


