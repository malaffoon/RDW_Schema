## Redshift aggregate reporting schema

#### To set up IntelliJ with the redshift database connection:
https://stackoverflow.com/questions/32319052/connect-intellij-to-amazon-redshift

####  To configure a search path in Redshift:
SHOW search_path;   <-- usually returns "$user, public"

ALTER DATABASE <database_name> SET search_path TO schema1,schema2;
ALTER ROLE <role_name> SET search_path TO schema1,schema2;
