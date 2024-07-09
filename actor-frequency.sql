--B. Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4.

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
	SELECT get_month_str('9-9-9'::TIMESTAMP);

--C.  Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections.

	DROP TABLE detailed_actor_frequency;
	DROP TABLE actor_frequency_summary;

	--detailed table
	CREATE TABLE detailed_actor_frequency (
		actor_id INT,
		actor_name VARCHAR(100),
		film_count INT,
		current_month VARCHAR(9)
	);

	SELECT * FROM detailed_actor_frequency;

	--create summary table
	CREATE TABLE actor_frequency_summary (
	    actor_name VARCHAR(100),
	    film_count INT
	);

	SELECT * FROM actor_frequency_summary;

--D.  Provide an original SQL query in a text format that will extract the raw data needed for the detailed section of your report from the source database.

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

--E.  Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will continually update the summary table as data is added to the detailed table.

DROP TRIGGER IF EXISTS refresh_actor_frequency_summary_trigger ON detailed_actor_frequency;
DROP FUNCTION IF EXISTS summary_trigger();

	--create trigger function to fill summary
	CREATE OR REPLACE FUNCTION summary_trigger()
	RETURNS TRIGGER AS $$
	BEGIN
	    DELETE FROM actor_frequency_summary;
	    INSERT INTO actor_frequency_summary
	    SELECT actor_name, film_count
	    FROM detailed_actor_frequency
	    ORDER BY film_count DESC;
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	--execute trigger function on change on detailed table
	CREATE TRIGGER refresh_actor_frequency_summary_trigger
	AFTER INSERT OR UPDATE OR DELETE ON detailed_actor_frequency
	FOR EACH STATEMENT
	EXECUTE FUNCTION summary_trigger();

SELECT * FROM actor_frequency_summary;

--F.  Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed table and summary table. The procedure should clear the contents of the 
--    detailed table and summary table and perform the raw data extraction from part D.

	--dummy row to show that stored procedure is working
	INSERT INTO detailed_actor_frequency
	VALUES (999, 'Norm Macdonald', 50, 'May');

	SELECT * FROM detailed_actor_frequency;

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
	    GROUP BY a.actor_id, a.first_name, a.last_name, a.last_update
	    ORDER BY film_count DESC;
	END;
	$$;
	
	--execute procedure
	CALL refresh_actor_data();


SELECT * FROM detailed_actor_frequency;
SELECT * FROM actor_frequency_summary;
