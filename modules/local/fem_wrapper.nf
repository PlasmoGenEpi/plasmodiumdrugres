/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

// TODO: handle coi 
process FEM_WRAPPER {

    label 'process_single'

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/FreqEstimationModel_wrapper/FreqEstimationModel_wrapper.R \\
        --aa_calls ${aa_calls} --groups ${loci_group_table}  --coi 3 --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"
    """
}