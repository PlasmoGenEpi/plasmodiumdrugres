#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Import modules
include { EXTRACT_ALLELE_TABLE } from './modules/local/extract_allele_table'
include { TRANSLATE_LOCI_OF_INTEREST } from './modules/local/translate_loci_of_interest'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from './modules/local/estimate_allele_prevalence_naive'
include { ESTIMATE_COI_NAIVE } from './modules/local/estimate_coi_naive'
include { IDM_WRAPPER } from './modules/local/idm_wrapper'
include { MLBM_WRAPPER } from './modules/local/mlbm_wrapper'
include { SLAF_FROM_STAVE_MLAF } from './modules/local/slaf_from_stave_mlaf'
include { CREATE_OUTPUT } from './modules/local/create_output'

// Inputs
// params.pmo = "${projectDir}/tests/input/example_PMO.json"
// params.allele_table = null
params.pmo = null
params.allele_table = "${projectDir}/tests/input/example2_allele_table.tsv"

params.bioinformatics_id = "ReducedMAD4HATTERSim-SeekDeep"
params.reference_bed = "${projectDir}/tests/input/example_PMO_insert_locs_of_panel.bed"
params.loci_of_interest_bed = "${projectDir}/tests/input/example_principal_resistance_marker_info_table.bed"
params.translate_loci_extra_args = ""
params.naive_coi_threshold = 1
params.loci_groups = "${projectDir}/tests/input/example_loci_groups.tsv"

params.mlaf_method_options = ["MLBM"]
params.coi_method_options = ["NAIVE_INT_METHOD", "NAIVE_QUANTILE_METHOD"]
params.slaf_method_options = ["IDM"]

params.coi_method = "NAIVE_INT_METHOD"
params.mlaf_method = "MLBM"
params.slaf_method = "IDM"

params.outdir = "/Users/kmurie/Documents/git_projects/plasmodiumdrugres/output"

workflow {
    // TODO: Add help message 
    VALIDATE_INPUTS()

    if (params.pmo) {
        // TODO: Filter to population option 
        EXTRACT_ALLELE_TABLE(params.pmo, params.bioinformatics_id)
        allele_table = EXTRACT_ALLELE_TABLE.out.allele_table
    } else if (params.allele_table) {
        allele_table = params.allele_table
    }

    // TODO: Add step if reference_bed is null to generate targeted reference

    TRANSLATE_LOCI_OF_INTEREST(allele_table, params.reference_bed, params.loci_of_interest_bed, params.translate_loci_extra_args)

    COI(params.coi_method, allele_table)

    // Estimate single locus allele prevalence
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls)

    // Multi Loci Allele Frequency 
     // TODO: add in multi locus prev 
    MLAF(params.mlaf_method,TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls, params.loci_groups)

    // Single locus allele frequency 
    // IDM or naive or slaf from mlaf
    SLAF(params.slaf_method, TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls)

    // OUTPUT
    CREATE_OUTPUT(SLAF.out.slaf_output, ESTIMATE_ALLELE_PREVALENCE_NAIVE.out.allele_prevalence, MLAF.out.mlaf_output, TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls,  COI.out.coi_output)

}

// TODO: Pull out to subworkflows 

workflow VALIDATE_INPUTS {
    // TODO: keep log of all the errors in this and report all at once 
    // TODO: put this into a function
    // Check if coi method valid 
    if (!params.coi_method_options.contains(params.coi_method)){
        log.error "Invalid mlaf_method specified: ${params.coi_method}. Allowed workflows are: ${params.coi_method_options}."
        exit 1
    }
    // Check if mlaf method valid 
    if (!params.mlaf_method_options.contains(params.mlaf_method)){
        log.error "Invalid mlaf_method specified: ${params.mlaf_method}. Allowed workflows are: ${params.mlaf_method_options}."
        exit 1
    }
    // Check if mlaf method valid 
    if (!params.slaf_method_options.contains(params.slaf_method)){
        log.error "Invalid mlaf_method specified: ${params.slaf_method}. Allowed workflows are: ${params.slaf_method_options}."
        exit 1
    }

    // PMO or allele table can be set 
    if (params.pmo && params.allele_table){
        log.error "Either pmo or allele_table can be set, but not both."
        exit 1
    }

    // TODO: Check bioinformatics_id is in pmo 
    // TODO: Check reference_bed, loci_of_interest_bed, loci_groups are all set and files exist 
}

workflow MLAF {

    take: 
    method
    amino_acid_calls
    loci_groups

    main:
    // TODO: add naive method (estimate_multilocus_prevfreq_naive) when groups are added in 
    // TODO: These estimates should also include prev output
    if (method == "MLBM") {
        MLBM_WRAPPER(amino_acid_calls, loci_groups)
        mlaf_output = MLBM_WRAPPER.out.mlaf
    } else {
        throw new IllegalArgumentException("Error: 'mlaf_method' must be one of ${params.mlaf_method_options} Provided value: ${method}.")
    }

    emit:
    mlaf_output = mlaf_output
}

workflow COI {

    take: 
    method
    allele_table

    main:
    if (method == "NAIVE_INT_METHOD") {
        ESTIMATE_COI_NAIVE(allele_table, "integer_method", params.naive_coi_threshold)
        coi_output = ESTIMATE_COI_NAIVE.out.coi_table
    } else if (method == "NAIVE_QUANTILE_METHOD") {
        ESTIMATE_COI_NAIVE(allele_table, "quantile_method", params.naive_coi_threshold)
        coi_output = ESTIMATE_COI_NAIVE.out.coi_table
    } else {
        throw new IllegalArgumentException("Error: 'coi_method' must be one of ${params.coi_method_options} Provided value: ${method}.")
    }

    emit:
    coi_output = coi_output
}

workflow SLAF {

    take: 
    method
    method_input

    main:
    // TODO: Add in SLAF_FROM_STAVE_MLAF when updated in PGEcore
    // SLAF_FROM_STAVE_MLAF(MLAF.out.mlaf_output)
    if (method == "IDM") {
        IDM_WRAPPER(method_input)
        slaf_output = IDM_WRAPPER.out.slaf
    } else {
        throw new IllegalArgumentException("Error: 'slaf_method' must be one of ${params.slaf_method_options} Provided value: ${method}.")
    }

    emit:
    slaf_output = slaf_output
}