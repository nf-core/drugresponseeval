#!/usr/bin/env python

import argparse
import pickle

from drevalpy.experiment import make_model_list
from drevalpy.models import FULL_MODEL_FACTORY

def get_parser():
    parser = argparse.ArgumentParser(description="Split data into CV splits")
    parser.add_argument("--models", type=str, required=True, help="List of models")
    parser.add_argument("--data", type=str, required=True, help="Path to response data")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    models = args.models.replace("[", "").replace("]", "").split(", ")
    response_data = pickle.load(open(args.data, "rb"))
    dataset_name = response_data.dataset_name
    models = [FULL_MODEL_FACTORY[model] for model in models]
    all_models = make_model_list(models, response_data)
    with open(f'models_{dataset_name}.txt', 'w', encoding='utf-8') as f:
        for model in all_models:
            f.write(f"{model}\n")


if __name__ == "__main__":
    main()
