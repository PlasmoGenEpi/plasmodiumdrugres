//
// Estimate multi locus allele frequencies using choice of tool/method
//

include { MLBM_WRAPPER } from './modules/local/mlbm_wrapper'

workflow ESTIMATE_MLAF {

    take: 
    method
    amino_acid_calls
    loci_groups

    main:
    // TODO: add naive method (estimate_multilocus_prevfreq_naive) when groups are added in 
    // TODO: These estimates should also include prev output
    if (method == "MLBM") {
        MLBM_WRAPPER(amino_acid_calls, loci_groups)
        mlaf_output = MLBM_WRAPPER.out.mlaf
    } else {
        throw new IllegalArgumentException("Error: 'mlaf_method' must be one of ${params.mlaf_method_options} Provided value: ${method}.")
    }

    emit:
    mlaf_output = mlaf_output
}