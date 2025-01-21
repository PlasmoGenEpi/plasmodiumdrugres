/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

process ESTIMATE_ML_PREVFREQ_NAIVE {

    label 'process_single'

    def output_filename = "mlafp.tsv"

    input:
    path aa_calls

    output:
    path "${output_filename}", emit: ml_prevfreq

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
        --input_path $aa_calls \
        --output_path $output_filename
    """
}
