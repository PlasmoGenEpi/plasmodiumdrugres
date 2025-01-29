//
// Generate reference bed file depending on input params
//

include { EXTRACT_PANEL_INFO_TO_BED } from '../../../modules/local/extract_panel_info_to_bed'
include { ADD_REF_SEQS_WITH_TARGETED_REF_FASTA } from '../../../modules/local/add_ref_seqs_with_targeted_ref_fasta'
include { ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA } from '../../../modules/local/add_ref_seqs_with_full_genome_ref_fasta'

workflow GENERATE_REFERENCE_BED_FILE {
    take: 
    pmo
    ref_type
    fasta 

    main:

    EXTRACT_PANEL_INFO_TO_BED(pmo, ref_type == "none" ? "TRUE" : "FALSE")

    if (ref_type == "targeted_reference") {
        // generate bed file and add to it using add_ref_seqs_with_fasta.nf
        ADD_REF_SEQS_WITH_TARGETED_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
        panel_info_bed = ADD_REF_SEQS_WITH_TARGETED_REF_FASTA.out.ref_bed_with_seqs
    } else if (ref_type == "genome_reference") {
        // generate bed file and add to it using add add_ref_seqs_with_genome.nf
        ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
        panel_info_bed = ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA.out.ref_bed_with_seqs
    } else {
        // generate bed file extracting from pmo at the same time
        panel_info_bed = EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed
    }

    // TODO: test this way instead 
    // switch (ref_type) {
    //     case "targeted_reference":
    //         ADD_REF_SEQS_WITH_TARGETED_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
    //         panel_info_bed = ADD_REF_SEQS_WITH_TARGETED_REF_FASTA.out.ref_bed_with_seqs
    //         break
    //     case "genome_reference":
    //         ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
    //         panel_info_bed = ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA.out.ref_bed_with_seqs
    //         break
    //     default:
    //         panel_info_bed = EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed
    // }

    emit:
    panel_info_bed = panel_info_bed
}