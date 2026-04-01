# nf-core/plasmodiumdrugres: Output

## Introduction

This document describes the output produced by the pipeline. All paths below are relative to the top-level results directory (`--outdir`).

Column definitions in this page are based on current pipeline behavior and validated against example method outputs in `../DR_tool_outputs/`.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

1. Translate loci of interest ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
2. Split by population
3. Estimate allele prevalence ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
4. Estimate multilocus allele frequency. Choice of method between:
   1. [MultiLociBiallelicModel](https://www.frontiersin.org/articles/10.3389/fepid.2022.943625/full) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   2. [FreqEstimationModel](https://doi.org/10.1186/1475-2875-13-102) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   3. Naive method ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
5. Estimate single locus allele frequency. Choice of method between:
   1. [Incomplete data model (IDM)](https://doi.org/10.1371/journal.pone.0287161) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   2. [Naive `PGEcore` method](https://github.com/PlasmoGenEpi/PGEcore)
   3. [mhaps_freq (from microhaplotype frequencies via DCIFER)](https://github.com/PlasmoGenEpi/PGEcore)
6. Merge prevalence and frequency outputs
7. Concatenate population outputs

### Translated Loci

<details markdown="1">
<summary>Output files</summary>

- `translated_loci/`
  - `amino_acid_calls.tsv.gz`: Raw amino acid calls from individual targets.
  - `collapsed_amino_acid_calls.tsv.gz`: Amino acid calls collapsed. E.g. if a locus is covered by multiple targets these will be collapsed from `amino_acid_calls.tsv.gz` into this file.
  - `loci_covered_by_target_samples_info.tsv`: The loci from the input that were found to be covered by input data.

</details>

### Single Locus Allele Frequencies

<details markdown="1">
<summary>Output files</summary>

- `sl_summary.tsv`: Single-locus summary table (prevalence + frequency), merged across populations.

</details>

#### `sl_summary.tsv` columns

Core columns (always present):

| Column         | Description                                                                         |
| -------------- | ----------------------------------------------------------------------------------- |
| `population`   | Population label for this row (a user-defined grouping of samples; see usage docs). |
| `variant`      | Single-locus amino-acid variant identifier.                                         |
| `prev`         | Estimated prevalence for the variant in the population.                             |
| `sample_count` | Number of samples with the variant (for prevalence estimate).                       |
| `sample_total` | Total number of samples considered (for prevalence estimate).                       |
| `freq`         | Estimated single-locus allele frequency.                                            |

Tool-specific extra columns:

| SLAF method               | Extra columns in `sl_summary.tsv`                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `IDM`                     | None (core columns only).                                                                  |
| `naive`                   | None (core columns only).                                                                  |
| `mhaps_freq` (via DCIFER) | `sample_total_for_allele_freq` (sample count associated with frequency estimation output). |

### Multi Locus Allele Frequencies

<details markdown="1">
<summary>Output files</summary>

- `ml_summary.tsv`: Multi-locus summary table, merged across populations.

</details>

#### `ml_summary.tsv` columns

Core columns (always present):

| Column       | Description                                 |
| ------------ | ------------------------------------------- |
| `population` | Population label for this row.              |
| `group_id`   | Group identifier from `--loci_groups`.      |
| `variant`    | Multi-locus variant / haplotype identifier. |
| `freq`       | Estimated multi-locus allele frequency.     |

Tool-specific extra columns:

| MLAF method | Extra columns in `ml_summary.tsv`                                      |
| ----------- | ---------------------------------------------------------------------- |
| `MLBM`      | None (core columns only).                                              |
| `FEM`       | `sequence`, `median_freq`, `CI_2.5`, `CI_97.5`, `prev`, `sample_total` |
| `naive`     | `sample_total`, `sample_count`, `prev`                                 |

### SL-from-ML Summary

<details markdown="1">
<summary>Output files</summary>

- `sl_from_ml_summary.tsv`: Single-locus frequencies derived from multi-locus estimates.

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.html`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files are only present if `--email` / `--email_on_fail` is set.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
