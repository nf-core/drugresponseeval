# nf-core/drugresponseeval: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished.
All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

1. [Parameter check](#parameter-check): Several parameters are validated to ensure that the pipeline can run
   successfully.
2. `RUN_CV` subworkflow: Finds the optimal hyperparameters for each model in a cross-validation setting.
   - [Load response](#load-response): The response data is loaded.
   - [CV split](#cv-split): The response data is split into cross-validation folds.
   - [Make model channel](#make-model-channel): From the input baseline and model names, channels are created. This
     step is necessary because for the Single-Drug Models, one model has to be created per drug.
   - [HPAM split](#hyperparameter-split): One YAML file is created per model and hyperparameter combination to be
     tested.
   - [Train and predict CV](#train-and-predict-cv): All models are trained and evaluated in a cross-validation setting.
   - [Evaluate and find max](#evaluate-and-find-max): For each CV split, the best hyperparameters are determined
     using a grid search per model
3. `MODEL_TESTING` subworkflow: The best hyperparameters are used to train the models on the full training set
   and predict the test set. Optionally, randomization and robustness testes are performed.
   - [Predict full](#predict-full): The model is trained on the full training set (train & validation) with the best
     hyperparameters to predict the test set.
   - [Randomization split](#randomization-split): Makes a channel per randomization to be tested.
   - [Randomization test](#randomization-test): If randomization tests are enabled, the model is trained on the full
     training set with the best hyperparameters to predict the randomized test set.
   - [Robustness test](#robustness-test): If robustness tests are enabled, the model is trained N times on the full
     training set with the best hyperparameters
   - [Consolidate results](#consolidate-results): The results of the model testing are consolidated into a single
     table for each model.
   - [Evaluate final](#evaluate-final): The performance of the models is calculated on the test set results.
   - [Collect results](#collect-results): The results of the evaluation metrics per model are collected into four
     overview tables.
4. `VISUALIZATION` subworkflow: Plots are created summarizing the results.
   - [Critical difference plot](#critical-difference): A critical difference plot is created to compare the performance
     of the models.
   - [Violin plot](#violin-plot): A violin plot is created to compare the performance of the models over the CV folds.
   - [Heatmap](#heatmap): A heatmap is created to compare the average performance of the models over the CV folds.
   - [Correlation comparison](#correlation-comparison): Renders a plot in which the per-drug/per-cell line
     correlations between y_true and y_predicted are compared between different models.
   - [Regression plots](#regression-plots): Plots in which the y_true and y_predicted values are compared between
     different models.
   - [Save tables](#save-tables): Saves the performance metrics of the models in a table.
   - [Write html](#write-html): Writes the plots to an HTML file per setting (LPO/LCO/LDO).
   - [Write index](#write-index): Writes an index.html file that links to all the HTML files.
5. [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### Parameter check

The process `PARAMS_CHECK` performs the following checks:

- `--models` / `--baselines`: Check if the model and baseline names are valid (for valid names, see the [usage](usage.md) page).
- `--test_mode`: Check whether the test mode is LPO, LCO, LDO or a combination of these.
- `--dataset_name`: Check if the dataset name is valid, i.e., GDSC1, GDSC2, or CCLE.
- `--cross_study_datasets`: If supplied, check if the datasets are valid, i.e., GDSC1, GDSC2, or CCLE or a
  combination of these.
- `--n_cv_splits`: Check if the number of cross-validation splits is a positive integer > 1.
- `--randomization_mode`: If supplied, checks if the randomization is SVCC, SVCD, SVRC, SVRD, or a combination of these.
- `--randomization_type`: If supplied, checks if the randomization type is valid, i.e., permutation or invariant.
- `--n_trials_robustness`: Checks if the number of trials for robustness tests is >= 0.
- `--optim_metric`: Checks if the optimization metric is either MSE, RMSE, MAE, R^2, Pearson, Spearman, Kendall, or
  Partial_Correlation.
- `--response_transformation`: If supplied, checks whether the response transformation is either standard,
  minmax, or robust.

It emits the path to the data but mostly so that the other processes wait for `PARAMS_CHECK` to finish before starting.

### Subworkflow `RUN_CV`

#### Load response

The response data is loaded into the pipeline. The downloaded data is exported to `--path_data`
This step is necessary to provide the pipeline with the response data that will be used to train and evaluate the models.

<details markdown="1">
<summary>Output files</summary>

- Folder `path_data/dataset_name`: Everything required for the models to run is saved into this folder.

</details>

#### CV split

The response data is split into as many cross-validation folds as specified over the `--n_cv_splits` parameter.
The data is split into training, validation, and test sets for each fold. For models using early stopping, the early
stopping dataset is split from the validation set. This ensures that all models are trained and evaluated on the
same dataset.

#### Make model channel

From the input baseline and model names, channels are created. This step is necessary because for the
Single-Drug Models, one model has to be created per drug. The model name then becomes the name of the model and the
drug, separated by a dot, e.g., `MOLIR.Drug1`. All of these models should be able to be trained in parallel
which is why they should be individual elements in the channel.

#### Hyperparameter split

One YAML file is created per model and hyperparameter combination to be tested. This ensures that all hyperparameter
can be tested in parallel.

#### Train and predict CV

A model is trained in the specified test mode, on the specific cross-validation split with the specified
hyperparameter combination.

As soon as the GPU support is available, the training and prediction will be done on the GPU for the models
SimpleNeuralNetwork, MultiOmicsNeuralNetwork, MOLIR, SuperFELTR, and DIPK.

#### Evaluate and find max

Over all hyperparameter combinations, the best hyperparameters for a specific cross-validation split are determined.
The best hyperparameters are determined based on the optimization metric specified via `--optim_metric`.

### Subworkflow `MODEL_TESTING`

### Predict full

The model is trained on the full training set (train & validation) per split with the best hyperparameters to predict
the test set of the CV split. If specified via `--cross_study_datasets`, the cross-study datasets are also
predicted.

<details markdown="1">
<summary>Output files</summary>

- `**predictions*.csv`: CSV file with the predicted response values for the test set.
- `**cross_study/cross_study*.csv`: CSV file with the predicted response values for the cross-study datasets.
- `**best_hpams*.json`: JSON file with the best hyperparameters for the model.

</details>

#### Randomization split

Takes the `--randomization_mode` as input and creates a channel for each randomization to be tested. This ensures that
all randomizations can be tested in parallel.

#### Randomization test

Trains the model on the randomized training + validation set with the best hyperparameters to predict the
unperturbed test set of the specified CV split. How the data is randomized is determined by the
`--randomization_type`.

As soon as GPU support is available, the training and prediction will be done on the GPU for
the models SimpleNeuralNetwork, MultiOmicsNeuralNetwork, MOLIR, SuperFELTR, and DIPK.

<details markdown="1">
<summary>Output files</summary>

- `**randomization*.csv`: CSV file with the predicted response values for the randomization test.

</details>

#### Robustness test

Trains the model `--n_trials_robustness` times on the full training set with the best hyperparameters to predict the test set of the
specific CV split.

As soon as GPU support is available, the training and prediction will be done on the GPU for the models
SimpleNeuralNetwork, MultiOmicsNeuralNetwork, MOLIR, SuperFELTR, and DIPK.

<details markdown="1">
<summary>Output files</summary>

- `**robustness*.csv`: CSV file with the predicted response values for the robustness test.

</details>

#### Consolidate results

For Single-Drug Models, the results of the model testing are consolidated such that their results look like the
results of the Multi-Drug Models.

<details markdown="1">
<summary>Output files</summary>

- `**predictions*.csv`: CSV file with the consolidated predicted response values for the test set.
- `**cross_study/cross_study*.csv`: CSV file with the consolidated predicted response values for the cross-study
  datasets.
- `**randomization*.csv`: CSV file with the consolidated predicted response values for the randomization test.
- `**robustness*.csv`: CSV file with the consolidated predicted response values for the robustness test.

</details>

#### Evaluate final

Calculates various performance metrics on the given test set results, including RMSE, MSE, MAE, R^2, Pearson
Correlation, Spearman Correlation, Kendall Correlation, and Partial Correlation.

#### Collect results

Collapses the results from above into four overview tables: `evaluation_results.csv`, `evaluation_results_per_drug.
csv`, `evaluation_results_per_cell_line.csv`, and `true_vs_pred.csv`.

<details markdown="1">
<summary>Output files</summary>

- `evaluation_results.csv`: Overall performance metrics. One value per model per CV fold and setting (LPO/LCO/LDO,
  full predictions, randomizations, robustness, cross-study predictions).
- `evaluation_results_per_drug.csv`: Performance metrics calculated per drug.
- `evaluation_results_per_cell_line.csv`: Performance metrics calculated per cell line.
- `true_vs_pred.csv`: true vs predicted values for each model.

</details>

### Subworkflow `VISUALIZATION`

#### Critical difference

The critical difference plot measures whether a model is significantly better than another model measured over its
average rank over all CV folds.

<details markdown="1">
<summary>Output files</summary>

- `critical_difference*.svg`: SVG file with the critical difference plot.

</details>

#### Violin plot

The violin shows the distribution of the performance metrics over the CV folds. This plot is rendered overall for
all real predictions and once per algorithm to compare the real predictions against, e.g., the randomization results.

<details markdown="1">
<summary>Output files</summary>

- `violin*.html`: HTML file with the violin plot.

</details>

#### Heatmap

The heatmap shows the average performance of the models over the CV folds. This plot is rendered overall for all
real predictions and once per algorithm to compare the real predictions against, e.g., the randomization results.

<details markdown="1">
<summary>Output files</summary>

- `heatmap*.html`: HTML file with the violin plot.

</details>

#### Correlation comparison

Renders a plot in which the per-drug/per-cell line correlations between y_true and y_predicted are compared between
different models.

<details markdown="1">
<summary>Output files</summary>

- `corr_comp_scatter*.html`: HTML file with the violin plot.

</details>

#### Regression plots

Plots in which the y_true and y_predicted values are compared between different models.

<details markdown="1">
<summary>Output files</summary>

- `regression_lines*.html`: HTML file with the violin plot.

</details>

#### Save tables

Saves the performance metrics of the models in an html table.

<details markdown="1">
<summary>Output files</summary>

- `table*.html`: HTML file with the violin plot.

</details>

#### Write html

Creates a summary HTML file per setting (LPO/LCO/LDO) that contains all the plots and tables.

<details markdown="1">
<summary>Output files</summary>

- `{LPO,LCO,LPO}.html`: HTML file with the violin plot.

</details>

#### Write index

Writes an index.html file that links to all the HTML files.

<details markdown="1">
<summary>Output files</summary>

- `index.html`: HTML file with the violin plot.
- `*.png`: Some png files for the logo, etc.

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
