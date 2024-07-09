--custom function for month string
CREATE OR REPLACE FUNCTION get_month_str(input_date TIMESTAMP)
RETURNS TEXT AS $$
DECLARE
	month_str TEXT;
BEGIN
	month_str := TO_CHAR(input_date, 'Month');
	RETURN month_str;
END;
$$ LANGUAGE plpgsql;

--example function call
SELECT get_month_str('2008-02-15'::TIMESTAMP);

--detailed table
CREATE TABLE detailed_actor_frequency (
	actor_id INT,
	actor_name VARCHAR(100),
	film_count INT,
	current_month VARCHAR(9)
);

--fill detailed table
INSERT INTO detailed_actor_frequency
SELECT 
	a.actor_id AS actor_id,
	CONCAT(a.first_name || ' ' || a.last_name) AS actor_name,
	COUNT(f_a.film_id) AS film_count,
	get_month_str(a.last_update) AS current_month
FROM actor a
JOIN film_actor f_a ON a.actor_id = f_a.actor_id
GROUP BY a.actor_id
ORDER BY film_count DESC;

--show detailed table
SELECT * FROM detailed_actor_frequency;

--create summary table
CREATE TABLE actor_frequency_summary (
    actor_name VARCHAR(100),
    film_count INT
);

--fill summary table
INSERT INTO actor_frequency_summary
SELECT 
	CONCAT(a.first_name || ' ' || a.last_name) AS actor_name,
	COUNT(f_a.film_id) AS film_count
FROM actor a
JOIN film_actor f_a ON a.actor_id = f_a.actor_id
GROUP BY a.actor_id
ORDER BY film_count DESC;

--show summary table
SELECT * FROM actor_frequency_summary;

--create trigger function to fill summary
CREATE OR REPLACE FUNCTION summary_trigger() 
RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM actor_frequency_summary;
    INSERT INTO actor_frequency_summary
        SELECT actor_name, film_count
        FROM detailed_actor_frequency d
		GROUP BY d.actor_id
		ORDER BY film_count DESC;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--execute trigger function on change on detailed table
CREATE TRIGGER refresh_actor_frequency_summary_trigger
AFTER INSERT OR UPDATE OR DELETE ON detailed_actor_frequency
FOR EACH STATEMENT
EXECUTE FUNCTION summary_trigger();

--stored procedure to refresh detailed and summary teable
CREATE OR REPLACE PROCEDURE refresh_actor_data()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM detailed_actor_frequency;
    DELETE FROM actor_frequency_summary;

    INSERT INTO detailed_actor_frequency (actor_id, actor_name, film_count, current_month)
    SELECT 
        a.actor_id AS actor_id,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        COUNT(f_a.film_id) AS film_count,
        get_month_str(a.last_update) AS current_month
    FROM actor a
    JOIN film_actor f_a ON a.actor_id = f_a.actor_id
    GROUP BY a.actor_id
    ORDER BY film_count DESC;

    INSERT INTO actor_frequency_summary (actor_name, film_count)
    SELECT 
        actor_name,
        film_count
    FROM detailed_actor_frequency
    ORDER BY film_count DESC;
END;
$$;

--execute procedure
CALL refresh_actor_data();