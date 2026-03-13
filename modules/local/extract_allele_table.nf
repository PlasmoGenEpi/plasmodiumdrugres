/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {

    label 'process_single'

    def output_filename = "allele_table"

    input:
    path pmo

    output:
    path "${output_filename}.tsv", emit: allele_table

    script:
    """
    # TODO: update this to use the new column names read_count and convert allele
    pmotools-python extract_allele_table \
        --file ${pmo} \
        --representative_haps_fields "seq" \
        --microhap_fields "reads" \
        --default_base_col_names specimen_name,target_name,allele \
        --output ${output_filename}
    """
}
