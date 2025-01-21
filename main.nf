#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { COUNT_SAMPLES_BY_COI } from './modules/local/count_samples_by_coi'
include { ESTIMATE_ML_PREVFREQ_NAIVE } from './modules/local/estimate_multilocus_prevfreq_naive'

params.coi_calls = "${projectDir}/bin/PGEcore/data/example_coi_table.tsv"
params.aa_calls = "${projectDir}/bin/PGEcore/data/example_amino_acid_calls.tsv"
workflow {
    COUNT_SAMPLES_BY_COI(params.coi_calls)
    ESTIMATE_ML_PREVFREQ_NAIVE(params.aa_calls)
}
