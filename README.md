## RDW_Schema 
The goal of this project is to create MySQL 5.6 db schema for Smarter Balanced Reporting Data Warehouse and load the core data.

This project uses [flyway](https://flywaydb.org/getstarted). You must have Flyway installed and running for things to work. 
For MacOS: 
```bash
brew install flyway 
```

#### To create the schema 
There are multiple schemas: a data warehouse and data mart(s). Each has a corresponding folder. 
Flyway configurations can be found in the `flyway.properties` file. 
A script have been provided (mostly to provide a hook for IDEA configurations).
To install, go to a corresponding folder and run:
```bash
warehouse$ flyway -configFile=flyway.properties migrate
OR
warehouse$ ../scripts/migrate
```

#### To wipe out the schema
```bash
warehouse$ flyway -configFile=flyway.properties clean
OR
warehouse$ ../scripts/clean
```

#### Alternate Data Source
The data source, user, password, etc. can be overridden on the command line, e.g.
```bash
warehouse$ ../scripts/migrate -url="jdbc:mysql://rdw-aurora-dev.cugsexobhx8t.us-west-2.rds.amazonaws.com:3306/" -user=sbac -password=mypassword
```

### Developing
Flyway requires prefixing each script with the version. To avoid a prefix collision use a timestamp for a prefix. 
This project uses the following pattern:yyyyMMddHHmmss. To get timestamp on MacOS:
```bash
date +'%Y%m%d%s'
```