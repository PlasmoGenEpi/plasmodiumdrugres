/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

// TODO: handle coi
process FEM_WRAPPER {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/bc/bc03a3feb106dd1a29e88a302f4b1606164b9801b0470a3ef29968cf03f42700/data'
:         'community.wave.seqera.io/library/fem_wrapper:c635184d8a5a3158' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    FreqEstimationModel_wrapper \\
        --aa_calls ${aa_calls} \\
        --loci_groups ${loci_group_table} \\
        --coi 3 \\
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        freqestimationmodel: \$( Rscript -e 'cat(as.character(packageVersion("FreqEstimationModel")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
