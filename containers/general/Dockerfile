FROM continuumio/miniconda3@sha256:456e3196bf3ffb13fee7c9216db4b18b5e6f4d37090b31df3e0309926e98cfe2
LABEL description="Dockerfile containing all the requirements for the lifebit-ai/etl-omop2phenofile" \
      author="henry@lifebit.ai, magda@lifebit.ai"

RUN apt-get --allow-releaseinfo-change update \
    && apt-get install -y wget zip procps libxt-dev p7zip-full uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a

ENV PATH=/opt/conda/envs/etl-omop2phenofile/bin:$PATH
ENV PATH="$PATH:/opt/bin/"

RUN Rscript -e 'devtools::install_github("OHDSI/FeatureExtraction@v3.2.0")'
RUN Rscript -e 'devtools::install_github("OHDSI/CohortGenerator@v0.4.0")'
RUN Rscript -e 'devtools::install_github("OHDSI/ROhdsiWebApi@v1.3.1")'


# Dump the details of the installed packages to a file for posterity
RUN conda env export --name etl-omop2phenofile > etl-omop2phenofile_exported.yml

USER root

WORKDIR /data/

CMD ["bash"]
