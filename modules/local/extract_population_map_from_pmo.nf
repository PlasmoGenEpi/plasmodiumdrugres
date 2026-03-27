/*
 * STEP - EXTRACT_POPULATION_MAP_FROM_PMO
 * Extract population map from PMO file
 */

process EXTRACT_POPULATION_MAP_FROM_PMO {

    label 'process_single'

    def output_filename = "population_map.tsv"

    input:
    path pmo
    val population_fields
    val separator

    output:
    path "${output_filename}", emit: population_map

    script:
    """
    pmotools-python export_specimen_meta_table \
        --file ${pmo} \
        --output specimen_meta_table.tsv

    python3 ${projectDir}/bin/specimen_info_to_population_map.py \
        --specimen-info specimen_meta_table.tsv \
        --output ${output_filename} \
        --fields ${population_fields} \
        --separator ${separator}
    """
}
