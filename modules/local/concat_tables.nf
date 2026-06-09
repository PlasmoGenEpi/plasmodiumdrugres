/*
 * STEP - CONCAT_TABLES
 * concatenate output tables
 */

process CONCAT_TABLES {

    label 'process_single'

    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    path sl_files
    path ml_files
    path sl_from_ml_files

    output:
    path "sl_summary.tsv", emit: sl_summary
    path "ml_summary.tsv", emit: ml_summary
    path "raw_summaries", emit: raw_summaries
    path "raw_summaries/raw_sl_from_ml_summary.tsv", emit: sl_from_ml_summary


    script:
    """
    # Concatenate deterministically using R (avoids shell header/ordering drift).
    Rscript ${projectDir}/bin/concat_tables.R \
        --sl-files "${sl_files.join(',')}" \
        --ml-files "${ml_files.join(',')}" \
        --sl-from-ml-files "${sl_from_ml_files.join(',')}" \
        --sl-out "sl_summary.tsv" \
        --ml-out "ml_summary.tsv" \
        --raw-out-dir "raw_summaries"
    """
}
