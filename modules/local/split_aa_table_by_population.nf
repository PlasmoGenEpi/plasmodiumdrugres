/*
 * STEP - SPLIT_AA_TABLE_BY_POP
 * Split amino acid tables into seperate populations based on specimen_id
 */

// TODO: update this to work off of column names 
process SPLIT_AA_TABLE_BY_POP {
    label 'process_single'
    
    input:
    path allele_table
    path population_map

    output:
    path "*.collapsed_amino_acid_calls.tsv.gz", emit: per_pop_tables
    path "unmapped_specimens.txt", optional: true, emit: unmapped_report

    script:
    """
    set -euo pipefail

    # Split the big allele table into one TSV per population.
    # Assumes tab-delimited input with header and first column = specimen_id.
    # population_map: header 'specimen_id\\tpopulation'
    gzip -d < "${allele_table}" > "collapsed_amino_acid_calls.tsv"
    awk 'BEGIN{FS=OFS="\\t"}
         NR==FNR { if(NR>1){ pop[\$1]=\$2 } ; next }    # read mapping
         FNR==1 { header=\$0; next }                    # save header of allele table
         {
           s=\$1; p=pop[s]
           if(p==""){ print s > "unmapped_specimens.txt"; next }
           f = p ".collapsed_amino_acid_calls.tsv"
           if(!(p in seen)){ print header > f; seen[p]=1 }
           print >> f
         }' "${population_map}" "collapsed_amino_acid_calls.tsv"
    
    for f in *.collapsed_amino_acid_calls.tsv; do
        gzip -f "\$f"
    done

    rm -f "collapsed_amino_acid_calls.tsv"
    """
}
