/*
 * STEP - RUN_MOIRE
 * run the r moire wrapper script
 */

process RUN_MOIRE {

  input:
  path input_allele_table

  output:
  path "coi_summary.tsv", emit: coi_summary
  path "he_summary.tsv", emit: he_summary
  path "allele_freq_summary.tsv", emit: allele_freq_summary
  path "relatedness_summary.tsv", emit: relatedness_summary
  path "effective_coi_summary.tsv", emit: effective_coi_summary

  script:
  def non_mandatory_args = task.ext.args ? task.ext.args : ''
  """
  Rscript ${projectDir}/bin/PGEcore/scripts/moire_wrapper/Moire_wrapper.R \
        --allele_table ${input_allele_table}\
        ${non_mandatory_args}
  """
}