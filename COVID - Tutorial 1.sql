/*
An SQL Script that takes a dive into the COVID data that explores the 
Deaths and Vaccination trends
*/

-- Select all the data from the Two datasets
SELECT * FROM PortfolioProject..CovidDeaths$ WHERE continent IS NOT NULL;
SELECT * FROM PortfolioProject..CovidVaccinations$ WHERE continent IS NOT NULL;

-- Data From A Continental View

-- Total Deaths v Total Cases
SELECT location, date, total_cases, total_deaths, (total_deaths/ total_cases * 100) AS 'Death Percentage'
FROM PortfolioProject..CovidDeaths$ 
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total Cases V Population
SELECT location, date, population, total_cases, ((total_cases/ population) * 100) AS 'Cases Percentage'
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL AND location = 'Tanzania'
ORDER BY location, date;

-- Infection Per Country
SELECT location, population, MAX(total_cases), MAX(total_cases)/ population * 100 AS 'Infection Rate'
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 1, 2;

-- Death Rates Per Country
SELECT 
	continent, location, population, MAX(CONVERT(INT, total_deaths)) AS [Total Deaths], 
	MAX(CONVERT(INT, total_deaths))/ population * 100 AS 'Death Rate'
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY 'Death Rate' DESC;

-- Death Rates Globally 
SELECT location, MAX(CAST(total_deaths AS INT)) AS [Total Deaths]
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;

-- Total Cases Globally
SELECT location, MAX(total_cases) AS [Total Cases]
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;

-- Continental Death V Cases Rate
SELECT 
	location, MAX(total_cases) AS [Total Cases], MAX(CAST(total_deaths AS INT)) AS [Total Deaths],
	 MAX(CAST(total_deaths AS INT))/ MAX(total_cases) * 100 AS [Death Rate]
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location;

SELECT location, population, SUM(new_cases) AS [Total Cases], SUM(CAST(new_deaths AS INT)) AS [Total Deaths]
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location, population;

-- Total Population Against Vaccinations
SELECT DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
FROM PortfolioProject..CovidDeaths$ DEA
JOIN PortfolioProject..CovidVaccinations$ VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL;

-- Rolling Count added according to the New Vaccinations per Country
SELECT 
	DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.date) AS [Total Vaccinations]
FROM PortfolioProject..CovidDeaths$ DEA
JOIN PortfolioProject..CovidVaccinations$ VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL AND DEA.location='Canada';

-- Compare population by the population VACCINATED
-- Using a CTE

WITH PopVSVaccinations AS
(
SELECT
	DEA.location, DEA.date, DEA.population, CAST(VAC.new_vaccinations AS INT) AS Vaccinated,
	SUM(CAST(VAC.new_vaccinations AS INT)) OVER (PARTITION BY DEA.location ORDER BY DEA.date) AS [Total Vaccinations]
FROM PortfolioProject..CovidDeaths$ DEA
JOIN PortfolioProject..CovidVaccinations$ VAC
ON 
	DEA.location = VAC.location
	AND
	DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL AND DEA.location = 'Canada'
)
SELECT location, date, population, [Total Vaccinations], [Total Vaccinations]/ population * 100 AS [Vaccination Rate]
FROM PopVSVaccinations;

-- Compare population by the population VACCINATED
-- CREATE A TABLE 

DROP TABLE IF EXISTS #CanadaPopVsVaccinationsTable

CREATE TABLE #CanadaPopVsVaccinationsTable 
(
	location nvarchar(255),
	date datetime,
	population numeric,
	totalVaccinations numeric,
)

INSERT INTO #CanadaPopVsVaccinationsTable
SELECT
	DEA.location, DEA.date, DEA.population, 
	SUM(CAST(VAC.new_vaccinations AS INT)) OVER (PARTITION BY DEA.location ORDER BY DEA.date) AS [Total Vaccinations]
FROM PortfolioProject..CovidDeaths$ DEA
JOIN PortfolioProject..CovidVaccinations$ VAC
ON 
	DEA.date = VAC.date
	AND
	DEA.location = VAC.location
WHERE DEA.continent IS NOT NULL AND DEA.location = 'Canada';

SELECT location, date, ROUND(totalVaccinations/ population * 100, 4) AS [Vaccination Percentage]
FROM #CanadaPopVsVaccinationsTable;

/*
VIEWS
-- Create a view for later visualisations
*/

CREATE ViEW PercentOfPopulationVaccinated AS
SELECT 
	D.continent, D.location, D.date, D.population, V.new_vaccinations, 
	SUM(CONVERT(INT, D.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.date) AS [Rolling Pop Vaccinated]
FROM PortfolioProject..CovidDeaths$ D
JOIN PortfolioProject..CovidVaccinations$ V
ON 
	D.location = V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL;