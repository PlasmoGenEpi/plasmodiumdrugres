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
    val representative_haps_fields = "seq"
    val microhap_fields = "read_count"

    output:
    path "${output_filename}.tsv", emit: allele_table

    script:
    """
    python3 pmotools-runner.py extract_allele_table \
        --file ${pmo} \
        --bioid ${bioinfoid} \
        --representative_haps_fields ${representative_haps_fields} \
        --microhap_fields ${microhap_fields} \
        --output ${output_filename}
    """
}
