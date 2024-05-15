#!/usr/bin/env python

import argparse
import sys
import pickle
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler


from dreval.models import MODEL_FACTORY
from dreval.experiment import train_and_predict, split_early_stopping


def get_parser():
    parser = argparse.ArgumentParser(description='Train and predict using a drug response prediction model.')
    parser.add_argument('--model_name', type=str, help='model to evaluate or list of models to compare')
    parser.add_argument('--test_mode', type=str, default='LPO', help='Test mode (LPO, LCO, LDO)')
    parser.add_argument('--hyperparameters', type=str, help='hyperparameters for the model')
    parser.add_argument('--cv_data', type=str, help='path to the cv data split')
    parser.add_argument('--response_transformation', type=str, help='response transformation to apply to the dataset')
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    model_class = MODEL_FACTORY[args.model_name]
    split = pickle.load(open(args.cv_data, 'rb'))
    train_dataset = split["train"]
    validation_dataset = split["validation"]
    hpams = pickle.load(open(args.hyperparameters, 'rb'))
    if model_class.early_stopping:
        validation_dataset, es_dataset = split_early_stopping(validation_dataset, args.test_mode)
    else:
        es_dataset = None
    model = model_class(target='IC50')
    if args.response_transformation == "None":
        response_transform = None
    elif args.response_transformation == "standard":
        response_transform = StandardScaler()
    elif args.response_transformation == "minmax":
        response_transform = MinMaxScaler()
    elif args.response_transformation == "robust":
        response_transform = RobustScaler()
    else:
        raise ValueError(f"Invalid response_transform: {args.response_transformation}. Choose robust, minmax or standard.")
    validation_dataset = train_and_predict(
        model=model,
        hpams=hpams,
        train_dataset=train_dataset,
        prediction_dataset=validation_dataset,
        early_stopping_dataset=es_dataset,
        response_transformation=response_transform
    )
    with open('prediction_dataset.pkl', 'wb') as f:
        pickle.dump(validation_dataset, f)


if __name__ == "__main__":
    main()
    sys.exit(0)
