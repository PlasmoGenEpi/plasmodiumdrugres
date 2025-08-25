process CONCAT_TABLES {
    input:
    path sl_files
    path ml_files

    output:
    path "sl_summary.tsv", emit: sl_summary
    path "ml_summary.tsv", emit: ml_summary

    publishDir "${params.outdir}", mode: 'copy', overwrite: true
    
    script:
    """
    # Concatenate SL summaries
    head -n 1 ${sl_files[0]} > sl_summary.tsv   # write header
    tail -n +2 -q ${sl_files.join(' ')} >> sl_summary.tsv  # append data

    # Concatenate ML summaries
    head -n 1 ${ml_files[0]} > ml_summary.tsv
    tail -n +2 -q ${ml_files.join(' ')} >> ml_summary.tsv
    """
}