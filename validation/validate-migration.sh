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

sql_dir=sql
out_dir="results-${timestamp}"

warehouse_mysql_conf=`mktemp`
reporting_mysql_conf=`mktemp`

declare -a warehouse_connection=("${warehouse_host}" "${warehouse_port}" "${warehouse_schema}" "${warehouse_user}" "${warehouse_mysql_conf}")
declare -a reporting_connection=("${reporting_host}" "${reporting_port}" "${reporting_schema}" "${reporting_user}" "${reporting_mysql_conf}")
declare -a reporting_olap_connection=("${reporting_olap_host}" "${reporting_olap_port}" "${reporting_olap_schema}" "${reporting_olap_user}" "${reporting_olap_password}")

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

report_query="select testNum, result1, result2, result3, result4, result5 FROM post_validation ORDER BY testNum, id;"

declare -a tests=(
    "ica|total-ica|total_exams"
    "ica|total-ica-scores|total_scale_score,total_standard_error,total_performance_level"
    "ica|total-ica-by-asmt-asmtyear-condition-complete|total_exams,assessment_id,assessment_year,administrative_condition,complete"
    "ica|total-ica-by-school-district|total_exams,school_id,district_name,school_name"
    "iab|total-iab|total_exams"
    "iab|total-iab-scores|total_scale_score,total_standard_error,total_performance_level"
    "iab|total-iab-by-asmt-asmtyear-condition-complete|total_exams,assessment_id,assessment_year,administrative_condition,complete"
    "iab|total-iab-by-school-district|total_exams,school_id,district_name,school_name"
)

# methods

function create_mysql_password_file() {
    local password=$1
    local file_path=$2
    echo -e "[client]\npassword=${password}" > ${file_path} && chmod 600 ${file_path}
}

function setup() {
    mkdir -p ${out_dir}
    create_mysql_password_file "${warehouse_password}" "${warehouse_mysql_conf}"
    create_mysql_password_file "${reporting_password}" "${reporting_mysql_conf}"
}

function teardown() {
    rm ${warehouse_mysql_conf}
    rm ${reporting_mysql_conf}
}

trap ctrl_c INT

function ctrl_c() {
    teardown
}

function get_line_count() {
    cat $1 | wc -l
}

function call_mysql() {
    declare -a connection=("${!1}")
    local sql_file=$2
    mysql --defaults-extra-file=${connection[4]} -h ${connection[0]} -P ${connection[1]} -u ${connection[3]} ${connection[2]} -v < ${sql_file}
}

function mysql_to_csv() {
    declare -a connection=("${!1}")
    local sql_file=$2
    local csv_file=$3
    local csv_headers=$4
    echo "${csv_headers}" >> ${csv_file}
    mysql --defaults-extra-file=${connection[4]} -h ${connection[0]} -P ${connection[1]} -u ${connection[3]} ${connection[2]} -s < ${sql_file} | tr '\t' ',' >> ${csv_file}
}

function psql_to_csv() {
    declare -a connection=("${!1}")
    local sql_file=$2
    local csv_file=$3
    local csv_headers=$4
    echo "${csv_headers}" >> ${csv_file}
    set PGPASSWORD=${connection[5]}
    psql -w -h ${connection[0]} -p ${connection[1]} -U ${connection[3]} -d ${connection[2]} -t -F, -A -f ${sql_file} >> ${csv_file}
}

# TODO - each test should have its own diffs
function test() {
    local test_type=`echo $1 | cut -f1 -d"|"`
    local test_name=`echo $1 | cut -f2 -d"|"`
    local test_headers=`echo $1 | cut -f3 -d"|"`

    echo "running ${test_type} test: ${test_name}..."

    if [ "${test_type}" == "ica" ]; then
        mysql_to_csv warehouse_connection[@] ${sql_dir}/warehouse/${test_name}.sql ${warehouse_ica} ${test_headers}
        mysql_to_csv reporting_connection[@] ${sql_dir}/reporting/${test_name}.sql ${reporting_ica} ${test_headers}
        psql_to_csv reporting_olap_connection[@] ${sql_dir}/reporting_olap/${test_name}.sql ${reporting_olap_ica} ${test_headers}
    else
        mysql_to_csv warehouse_connection[@] ${sql_dir}/warehouse/${test_name}.sql ${warehouse_iab} ${test_headers}
        mysql_to_csv reporting_connection[@] ${sql_dir}/reporting/${test_name}.sql ${reporting_iab} ${test_headers}
    fi
}

function run_tests() {
    for i in "${tests[@]}"
    do
        test ${i}
    done
}

function create_reports() {
    echo 'creating reports...'

    diff ${diff_options} ${warehouse_ica} ${reporting_ica} > ${warehouse_reporting_ica_diff}
    diff ${diff_options} ${warehouse_iab} ${reporting_iab} > ${warehouse_reporting_iab_diff}
    diff ${diff_options} ${reporting_ica} ${reporting_olap_ica} > ${reporting_reporting_olap_ica_diff}
}

function print_summary() {
    local total_warehouse_reporting_ica_differences=`get_line_count ${warehouse_reporting_ica_diff}`
    local total_warehouse_reporting_iab_differences=`get_line_count ${warehouse_reporting_iab_diff}`
    local total_warehouse_reporting_olap_ica_differences=`get_line_count ${reporting_reporting_olap_ica_diff}`
    local total_differences=$(( total_warehouse_reporting_ica_differences + total_warehouse_reporting_iab_differences + total_warehouse_reporting_olap_ica_differences ));

    local end_time=`date -u +%s`
    local elapsed_time="$(($end_time-$start_time))"
    local elapsed_time_formatted=`date -u -r ${elapsed_time} +%T`

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

}

# script lifecycle
setup
run_tests
create_reports
teardown
print_summary
