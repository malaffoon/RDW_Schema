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
Below is an example of creating a secret file for the local environment and setting the file permissions to the owner.
```bash
touch secrets/local.sh && chmod 600 secrets/local.sh
```
Next, enter the below variables into the secrets file and replace the placeholders with the appropriate values.
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
#### Running
To run the script simply execute it and pass in the file path to your secrets file.
```bash
./validate-migration.sh secrets/local.sh
```
#### Example Output
```
 __   __                   __   __       ___    __                            __       ___  __   __  
|__) |  \ |  |     |\/| | / _` |__)  /\   |  | /  \ |\ |    \  /  /\  |    | |  \  /\   |  /  \ |__) 
|  \ |__/ |/\|     |  | | \__> |  \ /~~\  |  | \__/ | \|     \/  /~~\ |___ | |__/ /~~\  |  \__/ |  \ 


validating...

  warehouse:      localhost:3306:warehouse:root
  reporting:      localhost:3306:reporting:root
  reporting_olap: localhost:5439:reporting_olap:root

total-ica
  warehouse/reporting (passed)
  warehouse/reporting_olap (1 differences) /RDW_Schema/validation/results-2017-11-21-104916/total-ica

total-ica-scores
  warehouse/reporting (passed)
  warehouse/reporting_olap (1 differences) /RDW_Schema/validation/results-2017-11-21-104916/total-ica-scores

total-ica-by-asmt-asmtyear-condition-complete
  warehouse/reporting (passed)
  warehouse/reporting_olap (42 differences) /RDW_Schema/validation/results-2017-11-21-104916/total-ica-by-asmt-asmtyear-condition-complete

total-ica-by-school-district
  warehouse/reporting (passed)
  warehouse/reporting_olap (1066 differences) /RDW_Schema/validation/results-2017-11-21-104916/total-ica-by-school-district

total-iab
  warehouse/reporting (passed)

total-iab-scores
  warehouse/reporting (1 differences) /RDW_Schema/validation/results-2017-11-21-104916/total-iab-scores

total-iab-by-asmt-asmtyear-condition-complete
  warehouse/reporting (passed)

total-iab-by-school-district
  warehouse/reporting (passed)

completed in 00:00:02
```
To investigate a failed test, open the printed directory link in the terminal output.
Each directory will include the following:
```
validation/results-2017-11-21-104916/total-ica
├── reporting_olap.csv
├── warehouse.csv
└── warehouse_reporting_olap.diff
```
