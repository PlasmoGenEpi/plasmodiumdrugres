/*
 * STEP - SLAF_FROM_MHAPS_FREQS
 * Run the script that calculates single loci allele frequencies by utilizing the allele frequency of microhaplotypes that they are covered by
 */

process SLAF_FROM_MHAPS_FREQS {

    label 'process_low'


    input:
    path mhaps_slaf_fnp
    path loci_of_interest_per_microhaps_fnp

    output:
    path "slaf.tsv", emit: slaf

    script:


    """
    Rscript ${projectDir}/bin/PGEcore/scripts/calc_slaf_based_on_mhap_freqs/slaf_from_mhaps_freqs.R \
        --mhaps_slaf_fnp ${mhaps_slaf_fnp}  \
        --loci_of_interest_per_microhaps_fnp ${loci_of_interest_per_microhaps_fnp}  \
        --slaf_output slaf.tsv
    """
}
