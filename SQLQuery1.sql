SELECT *
FROM CovidDataAnalysis.dbo.CovidDeaths
ORDER BY 3, 4

-- SELECT *
-- FROM CovidDataAnalysis.dbo.CovidVaccinations
-- ORDER BY 3, 4

-- Select the data that will be used.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDataAnalysis.dbo.CovidDeaths
ORDER BY location, date;

-- Country Analysis

-- Looking at Total Cases vs Total Deaths as Fatality Percentage 
   -- Specificially for United States
   -- Shows likelihood to die from contracting COVID-19
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 
    END AS fatality_percentage 
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
WHERE
	location like '%states%'
ORDER BY 
    location, date;

-- Looking at Total Cases vs Population
   -- Specificially for United States
   -- Shows what percentage of population contracted COVID-19
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 as affected_percentage
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
WHERE
	location like '%states%'
ORDER BY 
    location, date;

-- Looking at countries with highest affected_percentage
SELECT 
    location, 
    MAX(total_cases) as highest_affected_count, 
    population, 
    MAX((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))) * 100 as affected_percentage
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
GROUP BY
	location, population
ORDER BY 
    affected_percentage DESC;

-- Looking at countries with highest death count
SELECT 
    location, 
    MAX(total_deaths) AS highest_death_count, 
    MAX(population) AS population
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    highest_death_count DESC;

-- Continent Analysis

-- Looking at continent with the highest death count
SELECT 
    location, 
    MAX(total_deaths) AS highest_death_count
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
WHERE
	continent IS NULL
GROUP BY 
    location
ORDER BY 
    highest_death_count DESC;

-- Global Analysis

-- Looking at global fatality percentage over time
SELECT  
    date, 
    SUM(total_cases) AS global_total_cases, 
    SUM(total_deaths) AS global_total_deaths, 
    CASE 
        WHEN SUM(total_cases) = 0 THEN 0 
        ELSE (CAST(SUM(total_deaths) AS FLOAT) / CAST(SUM(total_cases) AS FLOAT)) * 100 
    END AS global_fatality_percentage
FROM 
    CovidDataAnalysis.dbo.CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY 
    date;


-- Looking at total population vs vaccinations
SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER 
								(PARTITION BY 
									cd.location 
								ORDER BY 
									cd.location, 
									cd.date) AS rolling_vaccination_count
FROM CovidDataAnalysis.dbo.CovidDeaths AS cd
JOIN CovidDataAnalysis.dbo.CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cd.continent IS NOT NULL
ORDER BY
	cd.location, cd.date;

-- Use CTE to get total vaccinated percentage
WITH PopulationVsVaccinated AS (
    SELECT
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(cv.new_vaccinations) OVER (
            PARTITION BY cd.location
            ORDER BY cd.date
        ) AS rolling_vaccination_count
    FROM CovidDataAnalysis.dbo.CovidDeaths AS cd
    JOIN CovidDataAnalysis.dbo.CovidVaccinations AS cv
        ON cd.location = cv.location
        AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL
)
SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    rolling_vaccination_count,
    (CAST(rolling_vaccination_count AS FLOAT) / CAST(population AS FLOAT)) * 100 AS vaccination_percentage
FROM PopulationVsVaccinated
ORDER BY location, date;

-- Creating a view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER 
								(PARTITION BY 
									cd.location 
								ORDER BY 
									cd.location, 
									cd.date) AS rolling_vaccination_count
FROM CovidDataAnalysis.dbo.CovidDeaths AS cd
JOIN CovidDataAnalysis.dbo.CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cd.continent IS NOT NULL;