### Migration Validation

#### Prerequisites
1. `mysql`
1. `psql`

#### Preparation
First, clone the repository and make sure the script is executable.
```bash
git clone https://github.com/SmarterApp/RDW_Schema
cd RDW_Schema/validation
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
1. To validate both reporting and aggregate reporting (aka OLAP), simply execute it and pass in the file path to your secrets file.
```bash
./validate-migration.sh secrets/local.sh
```
2. To validate both reporting only
```bash
./validate-migration.sh secrets/local.sh reporting
```
3. To validate aggregate reporting only
```bash
./validate-migration.sh secrets/local.sh olap
```

NOTE: When running tests you may see multiple "Warning: Using a password on the command line interface can be insecure.", please ignore it. 

#### Example Output
```
 __   __                   __   __       ___    __                            __       ___  __   __  
|__) |  \ |  |     |\/| | / _` |__)  /\   |  | /  \ |\ |    \  /  /\  |    | |  \  /\   |  /  \ |__) 
|  \ |__/ |/\|     |  | | \__> |  \ /~~\  |  | \__/ | \|     \/  /~~\ |___ | |__/ /~~\  |  \__/ |  \ 


validating...

  warehouse connection:      localhost:3306:warehouse:root
  reporting connection:      localhost:3306:reporting:root
  reporting olap connection: localhost:5439:reporting_olap:root

************ Running reporting olap tests ************
Running Test: total-ica *******************
getting data from warehouse
getting data from reporting
  olap_warehouse/olap_reporting (passed)

Running Test: total-ica-scores *******************
getting data from warehouse
getting data from reporting
  olap_warehouse/olap_reporting (passed)

Running Test: total-ica-by-asmt-schoolyear-condition-complete *******************
getting data from warehouse
getting data from reporting
  olap_warehouse/olap_reporting (passed)

Running Test: total-ica-by-school-district *******************
getting data from warehouse
getting data from reporting
  olap_warehouse/olap_reporting (passed)

************ Running reporting tests ************
Running Test: total-ica *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

Running Test: total-ica-scores *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (1 differences) /Users/allagorina/development/SBRDW/RDW_Schema/validation/results-2018-01-08-091053/total-ica-scores

Running Test: total-ica-by-asmt-schoolyear-condition-complete *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

Running Test: total-ica-by-school-district *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

Running Test: total-iab *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

Running Test: total-iab-scores *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (1 differences) /Users/allagorina/development/SBRDW/RDW_Schema/validation/results-2018-01-08-091053/total-iab-scores

Running Test: total-iab-by-asmt-asmtyear-condition-complete *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

Running Test: total-iab-by-school-district *******************
getting data from warehouse
getting data from reporting
  warehouse/reporting (passed)

completed in 00:10:37
```
To investigate a failed test, open the printed directory link in the terminal output.
If the comparison between warehouse and reporting_olap failed for instance, you would see the following files:
```
validation/results-2018-01-08-091053/total-ica-scores
├── reporting.csv
├── warehouse.csv
└── warehouse_reporting.diff
```
