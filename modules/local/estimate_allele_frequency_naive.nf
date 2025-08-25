/*
 * STEP - ESTIMATE_ALLELE_FREQUENCY_NAIVE
 * Estimate allele frequencies naively by read_count_prop or presence_absence
 */

process ESTIMATE_ALLELE_FREQUENCY_NAIVE {

    label 'process_single'

    def output_filename = "allele_freqs.tsv"

    input:
    path aa_calls
    val method

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.allele_freqs.tsv"), emit: slaf


    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_frequency_naive/estimate_allele_frequency_naive.R \
        --aa_calls ${aa_calls} \
        --method ${method} \
        --output "${aa_calls.getBaseName(3)}.allele_freqs.tsv"
    """
}
