SELECT *
FROM CovidProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM CovidProject..CovidVaccs
--ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths

--Looking at Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE date = '2022-03-13'
ORDER BY 1,2

--Looking at Total Cases vs Population
SELECT Location, date, total_cases, population, round((total_cases/population)*100,2) AS CasesPopulation
FROM CovidProject..CovidDeaths
WHERE date = '2022-03-13'
ORDER BY 1,2

--Looking at Countries with highest infection rate compared to population
SELECT Location, date, total_cases, population, round((total_cases/population)*100,2) AS CasesPopulation
FROM CovidProject..CovidDeaths
WHERE date = '2022-03-13'
ORDER BY 5 DESC

--Alternative to previous query
SELECT Location, population, MAX(total_cases) AS HighestInfections, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC

--Show countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as INT)) AS HighestDeaths
FROM CovidProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY Location
ORDER BY HighestDeaths DESC

--Break down by continent
SELECT location, MAX(cast(total_deaths as INT)) AS HighestDeaths
FROM CovidProject..CovidDeaths
WHERE continent IS null AND location <> 'Upper middle income' AND location <> 'High income' AND location <> 'Low income' AND location <> 'Lower middle income'
GROUP BY location
ORDER BY HighestDeaths DESC


--Global Numbers
SELECT date, sum(new_cases) AS TotalNewCases, sum(cast(new_deaths as INT)) AS TotalDeaths, sum(cast(new_deaths as INT))/sum(new_cases)*100 AS DeathPercent
FROM CovidProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1,2

--Join 2 tables
SELECT *
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS TotalVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

--option 1: Use CTE - use a calculated field in another calculation
WITH PopvsVacc (Continent, Location, Date, Population, New_vaccinations, TotalVaccs)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS TotalVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3
)
SELECT *, (TotalVaccs/Population)*100 as PercentPopulatioVaccs
FROM PopvsVacc

--TempTable

DROP TABLE if exists #PercentPopulationVaccs
CREATE TABLE #PercentPopulationVaccs
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalVaccs numeric
)

INSERT into #PercentPopulationVaccs
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS TotalVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3

SELECT *, (TotalVaccs/Population)*100 as PercentPopulatioVaccs
FROM #PercentPopulationVaccs


--Create a view to store data for later visualizations
CREATE VIEW PercentPopulationVaccs as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS TotalVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *
FROM PercentPopulationVaccs