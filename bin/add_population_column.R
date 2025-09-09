#!/usr/bin/env Rscript

# Load required libraries
suppressMessages(library(optparse))
suppressMessages(library(dplyr))
suppressMessages(library(readr))

# Define options
opts <- list(
    make_option(
        c("-f", "--table"),
        help = "TSV of frequencies to be merged",
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
if (!file.exists(args$table)) stop(paste(args$table, "does not exist"))

# Function to load frequency table
load_table <- function(table) {
    tbl <- read_tsv(
        table,
        col_types = cols(
            group_id = col_character(),
            variant = col_character(),
            freq = col_double()
        )
    )
    return(tbl)
}

# Function to merge tables
add_pop <- function(table, pop) {
    table$population <- pop
    # TODO: reorder columns so pop comes first
    return(table)
}

# Load input data
table <- load_table(args$table)

# Merge tables
table_with_pop <- add_pop(table, args$population)

# Save output
write_tsv(table_with_pop, args$output)
