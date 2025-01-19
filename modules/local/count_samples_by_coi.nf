/*
 * STEP - COUNT_SAMPLES_BY_COI
 * Count the number of samples with each COI in the distribution
 */

process COUNT_SAMPLES_BY_COI {

    label 'process_single'

    input:
    path coi_calls

    output:
    path ("sample_count_per_coi.tsv"), emit: sample_count_per_coi

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/count_samples_by_coi/count_samples_by_coi.R \\
      --coi_calls ${coi_calls} \\
      --output "sample_count_per_coi.tsv"
    """
}
