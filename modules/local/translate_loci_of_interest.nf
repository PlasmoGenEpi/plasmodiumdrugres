/*
 * translate_loci_of_interest
 *
 */
process TRANSLATE_LOCI_OF_INTEREST {
    label 'process_medium'
    input:
    path allele_table
    path ref_bed
    path loci_of_interest
    val extra_args
    output:
    path("trasnlated_loci/collapsed_amino_acid_calls.tsv.gz"), emit: collapsed_amino_acid_calls
    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/translate_loci_of_interest/translate_loci_of_interest.R \
        --allele_table ${allele_table} \
        --ref_bed ${ref_bed} \
        --loci_of_interest ${loci_of_interest} \
        --output_directory trasnlated_loci \
        ${extra_args}
    """
}
