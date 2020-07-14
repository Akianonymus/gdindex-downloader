#!/usr/bin/env bash
# Download file/folder from gdindex.
# shellcheck source=/dev/null

_usage() {
    printf "
The script can be used to download files/directory from gdindex.\n
Usage:\n %s [options.. ] <file_[url|id]> or <folder[url|id]>\n
Options:\n
  -d | --directory 'foldername' - option to _download given input in custom directory.\n
  -s | --skip-subdirs - Skip downloading of sub folders present in case of folders.\n
  -p | --parallel 'no_of_files_to_parallely_upload' - Download multiple files in parallel.\n
  --speed 'speed' - Limit the download speed, supported formats: 1K, 1M and 1G.\n
  -l | --log 'file_to_save_info' - Save downloaded files info to the given filename.\n
  -v | --verbose - Display detailed message (only for non-parallel uploads).\n
  --skip-internet-check - Do not check for internet connection, recommended to use in sync jobs.\n
  -u | --update - Update the installed script in your system.\n
  -V | --version - Show detailed info, only if script is installed system wide.\n
  --uninstall - Uninstall script, remove related files.\n
  -D | --debug - Display script command trace.\n
  -h | --help - Display usage instructions.\n\n" "${0##*/}"
    exit 0
}

_short_help() {
    printf "No valid arguments provided, use -h/--help flag to see usage.\n"
    exit 0
}

###################################################
# Automatic updater, only update if script is installed system wide.
###################################################
_auto_update() {
    (
        if [[ -w ${INFO_FILE} ]] && source "${INFO_FILE}" && command -v "${COMMAND_NAME}" &> /dev/null; then
            if [[ $((LAST_UPDATE_TIME + AUTO_UPDATE_INTERVAL)) -lt $(printf "%(%s)T\\n" "-1") ]]; then
                _update 2>&1 1>| "${INFO_PATH}/update.log"
                _update_config LAST_UPDATE_TIME "$(printf "%(%s)T\\n" "-1")" "${INFO_FILE}"
            fi
        else
            return 0
        fi
    ) &> /dev/null &
    return 0
}

###################################################
# Install/Update/uninstall the script.
###################################################
_update() {
    declare job="${1:-update}"
    [[ ${job} =~ uninstall ]] && job_string="--uninstall"
    _print_center "justify" "Fetching ${job} script.." "-"
    if [[ -w ${INFO_FILE} ]]; then
        source "${INFO_FILE}"
    fi
    declare repo="${REPO:-Akianonymus/gdindex-downloader}" type_value="${TYPE_VALUE:-master}"
    if script="$(curl --compressed -Ls "https://raw.githubusercontent.com/${repo}/${type_value}/install.sh")"; then
        _clear_line 1
        bash <(printf "%s\n" "${script}") ${job_string:-} --skip-internet-check
    else
        _print_center "justify" "Error: Cannot download ${job} script." "=" 1>&2
        exit 1
    fi
    exit "${?}"
}

###################################################
# Print the contents of info file if scipt is installed system wide.
# Path is "${HOME}/.gdindex-downloader/gdindex-downloader.info"
###################################################
_version_info() {
    if [[ -r ${INFO_FILE} ]] && source "${INFO_FILE}" && command -v "${COMMAND_NAME}" &> /dev/null; then
        printf "%s\n" "$(< "${INFO_FILE}")"
    else
        printf "%s\n" "gdindex-downloader is not installed system wide."
    fi
    exit 0
}

###################################################
# Default curl command use everywhere.
###################################################
_fetch() {
    curl -s --compressed "${@}" || return 1
}

###################################################
# convert json given by index url post request to a format which can be parsed by _json_value function
# This is dirty af, but who cares.
###################################################
_parse_json() {
    sed -e "s/\[{/\n\[{\n/g" -e "s/}\]/\n}\]\n/g" -e "s/},{/\n},{\n/g" \
        -e "s/\"id\"/\n\"id\"/g" \
        -e "s/\"name\"/\n\"name\"/g" \
        -e "s/\"mimeType\"/\n\"mimeType\"/g" \
        -e "s/\"modifiedTime\"/\n\"modifiedTime\"/g" \
        -e "s/\"size\"/\n\"size\"/g"
}

###################################################
# Check if url is valid and determine if it's folder.
# otherwise exit the script.
###################################################
_check_url() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    _print_center "justify" "Validating URL.." "-"
    declare url="${1}" headers
    if headers="$(_fetch -I -X POST "${url}")"; then
        code="$(_head 1 <<< "${headers}")"
        if ! [[ ${code} =~ ^(40.*|50.*)+$ ]]; then
            filename="$(sed -n "s/content-disposition:.*''//p" <<< "${headers}")"
            if [[ -n ${filename} ]]; then
                FILE_URL="${url}"
                FILE_SIZE="$(sed -n "s/content-length: //p" <<< "${headers//$'\r'/}")"
                for _ in {1..2}; do _clear_line 1; done && _newline "\n" && _print_center "justify" "File Detected" "=" && _newline "\n"
            else
                FOLDER_URL="${url}"
                for _ in {1..2}; do _clear_line 1; done && _print_center "justify" "Folder Detected" "=" && _newline "\n"
                _print_center "justify" "Fetching" " folder details.." "-"
                if JSON="$(_fetch -X POST "${url}/")" && ! [[ ${JSON} =~ html ]]; then
                    for _ in {1..2}; do _clear_line 1; done
                    JSON="$(_parse_json <<< "${JSON}")"
                else
                    for _ in {1..2}; do _clear_line 1; done
                    _print_center "justify" "Cannot fetch" " folder details" "=" && _newline "\n"
                    return 1
                fi

            fi
        else
            for _ in {1..2}; do _clear_line 1; done && _newline "\n" && _print_center "justify" "Invalid URL" "=" && _newline "\n"
            return 1
        fi
    else
        _clear_line 1
        _print_center "justify" "Error: Cannot check URL" "="
        printf "%s\n" "${headers}"
        exit 1
    fi
    export JSON
    return 0
}

###################################################
# Download a gdindex file
###################################################
_download_file() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    declare file_url="${1}" server_size="${2}"
    declare name error_status success_status
    name="$(_url_decode "$(_basename "${file_url}")")"
    if [[ -n ${name} ]]; then
        server_size_readable="$(_bytes_to_human "${server_size}")"
        _print_center "justify" "${name}" "${server_size:+ | ${server_size_readable}}" "="

        _log_in_file() {
            if [[ -n ${LOG_FILE_URL} && ! -d ${LOG_FILE_URL} ]]; then
                # shellcheck disable=SC2129
                # https://github.com/koalaman/shellcheck/issues/1202#issuecomment-608239163
                {
                    printf "%s\n" "Name: ${name}"
                    printf "%s\n" "Size: ${server_size_readable}"
                    printf "%s\n\n" "ID: ${file_url}"
                } >> "${LOG_FILE_URL}"
            fi
        }

        if [[ -s ${name} ]]; then
            declare local_size && local_size="$(wc -c < "${name}")"

            if [[ ${local_size} -ge "${server_size}" ]]; then
                _print_center "justify" "File already present" "=" && _newline "\n"
                _log_in_file
                return
            else
                _print_center "justify" "File is partially" " present, resuming.." "-"
                CONTINUE=" -C - "
            fi
        else
            _print_center "justify" "Downloading file.." "-"
        fi
        # shellcheck disable=SC2086 # Unnecessary to another check because ${CONTINUE} won't be anything problematic.
        curl -L -s ${CONTINUE} ${CURL_SPEED} -o "${name}" "${file_url}" &> /dev/null &
        pid="${!}"

        until [[ -f ${name} && -n ${pid} ]]; do _bash_sleep 0.5; done

        until ! ps -p "${pid}" &> /dev/null; do
            downloaded="$(wc -c < "${name}")"
            STATUS="$(_bytes_to_human "${downloaded}")"
            LEFT="$(_bytes_to_human "$((server_size - downloaded))")"
            _bash_sleep 0.5
            if [[ ${STATUS} != "${OLD_STATUS}" ]]; then
                printf '%s\r' "$(_print_center "justify" "Downloaded: ${STATUS}" " | Left: ${LEFT}" "=")"
            fi
            OLD_STATUS="${STATUS}"
        done
        _newline "\n"

        if [[ $(wc -c < "${name}") -ge "${server_size}" ]]; then
            for _ in {1..2}; do _clear_line 1; done
            _print_center "justify" "Downloaded" "=" && _newline "\n"
        else
            _print_center "justify" "Error: Incomplete" " download." "=" 1>&2
            return 1
        fi
        _log_in_file
    else
        _print_center "justify" "Failed some" ", unknown error." "=" 1>&2
        printf "%s\n" "${info}"
        return 1
    fi
    return 0
}

###################################################
# Download a gdrive folder along with sub folders
# File IDs are fetched inside the folder, and then downloaded seperately.
###################################################
_download_folder() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    declare folder_url="${1}" parallel="${2}"
    declare info name files_list=() files=() files_size=() folders=() error_status success_status num_of_files num_of_folders
    name="$(_url_decode "$(_basename "${folder_url}")")"
    if [[ -n ${name} ]]; then
        _newline "\n"
        _print_center "justify" "${name}" "="

        mapfile -t files <<< "$(_json_value name all all <<< "$(grep -v folder <<< "${JSON}" | grep mimeType -B1)" | sed "s|^|${folder_url}/|g")" || :
        mapfile -t files_size <<< "$(_json_value size all all <<< "${JSON}")" || :
        mapfile -t folders <<< "$(_json_value name all all <<< "$(grep folder -B1 <<< "${JSON}")" | sed "s|^|${folder_url}/|g")" || :

        mapfile -t files_list <<< "$(while read -r -u 4 file && read -r -u 5 size; do
            printf "%s\n" "${file}__.__${size}"
        done 4<<< "$(printf "%s\n" "${files[@]}")" 5<<< "$(printf "%s\n" "${files_size[@]}")")"

        if [[ -z ${files[*]:-${folders[*]}} ]]; then
            for _ in {1..2}; do _clear_line 1; done && _print_center "justify" "${name}" " | Empty Folder" "=" && _newline "\n" && return 0
        fi
        [[ -n ${files[*]} ]] && num_of_files="${#files[@]}"
        [[ -n ${folders[*]} ]] && num_of_folders="${#folders[@]}"

        for _ in {1..2}; do _clear_line 1; done
        _print_center "justify" "${name}" "${num_of_files:+ | ${num_of_files} files}${num_of_folders:+ | ${num_of_folders} sub folders}" "=" && _newline "\n\n"

        if [[ -f ${name} ]]; then
            name="${name}${RANDOM}"
            mkdir -p "${name}"
        else
            mkdir -p "${name}"
        fi

        cd "${name}" || exit 1

        if [[ -n "${num_of_files}" ]]; then
            if [[ -n ${parallel} ]]; then
                if [[ ${NO_OF_PARALLEL_JOBS} -gt ${num_of_files} ]]; then
                    NO_OF_PARALLEL_JOBS_FINAL="${num_of_files}"
                else
                    NO_OF_PARALLEL_JOBS_FINAL="${NO_OF_PARALLEL_JOBS}"
                fi

                [[ -f "${TMPFILE}"SUCCESS ]] && rm "${TMPFILE}"SUCCESS
                [[ -f "${TMPFILE}"ERROR ]] && rm "${TMPFILE}"ERROR

                export TMPFILE
                # shellcheck disable=SC2016
                printf "\"%s\"\n" "${files_list[@]}" | xargs -n1 -P"${NO_OF_PARALLEL_JOBS_FINAL}" -i bash -c '
                line="{}"
                if _download_file "${line//__.__*/}" "${line//*__.__/}" &> /dev/null; then
                    printf "1\n"
                else
                    printf "2\n" 1>&2
                fi
                ' 1>| "${TMPFILE}"SUCCESS 2>| "${TMPFILE}"ERROR &

                until [[ -f "${TMPFILE}"SUCCESS || -f "${TMPFILE}"ERROR ]]; do _bash_sleep 0.5; done

                _clear_line 1
                until [[ -z $(jobs -p) ]]; do
                    success_status="$(_count < "${TMPFILE}"SUCCESS)"
                    error_status="$(_count < "${TMPFILE}"ERROR)"
                    _bash_sleep 1
                    if [[ $(((success_status + error_status))) != "${TOTAL}" ]]; then
                        printf '%s\r' "$(_print_center "justify" "Status" ": ${success_status:-0} Downloaded | ${error_status:-0} Failed" "=")"
                    fi
                    TOTAL="$(((success_status + error_status)))"
                done
                _newline "\n"
                success_status="$(_count < "${TMPFILE}"SUCCESS)"
                error_status="$(_count < "${TMPFILE}"ERROR)"
                _clear_line 1 && _newline "\n"
            else
                for line in "${files_list[@]}"; do
                    if _download_file "${line//__.__*/}" "${line//*__.__/}"; then
                        success_status="$((success_status + 1))"
                    else
                        error_status="$((error_status + 1))"
                    fi
                    if [[ -z ${VERBOSE} ]]; then
                        for _ in {1..4}; do _clear_line 1; done
                    fi
                    _print_center "justify" "Status" ": ${success_status:-0} Downloaded | ${error_status:-0} Failed" "="
                done
            fi
        fi

        for _ in {1..2}; do _clear_line 1; done
        _newline "\n"
        [[ ${success_status} -gt 0 ]] && _print_center "justify" "Downloaded" ": ${success_status}" "="
        [[ ${error_status} -gt 0 ]] && _print_center "justify" "Failed" ": ${error_status}" "="
        _newline "\n"

        if [[ -z ${SKIP_SUBDIRS} && -n ${num_of_folders} ]]; then
            for folder in "${folders[@]}"; do
                _print_center "justify" "Fetching folder" " details.." "-"
                if JSON="$(_fetch -X POST "${folder}/")" && ! [[ ${JSON} =~ html ]]; then
                    JSON="$(_parse_json <<< "${JSON}")" && export JSON
                    _clear_line 1
                    # do this in a subshell so that the directory change doesn't apply to main loop
                    (_download_folder "${folder}" "${parallel:-}")
                else
                    _clear_line 1
                    _print_center "justify" "Cannot fetch" "folder details" "=" 1>&2
                    printf "%s\n" "${JSON}" 1>&2
                fi
            done
        fi
    else
        _clear_line 1
        _print_center "justify" "Error: some" " unknown error." "="
        printf "%s\n" "${JSON}" && return 1
    fi
    return 0
}

##################################################
# Process all arguments given to the script
###################################################
_setup_arguments() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    # Internal variables
    # De-initialize if any variables set already.
    unset LOG_FILE_URL FOLDERNAME SKIP_SUBDIRS NO_OF_PARALLEL_JOBS PARALLEL_DOWNLOAD
    unset DEBUG QUIET VERBOSE VERBOSE_PROGRESS SKIP_INTERNET_CHECK
    unset URL_INPUT_ARRAY FINAL_INPUT_ARRAY
    INFO_PATH="${HOME}/.gdindex-downloader"
    INFO_FILE="${INFO_PATH}/gdindex-downloader.info"

    # API
    API_KEY="AIzaSyD2dHsZJ9b4OXuy5B_owiL8W18NaNOM8tk"
    API_URL="https://www.googleapis.com"
    API_VERSION="v3"

    _check_longoptions() {
        [[ -z ${2} ]] &&
            printf '%s: %s: option requires an argument\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${1}" "${0##*/}" &&
            exit 1
        return 0
    }

    while [[ ${#} -gt 0 ]]; do
        case "${1}" in
            -h | --help)
                _usage
                ;;
            -D | --debug)
                DEBUG="true"
                ;;
            -u | --update)
                _check_debug && _update
                ;;
            --uninstall)
                _check_debug && _update uninstall
                ;;
            -V | --version)
                _version_info
                ;;
            -l | --log)
                _check_longoptions "${1}" "${2}"
                LOG_FILE_URL="${2}" && shift
                ;;
            -d | --directory)
                _check_longoptions "${1}" "${2}"
                FOLDERNAME="${2}" && shift
                ;;
            -s | --skip-subdirs)
                SKIP_SUBDIRS="true"
                ;;
            -p | --parallel)
                _check_longoptions "${1}" "${2}"
                NO_OF_PARALLEL_JOBS="${2}"
                case "${NO_OF_PARALLEL_JOBS}" in
                    '' | *[!0-9]*)
                        printf "\nError: -p/--parallel value can only be a positive integer.\n"
                        exit 1
                        ;;
                    *)
                        NO_OF_PARALLEL_JOBS="${2}"
                        ;;
                esac
                PARALLEL_DOWNLOAD="true" && shift
                ;;
            --speed)
                _check_longoptions "${1}" "${2}"
                regex='^([0-9]+)([k,K]|[m,M]|[g,G])+$'
                if [[ ${2} =~ ${regex} ]]; then
                    CURL_SPEED="--limit-rate ${2}" && shift
                else
                    printf "Error: Wrong speed limit format, supported formats: 1K , 1M and 1G\n" 1>&2
                    exit 1
                fi
                ;;
            -v | --verbose)
                VERBOSE="true"
                ;;
            --skip-internet-check)
                SKIP_INTERNET_CHECK=":"
                ;;
            *)
                # Check if user meant it to be a flag
                if [[ ${1} = -* ]]; then
                    printf '%s: %s: Unknown option\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${1}" "${0##*/}" && exit 1
                else
                    URL_INPUT_ARRAY+=("${1}")
                fi
                ;;
        esac
        shift
    done

    # If no input
    [[ -z ${URL_INPUT_ARRAY[*]} ]] && _short_help

    # Remove duplicates
    mapfile -t FINAL_INPUT_ARRAY <<< "$(_remove_array_duplicates "${URL_INPUT_ARRAY[@]}")"

    _check_debug

    export DEBUG LOG_FILE_URL VERBOSE API_KEY API_URL API_VERSION
    export INFO_PATH FOLDERNAME SKIP_SUBDIRS NO_OF_PARALLEL_JOBS PARALLEL_DOWNLOAD SKIP_INTERNET_CHECK
    export COLUMNS CURL_SPEED
    export -f _print_center _clear_line _newline _bash_sleep _tail _head _count _json_value _bytes_to_human
    export -f _fetch _check_url _download_file _download_folder _basename _url_decode

    return 0
}

###################################################
# Process all the values in "${FINAL_INPUT_ARRAY[@]}"
###################################################
_process_arguments() {
    ${FOLDERNAME:+mkdir -p ${FOLDERNAME}}
    cd "${FOLDERNAME:-.}" &> /dev/null || exit 1

    for url in "${FINAL_INPUT_ARRAY[@]}"; do
        _check_url "${url}" "${API_KEY}" || continue
        if [[ -n ${FOLDER_URL} ]]; then
            _download_folder "${FOLDER_URL}" "${PARALLEL_DOWNLOAD:-}"
        else
            _download_file "${FILE_URL}" "${FILE_SIZE}"
        fi
    done
    return 0
}

main() {
    [[ $# = 0 ]] && _short_help

    UTILS_FILE="${UTILS_FILE:-./utils.sh}"
    if [[ -r ${UTILS_FILE} ]]; then
        source "${UTILS_FILE}" || { printf "Error: Unable to source utils file ( %s ) .\n" "${UTILS_FILE}" && exit 1; }
    else
        printf "Error: Utils file ( %s ) not found\n" "${UTILS_FILE}"
        exit 1
    fi

    _check_bash_version && set -o errexit -o noclobber -o pipefail

    _setup_arguments "${@}"

    "${SKIP_INTERNET_CHECK:-_check_internet}"

    _setup_tempfile

    _cleanup() {
        {
            rm -f "${TMPFILE:?}"*
            export abnormal_exit
            if [[ -n ${abnormal_exit} ]]; then
                kill -- -$$
            else
                _auto_update
            fi
        } &> /dev/null || :
        return 0
    }

    trap 'printf "\n" ; abnormal_exit=1; exit' SIGINT SIGTERM
    trap '_cleanup' EXIT

    _print_center "justify" "Starting script" "-"
    START="$(printf "%(%s)T\\n" "-1")"

    _process_arguments

    END="$(printf "%(%s)T\\n" "-1")"
    DIFF="$((END - START))"
    _print_center "normal" " Time Elapsed: ""$((DIFF / 60))"" minute(s) and ""$((DIFF % 60))"" seconds. " "="
}

main "${@}"
