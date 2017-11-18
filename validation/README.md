### Migration Validation

#### Prerequisites
1. `mysql`
1. `psql`

#### Preparation
First make sure the script is executable.
```bash
chmod 755 validate-migration.sh
``` 
Next create an environment-specific secrets file under the git-ignored secrets directory and replace all the properties as needed.
It is important to place them somewhere that will not get checked in.

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
```bash
./validate-migration.sh [environment_properties_file]
```
#### Output

##### Success
```
completed in 00:00:08

/var/folders/h6/gw7zs2cd0cl0v5pd42gtf4740000gp/T/tmp.EdjR0AEZ
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

/var/folders/h6/gw7zs2cd0cl0v5pd42gtf4740000gp/T/tmp.EdjR0AEZ
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