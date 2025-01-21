/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Count the number of samples with each COI in the distribution
 */

process EXTRACT_ALLELE_TABLE {

    label 'process_single'

    def output_filename = "allele_table"

    input:
    path pmo
    val bioinfoid

    output:
    path "${output_filename}.tsv", emit: allele_table

    script:
    """
    pmotools-runner.py extract_allele_table \
        --file ${pmo} \
        --bioid ${bioinfoid} \
        --representative_haps_fields "seq" \
        --microhap_fields "read_count" \
        --output ${output_filename}
    """
}
