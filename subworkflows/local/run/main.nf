include { LOAD } from '../../../modules/local/load/main.nf'
include { SPLIT } from '../../../modules/local/split/main.nf'
include { SINGLE } from '../../../modules/local/single/main.nf'
include { AGGREGATE } from '../../../modules/local/aggregate/main.nf'
include { REPORT } from '../../../modules/local/report/main.nf'

workflow RUN {

    take:
    models                    // channel: model name/recipe strings
    normalization_reference   // val: baseline model name for REPORT
    dataset_file
    dataset_name
    test_mode
    n_cv_splits
    no_hyperparameter_tuning
    optim_metric
    hpo_num_samples
    response_transformation


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

    model_splits = models.combine(SPLIT.out.folds.flatten())

    SINGLE(
        model_splits,
        ch_dataset,
        no_hyperparameter_tuning,
        optim_metric,
        hpo_num_samples,
        response_transformation
    )

    AGGREGATE (
        SINGLE.out.result.collect()
    )

    REPORT (
        AGGREGATE.out.experiment,
        'Test',
        normalization_reference,
        ch_dataset
    )

}
