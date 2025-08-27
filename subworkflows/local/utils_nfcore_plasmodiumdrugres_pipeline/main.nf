//
// Subworkflow with functionality specific to the nf-core/plasmodiumdrugres pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification            } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { EXTRACT_ALLELE_TABLE      } from '../../../modules/local/extract_allele_table'
include { EXTRACT_BED_FILE_FROM_PMO } from '../../../subworkflows/local/generate_reference_bed_file'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //  array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved

    main:

    ch_versions = Channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    // TODO: Update schema with our inputs 
    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    //
    // Custom validation for pipeline parameters
    //
    validateInputParameters()

    //
    // Create allele table input for pipeline 
    //
    // TODO: add option to split pmo and then run it in chunks 
    def ref_type = params.targeted_reference ? "targeted_reference" : 
        params.genome_reference ? "genome_reference" : "none"
    def fasta = params.targeted_reference ?: params.genome_reference ?: ""
    if (params.pmo) {
        EXTRACT_ALLELE_TABLE(params.pmo, params.bioinformatics_id)
        allele_table = EXTRACT_ALLELE_TABLE.out.allele_table
        EXTRACT_BED_FILE_FROM_PMO(params.pmo, ref_type, fasta)
        panel_info_bed = EXTRACT_BED_FILE_FROM_PMO.out.panel_info_bed 
    } else if (params.allele_table) {
        allele_table = params.allele_table 
        panel_info_bed = params.panel_info_bed
    }

    emit:
    allele_table    = allele_table 
    panel_info_bed  = panel_info_bed
    versions        = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {

    take:
    email           //  string: email address
    email_on_fail   //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir          //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output
    hook_url        //  string: hook URL for notifications
    multiqc_report  //  string: Path to MultiQC report

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                multiqc_report.toList()
            )
        }

        completionSummary(monochrome_logs)
        if (hook_url) {
            imNotification(summary_params, hook_url)
        }
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting"
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// Check and validate pipeline parameters
//
def validateInputParameters() {
    // Collect validation errors
    def validation_errors = []
    def validation_warnings = []
    
    // Ensure only one of `pmo` or `allele_table` is set
    if (params.pmo && params.allele_table) {
        validation_errors.add("Only one of 'pmo' or 'allele_table' can be set, but not both.")
    }
    // If pmo set check bioinformatics_id is set
    if (params.pmo) {
        if (!params.bioinformatics_id) {
            validation_errors.add("Missing required parameter: '--bioinformatics_id' is not set and is required with --pmo.")
        }
        if (params.genome_reference && params.targeted_reference) {
            validation_warnings.add("WARNING: Both 'genome_reference' or 'targeted_reference' set, 'targeted_reference' will be used.")
        }
    } else if (params.allele_table) {
        if (!params.panel_info_bed) {
            validation_errors.add("Missing required parameter: '--panel_info_bed' is not set and is required with --allele_table.")
        }
        if (params.genome_reference || params.targeted_reference) {
            validation_warnings.add("WARNING: Either 'genome_reference' or 'targeted_reference' set, but neither will be used.")
        }
    } else {
        validation_errors.add("Missing required parameter: Either '--pmo' or '--allele_table' must be set, but neither were.")
    }

    // Warn if both population_map and population_label is set 
    if ((params.population_map) && (params.population_label!='pop1')) {
        validation_warnings.add("WARNING: both '--population_map' and --'population_label' set. '--population_map' will be used.")
    }
    // Check if `mlaf_method` is valid
    if (!params.mlaf_method_options.contains(params.mlaf_method)) {
        validation_errors.add("Invalid mlaf_method specified: '${params.mlaf_method}'. Allowed methods are: ${params.mlaf_method_options}.")
    }

    // Check if `slaf_method` is valid
    if (!params.slaf_method_options.contains(params.slaf_method)) {
        validation_errors.add("Invalid slaf_method specified: '${params.slaf_method}'. Allowed methods are: ${params.slaf_method_options}.")
    }

    // Check other required files: `loci_of_interest_bed`, `loci_groups`
    def required_files = [
        'loci_of_interest_bed': params.loci_of_interest_bed,
        'loci_groups': params.loci_groups
    ]

    required_files.each { file_label, file_path ->
        if (!file_path) {
            validation_errors.add("Missing required file parameter: '${file_label}' is not set.")
        } else if (!file(file_path).exists()) {
            validation_errors.add("File not found: '${file_label}' at path '${file_path}'.")
        }
    }

    // Print warnings if any
    if (validation_warnings.size() > 0) {
        log.warn "Input validation warnings:\n" +
            validation_warnings.collect { "- ${it}" }.join("\n")
    }

    // Report all errors at once
    if (validation_errors.size() > 0) {
        log.error "Input validation failed with the following errors:\n" +
            validation_errors.collect { "- ${it}" }.join("\n")
        exit 1
    }

    log.info "All input validations passed successfully."
}

//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    def (metas, fastqs) = input[1..2]

    // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
    def endedness_ok = metas.collect{ meta -> meta.single_end }.unique().size == 1
    if (!endedness_ok) {
        error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end: ${metas[0].id}")
    }

    return [ metas[0], fastqs ]
}
//
// Get attribute from genome config file e.g. fasta
//
def getGenomeAttribute(attribute) {
    if (params.genomes && params.genome && params.genomes.containsKey(params.genome)) {
        if (params.genomes[ params.genome ].containsKey(attribute)) {
            return params.genomes[ params.genome ][ attribute ]
        }
    }
    return null
}

//
// Exit pipeline if incorrect --genome key provided
//
def genomeExistsError() {
    if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
            "  Currently, the available genome keys are:\n" +
            "  ${params.genomes.keySet().join(", ")}\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}
//
// Generate methods description for MultiQC
//
def toolCitationText() {
    // TODO nf-core: Optionally add in-text citation tools to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "Tool (Foo et al. 2023)" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
    def citation_text = [
            "Tools used in the workflow included:",
            "IDM (Hashemi M, Schneider KA (2024)),",
            "MultiLocusBiallelicModel (Tsoungui Obama and Schneider 2022)",
            "PGEcore (PlasmoGenEpi)",
            "."
        ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    // TODO nf-core: Optionally add bibliographic entries to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "<li>Author (2023) Pub name, Journal, DOI</li>" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
    def reference_text = [
            "<li>Andrews S, (2010) FastQC, URL: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).</li>",
            "<li>Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics , 32(19), 3047–3048. doi: /10.1093/bioinformatics/btw354</li>"
        ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    } else meta["doi_text"] = ""
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = ""
    meta["tool_bibliography"] = ""

    // TODO nf-core: Only uncomment below if logic in toolCitationText/toolBibliographyText has been filled!
    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}

