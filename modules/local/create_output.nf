/*
 * STEP - CREATE_OUTPUT
 * Compile outputs into final summaries 
 */

process CREATE_OUTPUT {

    label 'process_single'

    publishDir(
        path: "${params.outdir}",
        mode: 'copy',
    )

    input:
    path slaf_table
    path slap_table 
    path mlaf_table

    output:
    path 'sl_summary.tsv', emit: sl_summary
    path 'ml_summary.tsv', emit: ml_summary

    script:
    // TODO: fix output dir param not being picked up 
    """
    Rscript ${projectDir}/bin/merge_tables.R --freq_table ${slaf_table} --prev_table ${slap_table}
    mv ${mlaf_table} ml_summary.tsv
    """
}

// slap naive now outputs stave 
// do any of the slaf methods output stave - IDM
// do any of the mlaf methods output stave 