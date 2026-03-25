#!/usr/bin/env Rscript

# Concatenate per-population summary TSVs deterministically.

suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(dplyr))

opts <- list(
  make_option(c("--sl-files"), type = "character", help = "Comma-separated list of sl_summary TSVs"),
  make_option(c("--ml-files"), type = "character", help = "Comma-separated list of ml_summary TSVs"),
  make_option(c("--sl-from-ml-files"), type = "character", help = "Comma-separated list of sl_from_ml_summary TSVs"),
  make_option(c("--sl-out"), type = "character", default = "sl_summary.tsv"),
  make_option(c("--ml-out"), type = "character", default = "ml_summary.tsv"),
  make_option(c("--sl-from-ml-out"), type = "character", default = "sl_from_ml_summary.tsv")
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

split_files <- function(x) {
  if (is.null(x) || is.na(x) || x == "") return(character(0))
  parts <- strsplit(x, ",", fixed = TRUE)[[1]]
  parts <- parts[parts != ""]
  return(parts)
}

files_to_df <- function(files) {
  # Keep column types stable-ish; most columns are numeric but we mostly sort on strings.
  dfs <- lapply(files, function(f) {
    stopifnot(file.exists(f))
    read_tsv(f, show_col_types = FALSE)
  })
  bind_rows(dfs)
}

maybe_sort <- function(df) {
  # Sort to ensure deterministic output across runs.
  if (all(c("population", "variant") %in% colnames(df))) {
    return(df %>% arrange(.data$population, .data$variant))
  }
  return(df)
}

sl_files <- split_files(args$`sl-files`)
ml_files <- split_files(args$`ml-files`)
sl_from_ml_files <- split_files(args$`sl-from-ml-files`)

sl_df <- maybe_sort(files_to_df(sl_files))
ml_df <- maybe_sort(files_to_df(ml_files))
sl_from_ml_df <- maybe_sort(files_to_df(sl_from_ml_files))

write_tsv(sl_df, args$`sl-out`)
write_tsv(ml_df, args$`ml-out`)
write_tsv(sl_from_ml_df, args$`sl-from-ml-out`)

