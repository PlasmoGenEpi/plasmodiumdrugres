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
// include { getGenomeAttribute } from './subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
// params.fasta = getGenomeAttribute('fasta')
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
    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PLASMODIUMDRUGRES(
        params.allele_table, // TODO: create this in the pipeline initialisation. Could be multiple
        params.panel_info_bed_with_ref, // TODO: create this in the pipeline initialisation
        params.loci_of_interest_bed,
        params.translate_loci_extra_args,
        params.coi_method,
        params.mlaf_method,
        params.loci_groups,
        params.slaf_method 
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    // PIPELINE_COMPLETION(
    //     params.email,
    //     params.email_on_fail,
    //     params.plaintext_email,
    //     params.outdir,
    //     params.monochrome_logs,
    //     params.hook_url,
    //     NFCORE_PLASMODIUMDRUGRES.out.sl_summary_table,
    // )
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
    allele_table 
    panel_info_bed_with_ref 
    loci_of_interest_bed
    translate_loci_extra_args
    coi_method
    mlaf_method
    loci_groups
    slaf_method 

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PLASMODIUMDRUGRES(
        allele_table, 
        panel_info_bed_with_ref, 
        loci_of_interest_bed,
        translate_loci_extra_args,
        coi_method,
        mlaf_method,
        loci_groups,
        slaf_method
    )

    emit:
    sl_summary_table = PLASMODIUMDRUGRES.out.sl_summary_table // channel: /path/to/sl_summary_table.tsv
}
