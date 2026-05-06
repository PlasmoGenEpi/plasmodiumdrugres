FROM ubuntu:24.04

# Terra / Google Cloud Batch run linux/amd64. Images built on Apple Silicon default to
# arm64 and fail with "exec format error" there. Build and push with e.g.:
#   docker buildx build --platform linux/amd64 -t <repo>:<tag> --push .

LABEL org.opencontainers.image.title="plasmogenepi/plasmodiumdrugres"
LABEL org.opencontainers.image.description="WDL/Terra runtime for plasmodiumdrugres pipeline"

ARG DEBIAN_FRONTEND="noninteractive"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"
ARG LC_ALL="en_US.UTF-8"
ARG CPU_COUNT=5
ARG TIME_ZONE=Etc/UTC

# Pin pipeline and pmotools sources for reproducibility
ARG PLASMODIUMDRUGRES_GIT_URL="https://github.com/PlasmoGenEpi/plasmodiumdrugres.git"
ARG PLASMODIUMDRUGRES_REF="main"
ARG PMOTOOLS_GIT_URL="https://github.com/PlasmoGenEpi/pmotools-python.git"
ARG PMOTOOLS_REF="develop"

RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -yq --no-install-recommends \
      ca-certificates curl wget git locales tzdata \
      build-essential autotools-dev autoconf libtool automake file \
      openssh-client \
      python3 python3-dev python3-pip \
      libssl-dev libcurl4-gnutls-dev \
      xz-utils zlib1g-dev libbz2-dev liblzma5 liblzma-dev \
      libxml2-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
      libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
      libmpfr-dev libgmp3-dev \
      muscle && \
    rm -rf /var/lib/apt/lists/*

# Add CRAN for R on Ubuntu noble (noble-cran40 may track newest compatible R, e.g. 4.5.x)
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > /etc/apt/sources.list.d/cran.list && \
    echo "deb-src https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" >> /etc/apt/sources.list.d/cran.list && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc >/dev/null

RUN apt-get update && \
    apt-get install -yq --no-install-recommends r-base r-base-dev && \
    rm -rf /var/lib/apt/lists/*

# Locale + timezone
RUN echo "$LANG UTF-8" >> /etc/locale.gen && locale-gen $LANG && \
    ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# GitHub host key for clone
RUN mkdir -p /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts

# pmotools-python
WORKDIR /opt
RUN git clone "$PMOTOOLS_GIT_URL" pmotools-python && \
    cd pmotools-python && \
    git checkout "$PMOTOOLS_REF"
RUN pip install --break-system-packages /opt/pmotools-python

# R configuration + packages
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/ && \
    echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = ${CPU_COUNT})" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site >/dev/null
RUN R -e 'install.packages(c("remotes"))'
RUN Rscript -e "remotes::install_cran(c('tibble','dplyr','stringr','readr','optparse','ggplot2','tidyr','data.table','validate','openxlsx','Rmpfr','rlang','doParallel','magrittr','checkmate','pegas','ape','rngtools','parallelly'), Ncpus = ${CPU_COUNT})"
RUN R -e "install.packages(c('dcifer','moire'), repos = c('https://plasmogenepi.r-universe.dev','https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('nickjhathaway/variantstring@develop')"
# noble-cran40 currently ships R 4.6.x; Bioc 3.22 targets R 4.5 — BiocManager requires 3.23+ for R 4.6.
RUN Rscript -e 'if (!require("BiocManager", quietly = TRUE)) { install.packages("BiocManager"); }; BiocManager::install(version = "3.23", ask = FALSE);'
RUN Rscript -e 'BiocManager::install(c("Biostrings","pwalign","msa"), ask = FALSE)'

# Pipeline scripts bundled into image (no git submodule required)
WORKDIR /opt
# PGEcore lives in git submodule bin/PGEcore; clone alone leaves scripts missing.
RUN git clone "$PLASMODIUMDRUGRES_GIT_URL" plasmodiumdrugres-src && \
    cd plasmodiumdrugres-src && \
    git checkout "$PLASMODIUMDRUGRES_REF" && \
    git submodule update --init --recursive

RUN mkdir -p /opt/plasmodiumdrugres && \
    cp -R /opt/plasmodiumdrugres-src/bin /opt/plasmodiumdrugres/bin

ENV PATH="/opt/pmotools-python/scripts:/opt/plasmodiumdrugres/bin:$PATH"

