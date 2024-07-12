#!/usr/bin/env python


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import logging
import sys

from drevalpy.utils import check_arguments
from drevalpy.evaluation import AVAILABLE_METRICS

logger = logging.getLogger()


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(description="Run the drug response prediction model test suite.")
    parser.add_argument("--run_id", type=str, default="my_run", help="identifier to save the results")
    parser.add_argument("--models", nargs="+", help="model to evaluate or list of models to compare")
    parser.add_argument(
        "--test_mode",
        nargs="+",
        default=["LPO"],
        help="Which tests to run (LPO=Leave-random-Pairs-Out, "
        "LCO=Leave-Cell-line-Out, LDO=Leave-Drug-Out). Can be a list of test runs e.g. 'LPO LCO LDO' to run all tests. Default is LPO",
    )
    parser.add_argument(
        "--randomization_mode",
        nargs="+",
        default=["None"],
        help="Which randomization tests to run, additionally to the normal run. Default is None which means no randomization tests are run."
        "Modes: SVCC, SVRC, SVCD, SVRD"
        "Can be a list of randomization tests e.g. 'SCVC SCVD' to run two tests. Default is None"
        "SVCC: Single View Constant for Cell Lines: in this mode, one experiment is done for every cell line view the model uses (e.g. gene expression, mutation, ..)."
        "For each experiment one cell line view is held constant while the others are randomized. "
        "SVRC Single View Random for Cell Lines: in this mode, one experiment is done for every cell line view the model uses (e.g. gene expression, mutation, ..)."
        "For each experiment one cell line view is randomized while the others are held constant."
        "SVCD: Single View Constant for Drugs: in this mode, one experiment is done for every drug view the model uses (e.g. fingerprints, target_information, ..)."
        "For each experiment one drug view is held constant while the others are randomized."
        "SVRD: Single View Random for Drugs: in this mode, one experiment is done for every drug view the model uses (e.g. gene expression, target_information, ..)."
        "For each experiment one drug view is randomized while the others are held constant.",
    )
    parser.add_argument(
        "--randomization_type",
        type=str,
        default="permutation",
        help="""type of randomization to use. Choose from "gaussian", "zeroing", "permutation". Default is "permutation"
                "gaussian": replace the features with random values sampled from a gaussian distribution with the same mean and standard deviation
                "zeroing": replace the features with zeros
                "permutation": permute the features over the instances, keeping the distribution of the features the same but dissolving the relationship to the target""",
    )
    parser.add_argument(
        "--n_trials_robustness",
        type=int,
        default=0,
        help="Number of trials to run for the robustness test. Default is 0, which means no robustness test is run. The robustness test is a test where the model is trained with varying seeds. This is done multiple times to see how stable the model is.",
    )

    parser.add_argument("--dataset_name", type=str, default="GDSC1", help="Name of the drug response dataset")

    parser.add_argument("--outdir", type=str, default="results/", help="Path to the output directory")

    parser.add_argument(
        "--curve_curator",
        type=str,
        default="false",
        help="Whether to run " "CurveCurator " "to sort out " "non-reactive " "curves",
    )
    parser.add_argument(
        "--overwrite",
        type=str,
        default="false",
        help="Overwrite existing results with the same path out and run_id? ",
    )
    parser.add_argument(
        "--optim_metric",
        type=str,
        default="RMSE",
        help=f"Metric for hyperparameter tuning choose from {list(AVAILABLE_METRICS.keys())} Default is RMSE.",
    )
    parser.add_argument(
        "--n_cv_splits", type=int, default=5, help="Number of cross-validation splits to use for the evaluation"
    )

    parser.add_argument(
        "--response_transformation",
        type=str,
        default="None",
        help="Transformation to apply to the response variable possible values: standard, minmax, robust",
    )
    parser.add_argument(
        "--multiprocessing",
        action="store_true",
        default=False,
        help="Whether to use multiprocessing for the evaluation. Default is False",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    check_arguments(args)


if __name__ == "__main__":
    sys.exit(main())
