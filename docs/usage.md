# nf-core/plasmodiumdrugres: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/plasmodiumdrugres/usage](https://nf-co.re/plasmodiumdrugres/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

**nf-core/plasmodiumdrugres** is a bioinformatics pipeline for analyzing drug resistance markers from microhaplotype data. It translates variants into amino acid changes at drug resistance loci and estimates allele frequencies and prevalences at both single-locus and multi-locus levels. Microhaplotype data can be supplied in the form of an allele table or a [PMO](https://plasmogenepi.github.io/PMO_Docs/) file.

Key words

- population
- locus
- multi-locus

## Loci of Interest Input

You will need to create a bed file including the locations of the loci that you are interested in before running the pipeline. It has to be a tab-separated file with 9 columns, and a header row as shown in the examples below.

```bash
--loci_of_interest_bed '[path to loci of interest file]'
```

### Full loci of interest bed file

This file will be used to call amino acids from your data and caluclate frequencies and prevalences for the single loci. You can include as many single loci as you like, however the pipeline will fail if a locus is completely missing from the input data for a population.

A final loci of interest bed file may look something like the one below.

```bed title="loci_of_interest.bed"
#chrom  start end name  length  strand  gene  aa_position gene_id
Pf3D7_04_v3 748237  748240  PF3D7_0417200.1-AA51  3 + dhfr-ts 51  PF3D7_0417200.1
Pf3D7_04_v3 748261  748264  PF3D7_0417200.1-AA59  3 + dhfr-ts 59  PF3D7_0417200.1
Pf3D7_04_v3 748408  748411  PF3D7_0417200.1-AA108 3 + dhfr-ts 108 PF3D7_0417200.1
Pf3D7_04_v3 748576  748579  PF3D7_0417200.1-AA164 3 + dhfr-ts 164 PF3D7_0417200.1
Pf3D7_05_v3 958144  958147  PF3D7_0523000.1-AA86  3 + mdr1  86  PF3D7_0523000.1
Pf3D7_05_v3 958438  958441  PF3D7_0523000.1-AA184 3 + mdr1  184 PF3D7_0523000.1
Pf3D7_05_v3 961624  961627  PF3D7_0523000.1-AA1246  3 + mdr1  1246  PF3D7_0523000.1
Pf3D7_07_v3 403623  403626  PF3D7_0709000.1-AA76  3 + crt 76  PF3D7_0709000.1
Pf3D7_07_v3 403686  403689  PF3D7_0709000.1-AA97  3 + crt 97  PF3D7_0709000.1
Pf3D7_08_v3 549680  549683  PF3D7_0810800.1-AA436 3 + dhps  436 PF3D7_0810800.1
Pf3D7_08_v3 549683  549686  PF3D7_0810800.1-AA437 3 + dhps  437 PF3D7_0810800.1
Pf3D7_08_v3 549992  549995  PF3D7_0810800.1-AA540 3 + dhps  540 PF3D7_0810800.1
Pf3D7_08_v3 550115  550118  PF3D7_0810800.1-AA581 3 + dhps  581 PF3D7_0810800.1
Pf3D7_08_v3 550211  550214  PF3D7_0810800.1-AA613 3 + dhps  613 PF3D7_0810800.1
```

| Column        | Description                                                                                                                               |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `#chrom`      | Chromosome that the locus is found on. You may have multiple loci with the same #chrom. This should match with the reference information. |
| `start`       | Genomic start position of the locus (0-based).                                                                                            |
| `end`         | Genomic end position of the locus (0-based).                                                                                              |
| `name`        | Unique identifier for the locus.                                                                                                          |
| `length`      | Length in base pairs. (e.g. 3 for a standard codon)                                                                                       |
| `strand`      | Strand orientation (+ or -) relative to the reference genome.                                                                             |
| `gene`        | Short gene name or symbol (e.g., dhfr-ts, mdr1, crt).                                                                                     |
| `gene_id`     | Full PlasmoDB gene model identifier (e.g., PF3D7_0417200.1).                                                                              |
| `aa_position` | Amino acid position within the protein where the codon is located.                                                                        |

An [example loci of interest bed file](../assets/loci_of_interest.bed) has been provided with the pipeline. It provides an extensive set of loci for _Plasmodium falciparum_, so you can simply filter for the loci relevant to your work rather than starting from scratch. If you identify a locus that should be added, [please let us know](Contributions and Support).

## Loci groups

Before running the pipeline, you will need to create a BED file that defines the groups of loci for which you want to generate multi-locus estimates. It has to be a tab-separated file with 3 columns, and a header row as shown in the examples below.

```bash
--loci_groups '[path to loci groups file]'
```

### Full loci groups file

This file specifies which loci from the loci of interest file should be grouped together for generating multi-locus estimates. You can include as many groups as you like, however some tools are limitted as to how many loci you can put in one group. Any gene_id, position combination listed in this file should also be defined in the locus of interest table.

A final loci groups file may look something like the one below. In this example, three groups are defined: crt, mdr1, and pfdhfr_pfdhps, containing 2, 3, and 4 loci, respectively.

```tsv title="loci_groups.tsv"
group_id  gene_id aa_position
crt PF3D7_0709000.1 76
crt PF3D7_0709000.1 97
mdr1  PF3D7_0523000.1 86
mdr1  PF3D7_0523000.1 184
mdr1  PF3D7_0523000.1 1246
pfdhfr_pfdhps PF3D7_0417200.1 51
pfdhfr_pfdhps PF3D7_0417200.1 59
pfdhfr_pfdhps PF3D7_0417200.1 108
pfdhfr_pfdhps PF3D7_0417200.1 164
pfdhfr_pfdhps PF3D7_0810800.1 436
pfdhfr_pfdhps PF3D7_0810800.1 437
pfdhfr_pfdhps PF3D7_0810800.1 540
pfdhfr_pfdhps PF3D7_0810800.1 581
pfdhfr_pfdhps PF3D7_0810800.1 613
```

Pf3D7_04_v3 748237 748240 PF3D7_0417200.1-AA51 3 + dhfr-ts 51 PF3D7_0417200.1
Pf3D7_04_v3 748261 748264 PF3D7_0417200.1-AA59 3 + dhfr-ts 59 PF3D7_0417200.1
Pf3D7_04_v3 748408 748411 PF3D7_0417200.1-AA108 3 + dhfr-ts 108 PF3D7_0417200.1
Pf3D7_04_v3 748576 748579 PF3D7_0417200.1-AA164 3 + dhfr-ts 164 PF3D7_0417200.1
Pf3D7_05_v3 958144 958147 PF3D7_0523000.1-AA86 3 + mdr1 86 PF3D7_0523000.1
Pf3D7_05_v3 958438 958441 PF3D7_0523000.1-AA184 3 + mdr1 184 PF3D7_0523000.1
Pf3D7_05_v3 961624 961627 PF3D7_0523000.1-AA1246 3 + mdr1 1246 PF3D7_0523000.1
Pf3D7_07_v3 403623 403626 PF3D7_0709000.1-AA76 3 + crt 76 PF3D7_0709000.1

| Column        | Description                                                        |
| ------------- | ------------------------------------------------------------------ |
| `group_id`    | Unique identifier for the group of loci.                           |
| `gene_id`     | Full PlasmoDB gene model identifier (e.g., PF3D7_0417200.1).       |
| `aa_position` | Amino acid position within the protein where the codon is located. |

## Input file

Decide if you will be running the pipeline from a [PMO file](#pmo-inputs) or an [allele table](#allele-table-inputs) as other required inputs will depend on this. The most simple way to run this pipeline is by using a [Portable Microhaplotype Object (PMO)](https://plasmogenepi.github.io/PMO_Docs/) file. To maximize flexibility, the pipeline also allows users to provide a PMO with reference sequences separately, or to supply an allele table with panel information in a separate file.

### PMO Inputs

Generate a PMO file using [this documentation](https://plasmogenepi.github.io/PMO_Docs/). If you include reference sequences in your PMO then this is all you need. If you don't then you should provide a reference with either `--genome_reference` or `--targeted_reference`. `--genome_reference` can be a fasta file including a full genome. `--targeted_reference` is a fasta file where sequence names match up with target_ids.

### Allele Table Inputs

When running with an allele table you should create the following inputs:

- [allele table](#allele-table)
- [panel info bed file](#panel-info)
- [population map (optional)](#population-map-optional)

#### Allele Table

You will need to create an allele table file that includes your genomic data. It has to be a tab-separated file with 3 columns, and a header row as shown in the examples below. You can optionally include a 4th column.

```bash
--allele_table '[path to allele table file]'
```

##### Full allele table

A final allele table may look something like the one below. In this example, three groups are defined: crt, mdr1, and pfdhfr_pfdhps, containing 2, 3, and 4 loci, respectively.

```tsv title="allele_table.tsv"
specimen_id  target_id  seq read_count
specimen_1  target1 TTATTTTTTTTGTCAATAGATAAATGATCAATATTTTCTATATTTAATCTATCAAGTATTTTTATATATCTATTATTTCTTTCTTCGATGGAT 93
specimen_1  target1 AATAAAGAAGAAGATAAATATGGAAAAAATGAAAAAAACGAAAAATATGACAAATATGACAAATATGAAAAATATGATAAATACAAAAAAGAT 708
specimen_1  target2 TCATTCTTTTTTTAACTAAAACTATTCATCTCAAAAATATAAGATATTTTATATGACGAATGCCATTGTATTTTTTGTTACGTAAAAC  236
specimen_2  target1 AATAAAGAAGAAGATAAATATGGAAAAAATGAAAAAAACGAAAAATATGACAAATATGACAAATATGAAAAATATGATAAATACAAAAAAGAT 733
specimen_3  target1 AATAAAGAAGAAGATAAATATGGAAAAAATGAAAAAAACGAAAAATATGACAAATATGACAAATATGAAAAATATGATAAATACAAAAAAGAT 650
```

| Column        | Description                                                                                                       |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| `specimen_id` | Unique identifier for the specimen or sample from which the sequence was obtained.                                |
| `target_id`   | Identifier for the genomic region being sequenced.                                                                |
| `seq`         | Observed nucleotide sequence (microhaplotype) aligned to the target region.                                       |
| `read_count`  | Number of sequencing reads supporting the given sequence in that specimen, representing its abundance. (Optional) |

#### Panel Info

Next, prepare a panel info bed file. This will define the locations of the targets in the `target_id` column in the allele table. It has to be a tab-separated file with 7 columns.

```bash
--panel_info_bed '[path to panel info file]'
```

##### Full panel info bed file

A final panel info bed file may look something like the one below.

```bed title="panel_info.bed"
#chrom  start   end     target_id       length  strand  ref_seq
Pf3D7_01_v3     145421  145629  target1    208     +       GATATGTTTAAATATATGATTCTCGAAAAAACTTTTTTTATTTTTTTTGTCAATAGATAAATGATCAATATTTTCTATATTTAATCTATCAAGTATTTTTATATATCTATTATTTCTTTCTTCGATGGATAAATTATAAGAATCAATATCCTTTCTTTCATCAACAAACTTTTTTATTGTTAACTCCATTTTTTTATTTAAGATACCA
Pf3D7_01_v3     162889  163091  target2   202     +       ATATACCAATAATACTTTTTTTTTTAAATAATGTAAAAAATGATTTATATAATTGTTATAAACAAATGATCACATATCATAATAATAATATCCTAAATCATAACTCTAATATTTTATCAAAAGAAAATGAAAAAAAACAACCTTTTTCAACATATAATATATCAAATCTTTGTTCTCCTGACCAAATGGTGATAAATAAAAA
```

| Column      | Description                                                                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `#chrom`    | Chromosome that the target is found on. You may have multiple targets with the same #chrom. This should match with the reference information. |
| `start`     | Genomic start position of the target (0-based).                                                                                               |
| `end`       | Genomic end position of the target (0-based).                                                                                                 |
| `target_id` | Identifier for the genomic region being sequenced.                                                                                            |
| `length`    | Length in base pairs.                                                                                                                         |
| `strand`    | Strand orientation (+ or -) relative to the reference genome.                                                                                 |
| `ref_seq`   | reference sequence for the target (optional if genome_reference or targeted reference supplied)                                               |

#### Population Map (optional)

If you would like to estimate prevalences and frequencies for several populations you need to provide a population map which assigns specimens to individual populations. The file only contains two columns `specimen_id` which should match the unique specimen_ids in the allele table, and `population` which contains identifiers for populations. The population identifier will be included in output tables.

```bash
--population_map '[path to population map file]'
```

##### Full Population Map

A final population map may look something like the one below, where 3 samples are assinged to two populations.

```tsv title="population_map.tsv"
specimen_id population
specimen_1  pop1
specimen_2  pop2
specimen_3  pop2
```

## Other params

- `--population_label` - If running one population used to label the dataset. (Default: pop1)
- `--translate_loci_extra_args` - Extra arguments when translating loci of interest. [See documentation here](https://github.com/PlasmoGenEpi/PGEcore/tree/develop/scripts/translate_loci_of_interest).
- `--slaf_method` - chosen method to estimate single locus allele frequencies (Default: IDM Options: ["IDM","naive","from_mlaf"])
- `--mlaf_method` - chosen method to estimate multi-locus allele frequencies (Default: MLBM Options: ["MLBM","FEM"])
- `--naive_slaf_method` - Chosen naive method when running `--slaf_method naive`. (Default:read_count_prop, Options: ["read_count_prop", "presence_absence])

## Running the pipeline

The typical command for running the pipeline from a PMO file is as follows:

```bash
nextflow run nf-core/plasmodiumdrugres --pmo input_file.pmo --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv --outdir ./results -profile docker
```

If you are supplying a reference the add the `--genome_reference` flag.

```bash
nextflow run nf-core/plasmodiumdrugres --pmo input_file.pmo --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv --genome_reference genome_reference.fasta --outdir ./results -profile docker
```

If you are supplying a targeted reference the add the `--targeted_reference` flag.

```bash
nextflow run nf-core/plasmodiumdrugres --pmo input_file.pmo --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv  --targeted_reference genome_reference.fasta --outdir ./results -profile docker
```

If you are running from an allele table you can run the pipeline like this:

```bash
nextflow run nf-core/plasmodiumdrugres --allele_table allele_table.tsv --panel_info_bed panel_info.bed --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv --outdir ./results -profile docker
```

If you have a population_map you can include it using this flag `--population_map`

```bash
nextflow run nf-core/plasmodiumdrugres --allele_table allele_table.tsv --panel_info_bed panel_info.bed --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv --population_map population_map.tsv --outdir ./results -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/plasmodiumdrugres -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
pmo: './input_file.pmo'
loci_of_interest_bed: './loci_of_interest.bed'
loci_groups: './loci_groups.tsv'
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/plasmodiumdrugres
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/plasmodiumdrugres releases page](https://github.com/nf-core/plasmodiumdrugres/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
