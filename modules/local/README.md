# Local nf-core-style modules

Pipeline-specific processes live under `modules/local/<module_name>/` with:

- `main.nf` — process definition (`conda`, `container`, `versions.yml` emit)
- `environment.yml` — Bioconda / conda-forge dependencies
- `meta.yml` — module metadata for linting and docs
- `Dockerfile` — when no single BioContainer exists (multi-tool R envs)

## Pilot: `translate_loci_of_interest`

R 4.4 + Bioconductor (`biostrings` 2.74, `pwalign` 1.2 — Bioc 3.19-era builds on bioconda). PGEcore scripts are read from `${projectDir}/bin/PGEcore` at runtime.

**Conda / mamba:**

```bash
nextflow run . -profile test,conda ...
```

**Docker** (build module image first; image is not on Docker Hub until published):

```bash
docker build -t plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0 modules/local/translate_loci_of_interest
docker run --rm plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0 R -e 'library(pwalign); library(validate)'
nf-test test tests/modules/local/translate_loci_of_interest.nf.test --profile test,docker
```

If nf-test reports `manifest unknown`, Docker is pulling from the registry because it does not see your local image (wrong Docker daemon/context, or image not built). Use `docker images | grep translate-loci` to confirm the tag exists.

**Conda** (no Docker image; uses `environment.yml`):

```bash
nf-test test tests/modules/local/translate_loci_of_interest.nf.test --profile test,conda
```

Other local modules still use the monolithic `plasmogenepi/plasmodiumdrugres` image until migrated to this layout.
