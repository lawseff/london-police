CREATE DOMAIN code_domain AS varchar(64);
CREATE DOMAIN year_month AS varchar(7);
CREATE DOMAIN name_domain AS varchar(255) NOT NULL;

-- Crime data

CREATE TABLE crime_category (
	code code_domain,
	category_name name_domain UNIQUE,

	PRIMARY KEY (code)
);

CREATE TABLE outcome_category (
	code code_domain,
	category_name name_domain UNIQUE,

	PRIMARY KEY (code)
);

CREATE TABLE street (
	id bigserial,
	street_name name_domain,

	PRIMARY KEY (id)
);

CREATE TABLE crime_location (
	latitude decimal NOT NULL,
	longitude decimal NOT NULL,
	street_id bigint,

	PRIMARY KEY(latitude, longitude),
	FOREIGN KEY (street_id) REFERENCES street(id)
);

CREATE TYPE location_type_enum AS ENUM('FORCE', 'BTP');

CREATE TABLE crime (
	id bigserial,
	persistent_id varchar(64),
	crime_category_code code_domain NOT NULL,
	crime_date year_month NOT NULL,
	location_latitude decimal NOT NULL,
	location_longitude decimal NOT NULL,
	location_type location_type_enum NOT NULL,
	location_subtype varchar(255),
	context text,
	outcome_category_code code_domain,
    outcome_date year_month,

	PRIMARY KEY (id),
	FOREIGN KEY (location_latitude, location_longitude) REFERENCES crime_location(latitude, longitude),
	FOREIGN KEY (crime_category_code) REFERENCES crime_category(code),
	FOREIGN KEY (outcome_category_code) REFERENCES outcome_category(code)

);

-- Stop and search data

CREATE TYPE stop_type_enum AS
	ENUM('PERSON_SEARCH', 'VEHICLE_SEARCH', 'PERSON_AND_VEHICLE_SEARCH');

CREATE TYPE gender_enum AS ENUM('MALE', 'FEMALE', 'OTHER');

CREATE TABLE street_stop (
	id bigserial,
	stop_type stop_type_enum NOT NULL,
	gender gender_enum,
	age_range varchar(255),
	self_defined_ethnicity varchar(255),
	officer_defined_ethnicity varchar(255),
	stop_time timestamp,
	location_latitude decimal,
	location_longitude decimal,
	legislation varchar(255),
	outcome_object varchar(255),
	object_of_search varchar(255),
	outcome_linked_to_object bool,
	removal_of_more_than_outer_clothing bool,
	operation_name varchar(255),

	PRIMARY KEY (id),
	FOREIGN KEY (location_latitude, location_longitude) REFERENCES crime_location(latitude, longitude)
);