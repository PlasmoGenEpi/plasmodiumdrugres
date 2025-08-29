//
// Estimate COI using choice of tool/method
//

include { ESTIMATE_COI_NAIVE } from '../../../modules/local/estimate_coi_naive'

// TODO: Add in moire module

workflow ESTIMATE_COI {

    take:
    method
    allele_table

    main:
    if (method == "NAIVE_INT_METHOD") {
        ESTIMATE_COI_NAIVE(allele_table, "integer_method", params.naive_coi_threshold)
        coi_output = ESTIMATE_COI_NAIVE.out.coi_table
    } else if (method == "NAIVE_QUANTILE_METHOD") {
        ESTIMATE_COI_NAIVE(allele_table, "quantile_method", params.naive_coi_threshold)
        coi_output = ESTIMATE_COI_NAIVE.out.coi_table
    } else {
        throw new IllegalArgumentException("Error: 'coi_method' must be one of ${params.coi_method_options} Provided value: ${method}.")
    }

    emit:
    coi_output = coi_output
}
