-- Solution queries for SQL Murder Mystery
-- Start by loading the schema and structure of the database
-- First, let's look at the crime scene. It will give us our first clue:
-- The introduction to the challenge gives us two pieces of info to start. 
-- The crime we are trying to solve happened in SQL City, and on 01/15/2018

SELECT *
FROM crime_scene_report
WHERE city = "SQL City" AND date = 20180115

-- We see three crimes, two of which are assaults, not murders
-- The crime we want states:
  -- "Security footage shows that there were 2 witnesses. 
  -- The first witness lives at the last house on "Northwestern Dr". The second witness, named Annabel, lives somewhere on "Franklin Ave"."
-- We'll come back to the person at Northwestern Dr. We'll look into Annabel first.

SELECT a.*, b.*
FROM person AS a 
JOIN interview AS b ON a.id = b.person_id
WHERE a.name LIKE "Annabel %"

-- Annabel says she recognized the killer from her time at the Get Fit Now gym on 01/09
-- Let's figure out who was there while she was. First we'll have to figure out what time she was at the gym.

SELECT a.*, b.*
FROM get_fit_now_member AS a 
JOIN get_fit_now_check_in AS b ON a.id = b.membership_id
WHERE check_in_date = 20180109
ORDER BY check_out_time DESC

-- Annabel was there from 16:00 to 17:00
-- It seems like there were only two people that met the criteria:
  -- Jeremy Bowers - 48Z55
  -- Joe Germuska - 48Z7A
-- With these two suspects, lets cross reference the interview of the person at Northwestern Dr.

SELECT a.*, b.*
FROM person AS a 
JOIN interview AS b ON a.id = b.person_id
WHERE address_street_name = "Northwestern Dr"
ORDER BY address_number DESC

-- Morty Schapiro is in the last house, and stated:
  -- Man, with gym bag, member number on bag started with "48Z", which is a Gold membership
  -- Lastly, suspect got into a car with a plate that included "H42W"
-- We'll look into the car, since both suspects from the prior query contain that id.

SELECT a.*, b.*
FROM drivers_license AS a 
JOIN person AS b ON a.id = b.license_id
WHERE a.plate_number LIKE '%H42W%' AND gender = "male"

-- Two suspects show up, but only one meets the criteria so far:
  -- Jeremy Bowers
-- We found him, and entering his name in the final query confirms it with the system:

INSERT INTO solution VALUES (1, 'Jeremy Bowers');
SELECT value FROM solution;

-- For the final challenge, we are tasked with finding who orchestrated the crime
-- We get two queries to complete the task

SELECT *
FROM interview
WHERE person_id = "67318"

-- Jeremy stated that he was hired by:
  -- Woman, wealthy, 65"-67" tall, red hair, drives a Tesla Model S, and she attened the SQL Symphony Concert 3 times in 12/2017
-- This will be a big query to complete this in one attempt

WITH filtered_driver AS 
(
  SELECT *
  FROM drivers_license AS a 
  JOIN person AS b ON a.id = b.license_id
  WHERE a.height >= 65 AND a.height <= 67 AND a.gender = 'female' AND a.hair_color = 'red' AND a.car_model = 'Model S'
)

SELECT *
FROM filtered_driver AS fd
JOIN income AS i ON fd.ssn = i.ssn
ORDER BY i.annual_income DESC;
