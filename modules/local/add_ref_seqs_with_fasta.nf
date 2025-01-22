/*
 * STEP - ADD_REF_SEQS_WITH_FASTA
 * add a column with the ref sequence pulled from a fasta file
 */

process ADD_REF_SEQS_WITH_FASTA {

    label 'process_single'

    def output_fnp = "ref_bed_with_seqs.bed"

    input:
    path ref_bed
    path fasta

    output:
    path ("${output_fnp}"), emit: ref_bed_with_seqs

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_fasta.R \
        --fasta ${fasta} \
        --ref_bed ${ref_bed} \
        --out ${output_fnp}
    """
}
