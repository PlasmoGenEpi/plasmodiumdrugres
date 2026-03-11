/*
 * STEP - DCIFER_WRAPPER
 * Run the Dcifer IBD wrapper script
 */

process DCIFER_IBD_WRAPPER {

    label 'process_low'

    def btwn_host_rel_output = 'btwn_host_rel.tsv'

    input:
    path allele_table

    output:
    path "$btwn_host_rel_output", emit: btwn_host_rel

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/dcifer_ibd_wrapper/dcifer_ibd_wrapper.R \
        --allele_table ${allele_table} --threads ${task.cpus} \
        --btwn_host_rel_output "$btwn_host_rel_output"
    """
}
