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
    switch (ref_type) {
        case "targeted_reference":
            ADD_REF_SEQS_WITH_TARGETED_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
            panel_info_bed = ADD_REF_SEQS_WITH_TARGETED_REF_FASTA.out.ref_bed_with_seqs
            break
        case "genome_reference":
            ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
            panel_info_bed = ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA.out.ref_bed_with_seqs
            break
        default:
            panel_info_bed = EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed
    }

    emit:
    panel_info_bed = panel_info_bed
}