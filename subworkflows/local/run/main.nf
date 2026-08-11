include { LOAD } from '../../../modules/local/load/main.nf'
include { SPLIT } from '../../../modules/local/split/main.nf'
include { SINGLE } from '../../../modules/local/single/main.nf'
include { AGGREGATE } from '../../../modules/local/aggregate/main.nf'
include { REPORT } from '../../../modules/local/report/main.nf'

workflow RUN {

    take:
    dataset_file
    dataset_name
    test_mode
    n_cv_splits


    main:

    if (!dataset_file) {
        LOAD (
            dataset_name
        )
        ch_dataset = LOAD.out.data.collect()
    } else {
        ch_dataset = channel.value(file(dataset_file, checkIfExists: true))
    }

    SPLIT (
        ch_dataset,
        test_mode,
        n_cv_splits
    )

    models = channel.fromList(['RandomForest', 'NaiveMeanEffectsPredictor'])
    model_splits = models.combine(SPLIT.out.folds.flatten())

    SINGLE(
        model_splits,
        ch_dataset
    )

    AGGREGATE (
        SINGLE.out.result.collect()
    )

    REPORT (
        AGGREGATE.out.experiment,
        'Test',
        'NaiveMeanEffectsPredictor',
        ch_dataset
    )

}
