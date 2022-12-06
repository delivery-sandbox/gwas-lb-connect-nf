# Pipeline documentation

<ins>Table of contents</ins>

  - [1 - Pipeline description](#1---pipeline-description)
    - [1.1 - Pipeline overview](#11---pipeline-overview)
    - [1.2 - Input](#12---input)
    - [1.3 - Default processes](#13---default-processes)
    - [1.4 - Optional processes](#14---optional-processes)
    - [1.5 - Output](#15---output)
  - [2 - Options](#2---options)
  - [3 - Usage](#3---usage)
    - [3.1 - Running with Docker or Singularity](#31---running-with-docker-or-singularity)
    - [3.2 - Execution examples](#32---execution-examples)
  - [4 - Additional design information](#4---additional-design-information)
    - [4.1 - Design overview](#41---design-overview)
    - [4.2 - Covariates specification](#42---covariates-specification)
    - [4.3 - User made JSON cohort specification](#43---user-made-json-cohort-specification)
    - [4.4 - Cohort skeleton](#44---cohort-skeleton)
    - [4.5 - OMOP connection details](#45---omop-connection-details)

## 1 - <ins>Pipeline description</ins>

### 1.1 - <ins>Pipeline overview</ins>

  - Name: etl_omop2phenofile
  - Tools: R programming language and data wrangling packages
  - Dependencies: are listed in the [docs/dependencies.md](docs/dependencies.md)

The purpose of this pipeline is to create a phenofile using OMOP clinical data ingested in a database. This phenofile can then be used by downstream omics pipelines.

The following diagram is a schematic representation of all the major processes performed by this pipeline and their interconnections. The diagram shows the default processes and output files in blue with solid lines. Optional processes (if any) and inputs/outputs are in red with dashed lines.

![Overview](overview.png)

For a more in-depth representation of all Nextflow processes and channels, see see [pipeline-dag](pipeline-dag.png).

### 1.2 - <ins>Input</ins>

This pipeline takes in a number of input formats. These include:

- Custom cohort specification:
  - A `JSON` file containing a user-made cohort specification

- Covariate specifications:
  - A `JSON` file containing details of the covariates to include in the phenofile

- A number of OMOP database connection parameters or AWS SSM credentials

For details of all other inputs and options, see the Options section of this document.

### 1.3 - <ins>Default processes</ins>

- `retrieve_parameters`: generates a JSON file containing database connection details provided via `--database_*` parameters when `--param_via_aws` equals FALSE or `--aws_param_name_*` parameters when `--param_via_aws` equals TRUE.

- `generate_cohort_jsons_from_user_spec`: generates `JSON` cohort definition file(s) using the user-made input `JSON` provided via `--cohortSpecifications`.

- `generate_cohorts_in_db`: using the cohort definition file(s) made with the process `generate_cohort_jsons_from_user_spec` writes cohort(s) in the OMOP database.

- `generate_phenofile`: generates a phenofile using the cohort(s) written to the OMOP database and an input covariate specification supplied via `--covariateSpecifications`.

- `obtain_pipeline_metadata`: gathers various metadata settings about the pipeline (version, container settings etc) to produce a report that is then used in `produce_report`.

### 1.4 - <ins>Optional processes</ins>

This pipeline has no optional processes.

### 1.5 - <ins>Output</ins>

This pipeline produces the following outputs. See section `Usage` for commands but briefly:

Running the following command:

```
nextflow run main.nf \
--covariateSpecifications 'covariate_specs.json' \
--cohortSpecifications 'user_cohort_specs.json' \
-profile singularity
```

Produces the following outputs:
```
results
├── cohorts
│   ├── cohort_counts.csv
│   └── json
│       └── NASH.json
├── phenofile
│   └── phenofile.phe
└── pipeline_info
    ├── execution_report_2022-04-01_13-49-01.html
    ├── execution_timeline_2022-04-01_13-49-01.html
    ├── execution_trace_2022-04-01_13-57-55.txt
    └── pipeline_metadata_report.tsv

4 directories, 7 files
```

A more detailed description of all outputs are as followed:

- **<ins>pipeline_info<ins>**

  This folder contains Nextflow reports (timeline, execution and trace reports) that provide information on the status of the pipeline, the resources used etc. These are are named `execution_report_datetime.html`, `execution_timeline_datetime.html`, `execution_trace_datetime.txt` (where `datetime` is the date and time the file was created). More information can be found in the Nextflow documentation: `https://www.nextflow.io/docs/latest/tracing.html`. In addition, it contains:

  - A file called `pipeline_metadata_report.tsv` which contains additional metadata about the pipeline.

- **<ins>cohorts<ins>**

  - A file called `cohorts_counts.csv`: a `CSV` file describing the cohort(s) made using `--cohortSpecifications`. Each created cohort has a `cohortId`, `cohortEntries` (number of entries) and `cohortSubjects` (number of participants).

  - A file called `cohort_table_name.txt`: a `CSV` file describing the name of the cohorts created (one per line), more specically, the name assigned to them when uploaded to the OMOP database.

  - A folder called `json`: contains, per cohort, the JSON specification file made with the process `generate_cohort_jsons_from_user_spec`. The structure is based off the default cohort skeleton supplied via `--cohortJsonSkeleton`.

- **<ins>phenofile<ins>**

  Contains the output final phenofile called `phenofile.csv`. The present columns include:

  - `cohortDefinitionId`: the cohort definition ID
  - `subjectId`: the participant ID
  - On column per covariate (or one per covariate per option

## 2 - Options

The following table describes all parameters used by the pipeline. These paramaters are defined in `nextflow.config` and/or the configuration files found in `conf/`.

| param name | default values | description |
|---|---|---|
| outdir | 'results' | Name of the folder where all outputs are saved |
| tracedir | 'results/pipeline_info' | Name of the folder where all Nextflow reports (execution, timeline trace) and unique identifiers (UIDs) are saved |
| raci_owner | 'Lifebit' | The owner of this pipeline/task according to the client RACI chart |
| domain_keywords | 'etl; omop; biobanks; Genomics England (GEL); Finngen; UK Biobank (UKB)' | Domain key words associated with the pipeline |
| unique_identifier | 1156219d800535edf834ca403aa93b72 | A unique identifier used in pipeline introspection reporting |
| phenofileName | phenofile | A name for the output TSV file |
| covariateSpecifications | false | A file containing details of the covariates to include in the phenofile. See detailed formatting required in section 4.2 |
| cohortSpecifications | false | A file containing user-made cohort(s) specification. See detailed formatting required in section 4.3 |
| codelistSpecifications | false | A file containing user-made codelist specification. See detailed formatting required in section 4.2. |
| domain | false | If using a `codelistSpecification`, the domain in which to search for the codes provided.  |
| conceptType | false | If using a `codelistSpecification`, defines whether to search in the `_source_concept_id` or `_concept_id` column of the specificed `domain` table.  |
| controlIndexDate | false | If using a `codelistSpecification`, defines which date to use as the control group index date. Can either be `first`, `last` or `random`. |
| path_to_db_jars | assets/jars/postgresqlV42.2.18.zip | The path to the JAR files used to connect to the database via R |
| sqlite_db | https://omop-rsqlite.s3.eu-west-1.amazonaws.com/cdm.sqlite | The path to a SQLite database containin OMOP data to be used instead of connecting to Postgres |
| pheno_label | PHE | A phenolabel value used in generating a phenofile using the cohort(s) written to the OMOP database and an input covariate specification |
| convert_plink | true | A boolean value used in generating a phenofile using the cohort(s) written to the OMOP database and an input covariate specification |
| database_dbms | false | An OMOP database dbms. A credential used to connect to the database and used regarding if `--param_via_aws` equals TRUE or FALSE |
| database_cdm_schema | false | An OMOP database cdm schema name. A credential used to connect to the database and used regarding if `--param_via_aws` equals TRUE or FALSE |
| database_cohort_schema | false | An OMOP database cohort schema name. A credential used to connect to the database and used regarding if `--param_via_aws` equals TRUE or FALSE |
| database_name | false | An OMOP database name. A credential used to connect to the database |
| database_host | false | An OMOP database host. A credential used to connect to the database |
| database_port | false | An OMOP database port. A credential used to connect to the database |
| database_username | false | An OMOP database user name. A credential used to connect to the database |
| database_password | false | An OMOP database password. A credential used to connect to the database |
| param_via_aws | false | A boolean if the OMOP database credentials should be extracted using AWS SSM parameters |
| aws_region | "eu-west-2" | The SSM parameters region used to extract OMOP database credentials |
| aws_param_name_for_database_name | false | The SSM parameter name used to extract OMOP database name. A credential later used to connect to the database |
| aws_param_name_for_database_host | false | The SSM parameter name used to extract OMOP database host. A credential later used to connect to the database |
| aws_param_name_for_database_port | false | The SSM parameter name used to extract OMOP database port. A credential later used to connect to the database |
| aws_param_name_for_database_username | false | The SSM parameter name used to extract OMOP database user name. A credential later used to connect to the database |
| aws_param_name_for_database_password | false | The SSM parameter name used to extract OMOP database password. A credential later used to connect to the database |
| help | false | Prints a help message when using `nexflow run main.nf --help` |
| container | 'quay.io/lifebitaiorg/etl_omop2phenofile:latest' | Name of the container used for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| cpus | 1 | Number of CPUs required for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| memory | '2 GB' | RAM required for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| disk | '30.GB' | Disk space required for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| max_cpus | 2 | Maximum number of CPUs allocated for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| max_memory | '4 GB' | Maximum RAM allocated for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| max_time | '8h' | Maximum time allocated for each Nextflow process (unless process specific labels are used with `withLabel` or `withName`) |
| config | 'conf/standard.config' | Standard configuration file used by the pipeline (aside from `nextflow.config`) |
| echo | false | Show `stdout` inside the shell terminal |
| errorStrategy | { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'terminate' } | Determines how Nextflow process errors are handled. Certain exit statuses can be captured to enable retries if needed. See https://www.nextflow.io/docs/latest/process.html?highlight=errorstrategy#errorstrategy for more details |
| maxRetries | 9 | Defines the maximum number of times a Nextflow process instance can be re-submitted in case of failure. See https://www.nextflow.io/docs/latest/process.html?highlight=maxretries#maxretries for more details |
| maxForks | 200 | Maximum number of tasks a Nextflow process can have running at the same time. See https://www.nextflow.io/docs/latest/process.html?highlight=errorstrategy#maxforks for more details |
| queueSize | 200 | The number of tasks the executor will handle in a parallel manner. See https://www.nextflow.io/docs/latest/config.html?highlight=queuesize#scope-executor for more details |
| executor | false | Name of the executor |

## 3 - <ins>Usage</ins>

### 3.1 - <ins>Running with Docker or Singularity</ins>


**Importantly**, this pipeline requires a SQL database with OMOP data ingested. Instructions for setting up a database and ingesting OMOP data can be found in the repository of the ingestion pipeline. For the pipeline to run correctly, the OMOP database must be complete, including all vocabulary tables. An appropriate database can be populated using the `ingest_omop_full` in the ingestion pipeline.

For testing purposes, a SQLite OMOP database can be supplied using the parameter `sqlite_db`. To connect using any SQLite database provided, the connection details in `testdata/connection_details_sqlite.json` should be used.

To run the pipeline with `docker` (used by default), type the following command:

```
nextflow run main.nf -profile cohortsFromSpec,docker
```

To run the pipeline with `singularity`, type the following command:

```
nextflow run main.nf -profile cohortsFromSpec,singularity
```

All profiles are found in `conf/`.

### 3.2 - <ins>Execution examples</ins>

The typical command for running this pipeline is as follows:

```
nextflow run main.nf \
--covariateSpecifications 'covariate_specs.json' \
--cohortSpecifications 'user_cohort_specs.json'
```

## 4 - Additional design information

### 4.1 - <ins>Design overview</ins>

The purpose of this pipeline is to create a phenofile using OMOP clinical data ingested in a database. This phenofile can then be used by downstream omics pipelines.

The pipeline makes phenofiles in 3 steps:

- **Step 1**: generate a cohort `JSON` definition file. This is done using as input the user-made JSON specification via `--cohortSpecifications`  or a codelist via `--codelistSpecifications`.

- **Step 2**: using the cohort definition file, create a new OMOP table in the database and add cohort participants in it.

- **Step 3**: using the table from **Step 2** and input covariates supplied via `--covariateSpecifications`, make a phenofile.

### 4.2 - <ins>Codelist specification</ins>

Users can supply a `csv` format codelist. The columns required are:

| column | description |
| --- | --- |
| Phenotype_Short | The short name of the phenotype being defined |
| Criteria_Ontology | The ontoloy of 'criteria' (for example ICD10) |
| Criteria | The code itself (for example E10) |
| Is_Inclusion_Criteria | Whether the code is an inclusion criteria |
| Is_Exclusion_Criteria | Whether the code is an exclusion criteria |

If using this mode to generate a cohort, the following pipeline parameters are also required:

- `domain`: The domain of the codes (choose one of ConditionOccurrence, ProcedureOccurrence, DrugExposure, Observation, DeviceExposure etc.)
- `controlIndexDate`: How to choose the index date for the control group. This mode creates a control group by finding participants from the same `domain` who are not part of the case group. For these participants, the index date can either be the `first`, `last` or a `random` date of an event in this domain.
- `conceptType`: Whether to look for the `criteria` in the `_source_concept_id` or `_concept_id` column of the `domain` table (choose one of `sourceConceptId` or `conceptId`).

### 4.3 - <ins>Cohort specification</ins>

If more complicated cohort definitons are required, a JSON specification cohort definition can be supplied using the parameter `--cohortSpecifications`. For example:

```
[
  {
    "cohort_name": "NASH",
    "cohort_identifier": 1,
    "index_event": {
      "domain": "ConditionOccurrence",
      "source_concept_ids": 40481087,
      "occurrence": "first"
    },
    "qualifying_events": [
      {
        "domain": "ConditionOccurrence",
        "source_concept_ids": 4027663,
        "time_period": "all",
        "count": { "logic": "exactly", "amount": 0 }
      }
    ],
    "control_group": {
      "cohort_identifier": 2,
      "domain": "ConditionOccurrence",
      "occurrence": "first"
    }
  }
]
```

| Component | Definition |
| --- | --- |
| `cohort_name` | Is used to name artefacts associated with the cohort definition |
| `cohort_identifier` | Is used to define the `cohort_definition_id` in the OMOP database and the `pheno_label` column in the output phenofile. |
| `index_event` | Is the expression used to define the index date using which patient age is calculated along with any temporal qualifying events. |
| `domain` | Is domain / table that the event belongs to. Likely examples include `ConditionOccurrence`, `ProcedureOccurrence`, `DrugExposure`, `Observation` etc. |
|  `concept_ids` | `source_concept_id` | The OMOP `concept_ids` associated with the event in question. If `source_concept_id`, the cohort will be built by querying the `_source_concept_id` column in the `domain` table. If `concept_id`, the cohort will be built by querying the `_concept_id` column in the `domain` table. |
| `occurrence` | Can be either `first` or `last`, and defines whether the index date should be defined using the first or last occurrence of the event. |
| `qualifying_events` | Any number of events used to limit the population defined using the `index_event`, for example the presence or absence of other phenotypes. |
| `time_period` | Can be either `before`, `after` or `all`, and defines which time period with respect to the index date to search for qualifying events. |
| `count` | The criteria on which to limit the populaiton using. For example, `{ "logic": "exactly", "amount": 0 }` will exclude all patients with an occurrence of the qualifying event. |
| `control_group` | The definition for the control group. This takes the  `1 - case group` population and bases the index date on the defined `domain`. Here, `occurrence` can either be `first`, `last` or `random` |

### 4.4 - <ins>Covariate specification</ins>

The `JSON` file supplied via `--covariateSpecifications` must be formatted as follows:

- It should be an array of `JSON` objects where 1 object is 1 covariate.

- Each object can have the following fields:

| field | mandatory | format | description |
|---|---|---|---|
| covariate_name | yes | String | Name of the covariate in the final phenofile output by this pipeline |
| covariate | yes | String | Name of the covariate |
| concept_ids | no | Integer | Corresponding OMOP concept ID, if there is one |
| transformation | no | String | Transformation to apply to the covariate, when making the phenofile. See below for allowed transformations |

Allowed `transformation` options are as follows:

| transformation | description |
|---|---|
| value | For continuous covariates, for example height and age, this takes the direct value of the covariate. |
| binary | Converts categorical covariates where there are multiple categories into a single binary. For example, if a for a `condition_occurrence` covariate several `concept_ids` are specificated, the `binary` transformation will produce a single binary covariate which will be positive if the participant has a record of **any** of the conditions specified. |
| encoded | Converts categorical covariates where there are multiple categories into a multiple binary columns, one for each category (one-hot encoding) |
| categorical | Converts categorical covariates into a multicategorical covariate, where the covariate value is the name of the category. If one participant is a member multiple categories, the phenofile will contain multiple rows |
| custom | Any custom R function can be written to transform the data. In such cases, the entry must be a string formatted as such: `"function(x) str_c("Text here: ", x)"` |


By default, the pipeline uses a covariate specifictation using just `AGE` and `SEX`.

### 4.5 - <ins>OMOP connection details</ins>

The `JSON` file supplied via `--omopDbConnectionDetails` must be formatted as follows:

- It should be an array of `JSON` objects where 1 object is 1 covariate.

- Each object can have the following fields:

| field | mandatory | format | description |
|---|---|---|---|
| dbms | yes | String | Name of the database engine |
| server | yes | String | Name of the database server |
| port | yes | Integer | Database port |
| user | yes | String | Database user |
| password | yes | String | Database password |
| cdmDatabaseSchema | yes | String | Database schema |
| cohortDatabaseSchema | yes | String | Whether the schema is public or private |
