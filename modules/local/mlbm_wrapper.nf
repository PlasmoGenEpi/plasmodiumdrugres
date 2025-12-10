/*
 * STEP - MLBM_WRAPPER
 * Run the MultiLociBiallelicModel (MLBM) wrapper script
 */

process MLBM_WRAPPER {

    label 'process_single'

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf


    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    Rscript ${projectDir}/bin/PGEcore/scripts/MultiLociBiallelicModel_wrapper/MultiLociBiallelicModel_wrapper.R \
        --aa_calls ${aa_calls} \
        --loci_group_table ${loci_group_table} \
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"\
        ${extra_args}
    """
}
