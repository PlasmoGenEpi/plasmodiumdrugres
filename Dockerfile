# Start with an official bioconda/base image which includes Conda
FROM bioconda/base:latest

# Set the working directory in the container
WORKDIR /workspace

# Install system dependencies and update packages
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && apt-get clean

# Install Miniconda (lightweight version of Conda)
RUN curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh

# Add Conda to PATH
ENV PATH="/opt/conda/bin:$PATH"

# Create Conda environment with the specified dependencies
RUN conda create -n nf-core-pipeline-env \
    r-base=4.4.2 \
    r-dplyr \
    r-optparse \
    r-ggplot2 \
    r-tidyr \
    r-data.table \
    r-stringr \
    r-readr \
    python=3.9 \
    nextflow \
    -c conda-forge \
    -c bioconda \
    -c defaults
