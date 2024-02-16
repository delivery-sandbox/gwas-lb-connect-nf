## Changelog

PR centric changelog with description of notable changes implemented in a PR.

### 1.1.0

PR: https://github.com/lifebit-ai/end-to-end-target-identification/pull/10

#### Added

- Added `outdir` parameter in order to redirect `publishDir` through orchestrator job id
- Added `end_to_end_job_id` variable to all step processes

### 1.0.0

PR: https://github.com/lifebit-ai/drug-discovery-protocol-orchestrator-nf/pull/9

#### Added

<!--
Example:
- Added Dockerfile
-->
- Added profile `test_full_gel_lifebit_connect_staging`

#### Changed

<!--
Example:
- Updated template ci.yml test
-->
- Updated default parameters in `nextflow.config`

#### Removed

<!--
Example:
- Removed containers/ folder
-->
- Removed S3-related parameters (`s3_outdir`, `data_source`, `phenotype_group`, `phenotype_label`). The result connection from one process to annother is done using CloudOS now.