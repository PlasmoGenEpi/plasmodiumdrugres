#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Import modules
include { EXTRACT_ALLELE_TABLE } from './modules/local/extract_allele_table'
include { TRANSLATE_LOCI_OF_INTEREST } from './modules/local/translate_loci_of_interest'
include { COUNT_SAMPLES_BY_COI } from './modules/local/count_samples_by_coi'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from './modules/local/estimate_allele_prevalence_naive'

params.pmo = "${projectDir}/tests/input/example_PMO.json"
params.bioinformatics_id = "ReducedMAD4HATTERSim-SeekDeep"
params.reference_bed = "${projectDir}/tests/input/example_PMO_insert_locs_of_panel.bed"
params.loci_of_interest_bed = "${projectDir}/tests/input/example_principal_resistance_marker_info_table.bed"
params.translate_loci_extra_args = ""

workflow {
    EXTRACT_ALLELE_TABLE(params.pmo, params.bioinformatics_id)

    // TODO: Add step if reference_bed is null to generate targeted reference

    TRANSLATE_LOCI_OF_INTEREST(EXTRACT_ALLELE_TABLE.out.allele_table, params.reference_bed, params.loci_of_interest_bed, params.translate_loci_extra_args)

    // TODO: workflow for estimating coi

    // Estimate single locus allele prevalence
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls)
}
