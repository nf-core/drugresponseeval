include { LOAD } from '../../../modules/local/load/main.nf'

workflow RUN {

    take:
    dataset

    main:

    LOAD (
        dataset
    )
}
