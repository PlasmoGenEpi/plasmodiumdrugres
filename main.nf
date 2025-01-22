#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Import modules
include { EXTRACT_ALLELE_TABLE } from './modules/local/extract_allele_table'
include { TRANSLATE_LOCI_OF_INTEREST } from './modules/local/translate_loci_of_interest'
include { COUNT_SAMPLES_BY_COI } from './modules/local/count_samples_by_coi'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from './modules/local/estimate_allele_prevalence_naive'
include { ESTIMATE_COI_NAIVE } from './modules/local/estimate_coi_naive'
include { IDM_WRAPPER } from './modules/local/idm_wrapper'
include { MLBM_WRAPPER } from './modules/local/mlbm_wrapper'
include { SLAF_FROM_STAVE_MLAF } from './modules/local/slaf_from_stave_mlaf'

params.pmo = "${projectDir}/tests/input/example_PMO.json"
params.bioinformatics_id = "ReducedMAD4HATTERSim-SeekDeep"
params.reference_bed = "${projectDir}/tests/input/example_PMO_insert_locs_of_panel.bed"
params.loci_of_interest_bed = "${projectDir}/tests/input/example_principal_resistance_marker_info_table.bed"
params.translate_loci_extra_args = ""
params.naive_coi_method = "integer_method"
params.naive_coi_threshold = 1
params.loci_groups = "${projectDir}/tests/input/example_loci_groups.tsv"
params.mlaf_method_options = ["MLBM"]

workflow {
    // TODO: Add help message 
    // TODO: add validation on params
    EXTRACT_ALLELE_TABLE(params.pmo, params.bioinformatics_id)

    // TODO: Add step if reference_bed is null to generate targeted reference

    TRANSLATE_LOCI_OF_INTEREST(EXTRACT_ALLELE_TABLE.out.allele_table, params.reference_bed, params.loci_of_interest_bed, params.translate_loci_extra_args)

    // TODO: Extract this into own workflow
    ESTIMATE_COI_NAIVE(EXTRACT_ALLELE_TABLE.out.allele_table, params.naive_coi_method, params.naive_coi_threshold)
    
    // Estimate single locus allele prevalence
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls)

    // Multiallelic Loci Allele Frequency 
    MLAF("MLBM",TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls, params.loci_groups)
    // Single locus allele frequency 
    // IDM or naive or slaf from mlaf
    IDM_WRAPPER(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls)
    // SLAF_FROM_STAVE_MLAF()
}

workflow MLAF {

    take: 
    method
    amino_acid_calls
    loci_groups

    main:
    // TODO: add naive method when groups are added in 
    if (method == "MLBM") {
        MLBM_WRAPPER(amino_acid_calls, loci_groups)
        mlaf_output = MLBM_WRAPPER.out.mlaf
    } else {
        throw new IllegalArgumentException("Error: 'mlaf_method' must be one of ${params.mlaf_method_options} Provided value: ${method}.")
    }

    emit:
    mlaf_output = mlaf_output
}