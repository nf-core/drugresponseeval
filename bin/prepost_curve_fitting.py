#!/usr/bin/env python
from drevalpy.datasets.curvecurator import preprocess, postprocess
from pathlib import Path
def get_parser():
    parser = argparse.ArgumentParser(description="Load data for drug response prediction.")
    parser.add_argument("--input_file", type=str, default="", help="Path to viability data csv file.")
    parser.add_argument("--output_dir", type=str, required=True, help="Output directory for all outputs.")
    parser.add_argument("--cores", type=int, default=0, help="The number of cores used by CurveCurator.")
    return parser


def main(input_file: str | Path, output_dir: str | Path, cores: int = 0):
    
    if cores == 0 or input_file == "":
        postprocess(output_dir)
    else:
        preprocess(input_file, output_dir, cores)

if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
