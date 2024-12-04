#!/usr/bin/env python
from drevalpy.datasets.curvecurator import preprocess
from pathlib import Path
import argparse
def get_parser():
    parser = argparse.ArgumentParser(description="Pre/postprocess CurveCurator viability data.")
    parser.add_argument("--path_data", type=str, default="", help="Path to base folder containing datasets.")
    parser.add_argument("--dataset_name", type=str, required=True, help="Dataset name.")
    parser.add_argument("--cores", type=int, default=0, help="The number of cores used for CurveCurator fitting.")
    return parser


def main(args):
    
    base_path = Path(args.path_data) / args.dataset_name
    preprocess(
        input_file=base_path / f"{args.dataset_name}_raw.csv",
        output_dir=args.dataset_name,
        dataset_name=args.dataset_name,
        cores=args.cores
    )

if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
