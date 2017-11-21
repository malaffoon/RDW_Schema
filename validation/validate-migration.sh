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

diff_options="-y --suppress-common-lines"

# (host port schema user password)
declare -a warehouse_connection=("${warehouse_host}" "${warehouse_port}" "${warehouse_schema}" "${warehouse_user}" "${warehouse_password}")
declare -a reporting_connection=("${reporting_host}" "${reporting_port}" "${reporting_schema}" "${reporting_user}" "${reporting_password}")
declare -a reporting_olap_connection=("${reporting_olap_host}" "${reporting_olap_port}" "${reporting_olap_schema}" "${reporting_olap_user}" "${reporting_olap_password}")

# type|test_name|query,result,headers,csv
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

function get_line_count() {
    cat $1 | wc -l
}

function create_mysql_password_file() {
    local password=$1
    local file_path=`mktemp`
    echo -e "[client]\npassword=${password}" > ${file_path} && chmod 600 ${file_path}
    echo ${file_path}
}

function mysql_to_csv() {
    declare -a connection=("${!1}")
    local sql_file=$2
    local csv_file=$3
    local csv_headers=$4
    local password_file=`create_mysql_password_file "${connection[4]}"`
    mysql --defaults-extra-file=${password_file} -h ${connection[0]} -P ${connection[1]} -u ${connection[3]} ${connection[2]} -s < ${sql_file} | tr '\t' ','
    rm ${password_file}
}

function psql_to_csv() {
    declare -a connection=("${!1}")
    local sql_file=$2
    local csv_file=$3
    local csv_headers=$4
    set PGPASSWORD=${connection[5]}
    psql -w -h ${connection[0]} -p ${connection[1]} -U ${connection[3]} -d ${connection[2]} -t -F, -A -f ${sql_file}
    set PGPASSWORD=
}

function run_test() {
    local cli_command=$1
    local schema_alias=$2
    local test_name=`echo $3 | cut -f2 -d"|"`
    local test_headers=`echo $3 | cut -f3 -d"|"`
    declare -a connection=("${!4}")
    local csv_file=`mktemp`
    echo "${test_headers}" >>  ${csv_file}
    if [ "${cli_command}" == "mysql" ]; then
        mysql_to_csv connection[@] ${sql_dir}/${schema_alias}/${test_name}.sql >> ${csv_file}
    else
        psql_to_csv connection[@] ${sql_dir}/${schema_alias}/${test_name}.sql >> ${csv_file}
    fi
    echo "${csv_file}"
}

function compare_test_results() {
    local test_name=$1
    local a_namespace=$2
    local a=$3
    local b_namespace=$4
    local b=$5
    local comparison_file=`mktemp`

    diff ${diff_options} ${a} ${b} > ${comparison_file}

    local total_differences=$(( `get_line_count ${comparison_file}` ))

    if [ "${total_differences}" == "0" ]; then
        echo "  ${a_namespace}/${b_namespace} (passed)"
    else
        local test_result_dir=${out_dir}/${test_name}
        local diff_file=${test_result_dir}/${a_namespace}_${b_namespace}.diff
        mkdir -p ${test_result_dir}
        mv ${a} ${test_result_dir}/${a_namespace}.csv
        mv ${b} ${test_result_dir}/${b_namespace}.csv
        mv ${comparison_file} ${diff_file}
        echo "  ${a_namespace}/${b_namespace} (${total_differences} differences) ${diff_file}"
    fi
}

function run_test_on_all_schema() {
    local test_type=`echo $1 | cut -f1 -d"|"`
    local test_name=`echo $1 | cut -f2 -d"|"`
    local test_headers=`echo $1 | cut -f3 -d"|"`

    echo "${test_name}"

    # get data from warehouse
    local warehouse_csv=`run_test "mysql" "warehouse" $1 warehouse_connection[@]`

    # get data from reporting and compare
    local reporting_csv=`run_test "mysql" "reporting" $1 reporting_connection[@]`
    compare_test_results ${test_name} "warehouse" ${warehouse_csv} "reporting" ${reporting_csv}

    # get data from reporting_olap and compare
    if [ "${test_type}" == "ica" ]; then
        local reporting_olap_csv=`run_test "psql" "reporting_olap" $1 reporting_olap_connection[@]`
        compare_test_results ${test_name} "warehouse" ${warehouse_csv} "reporting_olap" ${reporting_olap_csv}
    fi

    echo ''
}

function run_tests() {
    for i in "${tests[@]}"
    do
        run_test_on_all_schema ${i}
    done
}

# entry point
run_tests

# summarize results
end_time=`date -u +%s`
elapsed_time="$(($end_time-$start_time))"
elapsed_time_formatted=`date -u -r ${elapsed_time} +%T`

echo "completed in ${elapsed_time_formatted}"
echo ''