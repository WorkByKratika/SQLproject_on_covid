--select the data we are going to work on 
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
--Calculating the total death percentage
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
--likelihood of dying if you contract covid in India
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
WHERE location = 'India'
--Calculating the total cases vs population
select location, date, total_cases,population, (total_cases/population)*100 as covidcasePercentage
from CovidDeaths
--counties with highest infection rates compared to population
select location,population, max(total_cases),max((total_cases/population)*100 )as covidcasePercentage
from CovidDeaths
group by location,population
order by covidcasePercentage desc
--counties with highest death count compared to population
select location, max(cast(total_deaths as int))as death_count
from CovidDeaths
where  continent is not null
group by Location
order by  death_count desc
--looking at the deathcounts based on continents
select location, max(cast(total_deaths as int))as death_count
from CovidDeaths
where  continent is null
group by location
order by  death_count desc

--global numbers
--globally cases filtered on the basis of date
select date, sum(new_cases)as new_cases_per_day,sum(total_cases)as totalt_cases_per_day, sum(cast(new_deaths as int)) as new_deaths_per_day,
(sum(cast(new_deaths as int))/sum(new_cases))*100 as new_death_percentage
from CovidDeaths
where continent is not null
group by date
order by 1,2

select * from CovidVaccinations
--joining the two tables together based on location and date
select * 
from CovidDeaths as cd
join CovidVaccinations as cv
on cd.location =cv.location
and cd.date = cv.date

--calculating the total population vs vaccinations
select cd.location, cd.date, population, new_vaccinations,(new_vaccinations/population)*100 as vaccination_rate
from CovidDeaths as cd
join CovidVaccinations as cv
on cd.location =cv.location
and cd.date = cv.date
where cd.continent is not null
order by 1,2

--calculating the cumulative new vaccinaes based on locations(india) per day
select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
where cd.location ='India'

--calculating the cummlative vaccination rate (this cannot be done inthe same query so we have to form a temp table or CTE or sub query

with popvsvac (location, date, population, new_vac, cumm_vac)
as
(select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
)
select*, (cumm_vac/population)*100 as cumm_vac_rate
from popvsvac

--creating the temp table
drop table if exists #temp_covid 
create table #temp_covid
(location varchar(50), date datetime, population int, new_vac numeric, cumm_vac numeric)

insert into #temp_covid
select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent is not null

select * from #temp_covid


--calculate the max cumm_vac_rate based on location
with popvsvac (location, date, population, new_vac, cumm_vac)
as
(select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent is not null
)
select location, max (cumm_vac) as max_cumm_vac
from popvsvac
group by location
order by max_cumm_vac desc

--calculate the max cumm_vac_rate based on continent
with popvsvac (location, date, population, new_vac, cumm_vac)
as
(select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent is null
)
select location, max (cumm_vac) as max_cumm_vac
from popvsvac
group by location
order by max_cumm_vac desc

--creating a view (table view) for later visualisations
create view temp_covid as
select cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over (partition by cd.location order by cd.location, cd.date) as cummalative_vac
from Coviddeaths as cd
join covidvaccinations as cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent is not null


