#!/usr/bin/env Rscript

# Load required libraries
suppressMessages(library(optparse))
suppressMessages(library(dplyr))
suppressMessages(library(readr))

# Define options
opts <- list(
    make_option(
        c("-f", "--freq_table"),
        help = "TSV of frequencies to be merged",
        type = "character"
    ),
    make_option(
        c("-p", "--prev_table"),
        help = "TSV of prevalence to be merged",
        type = "character"
    ),
    make_option(
        c("--population"),
        help = "Name of population",
        type = "character"
    ),
    make_option(
        c("-o", "--output"),
        help = "Output file name. Default: %default",
        type = "character",
        default = "sl_summary.tsv"
    )
)

# Parse command-line arguments
parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

# Validate input files
if (!file.exists(args$freq_table)) stop(paste(args$freq_table, "does not exist"))
if (!file.exists(args$prev_table)) stop(paste(args$prev_table, "does not exist"))

# # NEW
# # Extract population from file name (before first '.')
# get_population <- function(filename) {
#     basename(filename) %>%
#         str_split("\\.", simplify = TRUE) %>%
#         .[1]
# }

# Function to load frequency table
load_freq_table <- function(freq) {
    freq_table <- read_tsv(
        freq,
        col_types = cols(
            variant = col_character(),
            freq = col_double()
        )
    )
    return(freq_table)
}

# Function to load prevalence table
load_prev_table <- function(prev) {
    prev_table <- read_tsv(
        prev,
        col_types = cols(
            variant = col_character(),
            prev = col_double()
        )
    )
    return(prev_table)
}

# Function to merge tables
merge_tables_add_pop <- function(freq_table, prev_table, pop) {
    merged_table <- full_join(prev_table, freq_table, by = "variant") %>%
        mutate(population = pop) %>%
        select(population, everything())
    return(merged_table)
}

# Load input data
freq_table <- load_freq_table(args$freq_table)
# rename sample_total from freq_table if present (in some methods, like dcifer_mhaps it will output sample total with the allele freqs)
if("sample_total" %in% colnames(freq_table)){
    freq_table = freq_table %>%
    dplyr::rename(sample_total_for_allele_freq = sample_total)
}
prev_table <- load_prev_table(args$prev_table)

# Merge tables
merged_table <- merge_tables_add_pop(freq_table, prev_table, args$population)

# Save output
write_tsv(merged_table, args$output)
