/*
 * STEP - SPLIT_ALLELE_TABLE_BY_POP
 * Split allele tables into seperate populations based on specimen_name
 */

// TODO: update this to work off of column names
process SPLIT_ALLELE_TABLE_BY_POP {
    label 'process_single'

    input:
    path allele_table
    path population_map

    output:
    path "*.allele_table.tsv.gz", emit: per_pop_tables
    path "unmapped_identifers.txt", optional: true, emit: unmapped_report

    script:
    //@todo consider being able to supply population_col and identifier_col, will use defaults of the piepline for now
    """

    ${projectDir}/bin/split_table_by_population_map.R \
            --input_table_fnp ${allele_table} \
            --population_map ${population_map} \
            --split_col population_index --identifier_col specimen_name \
            --output_stub .allele_table.tsv.gz
    """
}
