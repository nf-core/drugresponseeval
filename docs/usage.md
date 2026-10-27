# nf-core/drugresponseeval: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/drugresponseeval/usage](https://nf-co.re/drugresponseeval/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

DrugResponseEval is a Nextflow pipeline around [drevalpy](https://drevalpy.readthedocs.io/en/latest/) that benchmarks
drug response prediction models in a consistent and reproducible way. It finds the best hyperparameters for all models in
cross-validation, trains the final models, evaluates them on the test set, and optionally runs randomization and
robustness tests.

Choose how your data is split with `--test_mode` (`LPO`, `LCO`, `LTO` or `LDO`; see
[Available Settings](https://drevalpy.readthedocs.io/en/latest/usage.html#available-settings)). The
`NaiveMeanEffectsPredictor` baseline is always run (see
[Available Models](https://drevalpy.readthedocs.io/en/latest/usage.html#available-models)).

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
   --path_data <path_data> \
   --outdir results
```

This will launch the pipeline with the `docker/singularity/.../institute` configuration profile. See below for more information about profiles.

In your `outdir`, a folder named `myRun` will be created containing the results of the pipeline run. For all available
parameters, see the [parameter documentation](https://nf-co.re/drugresponseeval/parameters). Models, baselines and
datasets are described below.

If you do not want to re-download the data every time you run the pipeline, point `--path_data` to a persistent folder,
e.g., `--path_data /path/to/data`.

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
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

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

Pass model names to `--models` and baselines to `--baselines` (comma-separated). **Single-Drug Models** (marked with \*)
fit one model per drug and cannot generalize to new drugs, so they cannot be used with `--test_mode LDO`. All other
models are **Multi-Drug Models** and work in all four settings.

- **Baselines:** `NaivePredictor`, `NaiveCellLineMeanPredictor`, `NaiveDrugMeanPredictor`, `NaiveMeanEffectsPredictor`,
  `NaiveTissueMeanPredictor`, `NaiveTissueDrugMeanPredictor`, `AdaBoostDecisionTree`, `ElasticNet`, `Lasso`,
  `SingleDrugElasticNet`\*, `GradientBoosting`, `MultiViewXGBoost`, `MultiViewLightGBM`, `KNNRegressor`, `RandomForest`,
  `MultiViewRandomForest`, `SingleDrugRandomForest`\*, `SVR`
- **Custom models:** `SimpleNeuralNetwork`, `MultiViewNeuralNetwork`, `DrugGNN`, `EnsembleMF`
- **Published models:** `PharmaFormer`, `SRMF`, `MOLIR`\*, `SuperFELTR`\*, `DIPK`, `Precily`, `PaccMann`, `SparseGO`

For a description of every model, see
[Available Models](https://drevalpy.readthedocs.io/en/latest/usage.html#available-models) in the drevalpy documentation.

### Custom models

To use your own model, it must be part of the `drevalpy` Python package, because the pipeline calls all models through
it. Follow the drevalpy guide
[Implement your model](https://drevalpy.readthedocs.io/en/latest/runyourmodel.html) (see also
[a complete example](https://drevalpy.readthedocs.io/en/latest/example_tinynn.html)). Optionally, you can
[contribute](https://drevalpy.readthedocs.io/en/latest/contributing.html) it to drevalpy via a pull request.

Install your clone into the environment you will start Nextflow from (`pip install -e .`) and check that the pipeline
works with your model on the small toy data before using real data:

```bash
nextflow run nf-core/drugresponseeval -r dev -profile test --models YourModel
```

Use `--no_hyperparameter_tuning` while debugging to only train with the first hyperparameter set.

> [!IMPORTANT]
> Because the model only exists in your local `drevalpy` installation, run Nextflow **without** a container or conda
> profile (no `-profile docker/singularity/conda`), so that the processes use the `drevalpy` installed in your
> environment. The container images contain the released `drevalpy` and do not know your model. Cluster profiles that do not
> start a container are fine.

### Benchmark your own model

This section is the shortest path from "I have a model" to "my model is on the leaderboard". The leaderboard compares
models on fixed, precomputed cross-validation (CV) splits of CTRPv2 in the leave-cell-line-out setting (LCO), so every
model is evaluated on exactly the same data.

You need to do four things:

1. [Implement your model](#1-implement-your-model) in `drevalpy` and install it.
2. [Download the precomputed splits](#2-get-the-splits-and-the-leaderboard-results) and the existing leaderboard results.
3. [Run the pipeline](#3-run-your-model-on-the-leaderboard-splits) with your model on those splits.
4. [Add your results to the leaderboard](#4-compare-against-the-leaderboard) and plot it.

> [!NOTE]
> The leaderboard is defined for `--test_mode LCO` and `--dataset_name CTRPv2` (both are the pipeline defaults) with the
> default measure (`LN_IC50`, which resolves to the CurveCurator-refitted `LN_IC50_curvecurator`). Do not set
> `--no_refitting`.

#### 1. Implement your model

Implement and install your model as described in [Custom models](#custom-models) and check that it runs on the toy data.

#### 2. Get the splits and the leaderboard results

Download the following from [Zenodo](https://doi.org/10.5281/zenodo.12633909) and unzip them:

- `splits.zip`: the CV splits used for the leaderboard. It contains a folder `splits` with
  `cv_split_<i>_{train,validation,test}.csv` (and optionally `_validation_es.csv` and `_early_stopping.csv`) files.
- `leaderboard_Oct26.zip`: the results of the models that are already on the leaderboard
  (`evaluation_results.csv` and `true_vs_pred.csv`).

#### 3. Run your model on the leaderboard splits

The pipeline can use your own splits via `--custom_splitter_path` (see [Custom CV splits](#custom-cv-splits)). The file
`assets/custom_splitter_from_csvs.py` loads exactly the CSV format of `splits.zip`.

Copy it and set the path to the unzipped splits **inside the file**:

```bash
cp assets/custom_splitter_from_csvs.py my_splitter.py
# edit my_splitter.py: SPLITS_DIR = Path("/path/to/splits")
```

> [!WARNING]
> The splitter runs inside the `CV_SPLIT` process, so `SPLITS_DIR` must be an absolute path that is reachable from where
> the process runs (on a cluster: a shared file system).

Then run the pipeline:

```bash
nextflow run nf-core/drugresponseeval \
   -profile <your cluster profile, no container profile> \
   --run_id my_model \
   --test_mode LCO \
   --dataset_name CTRPv2 \
   --custom_splitter_path my_splitter.py \
   --models YourModel \
   --baselines NaiveMeanEffectsPredictor
```

- `--n_cv_splits` is ignored, the number of splits is read from the files.
- `--models` takes your model; `--baselines` are tuned and compared as well but skip randomization and robustness tests.
  The `NaiveMeanEffectsPredictor` is always run.
- Add `-profile gpu` (together with your cluster profile) if your model should train on a GPU.
- If the run is interrupted, restart it with the same command plus `-resume`.

When the run is finished, the results are in `results/my_model/`:

```
results/my_model/
├── evaluation_results.csv         # metrics per model and CV split
├── evaluation_results_per_drug.csv
├── evaluation_results_per_cl.csv
├── true_vs_pred.csv               # true and predicted responses
├── LCO/                           # predictions per model
└── index.html, LCO.html, ...      # report with all plots
```

Open `results/my_model/index.html` to look at your model on its own (critical difference diagram, violin plots, heatmaps, ...).

#### 4. Compare against the leaderboard

Add the lines of your model from `results/my_model/evaluation_results.csv` and `true_vs_pred.csv` to the existing
leaderboard results (`leaderboard_Oct26.zip`) and create the leaderboard plots and critical difference diagram. The
commands are described in the drevalpy guide
[Create the leaderboard](https://drevalpy.readthedocs.io/en/latest/leaderboard.html). Use `--test_mode LCO` and
`--dataset CTRPv2` there.

#### Troubleshooting

| Problem                                       | Likely cause                                                                                                                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| The pipeline does not find `YourModel`        | The model is not registered in `drevalpy/models/__init__.py`, or the clone is not installed (`pip install -e .`), or a container profile is used. |
| The splitter finds no folds                   | `SPLITS_DIR` in your splitter copy is wrong or not visible to the process.                                                                        |
| Splitter validation error (shared cell lines) | The splits do not match `--test_mode`; use the LCO splits with `--test_mode LCO`.                                                                 |
| No critical difference diagram                | Too few CV splits (at least 7 are recommended).                                                                                                   |
| Your model is missing in the leaderboard plot | The appended lines have a different test mode or dataset than `--test_mode` / `--dataset`.                                                        |

### Running an existing model with different input

The sklearn and neural network baseline models can run on other input data than their defaults. Set the `cell_line_views`
and `drug_views` of the model in `drevalpy/models/baselines/hyperparameters.yaml` to the name of your input, as described
in the drevalpy guide
[Custom input with drevalpy's baselines](https://drevalpy.readthedocs.io/en/latest/example_flexible_inputs.html). Then
install your clone as described in [Custom models](#custom-models) and run the pipeline without a container profile.

### Custom CV splits

By default, the CV splits are created by drevalpy. To use your own, pass a Python script via `--custom_splitter_path`.
The script must define a module-level function `create_splits(response_data, params)` that returns a list of folds.
Each fold is a dict with the keys `train`, `validation` and `test` (optionally also `validation_es` and
`early_stopping`, otherwise they are derived from `validation`) holding `DrugResponseDataset`s.
`params.test_mode` is the test mode the script is called for; the script is used for every mode in `--test_mode`, and
the output is validated against that mode (e.g., no shared cell lines between train and test for LCO).
The script runs inside the `CV_SPLIT` container, so it can only use the packages installed there and has to be able
to reach any files it reads. An example that loads folds from a directory of CSVs is in
`assets/custom_splitter_from_csvs.py`.

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

Supply a dataset via `--dataset_name`:

- **Cell line screens:** `CTRPv1`, `CTRPv2`, `CCLE`, `GDSC1`, `GDSC2`
- **Drug-cleaned CTRPv2 variants:** `CTRPv2_clean`, `CTRPv2_cleaner`, `CTRPv2_cleanest` (see [Cleaner datasets](#cleaner-datasets))
- **Clinically more relevant:** `BeatAML2` (AML patients), `PDX_Bruna` (breast cancer PDX)
- **For testing:** `TOYv1`, `TOYv2` (small datasets, used by `-profile test`)

The number of curves, drugs and cell lines per dataset is listed in
[Available Datasets](https://drevalpy.readthedocs.io/en/latest/usage.html#available-datasets) in the drevalpy
documentation.

To test generalization to other datasets, supply them via `--cross_study_datasets`. The drug response measure used as the
prediction target is set with `--measure` (`AUC`, `pEC50`, `EC50`, `IC50`, `LN_IC50` or `response`).

By default, the pipeline uses measures that were re-fitted with CurveCurator for all datasets, which makes them comparable
across studies. Only set `--no_refitting` if you want the originally published measures instead.

#### Custom datasets

To use your own dataset, give `--dataset_name` a name that is not in the list above. You can provide raw viability data,
which the pipeline fits automatically with CurveCurator, or prefit data (not recommended for comparability reasons). More
details are in the drevalpy documentation on
[Custom Datasets](https://drevalpy.readthedocs.io/en/latest/usage.html#custom-datasets).

<i>Raw viability data</i>

We expect a csv-formatted file in the location `<path_data>/<dataset>/<dataset_name>_raw.csv`
(corresponding to the `--path_data` and `--dataset_name` options), which contains the raw viability data in long format
with the columns `[“dose”, “response”, “sample”, “drug”]` and an optional “replicate” column.
If replicates are provided, the procedure will fit one curve per sample / drug pair using all replicates.

**All dosages have to be provided in µM!** The pipeline fits the curves using CurveCurator and saves the processed file
to `<path_data>/<dataset>/<dataset_name>.csv`. For individual results, look in the work directories.

<i>Prefit viability data</i>

We expect a csv-formatted file in the location `<path_data>/<dataset>/<dataset_name>.csv`
(corresponding to the `--path_data` and `--dataset_name` options), with at least the columns `[“cell_line_name”, “pubchem_id”, “<measure>”]`
where `<measure>` is replaced with the name of the measure you provide (`[“AUC”, “pEC50”, “EC50”, "LN_IC50", “IC50”, "response"]`).
It is required that you use measure names that are also working with the available datasets if you use the `--cross_study_datasets` option.
For LTO, you must also provide a `tissue` column with tissue information.

#### Cleaner datasets

Curve-curated screens contain many drugs that are inactive on essentially every cell line. To evaluate on a drug-cleaned
variant of the dataset given via `--dataset_name`, use one of the following (set at most one):

- `--clean_min_responders N`: keep only drugs with at least `N` reproducible (curve-curated) responder curves. This absolute
  count is recommended, as it is independent of screen size.
- `--clean_min_responder_frac F`: keep only drugs whose fraction of significant responder curves is at least `F` (in `(0, 1]`).

Three ready-made tiers of CTRPv2 are also available directly via `--dataset_name`: `CTRPv2_clean` (at least 15 responder
curves per drug), `CTRPv2_cleaner` (at least 30), and `CTRPv2_cleanest` (at least 50).

To clean any other curve-curated dataset with your own threshold, keep `--dataset_name` on the base dataset, e.g., to keep
only GDSC2 drugs with at least 30 responder curves:

```bash
nextflow run nf-core/drugresponseeval \
  --dataset_name GDSC2 \
  --clean_min_responders 30 \
  --outdir results/ \
  -profile docker
```

The cleaned variant is created once as `<dataset_name>_clean_min<N>` (or `<dataset_name>_clean_frac<F>`) next to the base
dataset in `--path_data`, reusing the base dataset's feature files, and results are written under that name.

Whole drugs are removed, never individual measurements. The cleaning is applied when the response data is loaded, only to
the main dataset (not to `--cross_study_datasets`), and requires curve-curated data, i.e., do not combine it with `--no_refitting`
on non-curated measures. Because inactive drugs are removed, LDO results on cleaned datasets are optimistic and should be
read as an upper bound.

### Optional settings

Details on all settings are in the drevalpy documentation.

- `--randomization_mode` (`SVCC`, `SVCD`, `SVRC`, `SVRD`) and `--randomization_type` (`permutation`, `invariant`): check
  how much the performance drops when the input data is randomized. See
  [Available Randomization Tests](https://drevalpy.readthedocs.io/en/latest/usage.html#available-randomization-tests).
- `--n_trials_robustness`: train the model repeatedly with different seeds to check how stable it is. See
  [Robustness Test](https://drevalpy.readthedocs.io/en/latest/usage.html#robustness-test).
- `--optim_metric` (default `RMSE`; also `MSE`, `MAE`, `R^2`, `Pearson`, `Spearman`, `Kendall`): the metric used to select
  the best hyperparameters. See [Available Metrics](https://drevalpy.readthedocs.io/en/latest/usage.html#available-metrics).
- `--response_transformation` (default `None`; also `standard`, `minmax`, `robust`, `drug_mean`, `drug_tissue_mean`):
  transform the response before training. See
  [Available Response Transformations](https://drevalpy.readthedocs.io/en/latest/usage.html#available-response-transformations).

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

### For developers

If the drevalpy (after Docker image release) or the unzip version was updated, the snapshots need to be updated:

- If not already installed, get nf-test: `curl -fsSL https://get.nf-test.com | bash` and run `./nf-test init`
- Run `nf-test test --profile=+docker --verbose`
- If tests/default.nf.test.snap already exists, run nf-test with `--update-snapshot`

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
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow `24.03.0-edge` or later).
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

To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

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
