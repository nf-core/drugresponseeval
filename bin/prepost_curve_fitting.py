#!/usr/bin/env python
from drevalpy.datasets.curvecurator import preprocess, postprocess
from pathlib import Path
def get_parser():
    parser = argparse.ArgumentParser(description="Load data for drug response prediction.")
    parser.add_argument("--path", type=str, default="", help="Path to base folder containing datasets.")
    parser.add_argument("--dataset", type=str, required=True, help="Dataset name.")
    parser.add_argument("--task", type=str, required=True, help="What to do, can be 'preprocess' / 'postprocess'")
    parser.add_argument("--cores", type=int, default=0, help="The number of cores used for CurveCurator fitting.")
    return parser


def main(path_data: str | Path, dataset_name: str | Path, task: str, cores: int = 1):
    
    base_path = Path(path_data) / dataset_name
    if task == 'postprocess':
        postprocess(output_folder=base_path, dataset_name=dataset_name)
    else:
        preprocess(
            input_file=base_path / f"{dataset_name}_raw.csv",
            output_dir=base_path,
            cores=cores
        )

if __name__ == "__main__":
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    main(args)
