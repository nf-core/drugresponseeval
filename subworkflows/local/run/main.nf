include { LOAD } from '../../../modules/local/load/main.nf'
include { SPLIT } from '../../../modules/local/split/main.nf'
include { SINGLE } from '../../../modules/local/single/main.nf'
include { AGGREGATE } from '../../../modules/local/aggregate/main.nf'
include { REPORT } from '../../../modules/local/report/main.nf'

workflow RUN {

    take:
    dataset
    test_mode
    n_cv_splits


    main:

    LOAD (
        dataset
    )

    SPLIT (
        LOAD.out.data,
        test_mode,
        n_cv_splits
    )

    models = channel.fromList(['RandomForest', 'NaiveMeanEffectsPredictor'])
    model_splits = models.combine(SPLIT.out.folds.flatten())

    SINGLE(
        model_splits,
        LOAD.out.data.collect()
    )

    AGGREGATE (
        SINGLE.out.result.collect()
    )

    REPORT (
        AGGREGATE.out.experiment,
        'Test',
        'NaiveMeanEffectsPredictor',
        LOAD.out.data
    )

}
