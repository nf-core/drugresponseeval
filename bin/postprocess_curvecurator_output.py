#!/usr/bin/env python
from drevalpy.datasets.curvecurator import postprocess
import argparse


def get_parser():
    parser = argparse.ArgumentParser(description="Postprocess CurveCurator viability data.")
    parser.add_argument("--dataset_name", type=str, required=True, help="Dataset name.")
    return parser


def main(args):
    postprocess(output_folder='./', dataset_name=args.dataset_name)


if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
