/*
 * STEP - DCIFER_WRAPPER
 * Run the Dcifer wrapper script
 */

process DCIFER_WRAPPER {

    label 'process_low'

    def btwn_host_rel_output = 'btwn_host_rel.tsv'

    input:
    path allele_table

    output:
    path "$btwn_host_rel_output", emit: btwn_host_rel

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/dcifer_wrapper/dcifer_wrapper.R \
        --allele_table ${allele_table} --btwn_host_rel_output \
        "$btwn_host_rel_output"
    """
}
