CREATE FUNCTION get_previous_date(year_month_value year_month) 
RETURNS year_month AS $$
DECLARE
	year_value integer;
	month_value integer;
BEGIN
	year_value := substring(year_month_value from 1 for 4)::integer;
	month_value := substring(year_month_value from 6 for 7)::integer - 1;
	IF month_value=0 THEN
		year_value := year_value - 1;
		month_value := 12;
	END IF;
	RETURN year_value || '-' || LPAD(month_value::char(2), 2, '0');
END; 
$$ LANGUAGE PLPGSQL;

CREATE FUNCTION timestamp_to_yearmonth(timestamp_value timestamp) 
RETURNS year_month AS $$
BEGIN
	RETURN EXTRACT
		(YEAR FROM timestamp_value)::char(4) || 
		'-' || 
		LPAD(EXTRACT(MONTH FROM timestamp_value)::char(2), 2, '0');
END; 
$$ LANGUAGE PLPGSQL;