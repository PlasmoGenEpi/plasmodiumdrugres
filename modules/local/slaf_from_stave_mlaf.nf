/*
 * STEP - SLAF_FROM_STAVE_MLAF
 * Compute single locus allele frequency (SLAF) from multi-locus AF (MLAF)
 */

process SLAF_FROM_STAVE_MLAF {

    label 'process_single'

    def output = 'slaf.tsv'

    input:
    path mlaf_input

    output:
    path "$output", emit: slaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/slaf_from_stave_mlaf/slaf_from_stave_mlaf.R \\
        --mlaf_input ${mlaf_input} --output "$output"
    """
}
