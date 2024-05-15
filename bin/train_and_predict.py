import pickle
from typing import Dict
from dreval.experiment import train_and_predict
from dreval.models import MODEL_FACTORY

def dreval_train_and_predict(
    model_name: str,
    hyperparameters: Dict,
    train_path: str,
    pred_path: str,
    es_path: str,
    response_transform: str,
    cl_feature_path: str,
    drug_feature_path: str

):
    model_class = MODEL_FACTORY[model_name]
    train_dataset = pickle.load(open(train_path, "rb"))
    pred_dataset = pickle.load(open(pred_path, "rb"))
    es_dataset = pickle.load(open(es_path, "rb"))

