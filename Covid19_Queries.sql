
SELECT *
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--SELECT *
--FROM Covid19_Project..CovidVaccinations
--ORDER BY 3,4;

--Select the data we are going to use
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases vs Total Deaths
--this shows the likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Covid19_Project..CovidDeaths
WHERE location LIKE '%States'
AND continent IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases vs Population
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentageOfPopulation
FROM Covid19_Project..CovidDeaths
WHERE location LIKE '%States'
AND continent IS NOT NULL
ORDER BY 1,2;

--Looking at highest country with the highest rate of Total Cases vs Population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount , MAX((total_cases/population))*100 AS InfectionPercentageOfPopulation
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionPercentageOfPopulation DESC;

--Showing Countries with Highest Death Rate over Population
SELECT location, population, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, MAX(total_deaths/population)*100 AS DeathPercentageOfPopulation
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathPercentageOfPopulation DESC;

--Highest Death Count by Continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--or we can use this alternative for the above query
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid19_Project..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
(SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS death_percentage
FROM Covid19_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 DESC;

--Join CovidDeaths and CovidVaccinations tables
--Looking at Accumulated Vaccinations over Population
--Using Common Table Expression (CTE)
WITH PopVsVac (Continent, Location, Date, Population, NewVaccinations, AccumulatedTotalVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS accumulated_total_vaccinations
--,(accumulated_total_vaccinations / dea.population) * 100
FROM Covid19_Project..CovidDeaths dea
JOIN Covid19_Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date    = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (AccumulatedTotalVaccinations/Population)*100 AS Accumulated_Vaccinations_Rate
FROM PopVsVac
ORDER BY 2,3;

--Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccination numeric,
	Rolling__People_Vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS accumulated_total_vaccinations
--,(accumulated_total_vaccinations / dea.population) * 100
FROM Covid19_Project..CovidDeaths dea
JOIN Covid19_Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date    = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (Rolling__People_Vaccinated/Population)*100 AS Accumulated_Vaccinations_Rate
FROM #PercentPopulationVaccinated
ORDER BY 2,3;

--Creating View to store data for visualization later
CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS accumulated_total_vaccinations
--,(accumulated_total_vaccinations / dea.population) * 100
FROM Covid19_Project..CovidDeaths dea
JOIN Covid19_Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date    = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

--Using the View
SELECT *
FROM PercentPopulationVaccinated