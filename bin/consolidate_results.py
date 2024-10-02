#!/usr/bin/env python

import argparse


def get_parser():
    parser = argparse.ArgumentParser(description="Consolidate results for SingleDrugModels")
    parser.add_argument("--test_mode", type=str, required=True, help="Test mode (LPO, LCO, LDO)")
    parser.add_argument("--model_names", type=str, nargs="+", required=True, help="All Model "
                                                                                  "names")
    parser.add_argument("--pred_files", type=str, nargs="+", required=True, help="All prediction "
                                                                                 "files")
    parser.add_argument("--n_cv_splits", type=int, required=True, help="Number of CV splits")
    parser.add_argument("--cross_study_datasets", type=str, nargs="+", help="All "
                                                                                          "cross-study "
                                                                                          "datasets")
    parser.add_argument("--randomizations", type=str, nargs="+", required=True, help="All "
                                                                                     "randomizations")
    parser.add_argument("--n_trials_robustness", type=int, required=True, help="Number of trials")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    print(args)


if __name__ == "__main__":
    main()
