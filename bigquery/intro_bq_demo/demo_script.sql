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

# Simple example for using BQ Preview and column projection effect on data queried

SELECT
  *
FROM
  `bigquery-public-data.patents.publications`
LIMIT
  10;

# Query for targeting specific columns and English filings, be sure to point out the UNNEST function and why it is needed. 
# Also point out the effect of the LIMIT keyword.

SELECT
  publication_number,
  inventor,
  descriptions.text,
  descriptions.language
FROM
  `bigquery-public-data.patents.publications` AS pubs,
  UNNEST(pubs.description_localized) AS descriptions
WHERE
  descriptions.language = 'en'
LIMIT
  5

# CREATE MODEL statement for connecting to Gemini. Be sure to show how to create a Cloud Resource connection. This will be created in advance.

CREATE MODEL `next_patent_demo.model_cloud_ai_gemini_pro`
REMOTE WITH CONNECTION `us.bq_llm_connection`
OPTIONS(endpoint = 'gemini-pro');

# Final query for using Gemini
    
WITH
  CTE_patent_text AS (
  SELECT
    publication_number,
    inventor,
    descriptions.text,
    descriptions.language
  FROM
    `bigquery-public-data.patents.publications` AS pubs,
    UNNEST(pubs.description_localized) AS descriptions
  WHERE
    descriptions.language = 'en'
  LIMIT 5)
SELECT
  	ml_generate_text_llm_result,text,language
FROM
  ML.GENERATE_TEXT(MODEL next_patent_demo.model_cloud_ai_gemini_pro,
    (
    SELECT
      CONCAT( 'Summarize the following patent description into a list with three key bullet points of the following form ',
              '\n * Bullet Point 1 \n * Bullet Point 2 \n Bullet Point 3 \n',
              'The patent description to summarize is: ', text ) AS prompt,
      text,
      language
    FROM
      CTE_patent_text ),
    STRUCT(0.8 AS temperature,
      3 AS top_k,
      TRUE AS flatten_json_output));

## Shift into Colab demo!
