/*
 * STEP - ESTIMATE_COI_NAIVE
 * Estimate COI naively by integer or quantile method
 */

process ESTIMATE_COI_NAIVE {

    label 'process_single'

    def output_filename = "coi_table.tsv"

    input:
    path allele_table
    val method
    val threshold

    output:
    path "${output_filename}", emit: coi_table

    script:

    // Set parameters based on the method
    def parameter_string = method == "integer_method"
        ? "--integer_threshold $threshold"
        : "--quantile_threshold $threshold"

    // Validate method and threshold combo
    if ((method == "integer_method") && (!(threshold instanceof Integer) || (threshold < 0))) {
            throw new IllegalArgumentException("Error: For 'integer_method', 'threshold' must be a positive integer. Provided value: ${threshold}.")
    } else if ((method == "quantile_method") && !(threshold >= 0.0 && threshold <= 1.0)) {
            throw new IllegalArgumentException("Error: For 'quantile_method', 'threshold' must be a Double between 0 and 1. Provided value: ${threshold}.")
    } else if (!(method in ["integer_method", "quantile_method"])) {
        throw new IllegalArgumentException("Error: 'method' must be either 'integer_method' or 'quantile_method'. Provided value: ${method}.")
    }

    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \\
        --input_path $allele_table \\
        --output_path $output_filename \\
        --method $method $parameter_string
    """
}
