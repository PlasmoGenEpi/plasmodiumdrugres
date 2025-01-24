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
    path aa_table 
    path coi_calls 

    output:
    path 'sl_summary_table.tsv', emit: sl_summary_table
    // path 'ml_summary_table.tsv', emit: ml_summary_table
    // path 'aa_table.tsv', emit: aa_table
    // path 'coi_table.tsv', emit: coi_table

    script:
    // TODO: Merge allele prev and freq
    // TODO: allele prev should have stave format
    // TODO: fix output dir param not being picked up 
    """
    echo $params.outdir
    mv $slaf_table sl_summary_table.tsv
    """
}
