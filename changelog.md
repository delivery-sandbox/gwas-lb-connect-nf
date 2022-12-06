# Changelog

## v1.3.0

### Enhancements

- Add new version of Nextflow for testing

## v1.2.3

### Enhancements

- Adds option to use SSM parameters for database credentials

## v1.2.2

### Fixes

- Updates the documentation

## v1.2.1

### Fixes

- In `codelist` mode, user `1` as default label for controls and `2` as default label for cases.

## v1.2.0

### Fixes

- Adds option to add specific database credentials

## v1.1.5

### Fixes

- Corrects headers in plink phenofile output.

### Enhancements

- Adds option to provide a valid range for covariates and impute with either the median or mean.

## v1.1.4

### Fixes

- Adds ability to automaticaly start a CloudOS job for CI testing.

## v1.1.3

### Fixes

- Updating the docs and container with the new pipeline name

## v1.1.2

### Fixes

- Fixes plink gender encodings

## v1.1.1

### Enhancements

- Adds Jenkinsfile

## v1.1.0

### Enhancements

- Makes `Capr` responsible for rendering cohort JSON and SQL to allow complex and flexible cohort definitions. 
- Changes the format of user cohort specifications to account for the use of `Capr`.
- Adds a new mode where cohorts can be defined using a codelist, complete with parameters to control control group definitions.
- Adds a parameter which reformats OMOP style phenofiles to plink style 

### Enhancements

## v1.0.4

### Enhancements

- Adds support for SQLlite databases and uses [Eunomia](https://github.com/OHDSI/Eunomia) database for testing (Fixes BL-582 and BL-595)
- Removes external dependency by storing postgres jar connection files in `assets` (Fixes BL-507)

## v1.0.3

### Enhancements

- Adds enhancements

## v1.0.2

### Enhancements

- Improves documentation

## v1.0.1

### Enhancements

- First release
- Includes basic functionality and extensive documentation


