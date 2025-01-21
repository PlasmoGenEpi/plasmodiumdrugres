/*
 * STEP - IDM_WRAPPER
 * Run the incomplete data model (IDM) wrapper script
 */

process IDM_WRAPPER {

    label 'process_single'

    def slaf_output = 'aa_slaf.tsv'

    input:
    path aa_calls_input

    output:
    path "$slaf_output", emit: slaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/IDM_wrapper/IDM_wrapper.R \\
        --aa_calls_input ${aa_calls_input} --slaf_output "$slaf_output"
    """
}
