/*
 * pileup_specific_snps
 *
 */
process PILEUP_SPECIFIC_SNPS {
    label 'process_low'
    input:
    path allele_table
    path ref_bed
    path snps_of_interest
    val extra_args
    output:
    path("base_counts/collapsed_snp_calls.tsv.gz"), emit: collapsed_snp_calls
    path("base_counts/snp_calls.tsv.gz"), emit: snp_calls
    path("base_counts/snps_covered_by_target_samples_info.tsv"), emit: snps_covered_by_target_samples_info

    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/pileup_specific_snps/pileup_specific_snps.R \
        --allele_table ${allele_table} \
        --ref_bed ${ref_bed} \
        --snps_of_interest ${snps_of_interest} \
        --output_directory base_counts \
        ${extra_args}
    """
}
