-- Prepare Data that gonna be using here

SELECT location,date,total_cases,new_cases,total_deaths,
population FROM `Learning.CovidDeaths` WHERE continent IS NOT NULL ORDER BY 1,2;

-- Clean the duplicate values 
DELETE FROM `Learning.CovidDeaths`
WHERE (iso_code, continent, location, date, population, total_cases,
             new_cases, new_cases_smoothed, total_deaths, new_deaths,
             new_deaths_smoothed, total_cases_per_million, new_cases_per_million,
             new_cases_smoothed_per_million, total_deaths_per_million,
             new_deaths_per_million, new_deaths_smoothed_per_million,
             reproduction_rate, icu_patients, icu_patients_per_million,
             hosp_patients, hosp_patients_per_million, weekly_icu_admissions,
             weekly_icu_admissions_per_million, weekly_hosp_admissions,
             weekly_hosp_admissions_per_million, total_tests) IN (
SELECT *
    FROM `Learning.CovidDeaths`
    GROUP BY iso_code, continent, location, date, population, total_cases,
             new_cases, new_cases_smoothed, total_deaths, new_deaths,
             new_deaths_smoothed, total_cases_per_million, new_cases_per_million,
             new_cases_smoothed_per_million, total_deaths_per_million,
             new_deaths_per_million, new_deaths_smoothed_per_million,
             reproduction_rate, icu_patients, icu_patients_per_million,
             hosp_patients, hosp_patients_per_million, weekly_icu_admissions,
             weekly_icu_admissions_per_million, weekly_hosp_admissions,
             weekly_hosp_admissions_per_million, total_tests
HAVING COUNT(*)>1
             );

-- Clean the NULL values to 0
UPDATE `Learning.CovidDeaths` 
SET 
    iso_code = IFNULL(iso_code, 0),
    continent = IFNULL(continent, 0),
    location = IFNULL(location, 0),
    date = IFNULL(date, 0),
    population = IFNULL(population, 0),
    total_cases = IFNULL(total_cases, 0),
    new_cases = IFNULL(new_cases, 0),
    new_cases_smoothed = IFNULL(new_cases_smoothed, 0),
    total_deaths = IFNULL(total_deaths, 0),
    new_deaths = IFNULL(new_deaths, 0),
    new_deaths_smoothed = IFNULL(new_deaths_smoothed, 0),
    total_cases_per_million = IFNULL(total_cases_per_million, 0),
    new_cases_per_million = IFNULL(new_cases_per_million, 0),
    new_cases_smoothed_per_million = IFNULL(new_cases_smoothed_per_million, 0),
    total_deaths_per_million = IFNULL(total_deaths_per_million, 0),
    new_deaths_per_million = IFNULL(new_deaths_per_million, 0),
    new_deaths_smoothed_per_million = IFNULL(new_deaths_smoothed_per_million, 0),
    reproduction_rate = IFNULL(reproduction_rate, 0),
    icu_patients = IFNULL(icu_patients, 0),
    icu_patients_per_million = IFNULL(icu_patients_per_million, 0),
    hosp_patients = IFNULL(hosp_patients, 0),
    hosp_patients_per_million = IFNULL(hosp_patients_per_million, 0),
    weekly_icu_admissions = IFNULL(weekly_icu_admissions, 0),
    weekly_icu_admissions_per_million = IFNULL(weekly_icu_admissions_per_million, 0),
    weekly_hosp_admissions = IFNULL(weekly_hosp_admissions, 0),
    weekly_hosp_admissions_per_million = IFNULL(weekly_hosp_admissions_per_million, 0),
    total_tests = IFNULL(total_tests, 0);

-- Update the NULL values to 0 to avoid missing data 
-- Looking Total Cases vs Total Deaths
SELECT   location,
         date,
         total_cases,
         total_deaths,
         population,
         (total_deaths/total_cases)*100 AS deathpercentage
FROM     `Learning.CovidDeaths`
WHERE    location LIKE "India"
AND      continent IS NOT NULL
ORDER BY 1,
         2;

-- Looking Total Cases Vs Population
-- Shows what percentage of population got covid
SELECT   location,
         date,
         population,
         total_cases,
         (total_cases/population)*100 AS percentpopulationinfected
FROM     `Learning.CovidDeaths`
WHERE    location = "India"
AND      continent IS NOT NULL
ORDER BY 1,
         2;

-- Ignore wrong locations and display Total Death Count
SELECT location,SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM `Learning.CovidDeaths` WHERE continent IS NULL
AND location NOT IN
("World","European Union","International","High income","Upper middle income","Lower middle income")
GROUP BY location
ORDER BY TotalDeathCount DESC;

--  Countries that have Highest Infection Rate compared to Population
SELECT   Location,
         Population,
         Max(total_cases)                  AS HighestInfectionCount,
         Max((total_cases/population))*100 AS PercentPopulationInfected
FROM     `Learning.CovidDeaths`
WHERE    continent IS NOT NULL
GROUP BY location,
         population
ORDER BY PercentPopulationInfected DESC;

-- 
SELECT   Location,
         Population,
         date,
         Max(total_cases)                  AS HighestInfectionCount,
         Max((total_cases/population))*100 AS PercentPopulationInfected
FROM     `Learning.CovidDeaths`
GROUP BY location,
         population,date
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT   location,
         Max(CAST(total_deaths AS INT)) AS totaldeathcount
FROM     `Learning.CovidDeaths`
WHERE    continent IS NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC;

-- Countries with Highest Death Count per Continent
SELECT   continent,
         Max(CAST(total_deaths AS INT)) AS totaldeathcount
FROM     `Learning.CovidDeaths`
WHERE    continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeathcount DESC;

-- Death Percentage across world
SELECT   SUM(new_cases)                       AS total_cases,
         SUM(new_deaths)                      AS total_deaths,
         (SUM(new_deaths)/SUM(new_cases))*100 AS deathpercentage
FROM     `Learning.CovidDeaths`
WHERE    continent IS NOT NULL
ORDER BY 1,
         2;

--  Total Population vs Vaccinations
WITH popvsvac AS
(
         SELECT   cd.continent,
                  cd.location,
                  cd.date,
                  cd.population,
                  cv.new_vaccinations,
                  SUM(CAST(cv.new_vaccinations AS INT))OVER(partition BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
         FROM `Learning.CovidDeaths` cd
         JOIN     `Learning.CovidVaccinations` cv
         ON       cd.location=cv.location
         AND      cd.date=cv.date
         WHERE    cd.continent IS NOT NULL
         ORDER BY 2,
                  3 )
SELECT *,
       (rollingpeoplevaccinated/population)*100 AS rollingpercent
FROM   popvsvac;


-- View to store data for later visualizations use

CREATE VIEW `sparrow-267808`.`Learning`.`PercentPopulationVaccinated` AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM `Learning.CovidDeaths` cd
JOIN `Learning.CovidVaccinations` cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;