/*
 * STEP - TRANSLATE_LOCI_OF_INTEREST
 * Pull out and translate loci of interest to amino acid calls
 */

process TRANSLATE_LOCI_OF_INTEREST {
    label 'process_low'

    def output_dir = "translated_loci"

    input:
    path allele_table
    path ref_bed
    path loci_of_interest
    val extra_args

    output:
    path ("${output_dir}/collapsed_amino_acid_calls.tsv.gz"), emit: collapsed_amino_acid_calls
    path ("${output_dir}/amino_acid_calls.tsv.gz"), emit: amino_acid_calls
    path ("${output_dir}/loci_covered_by_target_samples_info.tsv"), emit: loci_covered_by_target_samples_info
    path ("${output_dir}/loci_of_interest_for_target_for_microhap.tsv.gz"), emit: loci_of_interest_for_target_for_microhap

    publishDir "${params.outdir}", mode: "${params.publish_dir_mode}", overwrite: true

    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/translate_loci_of_interest/translate_loci_of_interest.R \
        --allele_table ${allele_table} \
        --ref_bed ${ref_bed} \
        --loci_of_interest ${loci_of_interest} \
        --output_directory ${output_dir} \
        ${extra_args}
    """
}
