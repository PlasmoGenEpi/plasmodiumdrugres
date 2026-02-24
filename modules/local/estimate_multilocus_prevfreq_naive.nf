/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

process ESTIMATE_ML_PREVFREQ_NAIVE {

    label 'process_single'

    input:
    path aa_calls
    path loci_groups

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv"), emit: slaf_from_mlaf

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    Rscript ${projectDir}/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
        --aa_table $aa_calls \
        --loci_groups_input $loci_groups \
        --output_path "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \
        --recalc_single_locus_output_path "${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv" \
        ${extra_args}
    """
}
