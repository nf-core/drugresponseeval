#!/usr/bin/env python
import argparse
import pickle
import sys
from dreval.evaluation import evaluate


def get_parser():
    parser = argparse.ArgumentParser(description='Evaluate model')
    parser.add_argument('--pred_data', type=str, required=True, help='Path to prediction data')
    parser.add_argument('--metric', type=str, default='RMSE', help='Metric to evaluate')
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    pred_data = pickle.load(open(args.pred_data, 'rb'))
    results = evaluate(dataset=pred_data, metric=[args.metric])
    with open("eval_results.pkl", "wb") as f:
        pickle.dump(results, f)


if __name__ == "__main__":
    main()
    sys.exit(0)
