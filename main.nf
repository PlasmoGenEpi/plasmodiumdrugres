#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/plasmodiumdrugres
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/plasmodiumdrugres
    Website: https://nf-co.re/plasmodiumdrugres
    Slack  : https://nfcore.slack.com/channels/plasmodiumdrugres
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLASMODIUMDRUGRES } from './workflows/plasmodiumdrugres'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline'
include { PIPELINE_COMPLETION } from './subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION(
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.help,
        params.help_full,
        params.show_hidden
    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PLASMODIUMDRUGRES(
        PIPELINE_INITIALISATION.out.allele_table_ch,
        PIPELINE_INITIALISATION.out.panel_info_bed_ch,
        params.loci_of_interest_bed,
        params.translate_loci_extra_args,
        PIPELINE_INITIALISATION.out.population_assignment_ch,
        params.mlaf_method,
        params.loci_groups,
        params.slaf_method
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION(
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        "multiqcreport",
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_PLASMODIUMDRUGRES {
    take:
    allele_table_ch
    panel_info_bed_ch
    loci_of_interest_bed
    translate_loci_extra_args
    population_assignment_ch
    mlaf_method
    loci_groups
    slaf_method

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PLASMODIUMDRUGRES(
        allele_table_ch,
        panel_info_bed_ch,
        loci_of_interest_bed,
        translate_loci_extra_args,
        population_assignment_ch,
        mlaf_method,
        loci_groups,
        slaf_method
    )

    // emit:
    sl_summary = PLASMODIUMDRUGRES.out.sl_summary // channel: /path/to/sl_summary.tsv
    ml_summary = PLASMODIUMDRUGRES.out.ml_summary // channel: /path/to/ml_summary.tsv
}
