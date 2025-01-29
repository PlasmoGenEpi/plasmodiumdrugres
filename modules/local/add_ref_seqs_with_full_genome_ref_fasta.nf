/*
 * STEP - ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA
 * add a column with the ref sequence pulled from a genome file using the coordinates of the bed file
 */

process ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA {

    label 'process_single'

    def output_fnp = "ref_bed_with_seqs.bed"

    input:
    path ref_bed
    path genome

    output:
    path ("${output_fnp}"), emit: ref_bed_with_seqs

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_full_genome_ref_fasta.R \
        --genome ${genome} \
        --ref_bed ${ref_bed} \
        --out ${output_fnp}
    """
}
