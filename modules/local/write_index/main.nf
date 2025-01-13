process WRITE_INDEX {
    label 'process_single'

    input:
    val(run_id)
    val(test_modes)
    val(nr_html_files)

    output:
    path('*.html'), emit: html_out
    path('*.png'), emit: graphic_elements

    script:
    """
    write_index.py \\
        --run_id ${run_id} \\
        --test_modes ${test_modes}
    """

}
