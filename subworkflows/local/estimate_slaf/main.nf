//
// Estimate single locus allele frequency using choice of tool/method
//

include { SLAF_FROM_STAVE_MLAF } from '../../../modules/local/slaf_from_stave_mlaf'
include { IDM_WRAPPER } from '../../../modules/local/idm_wrapper'
include { ESTIMATE_ALLELE_FREQUENCY_NAIVE } from '../../../modules/local/estimate_allele_frequency_naive'

workflow ESTIMATE_SLAF {

    take:
    method
    method_input

    main:
    if (method == "IDM") {
        IDM_WRAPPER(method_input)
        slaf_output = IDM_WRAPPER.out.slaf
    } else if (method == "naive") {
        ESTIMATE_ALLELE_FREQUENCY_NAIVE(method_input, params.naive_slaf_method)
        slaf_output = ESTIMATE_ALLELE_FREQUENCY_NAIVE.out.slaf
    } else if (method == "from_mlaf") {
        SLAF_FROM_STAVE_MLAF(method_input)
        slaf_output = SLAF_FROM_STAVE_MLAF.out.slaf
    } else {
        throw new IllegalArgumentException("Error: 'slaf_method' must be one of ${params.slaf_method_options} Provided value: ${method}.")
    }

    emit:
    slaf_output = slaf_output
}
