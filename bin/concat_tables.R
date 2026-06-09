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
  make_option(
    c("--raw-out-dir"),
    type = "character",
    default = "raw_summaries",
    help = "Directory for concatenated summary tables before column standardization"
  )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

SL_SUMMARY_COLS <- c("population", "variant", "prev", "sample_count", "sample_total", "freq")

ML_SUMMARY_REQUIRED_COLS <- c("population", "group_id", "variant")
ML_SUMMARY_OPTIONAL_COLS <- c("prev", "sample_count", "sample_total")
ML_SUMMARY_FREQ_COL <- "freq"

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

standardize_sl_summary <- function(df) {
  missing <- setdiff(SL_SUMMARY_COLS, colnames(df))
  if (length(missing) > 0) {
    stop(
      "sl_summary missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  df %>% select(all_of(SL_SUMMARY_COLS))
}

standardize_ml_summary <- function(df) {
  missing <- setdiff(ML_SUMMARY_REQUIRED_COLS, colnames(df))
  if (length(missing) > 0) {
    stop(
      "ml_summary missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  if (!ML_SUMMARY_FREQ_COL %in% colnames(df)) {
    stop("ml_summary missing required column: ", ML_SUMMARY_FREQ_COL)
  }

  optional_present <- ML_SUMMARY_OPTIONAL_COLS[
    ML_SUMMARY_OPTIONAL_COLS %in% colnames(df)
  ]
  cols <- c(ML_SUMMARY_REQUIRED_COLS, optional_present, ML_SUMMARY_FREQ_COL)
  df %>% select(all_of(cols))
}

maybe_sort <- function(df, sort_cols = c("population", "variant")) {
  # Sort to ensure deterministic output across runs.
  if (all(sort_cols %in% colnames(df))) {
    return(df %>% arrange(across(all_of(sort_cols))))
  }
  return(df)
}

sl_files <- split_files(args$`sl-files`)
ml_files <- split_files(args$`ml-files`)
sl_from_ml_files <- split_files(args$`sl-from-ml-files`)

sl_concat <- files_to_df(sl_files) %>% maybe_sort()
ml_concat <- files_to_df(ml_files) %>%
  maybe_sort(c("population", "group_id", "variant"))
sl_from_ml_concat <- maybe_sort(files_to_df(sl_from_ml_files))

dir.create(args$`raw-out-dir`, showWarnings = FALSE, recursive = TRUE)
write_tsv(sl_concat, file.path(args$`raw-out-dir`, "raw_sl_summary.tsv"))
write_tsv(ml_concat, file.path(args$`raw-out-dir`, "raw_ml_summary.tsv"))
write_tsv(
  sl_from_ml_concat,
  file.path(args$`raw-out-dir`, "raw_sl_from_ml_summary.tsv")
)

sl_df <- sl_concat %>% standardize_sl_summary()
ml_df <- ml_concat %>% standardize_ml_summary()

write_tsv(sl_df, args$`sl-out`)
write_tsv(ml_df, args$`ml-out`)
