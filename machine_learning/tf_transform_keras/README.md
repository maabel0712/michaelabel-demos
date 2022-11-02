## Introduction to TF Transform using Keras

This is a notebook based demo using TensorFlow Transform and Keras to

1. Preprocess a census dataset, performing scaling and one-hot encoding operations while preserving metadata to do the same at inference time.
2. Train a classification model on the prepared dataset to predict if a home has income greater than or less than 50k USD per year.
3. Include the preprocessing function in the SavedModel.
4. Verify that the preprocessing is included when serving predictions with trained model.

This demo uses TensorFlow Transform 0.24.0 and TensorFlow 2.3
