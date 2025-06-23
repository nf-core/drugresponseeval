# nf-core/drugresponseeval: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished.
All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

1. `PREPROCESS_CUSTOM` subworkflow: This subworkflow is only triggered if there is a custom dataset and if in the corresponding folder, there is a file named `[dataset_name]_raw.csv`. If this is the case, CurveCurator is run on the raw data.
   - [Preprocess raw viability](#preprocess-raw-viability): The raw viability data is put in a format suitable for CurveCurator.
   - [Fit curves](#fit-curves): Curves are fitted using CurveCurator.
   - [Postprocess CurveCurator data](#postprocess-curvecurator-data): The individual curves.tsv files are collected and one output file is written.
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
   - If `--final_model_on_full_data` is set: the model is trained on the full dataset to produce a production model. If `--no_hyperparameter_tuning` is **not** set, the model will be tuned on the full dataset, too. The model will be saved in the results directory.
     - [FINAL_SPLIT](#final-split): For each model class, the full dataset is split into training, validation, and potentially early stopping sets. This is done to ensure per model and not overall to retain the maximum amount of data for training (because the data is filtered according to cell line / drug feature availability).
     - [TUNE_FINAL_MODEL](#tune-final-model): The final model is tuned on the full dataset.
     - [EVALUATE_FIND_MAX_FINAL](#evaluate-and-find-max-final): The best hyperparameters for the final model are determined on the validation dataset.
     - [TRAIN_FINAL_MODEL](#train-final-model): The final model is trained on the full dataset (train+validation) with the best hyperparameters. The model is saved in the results directory.
   - [Consolidate results](#consolidate-results): The results of the model testing are consolidated into a single
     table for each model.
   - [Evaluate final](#evaluate-final): The performance of the models is calculated on the test set results.
   - [Collect results](#collect-results): The results of the evaluation metrics per model are collected into four
     overview tables.
4. `VISUALIZATION` subworkflow: Plots are created summarizing the results.
5. [Pipeline information](#pipeline-information): Report metrics generated during the workflow execution

### Subworkflow `PREPROCESS_CUSTOM`

This process is only triggered if there is a custom dataset and if in the corresponding folder, there is a file named `[dataset_name]_raw.csv`.

#### Preprocess raw viability

The file is processed to be in a format suitable for CurveCurator. One process will be started per dosage.

<details markdown="1">
<summary>Output files</summary>

- "${dataset_name}/\*/config.toml": Configuration files for CurveCurator. Each subdirectory corresponds to a different dosage.
- "${dataset_name}/\*/curvecurator_input.tsv": Input file for CurveCurator. Each subdirectory corresponds to a different dosage.

</details>

#### Fit curves

CurveCurator is run on the input files to fit the curves.

<details markdown="1">
<summary>Output files</summary>
- "curves.tsv": The fitted curves. These will be collected and postprocessed in the next step.
- "mad.txt": Other output - Median absolute deviation analysis is performed to detect problematic experiments, the results are stored in this file.
- "dashboard.html" - A dashboard with an overview of the fitted curves.
- "curveCurator.log" - Log file of the CurveCurator run.
</details>

#### Postprocess CurveCurator data

The individual curves.tsv files are collected and one output file is written to `path_data/dataset_name/dataset_name.csv`.
This file contains the new adjusted measures; available are pEC50 and AUC (now internally renamed as pEC50_curvecurator, AUC_curvecurator).

<details markdown="1">
<summary>Output files</summary>
- "dataset_name.csv": The postprocessed data; exported to the path_data folder.
</details>

### Subworkflow `RUN_CV`

#### Load response

The response data is loaded into the pipeline. If the data does not lie in `--path_data` it is downloaded from Zenodo
(`--zenodo_link`) and exported to `--path_data`. If it is downloaded, it is additionally unzipped by the UNZIP module.
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

All plots are created in the `visualization` subworkflow. They are saved in the results/report directory.

<details markdown="1">
<summary>Output files</summary>

- `critical_difference*.svg`: The critical difference plot measures whether a model is significantly better than another model measured over its
  average rank over all CV folds.
- `critical_difference*.html`: The corresponding p-values in a table.
- `violin*.html`: The violin shows the distribution of the performance metrics over the CV folds. This plot is rendered overall for
  all real predictions and once per algorithm to compare the real predictions against, e.g., the randomization results.
- `heatmap*.html`: The heatmap shows the average performance of the models over the CV folds.
- `comp_scatter*.html`: Renders a plot in which the per-drug/per-cell line performances between y_true and y_predicted are compared between
  different models.
- `regression_lines*.html`: Plots in which the y_true and y_predicted values are compared between different models (not rendered for Naive Predictors).
- `table*.html`: Saves the cross-study performance metrics of the models in an html table.
- `{LPO,LCO,LTO,LPO}.html`: Creates a summary HTML file per setting (LPO/LCO/LTO/LDO) that contains all the plots and tables.
- `index.html`: HTML file that links to all the HTML files.
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

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times, and resource usage.
