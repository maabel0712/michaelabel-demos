import argparse
import hypertune
import json
import logging
import pkgutil
import random
from datetime import datetime
from google.oauth2.service_account import Credentials as sac

from google.cloud import bigquery

def get_credentials():
    privatekey = pkgutil.get_data('trainer', 'privatekey.json')
    service_account_info = json.loads(privatekey.decode('utf-8'))
    return sac.from_service_account_info(service_account_info)

def train_and_evaluate(args):
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
    bq = bigquery.Client(project=args.project,
                         location=args.location,
                         credentials=get_credentials())
    job = bq.query(train_query)
    job.result() # wait for job to finish

    eval_query = """
        SELECT roc_auc
        FROM ML.EVALUATE(MODEL {})
    """.format(model_name)
    logging.info(eval_query)
    evaldf = bq.query(eval_query).to_dataframe()
    return evaldf['roc_auc'][0]

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--l2_reg', type=float, default=1.0)
    parser.add_argument('--num_parallel_tree', type=int, default=1)
    parser.add_argument('--max_tree_depth', type=int, default=6)
    parser.add_argument('--location', type=str, default='US')
    parser.add_argument('--project', type=str, required=True)
    parser.add_argument('--job-dir', default='ignored') # output directory to save artifacts. we have none

    # get args and invoke model
    args = parser.parse_args()
    hp_metric = train_and_evaluate(args)
    logging.info('{} Resulting ROC AUC: {}'.format(args.__dict__, hp_metric))

    # write out the metric so that the executable can be
    # invoked again with next set of metrics
    hpt = hypertune.HyperTune()
    hpt.report_hyperparameter_tuning_metric(
       hyperparameter_metric_tag='roc_auc',
       metric_value=hp_metric,
       global_step=1)
