# nf-core/drugresponseeval: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.0](https://github.com/nf-core/drugresponseeval/releases/tag/1.1.0): Humongous Zapdos - 03.07.2025

Second release of nf-core/drugresponseeval.

_Zapdos is a dual-type Electric/Flying Legendary Pokémon. It is said to be a divine bird that presides over the heavens, spending millennia among thunderclouds, before descending with lightning bolts. When Zapdos flaps its glittering wings, it releases electricity that can potentially cause thunderstorms._

### `Added`

- [#43](https://github.com/nf-core/drugresponseeval/pull/43) Preprint is out now! Linking it in the documentation.
- [#42](https://github.com/nf-core/drugresponseeval/pull/42) Added authors and licenses to the python scripts.
- [#43](https://github.com/nf-core/drugresponseeval/pull/43) Added `--no_hyperparameter_tuning` flag for quick runs without hyperparameter tuning: hpam_split takes this as argument
- [#43](https://github.com/nf-core/drugresponseeval/pull/43) Added `--final_model_on_full data` flag: if True, a final/production model is saved in the results directory. If hyperparameter_tuning is true, the final model is tuned, too. The model can later be loaded using the implemented load functions of the drevalpy models.
  - New process `FINAL_SPLIT`: splits the full dataset for each model class into train, validation, and optionally early stopping. This is done per model class and not overall because here, we no longer need across-model compatibility but want to train on the maximum amount of data (which might vary between models due to different feature availability)
  - New process `TUNE_FINAL_MODEL`: trains the final model(s) with all hyperparameter combinations
  - Added process `EVALUATE_AND_FIND_MAX_FINAL`: re-uses the `EVALUATE_AND_FIND_MAX` process to find the best hpam combination (evaluated on the validation dataset)
  - New process `TRAIN_FINAL_MODEL`: uses the best hpam combination to train the final model and save it
- [#43](https://github.com/nf-core/drugresponseeval/pull/43) Added ProteomicsElasticNet, SingleDrugProteomicsRandomForest to list of known models
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Reporting all package versions
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Added `UNZIP` module for loading and unzipping the drug response datasets instead of handling this in `LOAD_RESPONSE`: `UNZIP_RESPONSE`, `UNZIP_CS_RESPONSE` (for cross-study datasets).
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Added icon
- [#30](https://github.com/nf-core/drugresponseeval/pull/30) Added the possibility of a leave-tissue-out (LTO) split

### `Changed`

- [#53](https://github.com/nf-core/drugresponseeval/pull/53) Changed to large runner for the GitHub Actions because of Docker → Singularity conversion.
- [#42](https://github.com/nf-core/drugresponseeval/pull/42) Moved all publishDir directives to modules.config.
- [#44](https://github.com/nf-core/drugresponseeval/pull/44) Fixed drevalpy versions in conda and docker to 1.3.5: now supporting Python 3.13
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Support for AWS: changed the structure of load response and parameter check to conform more to Nextflow
  best practices.
- [#44](https://github.com/nf-core/drugresponseeval/pull/44) Since drevalpy 1.3.5., the split_early_stopping function is no longer private.
- [#39](https://github.com/nf-core/drugresponseeval/pull/39) Template update to version 3.3.1
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Changed the defaults for `test_mode` from LPO to LCO and `dataset_name` from GDSC to CTRPv2 to better match the publication.
- [#35](https://github.com/nf-core/drugresponseeval/pull/35) , [#38](https://github.com/nf-core/drugresponseeval/pull/38) Introducing `assets/NO_FILE` for empty file handling in the visualization process.
- [#30](https://github.com/nf-core/drugresponseeval/pull/30) Changed pipeline overview svg to Figure 1 from paper

### `Removed`

- [#30](https://github.com/nf-core/drugresponseeval/pull/30) Simplified visualization: multiple short processes were creating overhang → more efficient in one process.
- [#44](https://github.com/nf-core/drugresponseeval/pull/44) Removed the `--no_refitting parameter` in load_response. It was no longer needed because of the new, more nextflow-y preprocess workflow
- [#44](https://github.com/nf-core/drugresponseeval/pull/44) Removed redundant code in the visualization python script. Possible because of a new wrapper function in drevalpy 1.3.5.
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Removed `PARAMS_CHECK` process: now handled by the schema and the `utils_nfcore_drugresponseeval_pipeline` subworkflow.
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) Removed the `--curve_curator` flag which was true by default. It is now the `no_refitting` flag which is false by default.

### `Fixed`

- [#44](https://github.com/nf-core/drugresponseeval/pull/44) casting a path to a string in `bin/consolidate_results.py` for drevalpy 1.3.5 compatibility.
- [#43](https://github.com/nf-core/drugresponseeval/pull/43) casting drug to str in `bin/collect_results.py` because there were issues if all drugs were pubchem IDs and were treated as numeric values.
- [#43](https://github.com/nf-core/drugresponseeval/pull/43) forgot to add the `dataset_name` in `bin/load_response.py`, made the tissue identifier optional. This was causing problems for custom datasets.
- [#38](https://github.com/nf-core/drugresponseeval/pull/38) passing rand_modes in quotes to `bin/consolidate_results.py` because otherwise, if more than one mode was passed, it was not recognized as a list.
- [#30](https://github.com/nf-core/drugresponseeval/pull/30) Added the path to the data directory to `COLLECT_RESULTS` because from there, we get the drug and cell line names for visualization.
- [#30](https://github.com/nf-core/drugresponseeval/pull/30) Fixed handling of when 'None' was passed as randomization mode to `CONSOLIDATE_RESULTS`.

### `Dependencies`

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| drevalpy   | 1.1.3       | 1.3.5       |

### `Parameters`

| Params                       | Status                           |
| ---------------------------- | -------------------------------- |
| `--no_hyperparameter_tuning` | New                              |
| `--final_model_on_full_data` | New                              |
| `--no_refitting`             | New (replaces `--curve_curator`) |
| `--curve_curator`            | Removed                          |

## [v1.0.0](https://github.com/nf-core/drugresponseeval/releases/tag/1.0.0) - 31.01.2025

Initial release of nf-core/drugresponseeval, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Updated to the new template
- Added tests that run with docker, singularity, apptainer, and conda
- Added the docker container and the conda env.yml in the nextflow.config. We just need one container for all
  processes as this pipeline automates the PyPI package drevalpy.
- Added usage and output documentation.
- Added CurveCurator to preprocess curves of custom datasets

### `Fixed`

- Fixed linting issues
- Fixed bugs with path_data: can now be handled as absolute and relative paths

### `Dependencies`

### `Deprecated`
