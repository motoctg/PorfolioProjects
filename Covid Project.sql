-- 1. Data acquaintance

SELECT *
FROM `covid_database.Covid_Data.owid-covid-data` 
order by 3,4
LIMIT 1000

-- Select data that we are using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `covid_database.Covid_Data.owid-covid-data` 
order by 1,2

-- (US) Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE location = "United States"
ORDER BY date DESC;

-- (US) Looking at Total Cases vs Population

SELECT location, date, total_cases, population, (total_cases/population) * 100 as infrate
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE location = "United States"
ORDER BY location, date;

-- (Global) Looking at Countries with Highest Infection Rate (infrate) compared to Population
-- infrate will be how much of the population has reported a contracted case of covid

SELECT location, population, MAX(total_cases) as highestinfcount, MAX((total_cases/population)) * 100 as infrate
FROM `covid_database.Covid_Data.owid-covid-data`
GROUP BY location, population
ORDER BY infrate desc;

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths AS INT)) as totaldeathcount
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE continent IS NOT null
GROUP BY location
ORDER BY totaldeathcount desc;

-- 2. Global
-- Now looking at continent instead of countries

SELECT continent, MAX(CAST(total_deaths AS INT)) AS totaldeathcount
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeathcount DESC;

-- To avoid aggregate function errors, group by date (which "aggregates" the variables in the date column)
-- To avoid / by 0 errors, remove all null and 0 variables from all_deaths
-- To allow referencing all_cases and all_deaths from within the same query, nest the alias functions within the greater function

WITH global_deathpercentage AS (
    SELECT date, SUM(new_cases) as all_cases, SUM(CAST(new_deaths AS INT)) as all_deaths
    FROM `covid_database.Covid_Data.owid-covid-data`
    WHERE continent IS NOT NULL
    GROUP BY date
)
SELECT date, all_cases, all_deaths, all_deaths / all_cases * 100 as deathpercentage
FROM global_deathpercentage
WHERE all_cases IS NOT NULL AND all_cases <> 0
ORDER BY deathpercentage DESC;

-- 3. Vaccinations
-- Total Population vs Vaccinations (countries)

SELECT continent, location, date, population, new_vaccinations
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE continent IS NOT NULL
ORDER BY continent;

-- Creating a rolling count of vaccinations
-- OVER (PARTITION BY ...) to add the sum of new_vaccinations up as a rolling number, resetting to 0 at each new location

SELECT continent, location, date, population, new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
FROM `covid_database.Covid_Data.owid-covid-data`
WHERE continent IS NOT NULL
ORDER BY continent;

-- Creating a CTE to use column rolling_vaccinations in the math behind percent_vac
-- Creating a CTE will allow use of a column created with a query, from within it's own query

WITH popvac AS (
  SELECT continent, location, date, population, new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
  FROM `covid_database.Covid_Data.owid-covid-data`
  WHERE continent IS NOT NULL
  )
SELECT *, (rolling_vaccinations/population) * 100 AS percent_vac
FROM popvac

-- TEMP TABLE
-- Add DROP TABLE so we can run the query multiple times. This resets the table
-- CREATE TEMP TABLE makes the new table and the following lines are the columns and their datatype.=

DROP TABLE IF EXISTS populationvaccinatedpercentage
CREATE TEMP TABLE populationvaccinatedpercentage
(
  continent STRING,
  location STRING,
  date TIMESTAMP,
  population NUMERIC,
  new_vaccinations NUMERIC,
  rolling_vaccinations NUMERIC
);

INSERT INTO populationvaccinatedpercentage
WITH popvac AS (
  SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccinations
  FROM `covid_database.Covid_Data.owid-covid-data`
  WHERE continent IS NOT NULL
)
SELECT *, (rolling_vaccinations / population) * 100 AS percent_vac
FROM popvac;

-- CREATE VIEW to prepare for visualizations
-- To create a new view, the dataset must be referenced in the name, creating a path

CREATE VIEW covid_database.Covid_Data.populationvaccinatedpercentage AS
SELECT
  continent,
  location,
  date,
  population,
  new_vaccinations,
  SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
FROM
  `covid_database.Covid_Data.owid-covid-data`
WHERE
  continent IS NOT NULL
ORDER BY
  continent;
