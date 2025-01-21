#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { COUNT_SAMPLES_BY_COI } from './modules/local/count_samples_by_coi'

params.coi_calls = "${projectDir}/bin/PGEcore/data/example_coi_table.tsv"

workflow {
    COUNT_SAMPLES_BY_COI(params.coi_calls)
}
