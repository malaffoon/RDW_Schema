#!/usr/bin/env bash

# utility methods

function print_banner() {
    echo $''
    echo $' __   __                   __   __       ___    __                            __       ___  __   __  '
    echo $'|__) |  \ |  |     |\/| | / _` |__)  /\   |  | /  \ |\ |    \  /  /\  |    | |  \  /\   |  /  \ |__) '
    echo $'|  \ |__/ |/\|     |  | | \__> |  \ /~~\  |  | \__/ | \|     \/  /~~\ |___ | |__/ /~~\  |  \__/ |  \ '
    echo $''
    echo $''
}

function not_null() {
    if [ -z $1 ]; then
        echo "$2 must not be null"
        exit 1
    fi
}

function now_in_seconds() {
    echo `date -u +%s`;
}

function now_in_YYYY_mm_dd_HHMMSS() {
    echo `date '+%Y-%m-%d-%H%M%S'`
}

function format_seconds_to_HH_MM_SS() {
    echo `date -u -r $1 +%T`
}

function get_absolute_path() {
    local basedir=`cd "$(dirname "$0")" ; pwd -P`
    echo "${basedir}/${1}"
}

function get_line_count() {
    cat $1 | wc -l
}

function get_property_by_index() {
    echo $1 | cut -f${2} -d"|"
}

function print_connection() {
    declare -a connection=("${!1}")
    echo "${connection[0]}:${connection[1]}:${connection[2]}:${connection[3]}"
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

function run_tests() {
    declare -a tests=("${!1}")
    for test in "${tests[@]}"
    do
        run_test_on_all_schema ${test}
    done
}

function run_test() {
    local database_type=$1
    local sql_file=$2
    local test_name=`get_property_by_index $3 1`
    local test_headers=`get_property_by_index $3 2`
    declare -a connection=("${!4}")
    local csv_file=`mktemp`
    echo "${test_headers}" >>  ${csv_file}
    if [ "${database_type}" == "mysql" ]; then
        mysql_to_csv connection[@] ${sql_file} >> ${csv_file}
    else
        psql_to_csv connection[@] ${sql_file} >> ${csv_file}
    fi
    echo "${csv_file}"
}

function compare_test_results() {
    local test_name=$1
    local a_namespace=$2
    local a=$3
    local b_namespace=$4
    local b=$5
    local test_result_dir=$6
    local comparison_file=`mktemp`

    diff ${diff_options} ${a} ${b} > ${comparison_file}

    local total_differences=$(( `get_line_count ${comparison_file}` ))

    if [ "${total_differences}" == "0" ]; then
        echo "  ${a_namespace}/${b_namespace} (passed)"
    else
        local diff_file=${test_result_dir}/${a_namespace}_${b_namespace}.diff
        mkdir -p ${test_result_dir}
        mv ${a} ${test_result_dir}/${a_namespace}.csv
        mv ${b} ${test_result_dir}/${b_namespace}.csv
        mv ${comparison_file} ${diff_file}
        echo "  ${a_namespace}/${b_namespace} (${total_differences} differences) ${test_result_dir}"
    fi
}

# setting dependent methods

function validate_input() {
    not_null ${warehouse_host} "warehouse_host"
    not_null ${warehouse_port} "warehouse_port"
    not_null ${warehouse_schema} "warehouse_schema"
    not_null ${warehouse_user} "warehouse_user"

    not_null ${reporting_host} "reporting_host"
    not_null ${reporting_port} "reporting_port"
    not_null ${reporting_schema} "reporting_schema"
    not_null ${reporting_user} "reporting_user"

    not_null ${reporting_olap_host} "reporting_olap_host"
    not_null ${reporting_olap_port} "reporting_olap_port"
    not_null ${reporting_olap_schema} "reporting_olap_schema"
    not_null ${reporting_olap_user} "reporting_olap_user"
}

function run_test_on_all_schema() {

    # expand pipe delimited test object into variables
    local test_name=`get_property_by_index $1 1`
    local test_headers=`get_property_by_index $1 2`

    echo "${test_name}"

    # get data from warehouse
    local warehouse_csv=`run_test "mysql" ${sql_dir}/${test_name}/${warehouse_namespace}.sql $1 warehouse_connection[@]`

    # get data from reporting and compare
    local reporting_sql=${sql_dir}/${test_name}/${reporting_namespace}.sql
    if [ -f ${reporting_sql} ]; then
        local reporting_csv=`run_test "mysql" ${reporting_sql} $1 reporting_connection[@]`
        compare_test_results ${test_name} ${warehouse_namespace} ${warehouse_csv} ${reporting_namespace} ${reporting_csv} ${out_dir}/${test_name}
    fi

    # get data from reporting_olap and compare
    local reporting_olap_sql=${sql_dir}/${test_name}/${reporting_olap_namespace}.sql
    if [ -f ${reporting_olap_sql} ]; then
        local reporting_olap_csv=`run_test "psql" ${reporting_olap_sql} $1 reporting_olap_connection[@]`
        compare_test_results ${test_name} ${warehouse_namespace} ${warehouse_csv} ${reporting_olap_namespace} ${reporting_olap_csv} ${out_dir}/${test_name}
    fi

    echo ''
}

function print_settings() {
    echo "validating..."
    echo ''
    echo "  ${warehouse_namespace}: $(print_connection warehouse_connection[@])"
    echo "  ${reporting_namespace}: $(print_connection reporting_connection[@])"
    echo "  ${reporting_olap_namespace}: $(print_connection reporting_olap_connection[@])"
    echo ''
}

function print_summary() {
    local end_time=`now_in_seconds`
    local elapsed_time_formatted=`format_seconds_to_HH_MM_SS $(($end_time-$start_time))`

    echo "completed in ${elapsed_time_formatted}"
    echo ''
}



### Entry Point ###

print_banner

# process input
not_null $1 "argument 1: config file path"
source $1
validate_input

# settings
start_time=`now_in_seconds`
base_dir=`cd "$(dirname "$0")" ; pwd -P`
sql_dir=${base_dir}/sql
out_dir="${base_dir}/results-$(now_in_YYYY_mm_dd_HHMMSS)"
diff_options="-y --suppress-common-lines"
warehouse_namespace=warehouse
reporting_namespace=reporting
reporting_olap_namespace=reporting_olap

# (host port schema user password)
declare -a warehouse_connection=("${warehouse_host}" "${warehouse_port}" "${warehouse_schema}" "${warehouse_user}" "${warehouse_password}")
declare -a reporting_connection=("${reporting_host}" "${reporting_port}" "${reporting_schema}" "${reporting_user}" "${reporting_password}")
declare -a reporting_olap_connection=("${reporting_olap_host}" "${reporting_olap_port}" "${reporting_olap_schema}" "${reporting_olap_user}" "${reporting_olap_password}")

# type|test_name|query,result,headers,csv
declare -a tests=(
    "total-ica|total_exams"
    "total-ica-scores|total_scale_score,total_standard_error,total_performance_level"
    "total-ica-by-asmt-asmtyear-condition-complete|total_exams,assessment_id,assessment_year,administrative_condition,complete"
    "total-ica-by-school-district|total_exams,school_id,district_name,school_name"
    "total-iab|total_exams"
    "total-iab-scores|total_scale_score,total_standard_error,total_performance_level"
    "total-iab-by-asmt-asmtyear-condition-complete|total_exams,assessment_id,assessment_year,administrative_condition,complete"
    "total-iab-by-school-district|total_exams,school_id,district_name,school_name"
)

print_settings
run_tests tests[@]
print_summary