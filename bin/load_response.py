#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle
import pathlib
import pandas as pd
from drevalpy.datasets.loader import AVAILABLE_DATASETS
from drevalpy.datasets.dataset import DrugResponseDataset
from drevalpy.datasets.utils import CELL_LINE_IDENTIFIER, DRUG_IDENTIFIER, TISSUE_IDENTIFIER


def get_parser():
    parser = argparse.ArgumentParser(description="Load data for drug response prediction.")
    parser.add_argument("--response_dataset", type=str, default="data", help="Path to the drug response file.")
    parser.add_argument(
        "--cross_study_dataset",
        action="store_true",
        default=False,
        help="Whether to load cross-study datasets.",

    )
    parser.add_argument(
        "--no_refitting",
        action="store_true",
        default=False,
        help="If the CurveCurated measures should not be used.",
    )
    parser.add_argument(
        "--measure",
        type=str,
        default="LN_IC50",
        help="Name of the column in the dataset containing the drug response measures."
    )
    return parser


def main(args):
    dataset_name = pathlib.Path(args.response_dataset).stem
    input_file = pathlib.Path(f"{dataset_name}.csv")
    if dataset_name in AVAILABLE_DATASETS:
        response_file = pd.read_csv(input_file, dtype={"pubchem_id": str})
        response_data = DrugResponseDataset(
                            response=response_file[args.measure].values,
                            cell_line_ids=response_file[CELL_LINE_IDENTIFIER].values,
                            drug_ids=response_file[DRUG_IDENTIFIER].values,
                            tissues=response_file[TISSUE_IDENTIFIER].values,
                            dataset_name=dataset_name,
                        )
    else:
        response_data = DrugResponseDataset.from_csv(
            input_file=input_file, measure=args.measure, tissue_column=TISSUE_IDENTIFIER
        )
    outfile = f"cross_study_{dataset_name}.pkl" if args.cross_study_dataset else "response_dataset.pkl"
    # Pickle the object to a file
    with open(outfile, "wb") as f:
        pickle.dump(response_data, f)


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
