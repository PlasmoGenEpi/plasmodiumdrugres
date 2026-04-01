/*
 * STEP - PILEUP_SPECIFIC_SNPS
 * Extract SNPs of interest from allele table
 */

process PILEUP_SPECIFIC_SNPS {

    label 'process_low'

    def output_dir = "base_counts"

    input:
    path allele_table
    path ref_bed
    path snps_of_interest
    val extra_args

    output:
    path ("${output_dir}/collapsed_snp_calls.tsv.gz"), emit: collapsed_snp_calls
    path ("${output_dir}/snp_calls.tsv.gz"), emit: snp_calls
    path ("${output_dir}/snps_covered_by_target_samples_info.tsv"), emit: snps_covered_by_target_samples_info

    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/pileup_specific_snps/pileup_specific_snps.R \
        --allele_table ${allele_table} \
        --ref_bed ${ref_bed} \
        --snps_of_interest ${snps_of_interest} \
        --output_directory ${output_dir} \
        ${extra_args}
    """
}
