#!/usr/bin/env python

import argparse
import sys
import pickle
import yaml


from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import train_and_predict, get_model_name_and_drug_id, get_datasets_from_cv_split
from drevalpy.utils import get_response_transformation


def get_parser():
    parser = argparse.ArgumentParser(description="Train and predict using a drug response prediction model.")
    parser.add_argument("--model_name", type=str, help="model to evaluate or list of models to compare")
    parser.add_argument("--path_data", type=str, default="data", help="Data directory path")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO)")
    parser.add_argument("--hyperparameters", type=str, help="hyperparameters for the model")
    parser.add_argument("--cv_data", type=str, help="path to the cv data split")
    parser.add_argument("--response_transformation", type=str, help="response transformation to apply to the dataset")
    parser.add_argument("--model_checkpoint_dir", type=str, default="TEMPORARY", help="model checkpoint directory, if not provided: temporary directory is used")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()

    model_name, drug_id = get_model_name_and_drug_id(args.model_name)

    model_class = MODEL_FACTORY[model_name]
    split = pickle.load(open(args.cv_data, "rb"))

    train_dataset, validation_dataset, es_dataset, test_dataset = get_datasets_from_cv_split(
        split, model_class, model_name, drug_id)

    response_transform = get_response_transformation(args.response_transformation)
    hpams = yaml.load(open(args.hyperparameters, "r"), Loader=yaml.FullLoader)
    model = model_class()
    validation_dataset = train_and_predict(
        model=model,
        hpams=hpams,
        path_data=args.path_data,
        train_dataset=train_dataset,
        prediction_dataset=validation_dataset,
        early_stopping_dataset=es_dataset,
        response_transformation=response_transform,
        model_checkpoint_dir=args.model_checkpoint_dir
    )
    with open(f"prediction_dataset_{model_name}_{str(args.cv_data).split('.pkl')[0]}_"
              f"{str(args.hyperparameters).split('.yaml')[0]}.pkl",
              "wb") as f:
        pickle.dump(validation_dataset, f)


if __name__ == "__main__":
    main()
    sys.exit(0)
