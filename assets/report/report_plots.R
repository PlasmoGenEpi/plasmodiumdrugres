# Plot helpers for the pipeline HTML report.
# Quality Control: locus coverage, coverage by population, unassigned specimens.
# Sanity Checks: SLAF vs SL-from-ML.
# Results: prevalence, stacked frequency, haplotype stacks.
# Locus labels are gene:aa_position from the loci-of-interest BED (via coverage / AA call tables),
# not the BED name column. Example: dhfr-ts:51.
# print_plot() renders Plotly or a PNG. Coverage-by-population uses native plot_ly when interactive.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tidyr)
  library(tibble)
})

AA_COLOURS <- c(
  A = "#1b9e77", C = "#d95f02", D = "#7570b3", E = "#e7298a",
  F = "#66a61e", G = "#e6ab02", H = "#a6761d",   I = "#2c7bb6",
  K = "#d7191c", L = "#abd9e9", M = "#fdae61", N = "#41ab5d",
  P = "#762a83", Q = "#1a9641", R = "#d73027", S = "#4575b4",
  T = "#313695", V = "#a6d96a", W = "#8c510a", Y = "#c51b7d",
  X = "#636363", `*` = "#252525", other = "#969696"
)

read_tsv_if_exists <- function(path) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(tibble())
  }
  info <- file.info(path)
  if (isTRUE(info$isdir)) {
    return(tibble())
  }
  out <- read_tsv(path, show_col_types = FALSE)
  if (nrow(out) == 0) {
    return(out)
  }
  out
}

parse_sl_variant <- function(variant) {
  parts <- strsplit(as.character(variant), ":", fixed = TRUE)
  tibble(
    variant = as.character(variant),
    gene_id = vapply(parts, function(p) {
      if (length(p) < 3) {
        return(NA_character_)
      }
      paste(p[seq_len(length(p) - 2L)], collapse = ":")
    }, character(1)),
    aa_position = vapply(parts, function(p) {
      if (length(p) < 3) {
        return(NA_character_)
      }
      p[length(p) - 1L]
    }, character(1)),
    aa = vapply(parts, function(p) {
      if (length(p) < 3) {
        return(NA_character_)
      }
      p[length(p)]
    }, character(1))
  )
}

missing_chr <- function(x) {
  x <- trimws(as.character(x))
  is.na(x) | !nzchar(x) | x %in% c("NA", "NaN", ".")
}

# gene:aa_position when gene is present; otherwise gene_id:aa_position.
locus_label <- function(gene, gene_id, aa_position) {
  gene <- as.character(gene)
  gene_id <- as.character(gene_id)
  aa_position <- as.character(aa_position)
  prefix <- ifelse(missing_chr(gene), gene_id, gene)
  ifelse(missing_chr(aa_position), prefix, paste0(prefix, ":", aa_position))
}

gene_name_for_id <- function(gene_id, gene_lookup = tibble()) {
  gene_id <- as.character(gene_id)
  if (nrow(gene_lookup) == 0 || !"gene_id" %in% names(gene_lookup)) {
    return(gene_id)
  }
  hit <- match(gene_id, as.character(gene_lookup$gene_id))
  gene <- if ("gene" %in% names(gene_lookup)) as.character(gene_lookup$gene)[hit] else NA_character_
  ifelse(is.na(hit) | missing_chr(gene), gene_id, gene)
}

collect_gene_lookup <- function(aa_calls = tibble(), coverage = tibble()) {
  rows <- list()
  take <- function(df) {
    if (nrow(df) == 0 || !"gene_id" %in% names(df)) {
      return(NULL)
    }
    tibble(
      gene_id = as.character(df$gene_id),
      gene = if ("gene" %in% names(df)) as.character(df$gene) else NA_character_
    )
  }
  rows <- c(rows, list(take(aa_calls), take(coverage)))
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) {
    return(tibble(gene_id = character(), gene = character()))
  }
  bind_rows(rows) %>%
    mutate(gene = ifelse(missing_chr(.data$gene), NA_character_, trimws(.data$gene))) %>%
    group_by(.data$gene_id) %>%
    summarise(
      gene = {
        x <- .data$gene[!is.na(.data$gene)]
        if (length(x)) x[[1]] else NA_character_
      },
      .groups = "drop"
    )
}

# Split a concatenated gene:pos:aa_gene:pos:aa string into gene:pos:aa blocks.
split_concat_haplotype_blocks <- function(variant) {
  remaining <- as.character(variant)
  blocks <- character()
  while (nzchar(remaining)) {
    colons <- gregexpr(":", remaining, fixed = TRUE)[[1]]
    if (length(colons) < 2 || identical(colons, -1L)) {
      blocks <- c(blocks, remaining)
      break
    }
    gene_pos <- substring(remaining, 1L, colons[2] - 1L)
    rest <- substring(remaining, colons[2] + 1L)
    pos <- 1L
    aa_chars <- character()
    while (pos <= nchar(rest)) {
      ch <- substring(rest, pos, pos)
      if (!grepl("^[A-Za-z*]$", ch)) {
        break
      }
      aa_chars <- c(aa_chars, ch)
      pos <- pos + 1L
      if (pos > nchar(rest) || substring(rest, pos, pos) != "_") {
        break
      }
      tok <- sub("[_:].*$", "", substring(rest, pos + 1L))
      if (nchar(tok) == 1L && grepl("^[A-Za-z*]$", tok)) {
        pos <- pos + 1L
      } else {
        break
      }
    }
    blocks <- c(blocks, paste0(gene_pos, ":", paste(aa_chars, collapse = "_")))
    remaining <- sub("^_", "", substring(rest, pos))
  }
  blocks
}

# Each block is list(gene_id, aa) with amino acids concatenated (NRN, not N_R_N).
parse_haplotype_blocks <- function(variant) {
  variant <- as.character(variant)
  raw_blocks <- if (grepl(";", variant, fixed = TRUE)) {
    strsplit(variant, ";", fixed = TRUE)[[1]]
  } else {
    split_concat_haplotype_blocks(variant)
  }
  lapply(raw_blocks, function(block) {
    parts <- strsplit(block, ":", fixed = TRUE)[[1]]
    if (length(parts) < 3) {
      return(list(gene_id = NA_character_, aa = gsub("_", "", sub("^.*:", "", block))))
    }
    list(
      gene_id = paste(parts[seq_len(length(parts) - 2L)], collapse = ":"),
      aa = gsub("_", "", parts[length(parts)])
    )
  })
}

# Legend text: "dhfr: NRN; dhps: A". Falls back to gene_id when gene is missing.
haplotype_label <- function(variant, gene_lookup = tibble(), max_chars = 80) {
  vapply(as.character(variant), function(v) {
    blocks <- parse_haplotype_blocks(v)
    pieces <- character()
    current_gene <- NULL
    current_aa <- ""
    for (b in blocks) {
      if (!identical(b$gene_id, current_gene)) {
        if (!is.null(current_gene)) {
          pieces <- c(pieces, paste0(gene_name_for_id(current_gene, gene_lookup), ": ", current_aa))
        }
        current_gene <- b$gene_id
        current_aa <- b$aa
      } else {
        current_aa <- paste0(current_aa, b$aa)
      }
    }
    if (!is.null(current_gene)) {
      pieces <- c(pieces, paste0(gene_name_for_id(current_gene, gene_lookup), ": ", current_aa))
    }
    out <- paste(pieces, collapse = "; ")
    if (nchar(out) > max_chars) paste0(substr(out, 1L, max_chars), "...") else out
  }, character(1), USE.NAMES = FALSE)
}

empty_plot <- function(message) {
  ggplot() +
    annotate("text", x = 0, y = 0, label = message, size = 4) +
    theme_void()
}

theme_report <- function(rotate_x = TRUE) {
  theme_bw(base_size = 12) +
    theme(
      axis.text.x = element_text(
        angle = if (isTRUE(rotate_x)) 45 else 0,
        hjust = if (isTRUE(rotate_x)) 1 else 0.5,
        vjust = 1
      ),
      axis.title.x = element_text(margin = margin(t = 6)),
      axis.title.y = element_text(margin = margin(r = 10)),
      legend.position = "bottom",
      strip.background = element_rect(fill = "grey95"),
      plot.margin = margin(8, 12, 12, 8)
    )
}

freq_y_scale <- function(stacked = FALSE) {
  scale_y_continuous(
    breaks = seq(0, 1, 0.25),
    labels = function(x) format(x, nsmall = 2, trim = TRUE),
    limits = c(0, 1),
    expand = if (isTRUE(stacked)) c(0, 0) else c(0, 0.02)
  )
}

aa_fill_scale <- function(aas) {
  aas <- unique(as.character(aas))
  values <- AA_COLOURS[aas]
  missing <- is.na(values)
  if (any(missing)) {
    extra <- grDevices::hcl(
      h = seq(15, 375, length.out = sum(missing) + 1L)[seq_len(sum(missing))],
      c = 80,
      l = 55
    )
    names(extra) <- aas[missing]
    values[missing] <- extra
  }
  names(values) <- aas
  scale_fill_manual(values = values, drop = FALSE)
}

shared_x_across_groups <- function(df, group_col, x_col) {
  if (nrow(df) == 0 || !all(c(group_col, x_col) %in% names(df))) {
    return(TRUE)
  }
  sets <- split(as.character(df[[x_col]]), df[[group_col]])
  sets <- lapply(sets, function(x) sort(unique(x)))
  length(unique(sets)) <= 1
}

style_plotly_axes <- function(gp, equal_axes = FALSE, rotate_x = TRUE, hovermode = "x", xlab = NULL, ylab = NULL) {
  lay <- gp$x$layout
  if (is.null(lay)) {
    lay <- list()
  }
  lay$hovermode <- hovermode
  default_margin <- list(b = if (isTRUE(rotate_x)) 90 else 60, t = 70, l = 90, r = 30)
  if (is.null(lay$margin)) {
    lay$margin <- default_margin
  } else {
    for (k in names(default_margin)) {
      if (is.null(lay$margin[[k]])) {
        lay$margin[[k]] <- default_margin[[k]]
      }
    }
  }
  x_standoff <- if (isTRUE(rotate_x)) 24 else 12
  for (nm in names(lay)) {
    if (grepl("^(xaxis|yaxis)", nm) && is.list(lay[[nm]]) && isTRUE(identical(lay[[nm]]$visible, FALSE))) {
      next
    }
    if (grepl("^xaxis", nm)) {
      if (!identical(lay[[nm]]$constrain, "domain")) {
        lay[[nm]]$automargin <- TRUE
      }
      lay[[nm]]$tickangle <- if (isTRUE(rotate_x) && !isTRUE(equal_axes)) -45 else 0
      title <- lay[[nm]]$title
      if (is.null(title)) {
        title <- list()
      } else if (is.character(title)) {
        title <- list(text = title)
      }
      if (identical(nm, "xaxis")) {
        if ((is.null(title$text) || !nzchar(title$text)) && !is.null(xlab) && nzchar(xlab)) {
          title$text <- xlab
        }
      } else if (!is.null(xlab) && identical(title$text, xlab)) {
        title$text <- ""
      }
      title$standoff <- x_standoff
      lay[[nm]]$title <- title
      if (isTRUE(equal_axes)) {
        lay[[nm]]$range <- c(-0.02, 1.02)
        lay[[nm]]$constrain <- "domain"
        lay[[nm]]$zeroline <- FALSE
      }
    }
    if (grepl("^yaxis", nm)) {
      if (!identical(lay[[nm]]$constrain, "domain")) {
        lay[[nm]]$automargin <- TRUE
      }
      title <- lay[[nm]]$title
      if (is.null(title)) {
        title <- list()
      } else if (is.character(title)) {
        title <- list(text = title)
      }
      if (identical(nm, "yaxis")) {
        if ((is.null(title$text) || !nzchar(title$text)) && !is.null(ylab) && nzchar(ylab)) {
          title$text <- ylab
        }
      } else if (!is.null(ylab) && identical(title$text, ylab)) {
        title$text <- ""
      }
      title$standoff <- 12
      lay[[nm]]$title <- title
      if (isTRUE(equal_axes)) {
        x_id <- sub("^yaxis", "x", nm)
        lay[[nm]]$range <- c(-0.02, 1.02)
        lay[[nm]]$constrain <- "domain"
        lay[[nm]]$scaleanchor <- x_id
        lay[[nm]]$scaleratio <- 1
        lay[[nm]]$zeroline <- FALSE
      }
    }
  }
  # ggplotly duplicates axis titles as paper-referenced annotations.
  if (length(lay$annotations)) {
    for (i in seq_along(lay$annotations)) {
      ann <- lay$annotations[[i]]
      txt <- ann$text
      if (!is.null(txt) && (( !is.null(xlab) && identical(txt, xlab)) || ( !is.null(ylab) && identical(txt, ylab)))) {
        lay$annotations[[i]]$text <- ""
        next
      }
      y <- ann$y
      yref <- ann$yref
      if (!is.null(y) && is.numeric(y) && (is.null(yref) || identical(yref, "paper")) && y < 0.08) {
        lay$annotations[[i]]$y <- if (isTRUE(rotate_x)) -0.12 else -0.06
      }
    }
  }
  gp$x$layout <- lay
  gp
}

print_plot <- function(p, interactive = TRUE, file = NULL, width = 9, height = 5, equal_axes = FALSE, rotate_x = TRUE, hovermode = "x") {
  if (is.null(p)) {
    return(invisible(NULL))
  }
  if (isTRUE(interactive)) {
    xlab <- ylab <- NULL
    if (inherits(p, "ggplot")) {
      xlab <- p$labels$x
      ylab <- p$labels$y
    }
    if (inherits(p, "plotly")) {
      gp <- p
    } else {
      gp <- plotly::plotly_build(plotly::ggplotly(p, tooltip = "text"))
    }
    return(style_plotly_axes(gp, equal_axes = equal_axes, rotate_x = rotate_x, hovermode = hovermode, xlab = xlab, ylab = ylab))
  }
  if (!is.null(file)) {
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    ggsave(file, p, width = width, height = height, dpi = 120, bg = "white")
    knitr::include_graphics(normalizePath(file, mustWork = TRUE), rel_path = FALSE)
  } else {
    p
  }
}

plot_locus_coverage <- function(coverage) {
  if (nrow(coverage) == 0) {
    return(empty_plot("No locus coverage table was provided."))
  }
  needed <- c("n_samples", "total_samples")
  if (!all(needed %in% names(coverage))) {
    return(empty_plot("Locus coverage table is missing n_samples / total_samples."))
  }
  gene <- if ("gene" %in% names(coverage)) coverage$gene else NA_character_
  gene_id <- if ("gene_id" %in% names(coverage)) coverage$gene_id else NA_character_
  aa_position <- if ("aa_position" %in% names(coverage)) coverage$aa_position else seq_len(nrow(coverage))
  df <- coverage %>%
    mutate(
      locus = locus_label(gene, gene_id, aa_position),
      n_samples = ifelse(is.na(.data$n_samples), 0, .data$n_samples),
      total_samples = ifelse(is.na(.data$total_samples) | .data$total_samples == 0, NA_real_, .data$total_samples),
      frac = ifelse(is.na(.data$total_samples), NA_real_, .data$n_samples / .data$total_samples),
      status = ifelse(.data$n_samples == 0, "uncovered", "covered"),
      text = paste0(
        .data$locus, "<br>", .data$n_samples, " / ", .data$total_samples,
        " specimens with a call"
      )
    )
  ggplot(df, aes(x = .data$locus, y = .data$frac, fill = .data$status, text = .data$text)) +
    geom_col() +
    scale_y_continuous(labels = function(x) paste0(round(100 * x), "%"), limits = c(0, 1), expand = c(0, 0.02)) +
    scale_fill_manual(values = c(covered = "#2c7bb6", uncovered = "#d7191c")) +
    labs(
      x = "Locus",
      y = "Proportion of specimens with a call",
      fill = NULL,
      title = "Locus coverage"
    ) +
    theme_report()
}

plot_coverage_by_population <- function(aa_calls, population_assignment = tibble(), coverage = tibble(), population_label = "pop1", interactive = FALSE) {
  if (nrow(aa_calls) == 0) {
    return(empty_plot("No amino acid calls were provided."))
  }
  needed <- c("specimen_name", "aa_position")
  if (!all(needed %in% names(aa_calls))) {
    return(empty_plot("Amino acid calls are missing specimen_name / aa_position."))
  }
  gene <- if ("gene" %in% names(aa_calls)) aa_calls$gene else NA_character_
  gene_id <- if ("gene_id" %in% names(aa_calls)) aa_calls$gene_id else NA_character_
  calls <- aa_calls %>%
    mutate(locus = locus_label(gene, gene_id, .data$aa_position)) %>%
    distinct(.data$specimen_name, .data$locus)

  loci <- unique(calls$locus)
  if (nrow(coverage) > 0) {
    cov_gene <- if ("gene" %in% names(coverage)) coverage$gene else NA_character_
    cov_gene_id <- if ("gene_id" %in% names(coverage)) coverage$gene_id else NA_character_
    cov_pos <- if ("aa_position" %in% names(coverage)) coverage$aa_position else seq_len(nrow(coverage))
    loci <- unique(c(loci, locus_label(cov_gene, cov_gene_id, cov_pos)))
  }

  if (nrow(population_assignment) > 0 && all(c("specimen_name", "population") %in% names(population_assignment))) {
    pop_map <- population_assignment %>%
      distinct(.data$specimen_name, .data$population)
    calls <- calls %>%
      inner_join(pop_map, by = "specimen_name")
    totals <- pop_map %>%
      count(.data$population, name = "n_specimens")
  } else {
    calls <- calls %>%
      mutate(population = population_label)
    totals <- tibble(
      population = population_label,
      n_specimens = n_distinct(calls$specimen_name)
    )
  }

  if (nrow(calls) == 0 || nrow(totals) == 0) {
    return(empty_plot("No specimens could be matched to a population for locus coverage."))
  }

  df <- calls %>%
    count(.data$population, .data$locus, name = "n_with_call") %>%
    complete(
      population = totals$population,
      locus = loci,
      fill = list(n_with_call = 0)
    ) %>%
    left_join(totals, by = "population") %>%
    mutate(
      n_specimens = ifelse(is.na(.data$n_specimens) | .data$n_specimens == 0, NA_real_, .data$n_specimens),
      frac = ifelse(is.na(.data$n_specimens), NA_real_, .data$n_with_call / .data$n_specimens),
      text = paste0(
        .data$locus, " — ", .data$population, "<br>",
        .data$n_with_call, " / ", .data$n_specimens, " specimens with a call"
      )
    )

  if (isTRUE(interactive)) {
    pops <- sort(unique(as.character(df$population)))
    loc_levels <- sort(unique(as.character(df$locus)))
    z <- df %>%
      mutate(
        population = factor(.data$population, levels = pops),
        locus = factor(.data$locus, levels = loc_levels)
      ) %>%
      arrange(.data$locus, .data$population) %>%
      select("locus", "population", "frac") %>%
      pivot_wider(names_from = "population", values_from = "frac")
    txt <- df %>%
      mutate(
        population = factor(.data$population, levels = pops),
        locus = factor(.data$locus, levels = loc_levels)
      ) %>%
      arrange(.data$locus, .data$population) %>%
      select("locus", "population", "text") %>%
      pivot_wider(names_from = "population", values_from = "text")
    z_mat <- as.matrix(z[, -1, drop = FALSE])
    t_mat <- as.matrix(txt[, -1, drop = FALSE])
    storage.mode(z_mat) <- "numeric"
    return(
      plotly::plot_ly(
        x = colnames(z_mat),
        y = as.character(z$locus),
        z = z_mat,
        type = "heatmap",
        zauto = FALSE,
        zmin = 0,
        zmax = 1,
        colorscale = list(list(0, "#f7fbff"), list(1, "#08306b")),
        text = t_mat,
        hovertemplate = "%{text}<extra></extra>",
        colorbar = list(title = "Call rate", tickformat = ".2f")
      ) %>%
        plotly::layout(
          title = "Locus coverage by population",
          xaxis = list(title = "Population", tickangle = 0, automargin = TRUE),
          yaxis = list(
            title = "Locus",
            automargin = TRUE,
            categoryorder = "array",
            categoryarray = loc_levels
          )
        )
    )
  }

  ggplot(df, aes(x = .data$population, y = .data$locus, fill = .data$frac, text = .data$text)) +
    geom_tile(color = "white", linewidth = 0.4) +
    scale_fill_gradient(
      low = "#f7fbff",
      high = "#08306b",
      limits = c(0, 1),
      na.value = "#cccccc",
      breaks = seq(0, 1, 0.25),
      labels = function(x) format(x, nsmall = 2, trim = TRUE)
    ) +
    labs(
      x = "Population",
      y = "Locus",
      fill = "Call rate",
      title = "Locus coverage by population"
    ) +
    theme_report()
}

sanity_layout_dims <- function(n_pop) {
  n_pop <- max(1L, as.integer(n_pop))
  ncol <- if (n_pop <= 1L) 1L else 2L
  nrow <- as.integer(ceiling(n_pop / ncol))
  list(ncol = ncol, nrow = nrow, n_slots = ncol * nrow)
}

identity_rmse <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  x <- x[ok]
  y <- y[ok]
  if (length(x) == 0) {
    return(NA_real_)
  }
  sqrt(mean((y - x)^2))
}

format_rmse_label <- function(rmse) {
  paste0("RMSE = ", ifelse(is.na(rmse), "NA", sprintf("%.3f", rmse)))
}

group_hue_colours <- function(groups) {
  groups <- unique(as.character(groups))
  if (length(groups) == 0) {
    return(character())
  }
  hues <- seq(15, 375, length.out = length(groups) + 1L)[seq_along(groups)]
  cols <- grDevices::hcl(h = hues, c = 100, l = 45)
  names(cols) <- groups
  cols
}

plot_sl_vs_ml <- function(sl_summary, sl_from_ml, interactive = FALSE) {
  if (nrow(sl_summary) == 0 || nrow(sl_from_ml) == 0) {
    return(empty_plot("SL-from-ML frequencies are not available for a consistency check."))
  }
  if (!all(c("population", "variant", "freq") %in% names(sl_summary))) {
    return(empty_plot("sl_summary is missing population / variant / freq."))
  }
  if (!all(c("variant", "freq") %in% names(sl_from_ml))) {
    return(empty_plot("SL-from-ML table is missing variant / freq."))
  }
  sl <- sl_summary %>%
    select("population", "variant", sl_freq = "freq")
  ml <- sl_from_ml %>%
    mutate(
      population = if ("population" %in% names(.)) .data$population else sl$population[1],
      group_id = if ("group_id" %in% names(.)) .data$group_id else "all"
    ) %>%
    select("population", "group_id", "variant", ml_freq = "freq")
  raw <- inner_join(sl, ml, by = c("population", "variant")) %>%
    filter(!is.na(.data$sl_freq), !is.na(.data$ml_freq))
  if (nrow(raw) == 0) {
    return(empty_plot("No shared variants between sl_summary and SL-from-ML frequencies."))
  }
  stats <- raw %>%
    group_by(.data$population) %>%
    summarise(rmse = identity_rmse(.data$sl_freq, .data$ml_freq), .groups = "drop") %>%
    mutate(label = format_rmse_label(.data$rmse))
  groups <- sort(unique(as.character(raw$group_id)))
  df <- raw %>%
    group_by(.data$population, .data$group_id, .data$sl_freq, .data$ml_freq) %>%
    summarise(
      n = n(),
      variants = paste(.data$variant, collapse = "<br>"),
      .groups = "drop"
    ) %>%
    mutate(
      stagger = (match(as.character(.data$group_id), groups) - mean(seq_along(groups))) * 0.012,
      sl_plot = .data$sl_freq + .data$stagger,
      ml_plot = .data$ml_freq + .data$stagger,
      text = paste0(
        .data$variants, "<br>", .data$population,
        if_else(.data$group_id == "all", "", paste0(" | ", .data$group_id)),
        "<br>SLAF ", signif(.data$sl_freq, 3),
        " vs SL-from-ML ", signif(.data$ml_freq, 3),
        if_else(.data$n > 1, paste0("<br>", .data$n, " alleles at this coordinate"), "")
      )
    )
  if (isTRUE(interactive)) {
    return(plot_sl_vs_ml_plotly(df, stats))
  }
  n_pop <- n_distinct(df$population)
  dims <- sanity_layout_dims(n_pop)
  p <- ggplot(df, aes(x = .data$sl_plot, y = .data$ml_plot, colour = .data$group_id)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
    geom_point(aes(size = .data$n), shape = 21, fill = NA, stroke = 0.8, alpha = 0.9) +
    geom_text(
      data = stats,
      aes(x = 0.03, y = 0.97, label = .data$label),
      inherit.aes = FALSE,
      hjust = 0,
      vjust = 1,
      size = 3.2,
      colour = "grey20",
      lineheight = 0.95
    ) +
    scale_x_continuous(
      breaks = seq(0, 1, 0.25),
      labels = function(x) format(x, nsmall = 2, trim = TRUE)
    ) +
    scale_y_continuous(
      breaks = seq(0, 1, 0.25),
      labels = function(x) format(x, nsmall = 2, trim = TRUE)
    ) +
    scale_size_area(max_size = 6, breaks = sort(unique(df$n)), name = "n alleles") +
    coord_fixed(xlim = c(-0.02, 1.02), ylim = c(-0.02, 1.02), expand = FALSE, ratio = 1) +
    labs(
      x = "Single-locus frequency",
      y = "SL-from-ML",
      colour = "Loci group",
      title = "Single-locus frequency vs SL-from-ML"
    ) +
    theme_report(rotate_x = FALSE) +
    theme(
      aspect.ratio = 1,
      panel.spacing = unit(1.1, "lines"),
      legend.box = "vertical"
    )
  if (max(df$n) <= 1) {
    p <- p + guides(size = "none")
  }
  if (n_pop > 1) {
    p <- p + facet_wrap(~population, ncol = dims$ncol, scales = "fixed")
  }
  p
}

empty_sanity_axis <- function() {
  list(
    visible = FALSE,
    showticklabels = FALSE,
    ticks = "",
    showgrid = FALSE,
    showline = FALSE,
    zeroline = FALSE,
    title = "",
    range = c(-0.02, 1.02),
    constrain = "domain"
  )
}

empty_sanity_panel <- function() {
  plotly::plotly_empty(type = "scatter", mode = "markers") %>%
    plotly::layout(
      xaxis = empty_sanity_axis(),
      yaxis = empty_sanity_axis(),
      showlegend = FALSE
    )
}

plot_sl_vs_ml_plotly <- function(df, stats) {
  pops <- sort(unique(as.character(df$population)))
  groups <- sort(unique(as.character(df$group_id)))
  cols <- group_hue_colours(groups)
  dims <- sanity_layout_dims(length(pops))
  panels <- lapply(seq_len(dims$n_slots), function(i) {
    if (i > length(pops)) {
      return(empty_sanity_panel())
    }
    pop <- pops[[i]]
    pdat <- df[df$population == pop, , drop = FALSE]
    p <- plotly::plot_ly()
    p <- plotly::add_trace(
      p,
      x = c(0, 1),
      y = c(0, 1),
      type = "scatter",
      mode = "lines",
      line = list(dash = "dash", color = "rgba(80,80,80,0.85)", width = 1),
      hoverinfo = "skip",
      showlegend = FALSE,
      inherit = FALSE
    )
    for (g in groups) {
      gd <- pdat[pdat$group_id == g, , drop = FALSE]
      if (nrow(gd) == 0) {
        next
      }
      p <- plotly::add_trace(
        p,
        x = gd$sl_plot,
        y = gd$ml_plot,
        type = "scatter",
        mode = "markers",
        name = g,
        legendgroup = g,
        showlegend = i == 1 && length(groups) > 1,
        marker = list(
          size = 5 + 2 * sqrt(gd$n),
          color = unname(cols[[g]]),
          opacity = 0.85,
          symbol = "circle-open",
          line = list(width = 1.1, color = unname(cols[[g]]))
        ),
        text = gd$text,
        hovertemplate = "%{text}<extra></extra>",
        inherit = FALSE
      )
    }
    p
  })
  sp <- plotly::subplot(
    panels,
    nrows = dims$nrow,
    shareX = FALSE,
    shareY = FALSE,
    titleX = TRUE,
    titleY = TRUE,
    margin = if (dims$n_slots > 1) 0.06 else 0.04,
    widths = rep(1 / dims$ncol, dims$ncol),
    heights = rep(1 / dims$nrow, dims$nrow)
  )
  anns <- list()
  axis_base <- list(
    range = c(-0.02, 1.02),
    constrain = "domain",
    zeroline = FALSE,
    ticks = "outside",
    dtick = 0.25
  )
  lay <- list(
    title = list(text = "Single-locus frequency vs SL-from-ML"),
    legend = list(orientation = "h", y = -0.12),
    hovermode = "closest",
    margin = list(t = 80, b = 80, l = 70, r = 20),
    width = 220 + 260 * dims$ncol,
    height = 140 + 280 * dims$nrow
  )
  for (i in seq_len(dims$n_slots)) {
    xnm <- if (i == 1) "xaxis" else paste0("xaxis", i)
    ynm <- if (i == 1) "yaxis" else paste0("yaxis", i)
    x_id <- if (i == 1) "x" else paste0("x", i)
    y_id <- if (i == 1) "y" else paste0("y", i)
    col <- ((i - 1L) %% dims$ncol) + 1L
    row <- ((i - 1L) %/% dims$ncol) + 1L
    is_real <- i <= length(pops)
    if (!is_real) {
      lay[[xnm]] <- empty_sanity_axis()
      lay[[ynm]] <- empty_sanity_axis()
      next
    }
    lay[[xnm]] <- modifyList(
      axis_base,
      list(
        title = if (row == dims$nrow) "Single-locus frequency" else "",
        showticklabels = TRUE,
        showgrid = TRUE,
        scaleanchor = NULL
      )
    )
    lay[[ynm]] <- modifyList(
      axis_base,
      list(
        title = if (col == 1L) "SL-from-ML" else "",
        showticklabels = TRUE,
        showgrid = TRUE,
        scaleanchor = x_id,
        scaleratio = 1
      )
    )
    st <- stats[stats$population == pops[[i]], , drop = FALSE]
    anns <- c(
      anns,
      list(list(
        x = 0.5,
        y = 1.08,
        xref = paste0(x_id, " domain"),
        yref = paste0(y_id, " domain"),
        text = pops[[i]],
        showarrow = FALSE,
        xanchor = "center",
        yanchor = "bottom",
        font = list(size = 12)
      )),
      list(list(
        x = 0.03,
        y = 0.97,
        xref = paste0(x_id, " domain"),
        yref = paste0(y_id, " domain"),
        text = if (nrow(st) == 1) st$label else "RMSE = NA",
        showarrow = FALSE,
        xanchor = "left",
        yanchor = "top",
        align = "left",
        bgcolor = "rgba(255,255,255,0.75)",
        font = list(size = 11)
      ))
    )
  }
  base_lay <- sp$x$layout
  if (is.null(base_lay)) {
    base_lay <- list()
  }
  sp$x$layout <- modifyList(base_lay, lay)
  sp$x$layout$annotations <- anns
  sp
}

prep_sl_plot_df <- function(sl_summary, aa_calls = tibble(), coverage = tibble(), value_col = "prev") {
  if (nrow(sl_summary) == 0 || !value_col %in% names(sl_summary)) {
    return(tibble())
  }
  parsed <- parse_sl_variant(sl_summary$variant)
  gene_lookup <- collect_gene_lookup(aa_calls, coverage)
  out <- bind_cols(sl_summary, parsed %>% select(-"variant")) %>%
    mutate(
      gene_id = as.character(.data$gene_id),
      aa_position = as.character(.data$aa_position)
    ) %>%
    left_join(gene_lookup, by = "gene_id")
  if (!"gene" %in% names(out)) {
    out$gene <- NA_character_
  }
  out %>%
    mutate(
      locus = locus_label(.data$gene, .data$gene_id, .data$aa_position),
      value = .data[[value_col]],
      text = paste0(
        .data$locus, " ", .data$aa, "<br>",
        .data$population, "<br>", value_col, " ", signif(.data$value, 3)
      )
    ) %>%
    filter(!is.na(.data$value))
}

plot_sl_metric_bars <- function(sl_summary, aa_calls = tibble(), coverage = tibble(), value_col = "prev", ylab = "Prevalence", title = "Allele prevalence", stacked = FALSE, facet_by = "population") {
  df <- prep_sl_plot_df(sl_summary, aa_calls, coverage, value_col)
  if (nrow(df) == 0) {
    return(empty_plot(paste(ylab, "is not available in sl_summary.")))
  }
  by_locus <- identical(facet_by, "locus")
  x_col <- if (by_locus) "population" else "locus"
  facet_col <- if (by_locus) "locus" else "population"
  x_scales <- if (shared_x_across_groups(df, facet_col, x_col)) "fixed" else "free_x"
  y_scale <- if (isTRUE(stacked) || identical(value_col, "freq")) {
    freq_y_scale(stacked = stacked)
  } else {
    scale_y_continuous(
      breaks = seq(0, 1, 0.25),
      labels = function(x) format(x, nsmall = 2, trim = TRUE),
      expand = expansion(mult = c(0, 0.05))
    )
  }
  xlab <- if (by_locus) "Population" else "Locus"
  plot_title <- if (by_locus) paste0(title, " by population") else paste0(title, " by locus")
  p <- ggplot(df, aes(x = .data[[x_col]], y = .data$value, fill = .data$aa, text = .data$text)) +
    geom_col(position = if (isTRUE(stacked)) "stack" else "dodge") +
    y_scale +
    aa_fill_scale(df$aa) +
    labs(
      x = xlab,
      y = ylab,
      fill = "Amino acid",
      title = plot_title
    ) +
    theme_report(rotate_x = TRUE)
  if (by_locus) {
    p <- p + facet_wrap(~locus, ncol = 1, scales = x_scales)
  } else {
    p <- p + facet_wrap(~population, ncol = 1, scales = x_scales)
  }
  p
}

plot_prevalence_bars <- function(sl_summary, aa_calls = tibble(), coverage = tibble(), facet_by = "population") {
  plot_sl_metric_bars(
    sl_summary,
    aa_calls,
    coverage,
    value_col = "prev",
    ylab = "Prevalence",
    title = "Allele prevalence",
    facet_by = facet_by
  )
}

plot_frequency_bars <- function(sl_summary, aa_calls = tibble(), coverage = tibble(), facet_by = "population") {
  plot_sl_metric_bars(
    sl_summary,
    aa_calls,
    coverage,
    value_col = "freq",
    ylab = "Frequency",
    title = "Allele frequency",
    stacked = TRUE,
    facet_by = facet_by
  )
}

has_ml_column <- function(ml_summary, col) {
  nrow(ml_summary) > 0 && col %in% names(ml_summary) && any(!is.na(ml_summary[[col]]))
}

prep_haplotype_plot_df <- function(ml_summary, aa_calls = tibble(), coverage = tibble(), value_col = "freq", max_haplotypes = 12) {
  needed <- c("population", "group_id", "variant", value_col)
  if (nrow(ml_summary) == 0 || !all(needed %in% names(ml_summary))) {
    return(tibble())
  }
  df <- ml_summary %>%
    filter(!is.na(.data[[value_col]]), nzchar(.data$variant))
  if (nrow(df) == 0) {
    return(tibble())
  }
  gene_lookup <- collect_gene_lookup(aa_calls, coverage)
  rank_col <- if ("freq" %in% names(df) && any(!is.na(df$freq))) "freq" else value_col
  ranked <- df %>%
    group_by(.data$group_id, .data$variant) %>%
    summarise(rank_val = mean(.data[[rank_col]], na.rm = TRUE), .groups = "drop") %>%
    group_by(.data$group_id) %>%
    mutate(rank = row_number(desc(.data$rank_val))) %>%
    ungroup()
  df <- df %>%
    left_join(ranked, by = c("group_id", "variant")) %>%
    mutate(
      hap = if_else(
        .data$rank <= max_haplotypes,
        haplotype_label(.data$variant, gene_lookup),
        "other"
      )
    ) %>%
    group_by(.data$population, .data$group_id, .data$hap) %>%
    summarise(
      value = sum(.data[[value_col]], na.rm = TRUE),
      variant_hover = paste(unique(.data$variant), collapse = " | "),
      .groups = "drop"
    )
  hap_chr <- as.character(df$hap)
  hap_levels <- c(setdiff(unique(hap_chr), "other"), intersect("other", hap_chr))
  df$hap <- factor(hap_chr, levels = hap_levels)
  df$text <- paste0(
    df$variant_hover, "<br>",
    df$population, "<br>", value_col, " ", signif(df$value, 3)
  )
  df
}

plot_haplotype_bars <- function(ml_summary, aa_calls = tibble(), coverage = tibble(), value_col = "freq", ylab = "Haplotype frequency", title = "Multi-locus haplotype frequency", stacked = TRUE, max_haplotypes = 12) {
  if (nrow(ml_summary) == 0 || !value_col %in% names(ml_summary)) {
    return(empty_plot(paste(ylab, "is not available in ml_summary.")))
  }
  needed <- c("population", "group_id", "variant")
  if (!all(needed %in% names(ml_summary))) {
    return(empty_plot("ml_summary is missing population / group_id / variant."))
  }
  df <- prep_haplotype_plot_df(ml_summary, aa_calls, coverage, value_col, max_haplotypes)
  if (nrow(df) == 0) {
    return(empty_plot(paste("ml_summary has no haplotype", value_col, "rows.")))
  }
  x_scales <- if (shared_x_across_groups(df, "group_id", "population")) "fixed" else "free_x"
  y_scale <- if (isTRUE(stacked)) {
    freq_y_scale(stacked = TRUE)
  } else {
    scale_y_continuous(
      breaks = seq(0, 1, 0.25),
      labels = function(x) format(x, nsmall = 2, trim = TRUE),
      expand = expansion(mult = c(0, 0.05))
    )
  }
  ggplot(df, aes(x = .data$population, y = .data$value, fill = .data$hap, text = .data$text)) +
    geom_col(position = if (isTRUE(stacked)) "stack" else "dodge") +
    facet_wrap(~group_id, ncol = 1, scales = x_scales) +
    y_scale +
    labs(
      x = "Population",
      y = ylab,
      fill = "Haplotype",
      title = title
    ) +
    theme_report()
}

plot_haplotype_stack <- function(ml_summary, aa_calls = tibble(), coverage = tibble(), max_haplotypes = 12) {
  plot_haplotype_bars(
    ml_summary,
    aa_calls,
    coverage,
    value_col = "freq",
    ylab = "Haplotype frequency",
    title = "Multi-locus haplotype frequency",
    stacked = TRUE,
    max_haplotypes = max_haplotypes
  )
}

plot_haplotype_prevalence <- function(ml_summary, aa_calls = tibble(), coverage = tibble(), max_haplotypes = 12) {
  plot_haplotype_bars(
    ml_summary,
    aa_calls,
    coverage,
    value_col = "prev",
    ylab = "Haplotype prevalence",
    title = "Multi-locus haplotype prevalence",
    stacked = FALSE,
    max_haplotypes = max_haplotypes
  )
}
