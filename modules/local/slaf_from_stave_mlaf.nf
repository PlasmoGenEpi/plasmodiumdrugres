/*
 * STEP - SLAF_FROM_STAVE_MLAF
 * Compute single locus allele frequency (SLAF) from multi-locus AF (MLAF)
 */

process SLAF_FROM_STAVE_MLAF {

    label 'process_single'

    input:
    path mlaf_input

    output:
    tuple val("${mlaf_input.getBaseName(3)}"), path("${mlaf_input.getBaseName(3)}.allele_freqs.tsv"), emit: slaf

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/slaf_from_stave_mlaf/slaf_from_stave_mlaf.R \\
        --mlaf_input ${mlaf_input} --output "${mlaf_input.getBaseName(3)}.allele_freqs.tsv"
    """
}
