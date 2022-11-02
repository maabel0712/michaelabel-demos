# Demos and Lab Code for Serverless Data Processing with Dataflow course

Folder for demos written for the Serverless Data Processing with Dataflow coursecourse:

Demo list with short descriptions:

- [Beam Notebooks](./demos/beam_notebooks): An example of using Beam Notebooks to work with interactive Beam and the Dataframe API.
- [Dataflow SQL](./demos/dataflow_sql): A demo to show how to use Dataflow SQL to process real-time simulated San Diego traffic data.
- [Dataflow Monitoring](./demos/monitoring): Overview of the monitoring tools in Dataflow for both batch and streaming pipelines via a hands-on examples.
- [Performance](./demos/performance):  Show in a real example how graph optimization is occuring in Dataflow and call out opportunites for improving pipeline performance.
- [Shuffle Service](./demos/shuffle_service) A simple, quick demo to show how to (de)activate the Dataflow Shuffle service. Compare the resource utilization for a simple pipeline using and not using the Shuffle service.
- [Triggers](./demos/triggers) A simple, quick demo to show how the emitted results for the two possible accumulation modes compare. 

Lab code list with short descriptions:

- [Basic ETL Python](./lab_code/1_Basic_ETL_Python) Build a simple ETL pipeline using Python Beam.
- [Branching Pipelines Python](./lab_code/2_Branching_Pipelines_Python) Build a brancing ETL pipeline to write to both BQ and GCS.
- [Batch Analytics Python](./lab_code/3_Batch_Analytics_Python) Build a pipeline to perform aggregations on batch data using schemas in Python Beam.
- [SQL Batch Analytics Python](./lab_code/4_SQL_Batch_Analytics_Python) Build a pipeline to perform aggregations on batch data using schemas and Beam SQL in Python Beam.
- [Streaming Analytics Python](./lab_code/5_Streaming_Analytics_Python) Build a pipeline to perform aggregations on streaming data using schemas in Python Beam.
- [SQL Streaming Analytics Python](./lab_code/6_SQL_Streaming_Analytics_Python) Build a pipeline to perform aggregations on streaming data using schemas and Beam SQL in Python Beam.
- [Testing Batch Pipelines in Python](./lab_code/8a_Batch_Testing_Pipeline_Python) A pipeline and associated tests for processing batch data.
- [Testing Streaming Pipelines in Python](./lab_code/8b_Stream_Testing_Pipeline_Python) A pipeline and associated tests for processing streaming data.
- [Testing Batch Pipelines in Java](./lab_code/8a_Batch_Testing_Pipeline_Java) A pipeline and associated tests for processing batch data.
- [Testing Streaming Pipelines in Java](./lab_code/8b_Stream_Testing_Pipeline_Java) A pipeline and associated tests for processing streaming data.

Note that the other files in the [lab_code](./lab_code/) are part of the labs on Qwiklabs, and are only here for archival purposes.

