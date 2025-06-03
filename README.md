<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-drugresponseeval_logo_dark.png">
    <img alt="nf-core/drugresponseeval" src="docs/images/nf-core-drugresponseeval_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/drugresponseeval/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/drugresponseeval/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/drugresponseeval/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/drugresponseeval/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/drugresponseeval/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.14779984-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.14779984)

[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/drugresponseeval)

[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)
[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

# ![drevalpy_summary](assets/dreval_summary.svg)

**DrEval** is a bioinformatics framework which includes a PyPI package (drevalpy) and a Nextflow
pipeline (this repo). DrEval ensures that evaluations are statistically sound, biologically
meaningful, and reproducible. DrEval simplifies the implementation of drug response prediction
models, allowing researchers to focus on advancing their modeling innovations by automating
standardized evaluation protocols and preprocessing workflows. With DrEval, hyperparameter
tuning is fair and consistent. With its flexible model interface, DrEval supports any model type,
ranging from statistical models to complex neural networks. By contributing your model to the
DrEval catalog, you can increase your work's exposure, reusability, and transferability.

1. The response data is loaded
2. All models are trained and evaluated in a cross-validation setting
3. For each CV split, the best hyperparameters are determined using a grid search per model
4. The model is trained on the full training set (train & validation) with the best
   hyperparameters to predict the test set
5. If randomization tests are enabled, the model is trained on the full training set with the best
   hyperparameters to predict the randomized test set
6. If robustness tests are enabled, the model is trained N times on the full training set with the
   best hyperparameters
7. Plots are created summarizing the results

For baseline models, no randomization or robustness tests are performed.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

Now, you can run the pipeline using:

```bash
nextflow run nf-core/drugresponseeval \
   -profile <docker/singularity/.../institute> \
   --models <model1,model2,...> \
   --baselines <baseline1,baseline2,...> \
   --dataset_name <dataset_name> \
   --path_data <path_data> \
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/drugresponseeval/usage) and the [parameter documentation](https://nf-co.re/drugresponseeval/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/drugresponseeval/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/drugresponseeval/output).

## Credits

nf-core/drugresponseeval was originally written by Judith Bernett (TUM) and Pascal Iversen (FU
Berlin).

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

Contributors to nf-core/drugresponseeval and the drevalpy PyPI package:

- [Judith Bernett](https://github.com/JudithBernett) (TUM)
- [Pascal Iversen](https://github.com/PascalIversen) (FU Berlin)
- [Mario Picciani](https://github.com/picciama) (TUM)

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#drugresponseeval` channel](https://nfcore.slack.com/channels/drugresponseeval) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/drugresponseeval for your analysis, please cite it using the following doi: [10.5281/zenodo.14779984](https://doi.org/10.5281/zenodo.14779984)

The underlying data is available at doi: [10.5281/zenodo.12633909](https://doi.org/10.5281/zenodo.12633909).

The underlying python package is drevalpy, availably on [PyPI](https://pypi.org/project/drevalpy/) as standalone.

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
