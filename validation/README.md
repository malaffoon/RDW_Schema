### Migration Validation

#### Prerequisites
1. `mysql`
1. `psql`

#### Preparation
First make sure the script is executable.
```bash
chmod 755 validate-migration.sh
``` 
Next create an environment-specific secrets file under the git-ignored `secrets` directory.
It is important to place them somewhere that will not get checked in.
Also, you will need to set the access to just the file creator.
```bash
touch secrets/my-secrets.sh && chmod 600 secrets/my-secrets.sh
```
Next enter the below variables into the secrets file:
```bash
#!/usr/bin/env bash

warehouse_host=localhost
warehouse_port=3306
warehouse_schema=warehouse
warehouse_user=root
warehouse_password=

reporting_host=localhost
reporting_port=3306
reporting_schema=reporting
reporting_user=root
reporting_password=

reporting_olap_host=localhost
reporting_olap_port=5439
reporting_olap_schema=reporting_olap
reporting_olap_user=root
reporting_olap_password=
```
#### Execution
To run the script simply execute it and pass in the file path to your secrets file.
```bash
./validate-migration.sh secrets/my-secrets.sh
```
#### Output

##### Success
```
completed in 00:00:08

results-2017-11-17-201418
├── reporting_iab.csv
├── reporting_ica.csv
├── reporting_olap_ica.csv
├── reporting_reporting_olap_ica.diff
├── warehouse_iab.csv
├── warehouse_ica.csv
├── warehouse_reporting_iab.diff
└── warehouse_reporting_ica.diff

no issues detected.
```
The results can then be viewed in the output listed in the summary directory.

##### Failure
```
completed in 00:00:08

results-2017-11-17-201418
├── reporting_iab.csv
├── reporting_ica.csv
├── reporting_olap_ica.csv
├── reporting_reporting_olap_ica.diff
├── warehouse_iab.csv
├── warehouse_ica.csv
├── warehouse_reporting_iab.diff
└── warehouse_reporting_ica.diff

possible issues detected:

total differences: 1116
total differences between warehouse and reporting ICAs:        0
total differences between warehouse and reporting IABs:        0
total differences between reporting and reporting OLAP ICAs:     1116
```
When issues are detected these can be inspected by opening the corresponding diff file and looking at the side by side file comparisons.