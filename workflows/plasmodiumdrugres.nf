/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// include { paramsSummaryMap } from 'plugin/nf-schema'
// include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
// include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
// include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline'

include { TRANSLATE_LOCI_OF_INTEREST } from '../modules/local/translate_loci_of_interest'
include { SPLIT_AA_TABLE_BY_POP } from '../modules/local/split_aa_table_by_population'
include { SPLIT_ALLELE_TABLE_BY_POP } from '../modules/local/split_allele_table_by_population'
include { DCIFER_SLAF_WRAPPER } from '../modules/local/dcifer_slaf_wrapper'
include { SLAF_FROM_MHAPS_FREQS } from '../modules/local/slaf_from_mhaps_freqs'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from '../modules/local/estimate_allele_prevalence_naive'
include { ESTIMATE_MLAF } from '../subworkflows/local/estimate_mlaf'
include { ESTIMATE_SLAF } from '../subworkflows/local/estimate_slaf'
include { MERGE_TABLES } from '../modules/local/merge_tables'
include { CONCAT_TABLES } from '../modules/local/concat_tables'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



workflow PLASMODIUMDRUGRES {
    take:
    allele_table
    panel_info_bed_with_ref
    loci_of_interest_bed
    translate_loci_extra_args
    mlaf_method
    loci_groups
    slaf_method

    main:

    TRANSLATE_LOCI_OF_INTEREST(file(allele_table.value), file(panel_info_bed_with_ref.value), file(loci_of_interest_bed), translate_loci_extra_args)

    // split amino acid table
    if (params.population_map) {
        SPLIT_AA_TABLE_BY_POP(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls, file(params.population_map))
        aa_table_ch = (SPLIT_AA_TABLE_BY_POP.out.per_pop_tables).flatten()
    } else {
        aa_table_ch = TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls
    }

    // Estimate Single Locus Allele Prevalence
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(aa_table_ch)

    // Estimate Multi Loci Allele Frequency
    ESTIMATE_MLAF(mlaf_method, aa_table_ch, file(loci_groups))

    // Estimate Single Locus Allele Frequency
    if("mhaps_freq" == slaf_method){
        // split allele table
        if (params.population_map) {
            SPLIT_ALLELE_TABLE_BY_POP(file(allele_table.value), file(params.population_map))
            allele_table_ch = (SPLIT_ALLELE_TABLE_BY_POP.out.per_pop_tables).flatten()
        } else {
            allele_table_ch = channel.fromPath(file(allele_table.value))
        }
        DCIFER_SLAF_WRAPPER(allele_table_ch)
        SLAF_FROM_MHAPS_FREQS(DCIFER_SLAF_WRAPPER.out.mhaps_slaf, TRANSLATE_LOCI_OF_INTEREST.out.loci_of_interest_for_target_for_microhap)
        if (params.population_map) {
            slaf_ouput = SLAF_FROM_MHAPS_FREQS.out.slaf
        } else {
            //rename so has the same name as the other methods 
            slaf_ouput = SLAF_FROM_MHAPS_FREQS.out.slaf.map { tuple ->
                tuple[0] = "collapsed_amino_acid_calls"
                return tuple
            }
        }

    } else {
        ESTIMATE_SLAF(slaf_method, aa_table_ch)
        slaf_ouput = ESTIMATE_SLAF.out.slaf_output
    }

    // Create tuple of output files by population
    all_outputs = ESTIMATE_ALLELE_PREVALENCE_NAIVE.out.allele_prevalence.mix(
        ESTIMATE_MLAF.out.mlaf_output,
        ESTIMATE_MLAF.out.sl_from_ml_output,
        slaf_ouput)
    outputs_per_population = all_outputs.groupTuple()

    // OUTPUT
    // TODO: sort out mlaf and the prevelances
    if (params.population_map) {
        MERGE_TABLES(outputs_per_population)
    } else {
        updated_ch = outputs_per_population.map { tuple ->
            tuple[0] = params.population_label   // replace first element
            return tuple
        }
        MERGE_TABLES(updated_ch)
    }

    all_sl_summary_ch = MERGE_TABLES.out.sl_summary.collect()
    all_ml_summary_ch = MERGE_TABLES.out.ml_summary.collect()
    all_sl_from_ml_summary_ch = MERGE_TABLES.out.sl_from_ml_summary.collect()

    CONCAT_TABLES(all_sl_summary_ch, all_ml_summary_ch, all_sl_from_ml_summary_ch)
    // // //
    // // Collate and save software versions
    // //
    // // softwareVersionsToYAML(ch_versions)
    // //     .collectFile(
    // //         storeDir: "${params.outdir}/pipeline_info",
    // //         name: 'nf_core_' + 'pipeline_software_' + 'mqc_' + 'versions.yml',
    // //         sort: true,
    // //         newLine: true,
    // //     )
    // //     .set { ch_collated_versions }

    emit:
    sl_summary = CONCAT_TABLES.out.sl_summary
    ml_summary = CONCAT_TABLES.out.ml_summary
    sl_from_ml_summary = CONCAT_TABLES.out.sl_from_ml_summary
    // // versions = ch_versions // channel: [ path(versions.yml) ]
}
