-- Create Forestation view to help with queries
CREATE VIEW forestation
    AS
SELECT fa.country_code, fa.country_name, fa.year, fa.forest_area_sqkm,
	   la.total_area_sq_mi, r.region, r.income_group,
       ((fa.forest_area_sqkm / la.total_area_sq_mi) / 2.59) * 100 AS percent_forest
  FROM forest_area fa
  JOIN land_area la
    ON fa.country_code = la.country_code AND fa.year = la.year
  JOIN regions r
    ON fa.country_code = r.country_code;

-- Forest area of world in 1990
SELECT forest_area_sqkm
  FROM forest_area
 WHERE country_name = 'World' AND year = 1990;

-- 2016
SELECT forest_area_sqkm
  FROM forest_area
 WHERE country_name = 'World' AND year = 2016;

-- absolute loss
SELECT (SELECT forest_area_sqkm
          FROM forest_area
         WHERE country_name = 'World' AND year = 1990) -
       (SELECT forest_area_sqkm
          FROM forest_area
         WHERE country_name = 'World' AND year = 2016) AS forest_loss;

-- percent loss
SELECT ((SELECT forest_area_sqkm
          FROM forest_area
         WHERE country_name = 'World' AND year = 1990) -
       (SELECT forest_area_sqkm
          FROM forest_area
         WHERE country_name = 'World' AND year = 2016)) /
        (SELECT forest_area_sqkm
          FROM forest_area
         WHERE country_name = 'World' AND year = 1990) * 100 AS percent_loss

-- country land area comparison
SELECT country_code, country_name, total_area_sq_mi
  FROM forestation
 WHERE total_area_sq_mi * 2.59 <
       (SELECT (SELECT forest_area_sqkm
                  FROM forest_area
                 WHERE country_name = 'World' AND year = 1990) -
               (SELECT forest_area_sqkm
                  FROM forest_area
                 WHERE country_name = 'World' AND year = 2016))
   AND year = '2016'
 ORDER BY total_area_sq_mi DESC
 LIMIT 1;

-- percent forest table
SELECT year, region,
       ((SUM(forest_area_sqkm) / SUM(total_area_sq_mi)) / 2.59) * 100 AS region_percent_forest
  FROM forestation
 WHERE year IN ('1990', '2016')
 GROUP BY region, year
 ORDER BY region, year;

-- World percent forest (2016)
  WITH percent_forest AS
       (SELECT year, region,
               ((SUM(forest_area_sqkm) / SUM(total_area_sq_mi)) / 2.59) * 100 AS region_percent_forest
          FROM forestation
         WHERE year IN ('1990', '2016')
         GROUP BY region, year)

SELECT year, region, region_percent_forest
  FROM percent_forest
 WHERE region = 'World' AND year = '2016';

-- Region with highest percent forest (2016)
  WITH percent_forest AS
       (SELECT year, region,
               ((SUM(forest_area_sqkm) / SUM(total_area_sq_mi)) / 2.59) * 100 AS region_percent_forest
          FROM forestation
         WHERE year IN ('1990', '2016')
         GROUP BY region, year)

SELECT year, region, region_percent_forest
  FROM percent_forest
 WHERE year = '2016' AND region != 'World'
 ORDER BY region_percent_forest DESC
 LIMIT 1;

-- Region with lowest percent forest (2016)
WITH percent_forest AS
     (SELECT year, region,
             ((SUM(forest_area_sqkm) / SUM(total_area_sq_mi)) / 2.59) * 100 AS region_percent_forest
        FROM forestation
       WHERE year IN ('1990', '2016')
       GROUP BY region, year)

SELECT year, region, region_percent_forest
FROM percent_forest
WHERE year = '2016' AND region != 'World'
ORDER BY region_percent_forest
LIMIT 1;

 -- World percent forest (1990)
  WITH percent_forest AS
       (SELECT year, region,
               ((SUM(forest_area_sqkm) / SUM(total_area_sq_mi)) / 2.59) * 100 AS region_percent_forest
          FROM forestation
         WHERE year IN ('1990', '2016')
         GROUP BY region, year)

 SELECT year, region, region_percent_forest
   FROM percent_forest
  WHERE region = 'World' AND year = '1990';

 -- Relative forestation in each region (1990)
 SELECT year, region, percent_forest
   FROM forestation
  WHERE year = '1990'
  ORDER BY percent_forest DESC
  LIMIT 1;

-- increase in forest area
SELECT t1.country_name,
       t2.forest_area_2016 - t1.forest_area_1990 AS forest_increase
  FROM (SELECT country_name, forest_area_sqkm AS forest_area_1990
          FROM forest_area
         WHERE year = '1990') t1
  JOIN (SELECT country_name, forest_area_sqkm AS forest_area_2016
          FROM forest_area
         WHERE year = '2016') t2
    ON t1.country_name = t2.country_name
 WHERE t2.forest_area_2016 > t1.forest_area_1990
 ORDER BY forest_increase DESC
 LIMIT 5;

-- increase in percentage
SELECT t1.country_name,
       (t2.forest_area_2016 - t1.forest_area_1990) / t1.forest_area_1990 AS percent_forest_increase
  FROM (SELECT country_name, forest_area_sqkm AS forest_area_1990
          FROM forest_area
         WHERE year = '1990') t1
  JOIN (SELECT country_name, forest_area_sqkm AS forest_area_2016
          FROM forest_area
         WHERE year = '2016') t2
    ON t1.country_name = t2.country_name
 WHERE t2.forest_area_2016 > t1.forest_area_1990
 ORDER BY percent_forest_increase DESC
 LIMIT 5;

 -- decrease in forest area
SELECT t1.country_name, t1.region,
        t1.forest_area_1990 - t2.forest_area_2016 AS forest_decrease
  FROM (SELECT country_name, region,
               forest_area_sqkm AS forest_area_1990
          FROM forestation
         WHERE year = '1990') t1
  JOIN (SELECT country_name, region,
               forest_area_sqkm AS forest_area_2016
          FROM forestation
         WHERE year = '2016') t2
    ON t1.country_name = t2.country_name
 WHERE t2.forest_area_2016 < t1.forest_area_1990
   AND t1.country_name != 'World'
 ORDER BY forest_decrease DESC
 LIMIT 5;

 -- decrease in percentage
SELECT t1.country_name, t1.region,
        (t1.forest_area_1990 - t2.forest_area_2016) / t1.forest_area_1990 AS percent_forest_decrease
  FROM (SELECT country_name, region, forest_area_sqkm AS forest_area_1990
           FROM forestation
          WHERE year = '1990') t1
  JOIN (SELECT country_name, region, forest_area_sqkm AS forest_area_2016
           FROM forestation
          WHERE year = '2016') t2
    ON t1.country_name = t2.country_name
 WHERE t2.forest_area_2016 < t1.forest_area_1990
 ORDER BY percent_forest_decrease DESC
 LIMIT 5;

-- quartiles
SELECT country_name, percent_forest,
	   CASE WHEN percent_forest < 25 THEN 1
            WHEN percent_forest <= 50 THEN 2
            WHEN percent_forest <= 75 THEN 3
            ELSE 4 END AS quartile
  FROM forestation
 WHERE year = '2016' AND percent_forest IS NOT NULL;

-- quartile count
  WITH t1 AS (SELECT country_name, percent_forest,
	          CASE WHEN percent_forest < 25 THEN 1
                   WHEN percent_forest <= 50 THEN 2
                   WHEN percent_forest <= 75 THEN 3
                   ELSE 4 END AS quartile
              FROM forestation
             WHERE year = '2016' AND percent_forest IS NOT NULL)

SELECT quartile, COUNT(*) AS countries
  FROM t1
 GROUP BY quartile
 ORDER BY quartile;

-- top quartile
 WITH t1 AS (SELECT country_name, region, percent_forest,
             CASE WHEN percent_forest < 25 THEN 1
                  WHEN percent_forest <= 50 THEN 2
                  WHEN percent_forest <= 75 THEN 3
                  ELSE 4 END AS quartile
             FROM forestation
            WHERE year = '2016' AND percent_forest IS NOT NULL)

SELECT country_name, region, percent_forest
  FROM t1
 WHERE quartile = 4
 ORDER BY percent_forest DESC;


-- countries with percent forestation higher than the U.S.
SELECT country_name, percent_forest
  FROM forestation
 WHERE year = '2016' AND percent_forest >
       (SELECT percent_forest
          FROM forestation
         WHERE country_name = 'United States' AND year = '2016')
 ORDER BY percent_forest;

-- count
SELECT COUNT(*)
  FROM forestation
 WHERE year = '2016' AND percent_forest >
       (SELECT percent_forest
          FROM forestation
         WHERE country_name = 'United States' AND year = '2016');
