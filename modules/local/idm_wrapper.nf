/*
 * STEP - IDM_WRAPPER
 * Run the incomplete data model (IDM) wrapper script
 */

process IDM_WRAPPER {

    label 'process_single'

    input:
    path aa_calls_input 

    output:
    tuple val("${aa_calls_input.getBaseName(3)}"), path("${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    
    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/IDM_wrapper/IDM_wrapper.R \\
        --aa_calls_input ${aa_calls_input} --slaf_output "${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"
    """
}
