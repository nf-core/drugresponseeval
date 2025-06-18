#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle

from drevalpy.experiment import generate_data_saving_path, get_model_name_and_drug_id, train_final_model
from drevalpy.models import MODEL_FACTORY
from drevalpy.utils import get_response_transformation


def get_parser():
    parser = argparse.ArgumentParser(
        description="Train a final model on the full dataset for future predictions."
    )
    parser.add_argument("--response", type=str, required=True, help="Drug response data, pickled (output of load_response).")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--response_transformation", type=str, default="None", help="Response transformation.")
    parser.add_argument("--path_data", type=str, required=True, help="Path to data.")
    parser.add_argument("--model_checkpoint_dir", type=str, default="TEMPORARY", help="model checkpoint directory, if not provided: temporary directory is used")
    parser.add_argument("--metric", type=str, required=True, help="Optimization , default: RMSE.")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LTO, LDO).")
    parser.add_argument("--no_hyperparameter_tuning", action="store_true", default=False,
                        help="If set, no hyperparameter tuning is performed, only the first combination is used.")
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

    model_class = MODEL_FACTORY[model_name]

    response_data = pickle.load(open(args.response, "rb"))
    response_data.remove_nan_responses()

    response_transform = get_response_transformation(args.response_transformation)

    train_final_model(
        model_class=model_class,
        full_dataset=response_data,
        response_transformation=response_transform,
        path_data=args.path_data,
        model_checkpoint_dir=args.model_checkpoint_dir,
        metric=args.metric,
        result_path=final_model_path,
        test_mode=args.test_mode,
        val_ratio=0.1,
        hyperparameter_tuning=not args.no_hyperparameter_tuning
    )
