#!/usr/bin/env bash

# default options

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

# start up

echo $''
echo $'   __   __                   __   __       ___    __                            __       ___  __   __  '
echo $'  |__) |  \ |  |     |\/| | / _` |__)  /\   |  | /  \ |\ |    \  /  /\  |    | |  \  /\   |  /  \ |__) '
echo $'  |  \ |__/ |/\|     |  | | \__> |  \ /~~\  |  | \__/ | \|     \/  /~~\ |___ | |__/ /~~\  |  \__/ |  \ '
echo $''
echo $''

# process input

source $1

# validation options

if [ -z ${warehouse_host} ]; then echo "warehouse_host must be set"; exit 1; fi
if [ -z ${warehouse_port} ]; then echo "warehouse_port must be set"; exit 1; fi
if [ -z ${warehouse_schema} ]; then echo "warehouse_schema must be set"; exit 1; fi
if [ -z ${warehouse_user} ]; then echo "warehouse_user must be set"; exit 1; fi

if [ -z ${reporting_host} ]; then echo "reporting_host must be set"; exit 1; fi
if [ -z ${reporting_port} ]; then echo "reporting_port must be set"; exit 1; fi
if [ -z ${reporting_schema} ]; then echo "reporting_schema must be set"; exit 1; fi
if [ -z ${reporting_user} ]; then echo "reporting_user must be set"; exit 1; fi

if [ -z ${reporting_olap_host} ]; then echo "reporting_olap_host must be set"; exit 1; fi
if [ -z ${reporting_olap_port} ]; then echo "reporting_olap_port must be set"; exit 1; fi
if [ -z ${reporting_olap_schema} ]; then echo "reporting_olap_schema must be set"; exit 1; fi
if [ -z ${reporting_olap_user} ]; then echo "reporting_olap_user must be set"; exit 1; fi

# settings

timestamp=`date '+%Y-%m-%d-%H%M%S'`
start_time=`date -u +%s`

script_dir=.
out_dir=`mktemp -d`
warehouse_mysql_conf=`mktemp`
reporting_mysql_conf=`mktemp`

warehouse_ica=${out_dir}/warehouse_ica.csv
warehouse_iab=${out_dir}/warehouse_iab.csv
reporting_ica=${out_dir}/reporting_ica.csv
reporting_iab=${out_dir}/reporting_iab.csv
reporting_olap_ica=${out_dir}/reporting_olap_ica.csv

warehouse_reporting_ica_diff=${out_dir}/warehouse_reporting_ica.diff
warehouse_reporting_iab_diff=${out_dir}/warehouse_reporting_iab.diff
reporting_reporting_olap_ica_diff=${out_dir}/reporting_reporting_olap_ica.diff

diff_options="-y --suppress-common-lines"
tree_options="--noreport"

report_query="select testNum, result1, result2, result3, result4, result5 FROM ica_validation ORDER BY testNum, id;"

# set up

mkdir -p ${out_dir}

echo -e "[client]\npassword=${warehouse_password}" > ${warehouse_mysql_conf} && chmod 600 ${warehouse_mysql_conf}
echo -e "[client]\npassword=${reporting_password}" > ${reporting_mysql_conf} && chmod 600 ${reporting_mysql_conf}

# run sql analysis scripts

echo 'analyzing warehouse data...'

mysql --defaults-extra-file=${warehouse_mysql_conf} -h ${warehouse_host} -P ${warehouse_port} -u ${warehouse_user} ${warehouse_schema} -v < ${script_dir}/validate-reporting-ica.sql
mysql --defaults-extra-file=${warehouse_mysql_conf} -h ${warehouse_host} -P ${warehouse_port} -u ${warehouse_user} ${warehouse_schema} -B -e "${report_query}" | tr '\t' ',' > ${warehouse_ica}
mysql --defaults-extra-file=${warehouse_mysql_conf} -h ${warehouse_host} -P ${warehouse_port} -u ${warehouse_user} ${warehouse_schema} -v < ${script_dir}/validate-reporting-iab.sql
mysql --defaults-extra-file=${warehouse_mysql_conf} -h ${warehouse_host} -P ${warehouse_port} -u ${warehouse_user} ${warehouse_schema} -B -e "${report_query}" | tr '\t' ',' > ${warehouse_iab}

echo 'analyzing reporting data...'

mysql --defaults-extra-file=${reporting_mysql_conf} -h ${reporting_host} -P ${reporting_port} -u ${reporting_user} ${reporting_schema} -v < ${script_dir}/validate-warehouse-ica.sql
mysql --defaults-extra-file=${reporting_mysql_conf} -h ${reporting_host} -P ${reporting_port} -u ${reporting_user} ${reporting_schema} -B -e "${report_query}" | tr '\t' ',' > ${reporting_ica}
mysql --defaults-extra-file=${reporting_mysql_conf} -h ${reporting_host} -P ${reporting_port} -u ${reporting_user} ${reporting_schema} -v < ${script_dir}/validate-warehouse-iab.sql
mysql --defaults-extra-file=${reporting_mysql_conf} -h ${reporting_host} -P ${reporting_port} -u ${reporting_user} ${reporting_schema} -B -e "${report_query}" | tr '\t' ',' > ${reporting_iab}

echo 'analyzing reporting olap data...'

set PGPASSWORD=${reporting_olap_password}
psql -w -h ${reporting_olap_host} -p ${reporting_olap_port} -U ${reporting_olap_user} -d ${reporting_olap_schema} -a -f ${script_dir}/validate-reporting-olap-ica.sql
psql -w -h ${reporting_olap_host} -p ${reporting_olap_port} -U ${reporting_olap_user} -d ${reporting_olap_schema} -t -F, -A -c "${report_query}" > ${reporting_olap_ica}

echo 'creating reports...'

diff ${diff_options} ${warehouse_ica} ${reporting_ica} > ${warehouse_reporting_ica_diff}
diff ${diff_options} ${warehouse_iab} ${reporting_iab} > ${warehouse_reporting_iab_diff}
diff ${diff_options} ${reporting_ica} ${reporting_olap_ica} > ${reporting_reporting_olap_ica_diff}

# clean up

rm ${warehouse_mysql_conf}
rm ${reporting_mysql_conf}

# conclusion

total_warehouse_reporting_ica_differences=`cat ${warehouse_reporting_ica_diff} | wc -l`
total_warehouse_reporting_iab_differences=`cat ${warehouse_reporting_iab_diff} | wc -l`
total_warehouse_reporting_olap_ica_differences=`cat ${reporting_reporting_olap_ica_diff} | wc -l`
total_differences=$(( total_warehouse_reporting_ica_differences + total_warehouse_reporting_iab_differences + total_warehouse_reporting_olap_ica_differences ));

end_time=`date -u +%s`
elapsed_time="$(($end_time-$start_time))"
elapsed_time_formatted=`date -u -r ${elapsed_time} +%T`

echo ''
echo "completed in ${elapsed_time_formatted}"
echo ''
tree ${tree_options} ${out_dir}
echo ''
if [ "${total_differences}" == "0" ]; then
    echo 'no issues detected.';
else
    echo 'possible issues detected:';
    echo ''
    echo "total differences: ${total_differences}"
    echo "total differences between warehouse and reporting ICAs: ${total_warehouse_reporting_ica_differences}"
    echo "total differences between warehouse and reporting IABs: ${total_warehouse_reporting_iab_differences}"
    echo "total differences between reporting and reporting OLAP ICAs: ${total_warehouse_reporting_olap_ica_differences}"
fi
echo ''