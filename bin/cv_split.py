#!/usr/bin/env python

import argparse
import pickle
import sys


def get_parser():
    parser = argparse.ArgumentParser(description="Split data into CV splits")
    parser.add_argument("--response", type=str, required=True, help="Path to response data")
    parser.add_argument("--n_cv_splits", type=int, required=True, help="Number of CV splits")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO)")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    response_data = pickle.load(open(args.response, "rb"))
    response_data.split_dataset(
        n_cv_splits=args.n_cv_splits, mode=args.test_mode, split_validation=True, validation_ratio=0.1, random_state=42
    )
    for split_index, split in enumerate(response_data.cv_splits):
        with open(f"split_{split_index}.pkl", "wb") as f:
            pickle.dump(split, f)


if __name__ == "__main__":
    main()
    sys.exit(0)
