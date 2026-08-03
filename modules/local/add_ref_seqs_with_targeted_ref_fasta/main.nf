/*
 * STEP - ADD_REF_SEQS_WITH_TARGETED_REF_FASTA
 * add a column with the ref sequence pulled from a fasta file
 */

process ADD_REF_SEQS_WITH_TARGETED_REF_FASTA {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fb/fb139463543e2cfb7a14e54c85858a6e40e211d735dab9438ad3b737de28f133/data'
:         'community.wave.seqera.io/library/bioc_biostrings:859138378410587f' }"

    input:
    path ref_bed
    path fasta

    output:
    path ("ref_bed_with_seqs.bed"), emit: ref_bed_with_seqs
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_targeted_ref_fasta.R \
        --target_fasta ${fasta} \
        --ref_bed ${ref_bed} \
        --out ref_bed_with_seqs.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        bioconductor-biostrings: \$( Rscript -e 'cat(as.character(packageVersion("Biostrings")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
