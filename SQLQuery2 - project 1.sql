

Select * 
from PortfolioProject1..CovidDeaths
WHERE dea.continent <> ''  
order by 3,4 


--Select * from 
PortfolioProject1..CovidVaccinations
--order by 3,4 


Select Location, date, total_cases, new_cases, total_deaths, population  
from PortfolioProject1..CovidDeaths
order by 1,2

--Total cases vs total deaths 
SELECT location, date, total_cases, total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0-- Avoid division by zero to solve  Divide by zero error encountered.
        ELSE (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 
    END AS DeathPercentage
FROM 
    PortfolioProject1..CovidDeaths
Where location like '%Myanmar%'
ORDER BY 1,2 

--Total case Vs population 
-- replace CAST with TRY_CAST to convert the values to the specified data type but returns null 
--if the conversion fails instead of raising an error

	SELECT location, date, total_cases, population, 
    CASE 
        WHEN TRY_CAST(total_cases AS bigint) = 0 OR TRY_CAST(population AS bigint) = 0 THEN 0 
        ELSE 1 -- Indicate that division is possible
    END AS CanDivide,

    TRY_CAST(total_cases AS bigint) AS TotalCasesBigInt, -- it was needed coz there was error with data types so  i needed to check 
    TRY_CAST(population AS bigint) AS PopulationBigInt,

    CASE 
        WHEN TRY_CAST(total_cases AS bigint) = 0 OR TRY_CAST(population AS bigint) = 0 THEN 0 
        ELSE (TRY_CAST(total_cases AS decimal(18, 2)) / NULLIF(TRY_CAST(population AS decimal(18, 2)), 0)) * 100.0
    END AS PercentagePopulationInfected
FROM  
    PortfolioProject1..CovidDeaths
ORDER BY  1, 2


--Highest Infection rate compared to population 
SELECT location, MAX(total_cases) as HighestInfectionCount, population,
    CASE 
        WHEN TRY_CAST(MAX(total_cases) AS bigint) = 0 OR TRY_CAST(population AS bigint) = 0 THEN 0 
        ELSE 1 -- Indicate that division is possible
    END AS CanDivide,
    TRY_CAST(MAX(total_cases) as bigint) as TotalCasesBigInt,
    TRY_CAST(population AS bigint) AS PopulationBigInt,
    Case
        When TRY_CAST(MAX(total_cases) AS bigint) = 0 OR TRY_CAST(population AS bigint) = 0 THEN 0 
        ELSE MAX(TRY_CAST(total_cases AS decimal(18, 2)) / NULLIF(TRY_CAST(population AS decimal(18, 2)), 0)) * 100.0
    END AS PercentagePopulationInfected
FROM PortfolioProject1..CovidDeaths
GROUP BY  location,  population
ORDER BY PercentagePopulationInfected DESC

--Countries with highest Death Count per population 

SELECT  location, MAX(COALESCE(TRY_CAST(NULLIF(LTRIM(RTRIM(total_deaths)), '') AS bigint), 0))AS TotalDeathCount
--population,--MAX(COALESCE(TRY_CAST(NULLIF(LTRIM(RTRIM(total_deaths)), '') AS bigint), 0)) / CAST(population AS decimal(18, 2)) 
--AS DeathCountPerPopulation
FROM   PortfolioProject1..CovidDeaths
GROUP BY  location 
--population
ORDER BY TotalDeathCount DESC


--Total death by continet
SELECT continent, 
    SUM(COALESCE(total_deaths, 0)) AS TotalDeathsbyContinent
FROM CovidDeaths
WHERE continent != ''
GROUP BY continent;

--Total deaths by location
SELECT location, 
    SUM(COALESCE(total_deaths, 0)) AS TotalDeathsbylocation
FROM CovidDeaths
WHERE location != ''
GROUP BY location
Order BY TotalDeathsbylocation DESC

--Total New death by continet
SELECT continent, 
    SUM(COALESCE(new_deaths, 0)) AS TotalNewDeathsbyContinent
FROM CovidDeaths
WHERE continent != ''
GROUP BY continent;



--Global Numbers 
Select date, SUM(new_cases) -- total deaths
FROM  PortfolioProject1..CovidDeaths
 --CASE 
 --       WHEN total_cases = 0 THEN 0-- Avoid division by zero to solve  Divide by zero error encountered.
 --       ELSE (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 
 --   END AS DeathPercentage
WHERE dea.continent <> ''  
Group by date
ORDER BY 1,2 


SELECT SUM(CAST(new_cases AS int)) AS TotalNewCases , SUM(CAST(new_deaths AS int)) AS TotalNewDeaths , 
 
		(SUM(CAST(new_deaths AS int)) / CAST(SUM(CAST(new_cases AS int)) AS float)) * 100
   
	AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE dea.continent <> ''  
ORDER BY 1,2;



--CTE  --Total population vs vaccination - Rolling count 
-- By using NULLIF(population, 0), we ensure that if population is zero, the division operation will result in NULL, 
--and consequently, the VaccinationPercentage will also be NULL
WITH PopulationvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS (
   SELECT dea.continent AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		AS RollingPeopleVaccinated
    FROM PortfolioProject1..CovidDeaths dea 
    JOIN  PortfolioProject1..CovidVaccinations vac 
	ON 
	dea.location = vac.location 
	AND dea.date = vac.date
    WHERE  dea.continent <> '' 
    --AND dea.location LIKE '%Albania%'  -- Filter for location like '%Albania%'
)

-- Query from the CTE and order the result set
SELECT  * , 
CASE 
        WHEN population = 0 THEN NULL -- Return NULL if population is zero
        ELSE (RollingPeopleVaccinated * 100.0 / NULLIF(population, 0)) -- Handle division by zero
    END AS VaccinationPercentage
	--,RollingPeopleVaccinated,Population
FROM PopulationvsVac 
ORDER BY continent,location;


--We use TRY_CONVERT(DATETIME, dea.date) to attempt converting the dea.date value to a datetime format. 
--This will handle any invalid datetime values gracefully by returning NULL if the conversion fails.
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated 
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
(
Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinated
)
SELECT dea.continent AS continent, dea.location,  TRY_CONVERT(DATETIME, dea.date) AS Date,

    CASE 
	WHEN ISNUMERIC(dea.population) = 1 
	THEN CAST(dea.population AS NUMERIC) 
	ELSE NULL 
	END AS Population, 

    CASE 
	WHEN ISNUMERIC(vac.new_vaccinations) = 1 
	THEN CAST(vac.new_vaccinations AS NUMERIC) 
	ELSE NULL 
	END AS New_Vaccinations,

    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated

FROM PortfolioProject1..CovidDeaths dea 
JOIN  PortfolioProject1..CovidVaccinations vac 
ON 
dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent <> '';

SELECT  
    *, 
    CASE 
        WHEN Population = 0 THEN NULL 
        ELSE (RollingPeopleVaccinated * 100.0 / NULLIF(Population, 0))
    END AS VaccinationPercentage
FROM #PercentPopulationVaccinated
ORDER BY Continent, Location;
DROP TABLE IF EXISTS #PercentPopulationVaccinated;


-- Creating view for visualization 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent AS continent, dea.location, TRY_CONVERT(DATETIME, dea.date) AS Date,
    CASE 
        WHEN ISNUMERIC(dea.population) = 1 THEN CAST(dea.population AS NUMERIC) 
        ELSE NULL 
    END AS Population, 
    
	CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CAST(vac.new_vaccinations AS NUMERIC) 
        ELSE NULL 
    END AS New_Vaccinations,

    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths dea 
JOIN PortfolioProject1..CovidVaccinations vac
ON 
dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent <> '';

Select *
From PercentPopulationVaccinated 