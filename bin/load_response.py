#!/usr/bin/env python
import argparse
import pickle
from drevalpy.utils import load_data


def get_parser():
    parser = argparse.ArgumentParser(description="Load data for drug response prediction.")
    parser.add_argument("--dataset_name", type=str, required=True, help="Name of the dataset to load.")
    parser.add_argument("--path_data", type=str, default="data", help="Path to the data directory.")
    parser.add_argument("--cross_study_datasets", nargs='+', default=[],
                        help="List of datasets to use to evaluate predictions across studies. "
                             "Default is empty list which means no cross-study datasets are used.")
    return parser


def main(args):
    response_data, cross_study_datasets = load_data(
        dataset_name=args.dataset_name, cross_study_datasets=args.cross_study_datasets, path_data=args.path_data
    )

    # Pickle the object to a file
    with open("response_dataset.pkl", "wb") as f:
        pickle.dump(response_data, f)

    for cs_dataset in cross_study_datasets:
        ds_name = cs_dataset.dataset_name
        with open(f"cross_study_{ds_name}.pkl", "wb") as f:
            pickle.dump(cs_dataset, f)


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
