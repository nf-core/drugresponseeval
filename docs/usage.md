# nf-core/drugresponseeval: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/drugresponseeval/usage](https://nf-co.re/drugresponseeval/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

DrugResponseEval is a workflow designed to ensure that drug response prediction models are evaluated in a consistent and
reproducible manner. We offer three settings:

- **Leave-Pair-Out (LPO)**: Random pairs of cell lines and drugs are left out for testing but both the drug and the
  cell line might already be present in the training set. This is the **easiest setting** for your model but also the
  most uninformative one. The only application scenario for this setting is when you want to test whether your model
  can **complete the missing values in the training set**.
- **Leave-Cell-Line-Out (LCO)**: Random cell lines are left out for testing but the drugs might already be present in
  the training set. This setting is **more challenging** than LPO but still relatively easy. The application scenario
  for this setting is when you want to test whether your model can **predict the response of a new cell line**. This
  is very relevant for **personalized medicine**.
- **Leave-Tissue-Out (LTO)**: Random tissues of origin are left out for testing but the drugs and cell lines might already be
  present in the training set. This setting is **more challenging** than LCO because for LCO, very similar cell lines might
  end up in the test dataset. Because it can still leverage drug means, it is still relatively easy, though. The application
  scenario for this setting is when you want to test whether your model can **predict the response of a new tissue**.
  This is very relevant for **drug repurposing**.
- **Leave-Drug-Out (LDO)**: Random drugs are left out for testing but the cell lines might already be present in the
  training set. This setting is the **most challenging** one. The application scenario for this setting is when you
  want to test whether your model can **predict the response of a new drug**. This is very relevant for **drug
  development**.

An underlying issue is that drugs have a rather unique IC50/EC50 range. That means that by just predicting the mean response
that a drug has in the training set (aggregated over all cell lines), you can already achieve a rather good
prediction. This is why we also offer the possibility to compare your model to a **NaivePredictor** that predicts
the mean response of all drugs in the training set. We also offer four more advanced naive predictors:
**NaiveCellLineMeanPredictor**, **NaiveTissueMeanPredictor**, **NaiveDrugMeanPredictor**, and **NaiveMeanEffectsPredictor**.
The NaiveCellLineMeanPredictor predicts the mean response of a cell line in the training set, the NaiveTissueMeanPredictor
the mean response of a tissue of origin in the training set, the NaiveDrugMeanPredictor
predicts the mean response of a drug in the training set. The NaiveMeanEffectsPredictor combines both sources of variation
and predicts responses as the sum of the overall mean (NaivePredictor) + cell line + drug-specific means.
**The NaiveMeanEffectsPredictor is always run.**

Furthermore, we offer a variety of more advanced **baseline models** and some **state-of-the-art models** to compare
your model against. Similarly, we provide commonly used datasets to evaluate your model on (GDSC1, GDSC2, CCLE,
CTRPv1, CTRPv2). You can also provide your **own dataset or your own model by contributing to our PyPI package
[drevalpy](https://github.com/daisybio/drevalpy.git)** Before contributing, you can pull our respective repositories.
More information can be found in the [drevalpy readthedocs](https://drevalpy.readthedocs.io/en/latest/).

We first identify the best hyperparameters for all models and baselines in a cross-validation setting. Then, we
train the models on the whole training set and evaluate them on the test set. Furthermore, we offer randomization
and robustness tests.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/drugresponseeval \
   -profile <docker/singularity/.../institute> \
   --run_id myRun \
   --test_mode <LPO/LCO/LTO/LDO> \
   --models <model1,model2,...> \
   --baselines <baseline1,baseline2,...> \
   --dataset_name <dataset_name> \
   --path_data <path_data>
```

This will launch the pipeline with the `docker/singularity/.../institute` configuration profile. See below for more information about profiles.

In your `outdir`, a folder named `myRun` will be created containing the results of the pipeline run.

The `test_mode` parameter specifies the evaluation setting, e.g., `--test_mode LCO`.

The `models` and `baselines` parameters are lists of models and baselines to be evaluated, e.g.,
`--models ElasticNet,RandomForest --baselines NaivePredictor,NaiveCellLineMeanPredictor,NaiveDrugMeanPredictor`.

The `dataset_name` parameter specifies the dataset to be used for evaluation, e.g., `--dataset_name CTRPv2`.

If you do not want to re-download the data every time you run the pipeline, you can specify the path to the data with
the `path_data` parameter, e.g., `--path_data /path/to/data`.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir), defaults to 'results'
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command,
you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/drugresponseeval -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
models: 'ElasticNet'
baselines: 'NaivePredictor,NaiveCellLineMeanPredictor,NaiveDrugMeanPredictor'
dataset_name: 'GDSC2'
path_data: '/path/to/data'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Available Models

**Single-Drug Models** fit one model for each drug in the training set. They also cannot generalize to new drugs,
hence those models cannot be used in the LDO setting. **Multi-Drug Models** fit one model for all drugs in the training
set. They can be used in all three settings.

The following models are available:

| Model Name                       | Baseline / Published Model | Multi-Drug Model / Single-Drug Model | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| -------------------------------- | -------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NaivePredictor                   | Baseline Method            | Multi-Drug Model                     | Most simple method. Predicts the mean response of all drugs in the training set.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| NaiveCellLineMeanPredictor       | Baseline Method            | Multi-Drug Model                     | Predicts the mean response of a cell line in the training set.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| NaiveDrugMeanPredictor           | Baseline Method            | Multi-Drug Model                     | Predicts the mean response of a drug in the training set.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| NaiveTissueMeanPredictor         | Baseline Method            | Multi-Drug Model                     | Predicts the mean response of a tissue in the training set.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| NaiveMeanEffectsPredictor        | Baseline Method            | Multi-Drug Model                     | Predicts the drug- and cell-line specific mean effects.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ElasticNet                       | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Elastic Net](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.ElasticNet.html), [Lasso](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Lasso.html), or [Ridge](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Ridge.html) model on gene expression data and drug fingerprints (concatenated input matrix).                                                                                                                                                                                         |
| ProteomicsElasticNet             | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Elastic Net](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.ElasticNet.html), [Lasso](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Lasso.html), or [Ridge](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Ridge.html) model on proteomics data and drug fingerprints (concatenated input matrix).                                                                                                                                                                                              |
| SingleDrugElasticNet             | Baseline Method            | Single-Drug Model                    | Fits an ElasticNet model on gene expression data for each drug separately.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| SingleDrugProteomicsElasticNet   | Baseline Method            | Single-Drug Model                    | Fits an ElasticNet model on proteomics data for each drug separately.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| GradientBoosting                 | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Gradient Boosting Regressor](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingRegressor.html) gene expression data and drug fingerprints.                                                                                                                                                                                                                                                                                                                                                                                              |
| RandomForest                     | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Random Forest Regressor](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html) on gene expression data and drug fingerprints.                                                                                                                                                                                                                                                                                                                                                                                                   |
| MultiOmicsRandomForest           | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Random Forest Regressor](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html) on gene expression, methylation, mutation, copy number variation data, and drug fingerprints (concatenated matrix). The dimensionality of the methylation data is reduced with a PCA to the first 100 components before it is fed to the model.                                                                                                                                                                                                  |
| ProteomicsRandomForest           | Baseline Method            | Multi-Drug Model                     | Fits Random Forest on proteomics data and drug fingerprints.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| SingleDrugRandomForest           | Baseline Method            | Single-Drug Model                    | Fits an [Sklearn Random Forest Regressor](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html) on gene expression data for each drug separately.                                                                                                                                                                                                                                                                                                                                                                                                |
| SingleDrugProteomicsRandomForest | Baseline Method            | Single-Drug Model                    | Fits an [Sklearn Random Forest Regressor](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html) on proteomics data for each drug separately.                                                                                                                                                                                                                                                                                                                                                                                                     |
| SVR                              | Baseline Method            | Multi-Drug Model                     | Fits an [Sklearn Support Vector Regressor](https://scikit-learn.org/1.5/modules/generated/sklearn.svm.SVR.html) gene expression data and drug fingerprints.                                                                                                                                                                                                                                                                                                                                                                                                                               |
| SimpleNeuralNetwork              | Baseline Method            | Multi-Drug Model                     | Fits a simple feedforward neural network (implemented with [Pytorch Lightning](https://lightning.ai/docs/pytorch/stable/)) on gene expression and drug fingerprints (concatenated input) with 3 layers of varying dimensions and Dropout layers.                                                                                                                                                                                                                                                                                                                                          |
| MultiOmicsNeuralNetwork          | Baseline Method            | Multi-Drug Model                     | Fits a simple feedforward neural network (implemented with [Pytorch Lightning](https://lightning.ai/docs/pytorch/stable/)) on gene expression, methylation, mutation, copy number variation data, and drug fingerprints (concatenated input) with 3 layers of varying dimensions and Dropout layers. The dimensionality of the methylation data is reduced with a PCA to the first 100 components before it is fed to the model.                                                                                                                                                          |
| SRMF                             | Published Model            | Multi-Drug Model                     | [Similarity Regularization Matrix Factorization](https://doi.org/10.1186/s12885-017-3500-5) model by Wang et al. on gene expression data and drug fingerprints. Re-implemented Matlab code into Python. The basic idea is represent each drug and each cell line by their respective similarities to all other drugs/cell lines. Those similarities are mapped into a shared latent low-dimensional space from which responses are predicted.                                                                                                                                             |
| MOLIR                            | Published Model            | Single-Drug Model                    | Regression extension of [MOLI: multi-omics late integration deep neural network.](https://doi.org/10.1093/bioinformatics/btz318) by Sharifi-Noghabi et al. Takes somatic mutation, copy number variation and gene expression data as input. MOLI reduces the dimensionality of each omics type with a hidden layer, concatenates them into one representation and optimizes this representation via a combined cost function consisting of a triplet loss and a binary cross-entropy loss. We implemented a regression adaption with MSE loss and an adapted triplet loss for regression. |
| SuperFELTR                       | Published Model            | Single-Drug Model                    | Regression extension of [SuperFELT: supervised feature extraction learning using triplet loss for drug response](https://doi.org/10.1186/s12859-021-04146-z) by Park et al. Very similar to MOLI(R). In MOLI(R), encoders and the classifier were trained jointly. Super.FELT(R) trains them independently. MOLI(R) was trained without feature selection (except for the Variance Threshold on the gene expression). Super.FELT(R) uses feature selection for all omics data.                                                                                                            |
| DIPK                             | Published Model            | Multi-Drug Model                     | [Deep neural network Integrating Prior Knowledge](https://doi.org/10.1093/bib/bbae153) from Li et al. Uses gene interaction relationships (encoded by a graph auto-encoder), gene expression profiles (encoded by a denoising auto-encoder), and molecular topologies (encoded by MolGNet). Those features are integrated using multi-head attention layers.                                                                                                                                                                                                                              |

### Custom models

If you want to use your own model, you must contribute it to drevalpy. Please follow the following steps:

1. Fork the [drevalpy repository](https://github.com/daisybio/drevalpy)
2. Create a mamba environment: `mamba create -n drevalpy python=3.13`
3. Install the dependencies:
   - Run: `pip install poetry`
   - Then run: `poetry install`
4. Implement your model (for more information on that, check the [ReadTheDocs](https://drevalpy.readthedocs.io/en/latest/runyourmodel.html))
5. Test your model with the tests in `tests/`. Also, implement your own tests.
6. (You can then open a PR to the main repository for contributing your model)
7. Install drevalpy into your environment: `pip install -e .`
8. From your environment, try to run the pipeline: `nextflow run nf-core/drugresponseeval -r dev -profile test`
9. If everything works, try running your model: `nextflow run nf-core/drugresponseeval -r dev --models <your_model> --dataset_name <dataset_name>`

### Saving a production model

If you want to save a production model, you can set the `--final_model_on_full_data` flag. This will save the model trained on the full dataset in the results directory.
The model can later be loaded using the implemented load functions of the drevalpy models.
Here is an example of how to load a GradientBoosting model that was saved in the `results` directory:

```python
from drevalpy.models import MODEL_FACTORY

model_class = MODEL_FACTORY["GradientBoosting"]
# provide the path to the final_model directory
gb_model = model_class.load('results/test_run/LCO/GradientBoosting/final_model/')
```

You can then investigate the sklearn HistGradientBoostingRegressor model saved in `gb_model.model`.
You can then either use `drevalpy` functions to predict responses for new data or use the model directly with `sklearn` functions.

With `drevalpy`:

```python
from drevalpy.datasets.dataset import DrugResponseDataset
# first load the new data which must have the 'measure' column and the cell line and drug identifiers ('cell_line_name', 'pubchem_id').
# The tissue column is optional.
new_dataset = DrugResponseDataset.from_csv(input_file='path/to/new_data.csv', dataset_name='my_new_data',
                                           measure='LN_IC50', tissue_column='tissue')
# In the path_to_features directory, we expect a directory called like the dataset_name (here my_new_data), which contains the cell line and drug features.
path_to_features = 'path/to/cell_line_and_drug_features/'
cl_features = gb_model.load_cell_line_features(data_path=path_to_features, dataset_name='my_new_data')
drug_features = gb_model.load_drug_features(data_path=path_to_features, dataset_name='my_new_data')
# Now we have to filter the dataset to only contain the cell lines and drugs that are in the features.
cell_lines_to_keep = cl_features.identifiers if cl_features is not None else None
drugs_to_keep = drug_features.identifiers if drug_features is not None else None
new_dataset.reduce_to(cell_line_ids=cell_lines_to_keep, drug_ids=drugs_to_keep)
# Now we can predict the responses for the new data.
new_dataset._predictions = gb_model.predict(
  cell_line_ids=new_dataset.cell_line_ids,
  drug_ids=new_dataset.drug_ids,
  cell_line_input=cl_features,
  drug_input=drug_features,
)
# This will create a csv with 'cell_line_name', 'pubchem_id', 'response', 'predictions', 'tissue' (if provided) columns.
new_dataset.to_csv('path/to/predictions.csv')
```

### Available Datasets

The following datasets are available and can be supplied via `--dataset_name`:

| Dataset Name | Number of DRP curves | Number of drugs | Number of Cell Lines | Description                                                                                      |
| ------------ | -------------------- | --------------- | -------------------- | ------------------------------------------------------------------------------------------------ |
| CTRPv1       | 60,758               | 354             | 243                  | The Cancer Therapeutics Response Portal (CTRP) dataset version 1.                                |
| CTRPv2       | 395,025              | 546             | 886                  | The Cancer Therapeutics Response Portal (CTRP) dataset version 2.                                |
| CCLE         | 11,670               | 24              | 503                  | The Cancer Cell Line Encyclopedia (CCLE) dataset.                                                |
| GDSC1        | 316,506              | 378             | 970                  | The Genomics of Drug Sensitivity in Cancer (GDSC) dataset version 1.                             |
| GDSC2        | 234,437              | 287             | 969                  | The Genomics of Drug Sensitivity in Cancer (GDSC) dataset version 2.                             |
| TOYv1        | 2,711                | 36              | 90                   | A toy dataset for testing purposes subsetted from CTRPv2.                                        |
| TOYv2        | 2,784                | 36              | 90                   | A second toy dataset for cross study testing purposes. 80 cell lines and 32 drugs overlap TOYv2. |

Our pipeline also supports cross-study prediction, i.e., training on one dataset and testing on another (or multiple
others) to assess the generalization of the model. This dataset name can be supplied via `--cross_study_datasets`.

The drug response measure that you want to use as the target variable can be specified via the `--measure` parameter.
Available measures are `[“AUC”, “pEC50”, “EC50”, “IC50”]`.

We have re-fitted all the curves in the available datasets with <b>CurveCurator</b> to ensure that the data is processed
well. By default, we use those measures. If you do not want to use those measures, enable the `--no_refitting` flag.

#### Custom datasets

You can also provide your own custom dataset via the `--dataset_name` parameter by specifying a name that is not in the list of the available datasets.
This can be prefit data (not recommended for comparability reasons) or raw viability data that is automatically fit
with the exact same procedure that was used to refit the available datasets in the previous section.

<i>Raw viability data</i>

We expect a csv-formatted file in the location `<path_data>/<dataset>/<dataset_name>_raw.csv`
(corresponding to the `--path_data` and `--dataset_name` options), which contains the raw viability data in long format
with the columns `[“dose”, “response”, “sample”, “drug”]` and an optional “replicate” column.
If replicates are provided, the procedure will fit one curve per sample / drug pair using all replicates.

The pipeline then fits the curves using CurveCurator and saves the processed file to `<path_data>/<dataset>/<dataset_name>.csv`
For individual results, look in the work directories.

<i>Prefit viability data</i>

We expect a csv-formatted file in the location `<path_data>/<dataset>/<dataset_name>.csv`
(corresponding to the `--path_data` and `--dataset_name` options), with at least the columns `[“cell_line_id”, “drug_id”, <measure>”]`
where `<measure>` is replaced with the name of the measure you provide (`[“AUC”, “pEC50”, “EC50”, “IC50”]`).
It is required that you use measure names that are also working with the available datasets if you use the `--cross_study_datasets` option.

### Available Randomization Tests

We have several randomization modes and types available.

The modes are supplied via `--randomization_mode` and the types via `--randomization_type`.:

- **SVCC: Single View Constant for Cell Lines:** A single cell line view (e.g., gene expression) is held unperturbed
  while the others are randomized.
- **SVCD: Single View Constant for Drugs:** A single drug view (e.g., drug fingerprints) is held unperturbed while the
  others are randomized.
- **SVRC: Single View Random for Cell Lines:** A single cell line view (e.g., gene expression) is randomized while the
  others are held unperturbed.
- **SVRD: Single View Random for Drugs:** A single drug view (e.g., drug fingerprints) is randomized while the others
  are held unperturbed.

Currently, we support two ways of randomizing the data. The default is permututation.

- **Permutation**: Permutes the features over the instances, keeping the distribution of the features the same but
  dissolving the relationship to the target.
- **Invariant**: The randomization is done in a way that a key characteristic of the feature is preserved. In case
  of matrices, this is the mean and standard deviation of the feature view for this instance, for networks it is the
  degree distribution.

### Robustness Tests

The robustness test is a test where the model is trained with varying seeds. This is done multiple times to see how
stable the model is. Via `--n_trials_robustness`, you can specify the number of trials for the robustness tests.

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/drugresponseeval
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/drugresponseeval releases page](https://github.com/nf-core/drugresponseeval/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
