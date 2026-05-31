#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle

from drevalpy.experiment import make_model_list
from drevalpy.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(description="Split data into CV splits")
    parser.add_argument("--models", type=str, required=True, help="List of models")
    parser.add_argument("--data", type=str, required=True, help="Path to response data")
    parser.add_argument("--file_name", type=str, required=True, help="Name of the file")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    models = args.models.replace("[", "").replace("]", "").split(", ")
    response_data = pickle.load(open(args.data, "rb"))
    dataset_name = response_data.dataset_name
    models = [MODEL_FACTORY[model] for model in models]
    all_models = make_model_list(models, response_data)
    with open(f'{args.file_name}_{dataset_name}.txt', 'w', encoding='utf-8') as f:
        for model, model_class in all_models.items():
            f.write(f"{model_class},{model}\n")


if __name__ == "__main__":
    main()
