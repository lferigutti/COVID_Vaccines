--- ANALYSIS OF COVID DATABASE 27/07/2021 ---
-- The aim of this queries is to do an exploratory analysis of the COVID situation around the world
-- Also, the idea is to proof that vaccines are effective agains this deseas.

-- Skills used Joins, CTEs, tables, aggregate funcions, create views.


-- How many cases  are there in total per country?

SELECT cd.location, MAX(cd.total_cases) AS cases_today, cd.population
FROM COVID_database..covid_cases_death as cd
WHERE cd.location != 'World' and cd.location != 'Asia' AND cd.location != 'South America' AND cd.location != 'Europe' AND cd.location != 'European Union' AND cd.location != 'North America'
GROUP BY cd.location, cd.population
ORDER BY cases_today desc


-- Percentage of the population of each country that got covid (only counts countries with a population bigger than 5,000,000)

With case_today as(
SELECT cd.location, MAX(cd.total_cases) AS cases_today, cd.population
FROM COVID_database..covid_cases_death as cd
WHERE cd.location != 'World' and cd.location != 'Asia' AND cd.location != 'South America' AND cd.location != 'Europe' AND cd.location != 'European Union' AND cd.location != 'North America'
GROUP BY cd.location, cd.population

)
SELECT ct.location, ct.cases_today,ct.population, (ct.cases_today/ct.population)*100 AS Percentage_got_covid
FROM case_today as ct
WHERE ct.population > 5000000
ORDER BY Percentage_got_covid desc



-- Percentage of the population per country that die because of covid

SELECT cd.location, MAX(cast (cd.total_deaths AS INT)) AS total_deaths, cd.population
FROM COVID_database..covid_cases_death as cd
WHERE cd.location != 'World' and cd.location != 'Asia' AND cd.location != 'South America' AND cd.location != 'Europe' AND cd.location != 'European Union' AND cd.location != 'North America'
GROUP BY cd.location, cd.population
ORDER BY total_deaths desc



-- Percentage of death people and total cases

With death_today as(
SELECT cd.location, MAX(cd.total_cases) AS total_cases, MAX(cast (cd.total_deaths AS INT)) AS total_deaths, cd.population
FROM COVID_database..covid_cases_death as cd
WHERE cd.location != 'World' and cd.location != 'Asia'AND cd.location != 'Oceania' AND cd.location != 'South America' AND cd.location != 'Europe' AND cd.location != 'European Union' AND cd.location != 'North America'
GROUP BY cd.location, cd.population

)
SELECT dt.location,dt.population,dt.total_cases,(dt.total_cases/dt.population)*100 as Percentage_cases, dt.total_deaths, (dt.total_deaths/dt.population)*100 AS Percentage_death
FROM death_today as dt
WHERE dt.population > 5000000
ORDER BY Percentage_death desc


-- How is the rate death/cases per country, also flter with population > 1,000,000 and a minimun of 10,000 cases  (without CTS)

SELECT location, population, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS percentage_death_cases
FROM COVID_database..covid_cases_death
WHERE CAST(date AS DATE) = '2021-07-27'  AND iso_code NOT LIKE '%OWID%' AND population > 1000000 AND total_cases>10000
GROUP BY location, population, total_cases, total_deaths
ORDER BY percentage_death_cases DESC

-- Yemen has not many cases but almost 20% of the people that got it die.


-- Number of vaccines per country

SELECT location, MAX(CAST(total_vaccinations AS INT)) AS total_vaccines , MAX(CAST(people_vaccinated AS INT)) AS total_people_vaccinated, 
	MAX(CAST(people_fully_vaccinated AS INT)) AS total_people_fully_vaccinated 
FROM COVID_database..covid_test_vaccines
WHERE iso_code NOT LIKE '%OWID%'
GROUP BY location
ORDER BY total_vaccines DESC


-- % of people vaccinated and fully vaccinated per country (with population > 1,000,000)
WITH vaccines as(

	SELECT cd.location, cd.population, cd.continent,
		MAX(CAST(cv.people_vaccinated AS INT)) AS total_people_vaccinated,
		MAX(CAST(cv.people_fully_vaccinated AS INT)) AS total_people_fully_vaccinated

	FROM COVID_database..covid_cases_death AS cd
	JOIN COVID_database..covid_test_vaccines AS cv
	ON cd.location = cv.location
	WHERE  cd.population>1000000 AND cd.iso_code NOT LIKE '%OWID%'
	GROUP BY cd.location, cd.population, cd.continent
	
	)

SELECT v.location, v.population,
	v.total_people_vaccinated, 
	ROUND((v.total_people_vaccinated/v.population)*100,2) AS percentage_vaccinated,
	v.total_people_fully_vaccinated,
	ROUND((v.total_people_fully_vaccinated/v.population)*100,2) AS percentage_fully_vaccinated
FROM vaccines as v

ORDER BY percentage_fully_vaccinated DESC


--   % of people vaccinated and fully vaccinated per continent 

WITH vaccines as(

	SELECT cd.location, cd.population, cd.continent,
		MAX(CAST(cv.people_vaccinated AS INT)) AS total_people_vaccinated,
		MAX(CAST(cv.people_fully_vaccinated AS INT)) AS total_people_fully_vaccinated

	FROM COVID_database..covid_cases_death AS cd
	JOIN COVID_database..covid_test_vaccines AS cv
	ON cd.location = cv.location
	WHERE cd.iso_code LIKE '%OWID%'  AND cd.location != 'International' AND cd.location != 'Northern Cyprus' AND cd.location != 'Kosovo'
	GROUP BY cd.location, cd.population, cd.continent
	
	)

SELECT v.location, v.population,
	v.total_people_vaccinated, 
	ROUND((v.total_people_vaccinated/v.population)*100,2) AS percentage_vaccinated,
	v.total_people_fully_vaccinated,
	ROUND((v.total_people_fully_vaccinated/v.population)*100,2) AS percentage_fully_vaccinated
FROM vaccines as v

ORDER BY percentage_fully_vaccinated DESC

-- Europe is doing better in Vaccinations than the rest of the continents

-- Let's analize south america
-- Rate of new death / new cases

SELECT location,CAST(date as DATE) AS date, new_cases,new_deaths,
	ROUND((new_deaths/NULLIF(new_cases,0))*100,2) AS rate_new_death_per_case
FROM COVID_database..covid_cases_death
WHERE continent = 'South America'
ORDER BY location,date

-- IS not that clear, so now we want rate death/new cases per date

SELECT location, CAST(date as DATE) AS date, 
	total_cases, total_deaths,
	ROUND((total_deaths/total_cases)*100,2) AS percentage_deaths_cases
FROM COVID_database..covid_cases_death
WHERE continent = 'South America'
ORDER BY location,date



-- How effective is the vaccine. Lets study UK 

SELECT cd.location, CAST(cd.date as DATE) AS date_, 
	cd.total_cases, cd.total_deaths,
	ROUND((cd.total_deaths/cd.total_cases)*100,2) AS percentage_deaths_cases,
	ROUND((cv.people_vaccinated/cd.population)*100,2) AS percentage_vaccinated,
	ROUND((cv.people_fully_vaccinated/cd.population)*100,2) AS percentage_fully_vaccinated
FROM COVID_database..covid_cases_death as cd
JOIN COVID_database..covid_test_vaccines AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.location = 'United Kingdom'
GROUP BY cd.date, cd.location,cd.total_cases, cd.total_deaths, cv.total_vaccinations, cv.people_vaccinated,cd.population,cv.people_fully_vaccinated
ORDER BY cd.date




-- Is not that clear, percentage_death_cases is not that clear so let's study per month

WITH monthly AS(

SELECT cd.location, MONTH(cd.date)AS months,YEAR(cd.date)AS year,
	cd.new_cases, cd.new_deaths, cv.people_vaccinated, cd.population,
	
	ROUND((cv.people_vaccinated/cd.population)*100,2) AS percentage_vaccinated,
	ROUND((cv.people_fully_vaccinated/cd.population)*100,2) AS percentage_fully_vaccinated
FROM COVID_database..covid_cases_death as cd
JOIN COVID_database..covid_test_vaccines AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.location = 'United Kingdom' AND cd.population is not null
GROUP BY cd.date, cd.location,cd.new_cases, cd.new_deaths, cv.total_vaccinations, cv.people_vaccinated,cd.population,cv.people_fully_vaccinated
)

SELECT m.location, m.months,m.year, 
	SUM(m.new_cases) AS new_cases,
	SUM(CAST(m.new_deaths AS INT)) AS new_death, 
	ROUND((SUM(CAST(m.new_deaths AS int))/NULLIF(SUM(m.new_cases),0))*100,2) AS perc_death_cases,
	MAX(m.percentage_vaccinated) AS percentage_vaccinated,
	MAX(m.percentage_fully_vaccinated) AS percentage_fully_vaccinated
	
FROM monthly AS m
GROUP BY m.months, m.location, m.year
ORDER BY m.location, m.year, m.months 


--- Let's create a view to analize later
CREATE VIEW Analysis_per_month AS

WITH monthly AS(

SELECT cd.location, MONTH(cd.date)AS months,YEAR(cd.date)AS year,
	cd.new_cases, cd.new_deaths, cv.people_vaccinated, cd.population,
	
	ROUND((cv.people_vaccinated/cd.population)*100,2) AS percentage_vaccinated,
	ROUND((cv.people_fully_vaccinated/cd.population)*100,2) AS percentage_fully_vaccinated
FROM COVID_database..covid_cases_death as cd
JOIN COVID_database..covid_test_vaccines AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.population is not null
GROUP BY cd.date, cd.location,cd.new_cases, cd.new_deaths, cv.total_vaccinations, cv.people_vaccinated,cd.population,cv.people_fully_vaccinated
)

SELECT m.location, m.months,m.year, 
	SUM(m.new_cases) AS new_cases,
	SUM(CAST(m.new_deaths AS INT)) AS new_death, 
	ROUND((SUM(CAST(m.new_deaths AS int))/NULLIF(SUM(m.new_cases),0))*100,2) AS perc_death_cases,
	MAX(m.percentage_vaccinated) AS percentage_vaccinated,
	MAX(m.percentage_fully_vaccinated) AS percentage_fully_vaccinated
	
FROM monthly AS m
GROUP BY m.months, m.location, m.year
--ORDER BY m.months


