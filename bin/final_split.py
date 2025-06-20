#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle

from drevalpy.datasets.dataset import _split_early_stopping_data
from drevalpy.experiment import make_train_val_split
from drevalpy.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train a final model on the full dataset for future predictions."
    )
    parser.add_argument("--response", type=str, required=True, help="Drug response data, pickled (output of load_response).")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--path_data", type=str, required=True, help="Path to data.")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LTO, LDO).")
    return parser


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()

    model_class = MODEL_FACTORY[args.model_name]
    model = model_class()

    response_data = pickle.load(open(args.response, "rb"))
    response_data.remove_nan_responses()

    cl_features = model.load_cell_line_features(data_path=args.path_data, dataset_name=response_data.dataset_name)
    drug_features = model.load_drug_features(data_path=args.path_data, dataset_name=response_data.dataset_name)
    cell_lines_to_keep = cl_features.identifiers
    drugs_to_keep = drug_features.identifiers if drug_features is not None else None
    response_data.reduce_to(cell_line_ids=cell_lines_to_keep, drug_ids=drugs_to_keep)

    train_dataset, validation_dataset = make_train_val_split(response_data, test_mode=args.test_mode, val_ratio=0.1)

    if model_class.early_stopping:
        validation_dataset, early_stopping_dataset = _split_early_stopping_data(validation_dataset, args.test_mode)
    else:
        early_stopping_dataset = None

    # save
    with open('training_dataset.pkl', 'wb') as f:
        pickle.dump(train_dataset, f)
    with open('validation_dataset.pkl', 'wb') as f:
        pickle.dump(validation_dataset, f)
    with open('early_stopping_dataset.pkl', 'wb') as f:
        pickle.dump(early_stopping_dataset, f)
