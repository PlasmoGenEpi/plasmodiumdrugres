/*
 * STEP - DCIFER_WRAPPER
 * Run the Dcifer allele frequency wrapper script
 */

process DCIFER_SLAF_WRAPPER {

    label 'process_low'


    input:
    path allele_table

    output:
    tuple val("${allele_table.getBaseName(3)}"), path("${allele_table.getBaseName(3)}.mhaps_slaf.tsv"), emit: mhaps_slaf

    script:
    def extra_args = task.ext.args ? task.ext.args : ''


    """
    Rscript ${projectDir}/bin/PGEcore/scripts/dcifer_slaf_wrapper/dcifer_slaf_wrapper.R \
        --allele_table ${allele_table}  \
        --slaf_output "${allele_table.getBaseName(3)}.mhaps_slaf.tsv" \
        ${extra_args}
    """
}

//@todo need to figure out a way to add an optional --coi_table data/example_coi_table.tsv
//the below defaults are handled by the parmas.dcifer_slaf_wraper_* arguments which then gets added to task.ext.args
//--coi_lrank 2
//--qstart 0.5
//--tol 0.0001
