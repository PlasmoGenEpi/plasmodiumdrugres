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
    path "${output_filename}", emit: slaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_frequency_naive/estimate_allele_frequency_naive.R \
        --aa_calls ${aa_calls} \
        --method ${method} \
        --output ${output_filename}
    """
}
