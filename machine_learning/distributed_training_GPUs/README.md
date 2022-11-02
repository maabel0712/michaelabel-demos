## Distributed training using GPUs on Cloud AI Platform

This is a notebook based demo using Cloud AI Platform to perform distributed training using GPUs. The synchronous AllReduce strategy is used in this demo. The key points are:

1. You should set a distribution strategy and compile the model within the strategy.
2. CAIP makes it easy to change the underlying infrastructure quickly without having to change your training code! The `TF_CONFIG` environment variable is set by CAIP.
3. Adding more accelerators is not enough to improve performance. You need to think about optimizing your input pipeline for the infrastructure you're using.
