/*
 * STEP - EXTRACT_PANEL_INFO_TO_BED
 * Extract panel information to bed file, optionally including ref seqs
 */

process EXTRACT_PANEL_INFO_TO_BED {

    label 'process_single'

    def output_filename = "panel_info.bed"

    input:
    path pmo
    val add_ref_seqs

    output:
    path "${output_filename}", emit: panel_info_bed

    script:
    def parameter_string = add_ref_seqs == "TRUE"
        ? "--add_ref_seqs"
        : ""

    """
    pmotools-runner.py extract_insert_of_panels \
        --file ${pmo} \
        --output ${output_filename} \
        ${parameter_string}
    """
}