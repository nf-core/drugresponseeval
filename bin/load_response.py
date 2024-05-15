#!/usr/bin/env python

import argparse
from dreval.response_datasets import RESPONSE_DATASET_FACTORY
import os


def get_parser():
    parser = argparse.ArgumentParser(description='Load response data')
    parser.add_argument('--dataset_name', type=str, required=True, help='Name of the dataset to load')
    parser.add_argument('--path_out', type=str, default='results', help='Path to the output directory')
    parser.add_argument('--path_data', type=str, default='data', help='Data directory path')
    return parser


if __name__ == "__main__":
    args = get_parser().parse_args()
    assert args.dataset_name in RESPONSE_DATASET_FACTORY, f"Invalid dataset name. Available datasets are {list(RESPONSE_DATASET_FACTORY.keys())} If you want to use your own dataset, you need to implement a new response dataset class and add it to the RESPONSE_DATASET_FACTORY in the response_datasets init"
    if not os.path.exists(args.path_out):
        os.makedirs(args.path_out)
    response_data = RESPONSE_DATASET_FACTORY[args.dataset_name](path_data=args.path_data)
    response_data.save(path=f"{args.path_out}/response.csv")
