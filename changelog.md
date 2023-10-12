## Changelog

PR centric changelog with description of notable changes implemented in a PR.

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