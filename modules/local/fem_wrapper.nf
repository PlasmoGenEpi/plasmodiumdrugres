/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

// TODO: handle coi 
process FEM_WRAPPER {

    label 'process_single'

    def mlaf_output = 'aa_mlaf.tsv'

    input:
    path aa_calls
    path loci_group_table

    output:
    path "$mlaf_output", emit: mlaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/FreqEstimationModel_wrapper/FreqEstimationModel_wrapper.R \\
        --aa_calls ${aa_calls} --groups ${loci_group_table}  --coi 3 --mlaf_output "$mlaf_output" 
    """
}