"""Example custom splitter: returns the folds stored as CSVs in a hardcoded directory.

Pass it to the pipeline via ``--custom_splitter_path``. The directory must contain ``cv_split_<i>_<role>.csv`` files
as written by drevalpy (roles: train, validation, test, and optionally validation_es, early_stopping).
"""

import re
from pathlib import Path

from drevalpy.datasets.dataset import DrugResponseDataset

SPLITS_DIR = Path("/Path/to/precomputed/splits")
ROLES = ("train", "validation", "test", "validation_es", "early_stopping")


def create_splits(response_data, params):
    """
    Load the CV folds from SPLITS_DIR.

    :param response_data: full response dataset, only used for the dataset name
    :param params: additional parameters, not used here
    :returns: list of folds, each a dict mapping role to DrugResponseDataset
    """
    fold_ids = sorted(int(re.search(r"cv_split_(\d+)_train\.csv", f.name).group(1)) for f in SPLITS_DIR.glob("cv_split_*_train.csv"))
    return [
        {
            role: DrugResponseDataset.from_csv(SPLITS_DIR / f"cv_split_{i}_{role}.csv", dataset_name=response_data.dataset_name)
            for role in ROLES
            if (SPLITS_DIR / f"cv_split_{i}_{role}.csv").is_file()
        }
        for i in fold_ids
    ]
