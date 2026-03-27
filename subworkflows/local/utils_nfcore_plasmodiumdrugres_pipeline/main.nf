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
include { paramsHelp                } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification            } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { EXTRACT_ALLELE_TABLE      } from '../../../modules/local/extract_allele_table'
include { EXTRACT_BED_FILE_FROM_PMO } from '../../../subworkflows/local/generate_reference_bed_file'
include { EXTRACT_POPULATION_MAP_FROM_PMO } from '../../../modules/local/extract_population_map_from_pmo'

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
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:

    ch_versions = channel.empty()

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
    before_text = """
-\033[2m----------------------------------------------------\033[0m-
                                        \033[0;32m,--.\033[0;30m/\033[0;32m,-.\033[0m
\033[0;34m        ___     __   __   __   ___     \033[0;32m/,-._.--~\'\033[0m
\033[0;34m  |\\ | |__  __ /  ` /  \\ |__) |__         \033[0;33m}  {\033[0m
\033[0;34m  | \\| |       \\__, \\__/ |  \\ |___     \033[0;32m\\`-._,-`-,\033[0m
                                        \033[0;32m`._,._,\'\033[0m
\033[0;35m  nf-core/plasmodiumdrugres ${workflow.manifest.version}\033[0m
-\033[2m----------------------------------------------------\033[0m-
"""
    after_text = """${workflow.manifest.doi ? "\n* The pipeline\n" : ""}${workflow.manifest.doi.tokenize(",").collect { doi -> "    https://doi.org/${doi.trim().replace('https://doi.org/','')}"}.join("\n")}${workflow.manifest.doi ? "\n" : ""}
* The nf-core framework
    https://doi.org/10.1038/s41587-020-0439-x

* Software dependencies
    https://github.com/nf-core/plasmodiumdrugres/blob/master/CITATIONS.md
"""
    command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute> --input samplesheet.csv --outdir <OUTDIR>"

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command
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
    // Normalise PMO population fields:
    // - user provides comma-separated list, e.g. "collection_country, collection_date"
    // - python expects space-separated args for argparse `nargs='+'`.
    def pmo_population_fields_norm = null
    if (params.pmo_population_fields) {
        def raw = params.pmo_population_fields
        def fields = []
        if (raw instanceof List) {
            fields = raw.collect { it?.toString() ?: '' }
        } else {
            fields = raw.toString().split(',') as List
        }
        fields = fields.collect { it.trim() }.findAll { it }
        // Join with spaces so the shell splits into multiple `--fields` arguments.
        pmo_population_fields_norm = fields.join(' ')
    }
    // Initialise channels for all branches to avoid unbound variables
    // Note: avoid `def` here so Nextflow can statically detect these
    // variables for the `emit:` block.
    allele_table_ch = Channel.empty()
    panel_info_bed_ch = Channel.empty()
    population_assignment_ch = null
    if (params.pmo) {
        def pmo_ch = Channel.fromPath(params.pmo, checkIfExists: true)
        EXTRACT_ALLELE_TABLE(pmo_ch)
        allele_table_ch = EXTRACT_ALLELE_TABLE.out.allele_table
        EXTRACT_BED_FILE_FROM_PMO(pmo_ch, ref_type, fasta)
        panel_info_bed_ch = EXTRACT_BED_FILE_FROM_PMO.out.panel_info_bed
        if (params.population_assignment) {
            population_assignment_ch = Channel.fromPath(params.population_assignment, checkIfExists: true)
        } else if (pmo_population_fields_norm) {
            EXTRACT_POPULATION_MAP_FROM_PMO(pmo_ch, pmo_population_fields_norm, params.pmo_population_separator)
            population_assignment_ch = EXTRACT_POPULATION_MAP_FROM_PMO.out.population_map
        }
    } else if (params.allele_table) {
        allele_table_ch = Channel.fromPath(params.allele_table, checkIfExists: true)
        panel_info_bed_ch = Channel.fromPath(params.panel_info_bed, checkIfExists: true)
        if (params.population_assignment) {
            population_assignment_ch = Channel.fromPath(params.population_assignment, checkIfExists: true)
        }
    }

    emit:
    allele_table_ch    = allele_table_ch
    panel_info_bed_ch  = panel_info_bed_ch
    population_assignment_ch  = population_assignment_ch
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
    def multiqc_reports = multiqc_report.toList()

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
                multiqc_reports.getVal(),
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
    if (params.pmo_population_fields && params.population_assignment) {
        validation_warnings.add("WARNING: Both 'pmo_population_fields' and 'population_assignment' set, 'population_assignment' will be used.")
    }
    if (params.pmo) {
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
        if (params.pmo_population_fields) {
            validation_warnings.add("WARNING: 'pmo_population_fields' set with '--allele_table'. '--pmo_population_fields' is only used for PMO input and will be ignored.")
        }
    } else {
        validation_errors.add("Missing required parameter: Either '--pmo' or '--allele_table' must be set, but neither were.")
    }

    // Warn if both population_assignment and population_label is set
    if ((params.population_assignment) && (params.population_label!='pop1')) {
        validation_warnings.add("WARNING: both '--population_assignment' and --'population_label' set. '--population_assignment' will be used.")
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
    def citations = ["Tools used in the workflow included:"]
    if (params.slaf_method == "IDM") {
        citations << "IDM (Hashemi M, Schneider KA 2024)"
    }
    if (params.mlaf_method == "MLBM") {
        citations << "MultiLocusBiallelicModel (Tsoungui Obama and Schneider 2022)"
    }
    if (params.mlaf_method == "FEM") {
        citations << "FreqEstimationModel (Taylor et al. 2014)"
    }
    if (params.slaf_method == "mhaps_freq" && params.slaf_method_mhaps_freq_method == "dcifer") {
        citations << "Dcifer (Gerlovina et al. 2022)"
    }
    citations << "PGEcore (PlasmoGenEpi)"
    return citations.join(", ") + "."
}

def toolBibliographyText() {
    def refs = []
    if (params.slaf_method == "IDM") {
        refs << "<li>Hashemi M, Schneider KA (2024) Estimating multiplicity of infection, allele frequencies, and prevalences accounting for incomplete data. PLoS ONE 19(3): e0287161. doi: <a href='https://doi.org/10.1371/journal.pone.0287161'>10.1371/journal.pone.0287161</a></li>"
    }
    if (params.mlaf_method == "MLBM") {
        refs << "<li>Tsoungui Obama HCJ, Schneider KA (2022) A Maximum-Likelihood Method to Estimate Haplotype Frequencies and Prevalence Alongside Multiplicity of Infection from SNP Data. Frontiers in Epidemiology 2. <a href='https://www.frontiersin.org/articles/10.3389/fepid.2022.943625/full'>10.3389/fepid.2022.943625</a></li>"
    }
    if (params.mlaf_method == "FEM") {
        refs << "<li>Taylor AR, Flegg JA, Nsobya SL et al. (2014) Estimation of malaria haplotype and genotype frequencies: a statistical approach to overcome the challenge associated with multiclonal infections. Malar J 13, 102. doi: <a href='https://doi.org/10.1186/1475-2875-13-102'>10.1186/1475-2875-13-102</a></li>"
    }
    if (params.slaf_method == "mhaps_freq" && params.slaf_method_mhaps_freq_method == "dcifer") {
        refs << "<li>Gerlovina I, Gerlovin B, Rodríguez-Barraquer I, Greenhouse B (2022) Dcifer: an IBD-based method to calculate genetic distance between polyclonal infections. Genetics 222(2). doi: <a href='https://doi.org/10.1093/genetics/iyac126'>10.1093/genetics/iyac126</a></li>"
    }
    refs << "<li>PGEcore: <a href='https://github.com/PlasmoGenEpi/PGEcore'>https://github.com/PlasmoGenEpi/PGEcore</a></li>"
    refs << "<li>Ewels P, Magnusson M, Lundin S, Käller M (2016) MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics 32(19), 3047–3048. doi: <a href='https://doi.org/10.1093/bioinformatics/btw354'>10.1093/bioinformatics/btw354</a></li>"
    return refs.join(" ")
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familiar NXF ${workflow} variable syntax in the MultiQC YML file
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
    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
