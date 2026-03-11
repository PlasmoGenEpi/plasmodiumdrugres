/*
 * STEP - ESTIMATE_ALLELE_PREVALENCE_NAIVE
 * Estimate allele prevalence naively
 */

process ESTIMATE_ALLELE_PREVALENCE_NAIVE {

    label 'process_single'

    input:
    path aa_calls

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.allele_prev.tsv"), emit: allele_prevalence

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.R \
        --aa_calls ${aa_calls} \
        --output "${aa_calls.getBaseName(3)}.allele_prev.tsv"
    """
}
