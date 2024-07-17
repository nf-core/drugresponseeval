#!/usr/bin/env python
import argparse
import yaml

from drevalpy.models import MODEL_FACTORY
from drevalpy.experiment import get_randomization_test_views


def get_parser():
    parser = argparse.ArgumentParser(description="Create randomization test views.")
    parser.add_argument("--model_name", type=str, required=True, help="Name of the model to use.")
    parser.add_argument("--randomization_mode", type=str, required=True, help="Randomization mode to use.")
    return parser


def main(args):
    model_class = MODEL_FACTORY[args.model_name]
    model = model_class()

    randomization_test_views = get_randomization_test_views(
        model=model,
        randomization_mode=[args.randomization_mode]
    )

    key = list(randomization_test_views.keys())[0]
    # create as many dicts as there are elements in the value list of the key
    randomization_test_view_dicts = [{'test_name': key, 'view': value} for value in randomization_test_views[key]]

    for rand_dict in randomization_test_view_dicts:
        with open(f'randomization_test_view_{rand_dict["test_name"]}.yaml', 'w') as f:
            yaml.dump(rand_dict, f)


if __name__ == "__main__":
    arg_parser = get_parser()
    all_args = arg_parser.parse_args()
    main(all_args)
