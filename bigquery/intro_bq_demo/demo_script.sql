# Wikipedia Pageview metadata intro query

SELECT
    language, SUM(views) as views
FROM `bigquery-samples.wikipedia_benchmark.Wiki10M`
WHERE
    title like "%next%"
GROUP by language
ORDER by views DESC;

SELECT
    language, SUM(views) as views
FROM `bigquery-samples.wikipedia_benchmark.Wiki1B`
WHERE
    title like "%next%"
GROUP by language
ORDER by views DESC;

# While this query runs, talk through pricing. 
# After query, show execution details and talk through how the query was executed.

SELECT
    language, SUM(views) as views
FROM `bigquery-samples.wikipedia_benchmark.Wiki100B`
WHERE
    title like "%next%"
GROUP by language
ORDER by views DESC;
