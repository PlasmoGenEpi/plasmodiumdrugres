/*
 * STEP - MERGE_TABLES
 * Compile outputs into final summaries
 */

process MERGE_TABLES {

    label 'process_single'

    input:
    tuple val(pop), path(pop_files)

    output:
    path "${pop}.sl_summary.tsv", emit: sl_summary
    path "${pop}.ml_summary.tsv", emit: ml_summary

    script:
    // TODO: fix output dir param not being picked up
    """
    slap_table=\$(ls ${pop_files} | grep 'prev')
    mlaf_table=\$(ls ${pop_files} | grep 'mlaf')
    slaf_table=\$(ls ${pop_files} | grep 'slaf')

    Rscript ${projectDir}/bin/merge_tables.R --freq_table \${slaf_table} --population ${pop} --prev_table \${slap_table} --output ${pop}.sl_summary.tsv
    mv \${mlaf_table} ${pop}.ml_summary.tsv
    """
}

// slap naive now outputs stave
// do any of the slaf methods output stave - IDM
// do any of the mlaf methods output stave
