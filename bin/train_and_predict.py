#!/usr/bin/env python
import os
import random
import sys
import pickle
from typing import Dict
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler
from dreval.experiment import train_and_predict
from dreval.models import MODEL_FACTORY
import logging
import argparse


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train and predict using a drug response prediction model."
    )
    parser.add_argument(
        "--model_name",
        type=str,
        help="model to evaluate or list of models to compare",
    )
    parser.add_argument(
        "--hyperparameters",
        type=str,
        help="hyperparameters for the model",
    )
    parser.add_argument(
        "--train_data",
        type=str,
        help="path to the training dataset",
    )
    parser.add_argument(
        "--prediction_data",
        type=str,
        help="path to the prediction dataset",
    )
    parser.add_argument(
        "--early_stopping_data",
        type=str,
        help="path to the early stopping dataset",
    )
    parser.add_argument(
        "--response_transformation",
        type=str,
        help="response transformation to apply to the dataset",
    )
    parser.add_argument(
        "--cl_features",
        type=str,
        help="path to the cell line feature dataset",
    )
    parser.add_argument(
        "--drug_features",
        type=str,
        help="path to the drug feature dataset",
    )
    return parser


def dreval_train_and_predict(
    model_name: str,
    hpam_path: str,
    train_path: str,
    pred_path: str,
    es_path: str,
    response_transform: str,
    cl_feature_path: str,
    drug_feature_path: str

):
    model_class = MODEL_FACTORY[model_name]
    model = model_class(target='IC50')
    train_dataset = pickle.load(open(train_path, "rb"))
    pred_dataset = pickle.load(open(pred_path, "rb"))
    if model.early_stopping:
        es_dataset = pickle.load(open(es_path, "rb"))
    else:
        es_dataset = None
    cl_feature = pickle.load(open(cl_feature_path, "rb"))
    drug_feature = pickle.load(open(drug_feature_path, "rb"))
    if response_transform == "None":
        response_transform = None
    elif response_transform == "standard":
        response_transform = StandardScaler()
    elif response_transform == "minmax":
        response_transform = MinMaxScaler()
    elif response_transform == "robust":
        response_transform = RobustScaler()
    else:
        raise ValueError(f"Invalid response_transform: {response_transform}. Choose robust, minmax or standard.")
    hyperparameters = pickle.load(open(hpam_path, "rb"))
    prediction_dataset = train_and_predict(
        model=model,
        hpams=hyperparameters,
        train_dataset=train_dataset,
        prediction_dataset=pred_dataset,
        early_stopping_dataset=(
            es_dataset if model.early_stopping else None
        ),
        response_transformation=response_transform,
        cl_features=cl_feature,
        drug_features=drug_feature
    )
    hpams = [f'{key}:{value}' for key, value in hyperparameters.items()]
    hyperparameters = '_'.join(hpams)
    filename = f'prediction_dataset.pkl'
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger()
    logger.info(f"Saving prediction dataset to {filename}")
    logger.info(os.getcwd())
    logger.info(filename)
    with open(filename, 'wb') as f:
        pickle.dump(prediction_dataset, f)


if __name__ == "__main__":
    args = get_parser().parse_args()
    dreval_train_and_predict(
        model_name=args.model_name,
        hpam_path=args.hyperparameters,
        train_path=args.train_data,
        pred_path=args.prediction_data,
        es_path=args.early_stopping_data,
        response_transform=args.response_transformation,
        cl_feature_path=args.cl_features,
        drug_feature_path=args.drug_features
    )
    sys.exit(0)
