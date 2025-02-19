/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

process ESTIMATE_ML_PREVFREQ_NAIVE {

    label 'process_single'

    def output_filename = "mlafp.tsv"

    input:
    path aa_calls
    path loci_groups

    output:
    path "${output_filename}", emit: ml_prevfreq

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
        --aa_table $aa_calls \
        --loci_groups_input $loci_groups\
        --output_path $output_filename
    """
}
