/*
 * STEP - MLBM_WRAPPER
 * Run the MultiLociBiallelicModel (MLBM) wrapper script
 */

process MLBM_WRAPPER {

    label 'process_single'

    def mlaf_output = 'aa_mlaf.tsv'

    input:
    path aa_calls
    path loci_group_table

    output:
    path "$mlaf_output", emit: mlaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/MultiLociBiallelicModel_wrapper/MultiLociBiallelicModel_wrapper.R \\
        --aa_calls ${aa_calls} --loci_group_table ${loci_group_table} --mlaf_output "$mlaf_output" 
    """
}
