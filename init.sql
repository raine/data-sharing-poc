DROP ROLE IF EXISTS guest;

CREATE TABLE employees (
   employee_id    NUMERIC NOT NULL,
   first_name     TEXT NOT NULL,
   last_name      TEXT NOT NULL,
   date_of_birth  DATE,
   pw_hash        TEXT  NOT NULL,
   phone_number   TEXT NOT NULL,
   CONSTRAINT employees_pk PRIMARY KEY (employee_id)
);

CREATE FUNCTION random_string(minlen NUMERIC, maxlen NUMERIC)
RETURNS TEXT AS $$ DECLARE
  rv TEXT := ''; i INTEGER := 0; len INTEGER := 0;
BEGIN
  IF maxlen < 1 OR minlen < 1 OR maxlen < minlen THEN
    RETURN rv;
  END IF;
  len := floor(random()*(maxlen-minlen)) + minlen;
  FOR i IN 1..floor(len) LOOP
    rv := rv || chr(97+CAST(random() * 25 AS INTEGER));
  END LOOP;
  RETURN rv;
END;
$$ LANGUAGE plpgsql;

INSERT INTO employees (
  employee_id,
  first_name,
  last_name,
  date_of_birth,
  phone_number,
  pw_hash
)
SELECT GENERATE_SERIES,
       initcap(lower(random_string(2, 8))),
       initcap(lower(random_string(2, 8))),
       CURRENT_DATE - CAST(floor(random() * 365 * 10 + 40 * 365) AS NUMERIC) * INTERVAL '1 DAY',
       CAST(floor(random() * 9000 + 1000) AS NUMERIC),
       md5(random()::text)
  FROM GENERATE_SERIES(1, 1000);

CREATE ROLE guest WITH login;
CREATE SCHEMA AUTHORIZATION guest;

 -- public is pseudo-user meaning everybody
REVOKE CREATE ON SCHEMA public FROM public;
REVOKE ALL ON SCHEMA public FROM guest;
REVOKE ALL ON SCHEMA guest FROM guest;
GRANT USAGE ON SCHEMA guest TO guest;

CREATE MATERIALIZED VIEW guest.employees_view AS
  SELECT employee_id, first_name, last_name
    FROM public.employees;

GRANT SELECT ON guest.employees_view TO guest;
