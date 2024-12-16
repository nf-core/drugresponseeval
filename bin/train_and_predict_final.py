#!/usr/bin/env python
import os
import json
import sys
import argparse
import pickle
from typing import Dict, Optional
import yaml
from sklearn.base import TransformerMixin

from drevalpy.datasets.dataset import DrugResponseDataset
from drevalpy.models.drp_model import DRPModel
from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import (get_model_name_and_drug_id,
                                 get_datasets_from_cv_split,
                                 generate_data_saving_path,
                                 train_and_predict,
                                 randomize_train_predict,
                                 robustness_train_predict,
                                 cross_study_prediction)
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
        help="Randomization type (permutation, invariant).",
    )
    parser.add_argument("--robustness_trial", type=int, help="Robustness trial index.")
    parser.add_argument("--cross_study_datasets", nargs="+", help="Path to cross study datasets.")
    parser.add_argument("--model_checkpoint_dir", type=str, default="TEMPORARY", help="model checkpoint directory, if not provided: temporary directory is used")

    return parser


def prep_data(arguments):
    model_name, drug_id = get_model_name_and_drug_id(arguments.model_name)
    model_class = MODEL_FACTORY[model_name]
    model = model_class()

    split = pickle.load(open(arguments.split_dataset_path, "rb"))
    train_dataset, validation_dataset, es_dataset, test_dataset = get_datasets_from_cv_split(
        split, model_class, model_name, drug_id)

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

    response_transform = get_response_transformation(arguments.response_transformation)
    return model, drug_id, best_hpams, train_dataset, test_dataset, es_dataset, response_transform


def compute_randomization(
    randomization_test_view: Dict[str, str],
    model: DRPModel,
    hpam_set: Dict,
    path_data: str,
    train_dataset: DrugResponseDataset,
    test_dataset: DrugResponseDataset,
    early_stopping_dataset: Optional[DrugResponseDataset],
    split_id: str,
    randomization_type: str = "permutation",
    response_transformation=Optional[TransformerMixin],
    randomization_test_path: str = "",
    model_checkpoint_dir: str = "TEMPORARY",
):
    randomization_test_file = os.path.join(
        randomization_test_path,
        f'randomization_{randomization_test_view["test_name"]}_{split_id}.csv'
    )
    randomize_train_predict(
        view=randomization_test_view["view"],
        test_name=randomization_test_view["test_name"],
        randomization_type=randomization_type,
        randomization_test_file=randomization_test_file,
        model=model,
        hpam_set=hpam_set,
        path_data=path_data,
        train_dataset=train_dataset,
        test_dataset=test_dataset,
        early_stopping_dataset=early_stopping_dataset,
        response_transformation=response_transformation,
        model_checkpoint_dir=model_checkpoint_dir
    )


def compute_robustness(
    model: DRPModel,
    hpam_set: Dict,
    path_data: str,
    train_dataset: DrugResponseDataset,
    test_dataset: DrugResponseDataset,
    early_stopping_dataset: Optional[DrugResponseDataset],
    split_id: str,
    trial: int,
    response_transformation=Optional[TransformerMixin],
    rob_path: str = "",
    model_checkpoint_dir: str = "TEMPORARY",
):
    robustness_test_file = os.path.join(
        rob_path,
        f"robustness_{trial}_{split_id}.csv",
    )
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
        model_checkpoint_dir=model_checkpoint_dir
    )


def compute_cross(
    cross_study_dataset,
    model,
    test_mode,
    train_dataset,
    path_data,
    early_stopping_dataset,
    response_transformation,
    path_out,
    split_index
):
    split_index = split_index.split("split_")[1]
    cross_study_dataset = pickle.load(open(cross_study_dataset, "rb"))
    cross_study_dataset.remove_nan_responses()
    cross_study_prediction(
        dataset=cross_study_dataset,
        model=model,
        test_mode=test_mode,
        train_dataset=train_dataset,
        path_data=path_data,
        early_stopping_dataset=(
            early_stopping_dataset if model.early_stopping else None
        ),
        response_transformation=response_transformation,
        path_out=path_out,
        split_index=split_index,
    )


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    selected_model, drug_id, hpam_combi, train_set, test_set, es_set, transformation = prep_data(
        args)

    if args.mode == "full":
        predictions_path = generate_data_saving_path(
            model_name=selected_model.get_model_name(),
            drug_id=drug_id,
            result_path='',
            suffix='predictions',
        )
        hpam_path = generate_data_saving_path(
            model_name=selected_model.get_model_name(),
            drug_id=drug_id,
            result_path='',
            suffix='best_hpams',
        )
        hpam_path = os.path.join(hpam_path, f"best_hpams_{args.split_id}.json")
        # save the best hyperparameters as json
        with open(
            hpam_path,
            "w",
            encoding="utf-8",
        ) as f:
            json.dump(hpam_combi, f)

        test_set = train_and_predict(
            model=selected_model,
            hpams=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            prediction_dataset=test_set,
            early_stopping_dataset=es_set,
            response_transformation=transformation,
            model_checkpoint_dir=args.model_checkpoint_dir
        )
        prediction_dataset = os.path.join(
            predictions_path,
            f"predictions_{args.split_id}.csv",
        )
        test_set.save(prediction_dataset)
        for ds in args.cross_study_datasets:
            if ds == "NONE.csv":
                continue
            compute_cross(
                cross_study_dataset=ds,
                model=selected_model,
                test_mode=args.test_mode,
                train_dataset=train_set,
                path_data=args.path_data,
                early_stopping_dataset=es_set,
                response_transformation=transformation,
                path_out=os.path.dirname(predictions_path),
                split_index=args.split_id
            )
    elif args.mode == "randomization":
        with open(args.randomization_views_path, "r") as f:
            rand_test_view = yaml.safe_load(f)
        rand_path = generate_data_saving_path(
            model_name=selected_model.get_model_name(),
            drug_id=drug_id,
            result_path='',
            suffix='randomization',
        )
        compute_randomization(
            randomization_test_view=rand_test_view,
            model=selected_model,
            hpam_set=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            test_dataset=test_set,
            early_stopping_dataset=es_set,
            split_id=args.split_id,
            randomization_type=args.randomization_type,
            response_transformation=transformation,
            randomization_test_path=rand_path,
            model_checkpoint_dir=args.model_checkpoint_dir

        )
    elif args.mode == "robustness":
        rob_path = generate_data_saving_path(
            model_name=selected_model.get_model_name(),
            drug_id=drug_id,
            result_path='',
            suffix='robustness',
        )
        compute_robustness(
            model=selected_model,
            hpam_set=hpam_combi,
            path_data=args.path_data,
            train_dataset=train_set,
            test_dataset=test_set,
            early_stopping_dataset=es_set,
            split_id=args.split_id,
            trial=args.robustness_trial,
            response_transformation=transformation,
            rob_path=rob_path,
            model_checkpoint_dir=args.model_checkpoint_dir
        )
    else:
        raise ValueError(f"Invalid mode: {args.mode}. Choose full, randomization, or robustness.")

    sys.exit(0)
