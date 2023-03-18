CREATE TABLE `deaths` (
  `iso_code` text,
  `continent` text,
  `location` text,
  `date` text,
  `population` varchar(40) DEFAULT NULL,
  `total_cases` text,
  `new_cases` varchar(40) DEFAULT NULL,
  `new_cases_smoothed` text,
  `total_deaths` text,
  `new_deaths` varchar(40) DEFAULT NULL,
  `new_deaths_smoothed` text,
  `total_cases_per_million` text,
  `new_cases_per_million` varchar(40) DEFAULT NULL,
  `new_cases_smoothed_per_million` text,
  `total_deaths_per_million` text,
  `new_deaths_per_million` varchar(40) DEFAULT NULL,
  `new_deaths_smoothed_per_million` text,
  `reproduction_rate` text,
  `icu_patients` text,
  `icu_patients_per_million` text,
  `hosp_patients` text,
  `hosp_patients_per_million` text,
  `weekly_icu_admissions` text,
  `weekly_icu_admissions_per_million` text,
  `weekly_hosp_admissions` text,
  `weekly_hosp_admissions_per_million` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- made everything into varchar due to int not working (Error code 1366)
load data 
	infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\porfolioproject1\\CovidDeaths.csv'
    into table deaths
    FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
    LINES TERMINATED BY '\n';
    
CREATE TABLE `covidvaccinations` (
  `iso_code` text,
  `continent` text,
  `location` text,
  `date` text,
  `total_tests` text,
  `new_tests` text,
  `total_tests_per_thousand` text,
  `new_tests_per_thousand` text,
  `new_tests_smoothed` text,
  `new_tests_smoothed_per_thousand` text,
  `positive_rate` text,
  `tests_per_case` text,
  `tests_units` text,
  `total_vaccinations` text,
  `people_vaccinated` text,
  `people_fully_vaccinated` text,
  `total_boosters` text,
  `new_vaccinations` text,
  `new_vaccinations_smoothed` text,
  `total_vaccinations_per_hundred` text,
  `people_vaccinated_per_hundred` text,
  `people_fully_vaccinated_per_hundred` text,
  `total_boosters_per_hundred` text,
  `new_vaccinations_smoothed_per_million` text,
  `new_people_vaccinated_smoothed` text,
  `new_people_vaccinated_smoothed_per_hundred` text,
  `stringency_index` text,
  `population_density` varchar(40) DEFAULT NULL,
  `median_age` varchar(40) DEFAULT NULL,
  `aged_65_older` varchar(40) DEFAULT NULL,
  `aged_70_older` varchar(40) DEFAULT NULL,
  `gdp_per_capita` varchar(40) DEFAULT NULL,
  `extreme_poverty` text,
  `cardiovasc_death_rate` varchar(40) DEFAULT NULL,
  `diabetes_prevalence` varchar(40) DEFAULT NULL,
  `female_smokers` text,
  `male_smokers` text,
  `handwashing_facilities` varchar(40) DEFAULT NULL,
  `hospital_beds_per_thousand` varchar(40) DEFAULT NULL,
  `life_expectancy` varchar(40) DEFAULT NULL,
  `human_development_index` varchar(40) DEFAULT NULL,
  `excess_mortality_cumulative_absolute` text,
  `excess_mortality_cumulative` text,
  `excess_mortality` text,
  `excess_mortality_cumulative_per_million` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

load data 
	infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\porfolioproject1\\CovidVaccincations.csv'
    into table vaccinations
    FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
    LINES TERMINATED BY '\n';
    
SELECT *
FROM deaths;

-- looking at countries with the highest death percentage compared to total population
-- noticed that location included continents and extra categories such as high income
-- realized the continents were not null and instead were empty strings
-- tableau table 1
SELECT location, population,
       -- Max(Cast(total_cases AS SIGNED))         AS TotalCases,
       Max(Cast(total_deaths AS SIGNED))        AS TotalDeaths,
       Max(( total_deaths / population )) * 100 AS TotalDeathPercentage
FROM   deaths
WHERE  continent != ('')
GROUP  BY location, population
HAVING location not in ('high income') 
ORDER  BY totaldeathpercentage DESC; 

-- looking at deaths per continent
-- tableau table 2
select continent, Max(Cast(total_deaths AS SIGNED)) AS TotalDeaths
from deaths
WHERE  continent != ('')
group by continent;


-- seeing if any locations have more COVID cases than vaccinations
With CovidVsVaccinations (location, TotalCases, TotalVaccinations)
AS
(SELECT dea.location, max(total_cases/population *100) as TotalCases, max(total_vaccinations/dea.population * 100) as TotalVaccinations
from deaths dea
join vaccinations vac
on dea.location = vac.location
    and dea.date = vac.date
group by dea.location)

Select *
from CovidVsVaccinations
where TotalCases > TotalVaccinations;


-- looking at effects of diabetes and cardiovascular disease on life expectancy
SELECT location, Avg(diabetes_prevalence), Avg(cardiovasc_death_rate),
	   AVG(life_expectancy)
from vaccinations
group by location
order by 4 desc;



-- looking at number of COVID cases on rolling basis and vaccinations for each country's population
-- CREATED VIEW
-- tableau table 3
CREATE VIEW PercentPopulationWithCovid as
WITH CovidCaseVsVac (location, date, new_cases, RollingNewCases, total_vaccinations, population)
AS
(
SELECT dea.location, dea.date, dea.new_cases, 
	   Sum(Cast(dea.new_cases as signed)) OVER (PARTITION by dea.location Order by dea.location, dea.date) as RollingNewCases,
       vac.total_vaccinations, dea.population
       -- Sum(Cast(vac.new_vaccinations as signed)) OVER (PARTITION by dea.location Order by dea.location, dea.date) as RollingNewVaccinations
from deaths as dea
JOIN vaccinations as vac
	on dea.location = vac.location
    and dea.date = vac.date
)
SELECT *, (RollingNewCases/population) * 100 AS RollingInfectionPercentage
FROM CovidCaseVsVac; 



-- updated the tables to make the 0/empty strings into NULL values
SET SQL_SAFE_UPDATES = 0;

update vaccinations 
SET  people_fully_vaccinated = NULL
where people_fully_vaccinated = 0;

update vaccinations 
SET  total_vaccinations = NULL
where total_vaccinations = 0;

update vaccinations 
SET  diabetes_prevalence = NULL
where diabetes_prevalence = '';

update vaccinations 
SET  extreme_poverty = NULL
where extreme_poverty = '';

update vaccinations 
SET  cardiovasc_death_rate = NULL
where cardiovasc_death_rate = '';

update vaccinations 
SET  excess_mortality_cumulative_per_million = NULL
where excess_mortality_cumulative_per_million = 0;

update vaccinations 
SET  GDP_per_capita = NULL
where GDP_per_capita = '';

-- TEMP TABLE
DROP TABLE if exists GDPVsMortality;

-- kept getting error code 1292 (Truncated incorrect double/integer value)
-- switched some columns from float to varchar, which fixed the error
Create Table GDPVsMortality
(
location varchar(255),
GDP_per_capita varchar(255),
VaccinatedPopulation float,
Population varchar(255),
ExcessMortality float
);

INSERT INTO GDPVsMortality
SELECT vac.location, MAX(vac.GDP_per_capita) as GDP_per_capita, 
	   Max(Cast(people_fully_vaccinated as float)) as VaccinatedPopulation, 
	   Max(Population) as Population,
       -- MAX(Cast(people_fully_vaccinated/population * 100 as float)) as PercentPopulationVaccinated, 
	   Max(Cast(excess_mortality_cumulative_per_million as float)) as ExcessMortality
FROM vaccinations as vac
JOIN deaths as dea 
	on dea.location = vac.location
    and dea.date = vac.date
WHERE  vac.continent != ('')
GROUP BY vac.location;
-- ORDER BY MAX(Cast(GDP_per_capita as Signed)) desc;

-- looking at relationship between GDP and Excess Mortality and Percent Population Vaccinated)
-- tableau table 4
select *, VaccinatedPopulation/Population * 100 as PercentPopulationVaccinated
from GDPVsMortality
ORDER BY Cast(GDP_per_capita as signed) desc;



