#!/usr/bin/env python

import argparse
import sys
import yaml
from dreval.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(description='Take model name, get hyperparameters, and split into single hyperparameter combinations')
    parser.add_argument('--model_name', type=str, help='model name')
    return parser


if __name__ == "__main__":
    parser = get_parser()
    args = parser.parse_args()
    model_class = MODEL_FACTORY[args.model_name]
    hyperparameters = model_class.get_hyperparameter_set()
    hpam_idx = 0
    for hpam_combi in hyperparameters:
        with open(f'hpam_{hpam_idx}.yaml', 'w') as yaml_file:
            hpam_idx += 1
            yaml.dump(hpam_combi, yaml_file, default_flow_style=False)

