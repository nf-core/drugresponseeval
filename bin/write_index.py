#!/usr/bin/env python
import argparse

from drevalpy.visualization.utils import create_index_html


def get_parser():
    parser = argparse.ArgumentParser(description="Write index.html.")
    parser.add_argument("--run_id", type=str, required=True, help="Run ID.")
    parser.add_argument("--test_modes", type=str, required=True, help="Test modes.")
    return parser


if __name__ == "__main__":
    args = get_parser().parse_args()
    settings = args.test_modes.split(",")
    create_index_html(custom_id=args.run_id, test_modes=settings, prefix_results="")
