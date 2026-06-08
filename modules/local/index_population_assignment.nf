/*
 * STEP - INDEX_POPULATION_ASSIGNMENT
 * Add stable internal indices to population assignment labels
 */

process INDEX_POPULATION_ASSIGNMENT {

    label 'process_single'

    input:
    path population_map

    output:
    path "population_map_indexed.tsv", emit: population_map_indexed
    path "population_index_lookup.tsv", emit: population_index_lookup

    script:
    """
    Rscript ${projectDir}/bin/index_population_assignment.R \
        --population_map ${population_map} \
        --population_col population \
        --identifier_col specimen_name \
        --indexed_output population_map_indexed.tsv \
        --lookup_output population_index_lookup.tsv
    """
}
