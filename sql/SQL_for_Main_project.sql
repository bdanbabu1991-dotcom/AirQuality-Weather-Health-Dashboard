

SET GLOBAL local_infile = 1;

CREATE TABLE air_quality (
    date_raw     VARCHAR(50),
    city         VARCHAR(50),
    pm2_5        DECIMAL(10,2),
    pm10         DECIMAL(10,2),
    no           DECIMAL(10,2),
    no2          DECIMAL(10,2),
    nox          DECIMAL(10,2),
    nh3          DECIMAL(10,2),
    co           DECIMAL(10,2),
    so2          DECIMAL(10,2),
    o3           DECIMAL(10,2),
    benzene      DECIMAL(10,2),
    toluene      DECIMAL(10,2),
    xylane       DECIMAL(10,2),
    aqi          DECIMAL(10,2),
    aqi_bucket   VARCHAR(20),
    city_code    VARCHAR(10)
);

LOAD DATA LOCAL INFILE 'C:/DA Main Project/Air_Quality_updated.csv'
INTO TABLE air_quality
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  date_raw, city, pm2_5, pm10, no, no2, nox, nh3, co, so2, o3, 
  @vbenzene, @vtoluene, @vxylane, aqi, aqi_bucket,city_code
)
SET 
  benzene = NULLIF(@vbenzene, ''),
  toluene = NULLIF(@vtoluene, ''),
  xylane = NULLIF(@vxylane, '');

select count(*) from air_quality;

select * from air_quality limit 15;

select * from air_quality where city_code is null;

select distinct city_code from air_quality;

select * from air_quality 
where city_code is null or city_code = '';

create table health_report (
	date_raw					varchar(50),
    city						varchar(50),
    population_millions			decimal(10,3),
    pm2_5						decimal(10,3),
    aqi							int,
    aqi_category				varchar(50),
    resp_admissions_per_100k	varchar(100),
    resp_admissions_est_cases	int,
    cardio_admissions_per_100k	decimal(10,3),
    cardio_admissions_est_cases	int,
    asthma_er_visits_per_100k	decimal(10,3),
    asthma_er_visits_est_cases	int,
    mortality_per_100k			decimal(10,3),
    mortality_est_cases			int,
    health_risk_index			decimal(10,3),
    city_code					varchar(50)
);
   
LOAD DATA LOCAL INFILE 'C:/DA Main Project/Health_Report.csv'
INTO TABLE health_report
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_raw, city, population_millions, pm2_5, aqi, aqi_category, 
 resp_admissions_per_100k, resp_admissions_est_cases, cardio_admissions_per_100k, 
 cardio_admissions_est_cases, asthma_er_visits_per_100k, asthma_er_visits_est_cases, 
 mortality_per_100k, mortality_est_cases, health_risk_index, city_code, @dummy);
 
 
 select * from health_report;
 
 select count(*) from health_report;
 
 CREATE TABLE weather_report (
    date_raw VARCHAR(50),
    city_name VARCHAR(50),
    avg_temp DECIMAL(10,2),
    max_temp INT,
    min_temp INT,
    avg_humidity DECIMAL(10,2),
    total_rainfall DECIMAL(10,2),
    avg_windspeed DECIMAL(10,2),
    avg_cloudcover DECIMAL(10,2),
    avg_pressure DECIMAL(10,2),
    city_code VARCHAR(20)
);

LOAD DATA LOCAL INFILE 'C:/DA Main Project/weather_report_updated.csv'
INTO TABLE weather_report
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from weather_report;

select count(*) from weather_report;

select w.date_raw, w.city_name, w.avg_temp, a.aqi, h.health_risk_index
from weather_report w
join air_quality a on w.date_raw = a.date_raw and w.city_code = a.city_code
join health_report h on w.date_raw = h.date_raw and w.city_code = h.city_code
limit 10;

select date_raw, city_code from air_quality limit 5;
select date_raw, city_code from health_report limit 5;
select date_raw, city_code from weather_report limit 5;
select * from health_report limit 5;

SELECT DATE_FORMAT(STR_TO_DATE(date_raw, '%Y-%m-%d'), '%d-%m-%Y') AS formatted_date 
FROM weather_report 
LIMIT 15;

SET SQL_SAFE_UPDATES = 0;

UPDATE weather_report 
SET date_raw = DATE_FORMAT(STR_TO_DATE(date_raw, '%Y-%m-%d'), '%d-%m-%Y');

SET SQL_SAFE_UPDATES = 1;

select date_raw from weather_report limit 5;

select w.date_raw, w.city_name, w.avg_temp, a.aqi, h.health_risk_index
from weather_report w
join air_quality a on w.date_raw = a.date_raw
join health_report h on w.date_raw = h.date_raw
limit 10;

--Avg_AQI & Avg Health Risk  
select w.city_name,
		round(avg(a.aqi), 2) as avg_aqi,
        round(avg(h.health_risk_index), 2) as avg_health_risk_index
from weather_report w
join air_quality a on w.date_raw = a.date_raw
join health_report h on w.date_raw = h.date_raw
group by city_name
order by avg_aqi desc;


select w.city_name,
		round(avg(h.resp_admissions_est_cases), 2) as avg_res_cases,
        round(avg(w.max_temp), 2) as avg_max_temp
from weather_report w
join health_report h on w.date_raw = h.date_raw
group by city_name
order by avg_res_cases desc;

select h.aqi_category, 
       round(avg(h.mortality_per_100k), 2) as avg_mortality_rate,
       SUM(h.mortality_est_cases) as total_estimated_cases
from health_report h
group by h.aqi_category
order by avg_mortality_rate desc;

SELECT city, 
       ROUND(AVG(aqi), 2) AS avg_aqi,
       DENSE_RANK() OVER (ORDER BY AVG(aqi) DESC) AS pollution_rank
FROM air_quality
GROUP BY city;

CREATE VIEW master_environmental_report AS
SELECT w.date_raw, w.city_name, w.city_code, w.avg_temp, w.total_rainfall,
       a.pm2_5, a.aqi,
       h.aqi_category, h.health_risk_index, h.resp_admissions_est_cases, h.mortality_est_cases
FROM weather_report w
JOIN air_quality a ON w.date_raw = a.date_raw AND w.city_code = a.city_code
JOIN health_report h ON w.date_raw = h.date_raw AND w.city_code = h.city_code;

SELECT city_name,
    CASE 
        WHEN total_rainfall = 0 THEN 'No Rain'
        WHEN total_rainfall > 0 AND total_rainfall <= 5 THEN 'Light Rain'
        ELSE 'Heavy Rain'
    END AS rainfall_status,
    count(*) as total_days
from weather_report
group by city_name, rainfall_status;

select w.max_temp,
		round(avg(a.pm2_5), 2) as avg_pm2_5,
        round(avg(a.aqi), 2) as avg_aqi,
        count(*) as total_days
from weather_report w
join air_quality a on w.date_raw = a.date_raw
group by w.max_temp
order by w.max_temp desc;

select w.city_name,
		round(avg(w.max_temp), 2) as avg_max_temp,
        round(avg(a.aqi), 2) as avg_aqi,
        round(avg(w.avg_windspeed), 2) as avg_wind_speed
from weather_report w
join air_quality a on w.date_raw = a.date_raw
group by w.city_name
order by avg_aqi;

select  w.date_raw,
		w.city_name,
		a.aqi,
        h.health_risk_index,
        h.aqi_category
from weather_report w
join air_quality a on w.date_raw = a.date_raw
join health_report h on w.date_raw = h.date_raw
order by a.aqi desc, h.health_risk_index desc
limit 10;    
