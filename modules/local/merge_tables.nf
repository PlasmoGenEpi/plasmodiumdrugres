/*
 * STEP - MERGE_TABLES
 * Compile outputs into final summaries
 */

process MERGE_TABLES {

    label 'process_single'

    input:
    tuple val(pop_index), path(pop_files)
    path population_index_lookup

    output:
    path "${pop_index}.sl_summary.tsv", emit: sl_summary
    path "${pop_index}.ml_summary.tsv", emit: ml_summary
    path "${pop_index}.sl_from_ml_summary.tsv", emit: sl_from_ml_summary

    script:
    """
    if [ -s ${population_index_lookup} ]; then
        true_population=\$(awk -F'\\t' -v idx="${pop_index}" '\$1==idx {print \$2; exit}' ${population_index_lookup})
    else
        true_population="${pop_index}"
    fi

    slap_table=\$(ls ${pop_files} | grep 'prev')
    mlaf_table=\$(ls ${pop_files} | grep 'mlaf')
    slaf_table=\$(ls ${pop_files} | grep 'slaf')
    sl_from_ml_table=\$(ls ${pop_files} | grep 'sl_from_ml')

    Rscript ${projectDir}/bin/merge_tables.R --freq_table \${slaf_table} --population "\${true_population}" --prev_table \${slap_table} --output ${pop_index}.sl_summary.tsv
    Rscript ${projectDir}/bin/add_population_column.R --table \${mlaf_table} --population "\${true_population}" --output ${pop_index}.ml_summary.tsv
    Rscript ${projectDir}/bin/add_population_column.R --table \${sl_from_ml_table} --population "\${true_population}" --output ${pop_index}.sl_from_ml_summary.tsv
    """
}

// slap naive now outputs stave
// do any of the slaf methods output stave - IDM
// do any of the mlaf methods output stave
