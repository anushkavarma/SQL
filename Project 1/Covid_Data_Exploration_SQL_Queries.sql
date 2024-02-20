--Dataset: OurWorldInData Covid Data
--Source: Alex the Analyst, YouTube
--Queried using: SSMS

/* -- PART 1 -- */

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY location, date;

--Select data that we are going to be using (COVID data as of 2/24)

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY location, date;

--Looking at Total Cases vs Total Deaths
--for United States, shows the likelihood of dying if you contract COVID (here, I had to change the data type for total deaths and total cases)

SELECT location, date, total_cases, total_deaths, (convert(float, total_deaths) / NULLIF(convert(float, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%state%'
ORDER BY 1,2

--for India, shows the likelihood of dying if you contract COVID

SELECT location, date, total_cases, total_deaths, (convert(float, total_deaths) / NULLIF(convert(float, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'India' AND total_cases IS NOT NULL
ORDER BY location, date

--Looking at Total Cases vs Population
--for United States, shows the percentage of population that got COVID

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%state%'
ORDER BY 1,2

--for India, shows the percentage of population that got COVID (filtering out the dates for which there was null data for total cases)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE 'India' AND total_cases IS NOT NULL
ORDER BY location, date

--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Looking at countries with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

/* -- PART 2 -- LOOKING AT CONTINENTS AND GLOBAL NUMBERS -- */

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
-- total cases, deaths, death percentage as of 2/2024

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL

/* -- PART 3 -- JOINING THE TABLES -- */

-- Vaccination table

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations

-- Looking at total population vs. vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Looking at total population vs. vaccinations by country, with a rolling count of people vaccinated
--(here, since the new_vaccinations had substantially increased since the bootcamp video's publishing, I had to convert the data type into bigint)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM((CONVERT(bigint, vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Looking at total population vs. vaccinations by country, with a percentage rolling count of people vaccinated

-- Using CTE for RollingPeopleVaccinated to show the percentage column

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM((CONVERT(bigint, vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPercentage
FROM PopVsVac

-- Using temp table for RollingPeopleVaccinated to show the percentage column

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM((CONVERT(bigint, vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated

/* -- PART 4 -- CREATING A VIEW FOR LATER VISUALIZATIONS -- */

USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM((CONVERT(bigint, vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *
FROM PercentPopulationVaccinated