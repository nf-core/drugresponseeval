#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle
import yaml

from drevalpy.experiment import get_model_name_and_drug_id, train_and_predict
from drevalpy.models import MODEL_FACTORY
from drevalpy.utils import get_response_transformation


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train a final model on the full dataset for future predictions."
    )
    parser.add_argument("--train_data", type=str, required=True, help="Train dataset, pickled output of final_split.py.")
    parser.add_argument("--val_data", type=str, required=True, help="Validation dataset, pickled output of final_split.py.")
    parser.add_argument("--early_stopping_data", type=str, required=True, help="Early stopping dataset, pickled output of final_split.py.")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--hpam_combi", type=str, required=True, help="Hyperparameter combination file, yaml format.")
    parser.add_argument("--response_transformation", type=str, default="None", help="Response transformation.")
    parser.add_argument("--path_data", type=str, required=True, help="Path to data.")
    parser.add_argument("--model_checkpoint_dir", type=str, default="TEMPORARY", help="model checkpoint directory, if not provided: temporary directory is used")
    return parser


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()

    train_dataset = pickle.load(open(args.train_data, "rb"))
    validation_dataset = pickle.load(open(args.val_data, "rb"))
    early_stopping_dataset = pickle.load(open(args.early_stopping_data, "rb"))
    response_transform = get_response_transformation(args.response_transformation)

    model_name, drug_id = get_model_name_and_drug_id(args.model_name)
    model_class = MODEL_FACTORY[model_name]
    hpams = yaml.load(open(args.hpam_combi, "r"), Loader=yaml.FullLoader)
    model = model_class()

    validation_dataset = train_and_predict(
        model=model,
        hpams=hpams,
        path_data=args.path_data,
        train_dataset=train_dataset,
        prediction_dataset=validation_dataset,
        early_stopping_dataset=early_stopping_dataset,
        response_transformation=response_transform,
        model_checkpoint_dir=args.model_checkpoint_dir,
    )
    with open(f"final_prediction_dataset_{model_name}_"
              f"{str(args.hpam_combi).split('.yaml')[0]}.pkl",
              "wb") as f:
        pickle.dump(validation_dataset, f)
