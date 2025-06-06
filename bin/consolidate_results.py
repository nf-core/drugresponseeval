#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import os
import argparse
from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import consolidate_single_drug_model_predictions


def get_parser():
    parser = argparse.ArgumentParser(description="Consolidate results for SingleDrugModels")
    parser.add_argument('--run_id', type=str, required=True, help="Run ID")
    parser.add_argument("--test_mode", type=str, required=True, help="Test mode (LPO, LCO, LDO)")
    parser.add_argument("--model_name", type=str, required=True, help="All Model "
                                                                                  "names")
    parser.add_argument("--outdir_path", type=str, required=True, help="Output directory path")
    parser.add_argument("--n_cv_splits", type=int, required=True, help="Number of CV splits")
    parser.add_argument("--cross_study_datasets", type=str, nargs="+", help="All "
                                                                                          "cross-study "
                                                                                          "datasets")
    parser.add_argument("--randomization_modes", type=str, required=True, help="All "
                                                                                     "randomizations")
    parser.add_argument("--n_trials_robustness", type=int, required=True, help="Number of trials")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    results_path = os.path.join(
        args.outdir_path,
        args.run_id,
        args.test_mode,
    )
    if args.randomization_modes == "[None]":
        randomizations = None
    else:
        randomizations = args.randomization_modes.split('[')[1].split(']')[0].split(', ')
    model = MODEL_FACTORY[args.model_name]
    if args.cross_study_datasets is None:
        args.cross_study_datasets = []
    consolidate_single_drug_model_predictions(
        models=[model],
        n_cv_splits=args.n_cv_splits,
        results_path=results_path,
        cross_study_datasets=args.cross_study_datasets,
        randomization_mode=randomizations,
        n_trials_robustness=args.n_trials_robustness,
        out_path=""
    )


if __name__ == "__main__":
    main()
