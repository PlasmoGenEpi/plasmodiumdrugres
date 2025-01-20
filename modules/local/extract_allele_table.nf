/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Count the number of samples with each COI in the distribution
 */

process EXTRACT_ALLELE_TABLE {

    label 'process_single'

    input:
    path pmo
    val bioinfoid

    output:
    path ("allele_table.tsv"), emit: allele_table

    script:
    """
    python3 pmotools-runner.py extract_allele_table \
        --file ${pmo} \
        --bioid ${bioinfoid} \
        --representative_haps_fields seq \
        --microhap_fields read_count \
        --output allele_table
    """
}
