#!/usr/bin/env python
import argparse
from dreval.datasets import RESPONSE_DATASET_FACTORY
import pickle


def get_parser():
    parser = argparse.ArgumentParser(description='Load response data')
    parser.add_argument('--dataset_name', type=str, required=True, help='Name of the dataset to load')
    parser.add_argument('--path_data', type=str, default='data', help='Data directory path')
    return parser


if __name__ == "__main__":
    args = get_parser().parse_args()
    assert args.dataset_name in RESPONSE_DATASET_FACTORY, f"Invalid dataset name. Available datasets are {list(RESPONSE_DATASET_FACTORY.keys())} If you want to use your own dataset, you need to implement a new response dataset class and add it to the RESPONSE_DATASET_FACTORY in the response_datasets init"

    response_data = RESPONSE_DATASET_FACTORY[args.dataset_name](path_data=args.path_data)

    # Pickle the object to a file
    with open("response_dataset.pkl", 'wb') as f:
        pickle.dump(response_data, f)
