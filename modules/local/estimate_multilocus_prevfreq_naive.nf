/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

// TODO: add this as option in the workflow
process ESTIMATE_ML_PREVFREQ_NAIVE {

    label 'process_single'

    input:
    path aa_calls
    path loci_groups

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.ml_prevfreq.tsv"), emit: ml_prevfreq

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
        --aa_table $aa_calls \
        --loci_groups_input $loci_groups \
        --output_path "${aa_calls.getBaseName(3)}.ml_prevfreq.tsv"
    """
}