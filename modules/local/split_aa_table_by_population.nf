/*
 * STEP - SPLIT_AA_TABLE_BY_POP
 * Split amino acid tables into seperate populations based on specimen_name
 */

process SPLIT_AA_TABLE_BY_POP {
    label 'process_single'

    input:
    path aa_table
    path population_map

    output:
    path "*.collapsed_amino_acid_calls.tsv.gz", emit: per_pop_tables
    path "unmapped_specimens.txt", optional: true, emit: unmapped_report

    script:
    """
     ${projectDir}/bin/split_table_by_population_map.R \
            --input_table_fnp ${aa_table} \
            --population_map ${population_map} \
            --split_col population_index --identifier_col specimen_name \
            --output_stub .collapsed_amino_acid_calls.tsv.gz
    """
}
