FROM ubuntu:24.04
LABEL authors="pge"

ARG DEBIAN_FRONTEND="noninteractive"
ARG SHELL="/bin/bash"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"
ARG LC_ALL="en_US.UTF-8"
ARG CPU_COUNT=5
ARG TIME_ZONE=Etc/UTC

RUN ulimit -n 10000

# install wget for getting pubkey
RUN apt-get update
RUN apt-get -yq dist-upgrade wget

# add packages source to install r 4.4 which is needed for BiocManager 3.19 which is needed pwalign
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > /etc/apt/sources.list.d/cran.list
RUN echo "deb-src https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" >> /etc/apt/sources.list.d/cran.list
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# install basics
RUN apt-get update
RUN apt-get -yq dist-upgrade
RUN apt-get install -yq --no-install-recommends autotools-dev autoconf libtool automake build-essential curl wget file git locales libssl-dev libcurl4-gnutls-dev ca-certificates xz-utils zlib1g-dev libbz2-dev liblzma5 liblzma-doc liblzma-dev openssh-client python3-dev python3-pip libxml2-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

# install common bio tools
RUN apt-get install -yq --no-install-recommends muscle r-base r-base-dev

# set environment locale
RUN echo "$LANG UTF-8" >> /etc/locale.gen
RUN echo "LANG=$LANG" > /etc/locale.conf
RUN echo "LC_ALL=$LC_ALL" >> /etc/environment
RUN echo "LANGUAGE=$LANGUAGE" >> /etc/environment
RUN locale-gen $LANG
RUN update-locale LANG=$LANG

RUN DEBIAN_FRONTEND=noninteractive TZ=$TIME_ZONE apt-get -y install tzdata

# add github key so can git clone from github
RUN mkdir ~/.ssh/
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts


# pmotools
WORKDIR /opt
RUN git clone https://github.com/PlasmoGenEpi/pmotools-python.git
WORKDIR /opt/pmotools-python
RUN git checkout develop
RUN pip install --break-system-packages .

# R configuration
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = ${CPU_COUNT})" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages(c("remotes", "devtools"))'

# R packages
RUN Rscript -e 'remotes::install_cran(c("tibble", "dplyr", "stringr", "readr", "optparse", "ggplot2", "tidyr", "data.table", "validate", "openxlsx", "Rmpfr", "rlang", "doParallel", "magrittr", "checkmate", "pegas", "ape", "rngtools"))'

RUN R -e "install.packages(c('dcifer', 'moire'), repos = c('https://plasmogenepi.r-universe.dev', 'https://cloud.r-project.org'))"
RUN R -e "devtools::install_github('mrc-ide/variantstring@develop')"

# Bioconductor packages (have to install 3.19 because that's needed for pwalign)
RUN Rscript -e 'if (!require("BiocManager", quietly = TRUE)) { install.packages("BiocManager"); }; BiocManager::install(version = "3.19", ask = FALSE);'
RUN Rscript -e 'BiocManager::install("Biostrings", ask = FALSE)'
RUN Rscript -e 'BiocManager::install("pwalign", ask = FALSE)'


# update path
ENV PATH="/opt/pmotools-python/scripts:$PATH"
