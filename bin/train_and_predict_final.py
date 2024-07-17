#!/usr/bin/env python

import sys
import argparse
import pickle
import warnings
from typing import Dict, Optional

import yaml
from drevalpy.datasets.dataset import DrugResponseDataset
from drevalpy.models.drp_model import DRPModel
from sklearn.base import TransformerMixin
from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import train_and_predict, randomize_train_predict, robustness_train_predict
from drevalpy.utils import get_response_transformation


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train and predict: either full mode, randomization mode, " "or robustness mode."
    )
    parser.add_argument("--mode", type=str, default="full", help="Mode: full, randomization, or robustness.")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--split_id", type=str, required=True, help="Split id.")
    parser.add_argument("--split_dataset_path", type=str, required=True, help="Path to split dataset.")
    parser.add_argument("--hyperparameters_path", type=str, required=True, help="Path to hyperparameters.")
    parser.add_argument("--response_transformation", type=str, default="None", help="Response transformation.")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO).")
    parser.add_argument("--path_data", type=str, required=True, help="Path to data.")
    parser.add_argument("--randomization_views_path", type=str, default=None, help="Path to randomization views.")
    parser.add_argument(
        "--randomization_type",
        type=str,
        default="permutation",
        help="Randomization type (permutation, zeroing, gaussian).",
    )
    parser.add_argument("--robustness_trial", type=int, help="Robustness trial index.")
    return parser


def prep_data(arguments):
    split = pickle.load(open(arguments.split_dataset_path, "rb"))
    train_dataset = split["train"]
    validation_dataset = split["validation"]
    test_dataset = split["test"]

    model_class = MODEL_FACTORY[arguments.model_name]
    if model_class.early_stopping:
        validation_dataset = split["validation_es"]
        es_dataset = split["early_stopping"]
    else:
        es_dataset = None

    train_dataset.add_rows(validation_dataset)
    train_dataset.shuffle(random_state=42)

    with open(arguments.hyperparameters_path, "r") as f:
        best_hpam_dict = yaml.safe_load(f)
    best_hpams = best_hpam_dict[f"{arguments.model_name}_{arguments.split_id}"]["best_hpam_combi"]

    model = model_class(target="IC50")
    response_transform = get_response_transformation(arguments.response_transformation)
    return model, best_hpams, train_dataset, test_dataset, es_dataset, response_transform


def compute_randomization(
    randomization_test_view: Dict[str, str],
    model: DRPModel,
    hpam_set: Dict,
    path_data: str,
    train_dataset: DrugResponseDataset,
    test_dataset: DrugResponseDataset,
    early_stopping_dataset: Optional[DrugResponseDataset],
    split_id: str,
    test_mode: str,
    randomization_type: str = "permutation",
    response_transformation=Optional[TransformerMixin],
):
    cl_features = model.load_cell_line_features(data_path=path_data, dataset_name=train_dataset.dataset_name)
    drug_features = model.load_drug_features(data_path=path_data, dataset_name=train_dataset.dataset_name)

    randomization_test_file = f'randomization_{randomization_test_view["test_name"]}_{split_id}.csv'
    if (randomization_test_view["view"] not in cl_features.get_view_names()) and (
        randomization_test_view["view"] not in drug_features.get_view_names()
    ):
        warnings.warn(
            f"View {randomization_test_view['view']} not found in features. Skipping randomization test {randomization_test_view['test_name']} which includes this view."
        )
        return

    randomize_train_predict(
        view=randomization_test_view["view"],
        randomization_type=randomization_type,
        randomization_test_file=randomization_test_file,
        model=model,
        hpam_set=hpam_set,
        path_data=path_data,
        train_dataset=train_dataset,
        test_dataset=test_dataset,
        early_stopping_dataset=early_stopping_dataset,
        response_transformation=response_transformation,
        cl_features=cl_features,
        drug_features=drug_features,
    )


def compute_robustness(
    model: DRPModel,
    hpam_set: Dict,
    path_data: str,
    train_dataset: DrugResponseDataset,
    test_dataset: DrugResponseDataset,
    early_stopping_dataset: Optional[DrugResponseDataset],
    split_id: str,
    test_mode: str,
    trial: int,
    response_transformation=Optional[TransformerMixin],
):
    robustness_test_file = f"robustness_{trial}_{split_id}.csv"

    robustness_train_predict(
        trial=trial,
        trial_file=robustness_test_file,
        train_dataset=train_dataset,
        test_dataset=test_dataset,
        early_stopping_dataset=early_stopping_dataset,
        model=model,
        hpam_set=hpam_set,
        path_data=path_data,
        response_transformation=response_transformation,
    )


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    selected_model, hpam_combi, train_set, test_set, es_set, transformation = prep_data(args)

    if args.mode == "full":
        test_set = train_and_predict(
            model=selected_model,
            hpams=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            prediction_dataset=test_set,
            early_stopping_dataset=es_set,
            response_transformation=transformation,
        )
        prediction_dataset = f"predictions_{args.split_id}.csv"
        test_set.save(prediction_dataset)
    elif args.mode == "randomization":
        with open(args.randomization_views_path, "r") as f:
            rand_test_view = yaml.safe_load(f)
        compute_randomization(
            randomization_test_view=rand_test_view,
            model=selected_model,
            hpam_set=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            test_dataset=test_set,
            early_stopping_dataset=es_set,
            split_id=args.split_id,
            test_mode=args.test_mode,
            randomization_type=args.randomization_type,
            response_transformation=transformation,
        )
    elif args.mode == "robustness":
        compute_robustness(
            model=selected_model,
            hpam_set=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            test_dataset=test_set,
            early_stopping_dataset=es_set,
            split_id=args.split_id,
            test_mode=args.test_mode,
            trial=args.robustness_trial,
            response_transformation=transformation,
        )
    else:
        raise ValueError(f"Invalid mode: {args.mode}. Choose full, randomization, or robustness.")

    sys.exit(0)
