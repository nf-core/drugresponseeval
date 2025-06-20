#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle
import yaml
import os

from drevalpy.experiment import generate_data_saving_path, get_model_name_and_drug_id
from drevalpy.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train a final model on the full dataset for future predictions."
    )
    parser.add_argument("--train_data", type=str, required=True, help="Train data, pickled (output of final split).")
    parser.add_argument("--val_data", type=str, required=True, help="Validation data, pickled (output of final split).")
    parser.add_argument("--early_stop_data", type=str, required=True,
                        help="Early stopping data, pickled (output of final split).")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--path_data", type=str, required=True, help="Path to data.")
    parser.add_argument("--model_checkpoint_dir", type=str, default="TEMPORARY", help="model checkpoint directory, if not provided: temporary directory is used")
    parser.add_argument("--best_hpam_combi", type=str, required=True, help="Best hyperparameter combination file, yaml format.")
    return parser


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()

    model_name, drug_id = get_model_name_and_drug_id(args.model_name)

    final_model_path = generate_data_saving_path(
        model_name=model_name,
        drug_id=drug_id,
        result_path="",
        suffix="final_model"
    )

    train_dataset = pickle.load(open(args.train_data, "rb"))
    validation_dataset = pickle.load(open(args.val_data, "rb"))
    es_dataset = pickle.load(open(args.early_stop_data, "rb"))
    train_dataset.add_rows(validation_dataset)
    train_dataset.shuffle(random_state=42)

    best_hpam_combi = yaml.load(open(args.best_hpam_combi, "r"), Loader=yaml.FullLoader)[f'{model_name}_final']['best_hpam_combi']
    model = MODEL_FACTORY[model_name]()
    cl_features = model.load_cell_line_features(data_path=args.path_data, dataset_name=train_dataset.dataset_name)
    drug_features = model.load_drug_features(data_path=args.path_data, dataset_name=train_dataset.dataset_name)
    model.build_model(hyperparameters=best_hpam_combi)
    model.train(
        output=train_dataset,
        output_earlystopping=es_dataset,
        cell_line_input=cl_features,
        drug_input=drug_features,
        model_checkpoint_dir=args.model_checkpoint_dir,
    )
    os.makedirs(final_model_path, exist_ok=True)
    model.save(final_model_path)
