#!/usr/bin/env python

import argparse
import sys
import pickle
import yaml


from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import train_and_predict
from drevalpy.utils import get_response_transformation


def get_parser():
    parser = argparse.ArgumentParser(description="Train and predict using a drug response prediction model.")
    parser.add_argument("--model_name", type=str, help="model to evaluate or list of models to compare")
    parser.add_argument("--path_data", type=str, default="data", help="Data directory path")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO)")
    parser.add_argument("--hyperparameters", type=str, help="hyperparameters for the model")
    parser.add_argument("--cv_data", type=str, help="path to the cv data split")
    parser.add_argument("--response_transformation", type=str, help="response transformation to apply to the dataset")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    model_class = MODEL_FACTORY[args.model_name]
    split = pickle.load(open(args.cv_data, "rb"))
    train_dataset = split["train"]
    validation_dataset = split["validation"]
    hpams = yaml.load(open(args.hyperparameters, "r"), Loader=yaml.FullLoader)
    if model_class.early_stopping:
        validation_dataset = split["validation_es"]
        es_dataset = split["early_stopping"]
    else:
        es_dataset = None
    model = model_class()
    response_transform = get_response_transformation(args.response_transformation)
    validation_dataset = train_and_predict(
        model=model,
        hpams=hpams,
        path_data=args.path_data,
        train_dataset=train_dataset,
        prediction_dataset=validation_dataset,
        early_stopping_dataset=es_dataset,
        response_transformation=response_transform,
    )
    with open(f"prediction_dataset_{validation_dataset.__hash__()}.pkl", "wb") as f:
        pickle.dump(validation_dataset, f)


if __name__ == "__main__":
    main()
    sys.exit(0)
