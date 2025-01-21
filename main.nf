#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { COUNT_SAMPLES_BY_COI } from './modules/local/count_samples_by_coi'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from './modules/local/estimate_allele_prevalence_naive'

params.coi_calls = "${projectDir}/bin/PGEcore/data/example_coi_table.tsv"
params.aa_calls = "${projectDir}/bin/PGEcore/data/example_amino_acid_calls.tsv"
workflow {
    COUNT_SAMPLES_BY_COI(params.coi_calls)
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(params.aa_calls)
}
