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
    pmotools-python extract_insert_of_panels \
        --file ${pmo} \
        --output ${output_filename} \
        ${parameter_string}

    # Rename header column from target_id to target_name
    awk 'BEGIN{FS=OFS="\t"} NR==1 {for(i=1;i<=NF;i++) if(\$i=="target_id") \$i="target_name"} {print}' \
        ${output_filename} > ${output_filename}.tmp && \
    mv ${output_filename}.tmp ${output_filename}
    """
}
