# Using Cloud AI Platform HyperTune service for hyperparameter tuning for BigQuery ML models.

In this demo we will see how we can use the Cloud AI Platform HyperTune service to perform hyperparameter tuning for BigQuery ML models. We will

1. Preprocess data and save results in a BigQuery dataset.
2. Download a JSON file containing API credentials for our trainer package to be able to access BigQuery.
3. Explore the trainer package
4. Explore the `hyperparam.yaml` configuration file for the HyperTune job.
5. Run the HyperTune job and explore the outputs.

**Note: I'm assuming anyone going through this demo is familiar with the products, so the details will be sparse at times.**

## Preprocess data

First we will preprocess our data. We will be working with a public dataset of Google Analytics data from the Google Merchandise store. Our ultimate goal will be to build a model to predict whether a customer will buy on a return visit to the store or not. First we will preprocess our data to minimize the time (and cost) associated to training our model on BigQuery ML.

We will first create a dataset in BigQuery named `ecommerce` in the US multiregion. Then we will create a table with preprocessed data by running the following query:

```SQL
CREATE OR REPLACE TABLE ecommerce.preprocessed_data AS
WITH all_visitor_stats AS (
    SELECT
      fullvisitorid,
      IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM `data-to-insights.ecommerce.web_analytics`
      GROUP BY fullvisitorid
    )
    # add in new features
    SELECT * EXCEPT(unique_session_id) FROM (

      SELECT
          CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

          # labels
          will_buy_on_return_visit,

          MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

          # behavior on the site
          IFNULL(totals.bounces, 0) AS bounces,
          IFNULL(totals.timeOnSite, 0) AS time_on_site,
          totals.pageviews,

          # where the visitor came from
          trafficSource.source,
          trafficSource.medium,
          channelGrouping,

          # mobile or desktop
          device.deviceCategory,

          # geographic
          IFNULL(geoNetwork.country, "") AS country

      FROM `data-to-insights.ecommerce.web_analytics`,
         UNNEST(hits) AS h

      JOIN all_visitor_stats USING(fullvisitorid)

      WHERE 1=1
        # only predict for new visits
        AND totals.newVisits = 1
        AND date BETWEEN '20160801' AND '20170430' # train 9 months

      GROUP BY
      unique_session_id,
      will_buy_on_return_visit,
      bounces,
      time_on_site,
      totals.pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      country
    );
```

Once this query finishes executing, our data will be in place for the next step.

## Download credentials in JSON file

In the Google Cloud console, go to **Identity and Security >> Identity >> Service Accounts** and select your default Compute Engine service account. Then, under **Keys**, click **Add Key >> Create Key**, select JSON as the type and click **Create**. After this a JSON key will be downloaded to your local machine. Be sure to place this file in the `trainer` folder for this demo and rename it to `privatekey.json`.

## Explore the `trainer` package

Like with standard CAIP training jobs, we will be packaging our code to run the BigQuery ML training jobs into a Python package with the following file structure

```bash
trainer
├── __init__.py
└── train_and_eval.py
└── privatekey.json
```

We will focus on the `train_and_eval.py` file. The following code loads in the credentials from the `privatekey.json` file:

```Python
def get_credentials():
    privatekey = pkgutil.get_data('trainer', 'privatekey.json')
    service_account_info = json.loads(privatekey.decode('utf-8'))
    return sac.from_service_account_info(service_account_info)
```
Then we will train the model in BigQuery ML. Here's the code for doing so:

```Python
model_name = "ecommerce.hpt_class_model_{}_{}".format(datetime.now().strftime("%H%M%S"), random.randint(0,100))
train_query = """
    CREATE OR REPLACE MODEL `{}`
    OPTIONS
      (model_type='BOOSTED_TREE_CLASSIFIER' , l2_reg = {}, num_parallel_tree = {}, max_tree_depth = {},
          labels = ['will_buy_on_return_visit']) AS

    SELECT * FROM ecommerce.preprocessed_data;
""".format(model_name,
           args.l2_reg,
           args.num_parallel_tree,
           args.max_tree_depth)
logging.info(train_query)
```

A few notes about the code above:

* We will be creating different models for each trial. We will identify the trials with a timestamp and a random integer (in case the trials begin at the same second, which is actually possible!)
* The query is for training a gradient boosted forest model. Note that we have turned `l2_reg`, `num_parallel_tree` and `max_tree_depth` into command-line arguments in preparation for hyperparameter tuning.
* For later reference, we will log the query used for each trial. We will be able to see this in Cloud Operations logging after the HyperTune job.

```Python
bq = bigquery.Client(project=args.project,
                     location=args.location,
                     credentials=get_credentials())
job = bq.query(train_query)
job.result() # wait for job to finish
```

Next we will use the BigQuery client library to submit the query to BigQuery. We create our client by passing in our project ID, location of the dataset (`US` will be the default) and the credentials we loaded earlier.

```Python
eval_query = """
    SELECT roc_auc
    FROM ML.EVALUATE(MODEL {})
""".format(model_name)
logging.info(eval_query)
evaldf = bq.query(eval_query).to_dataframe()
return evaldf['roc_auc'][0]
...

hp_metric = train_and_evaluate(args)
logging.info('{} Resulting ROC AUC: {}'.format(args.__dict__, hp_metric))

# write out the metric so that the executable can be
# invoked again with next set of metrics
hpt = hypertune.HyperTune()
hpt.report_hyperparameter_tuning_metric(
   hyperparameter_metric_tag='roc_auc',
   metric_value=hp_metric,
   global_step=1)

```

We still need the metric to report for the HyperTune service. We will query `ML.EVALUATE` to pull our evaluation metrics. We will optimize for `roc_auc` in our hyperparameter tuning job, so we will return the evaluation `roc_auc`, and report the metric to CAIP using the `cloudml-hypertune` package.

Finally we will be creating command-line arguments for our hyperparameters above, `location`, `project`, and the `job-dir`.

## Explore the `hyperparam.yaml` configuration file

Next we will create our configuration file for the hyperparameter tuning job.

```yaml
scaleTier: CUSTOM
masterType: n1-highmem-2
```

First we will set the machine type to `n1-highmem-2`. Why? As of writing, this is the cheapest machine type available for CAIP training and we're going to be using BigQuery to execute the training jobs. The VMs on CAIP will just be managing submitting the queries and evaluation metrics.

```yaml
hyperparameters:
    hyperparameterMetricTag: roc_auc
    goal: MAXIMIZE
    maxTrials: 10
    maxParallelTrials: 2
```

We then start defining out HyperTune configuration. We will be trying to maximize roc_auc over 10 trials, allowing 2 to run in parallel at a time.  

```yaml
params:
- parameterName: l2_reg
  type: DOUBLE
  minValue: 0
  maxValue: 1
  scaleType: UNIT_LINEAR_SCALE
- parameterName: num_parallel_tree
  type: INTEGER
  minValue: 1
  maxValue: 10
  scaleType: UNIT_LINEAR_SCALE
- parameterName: max_tree_depth
  type: INTEGER
  minValue: 2
  maxValue: 10
  scaleType: UNIT_LINEAR_SCALE
```
Finally, we will define the hyperparameters we wish to tune for and the ranges of values that the hyperparameters can take. We set min values, max values, and the scale type we wish to use to sample the range of possible values.

## Run the HyperTune job

Finally we're ready to submit our training job! Go to the directory containing `hyperparam.yaml` and the `trainer` package and run the following `gcloud` command

```bash
PROJECT=$(gcloud config list project --format "value(core.project)")
BUCKET=gs://${PROJECT}
JOB_ID=bqml_hpt_$(date -u +%y%m%d_%H%M%S)

gcloud ai-platform jobs submit training ${JOB_ID}  \
--region=us-central1 \
--module-name=trainer.train_and_eval \
--package-path=$(pwd)/trainer \
--staging-bucket=${BUCKET} \
--config=hyperparam.yaml \
--runtime-version=2.2 \
--python-version=3.7 \
-- \
--project=${PROJECT}
```

It will take around an hour or so to run the HyperTune job. After it finishes be sure to check out the job on AI Platform and the models on BigQuery!
