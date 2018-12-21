#!/bin/bash
## go.mod dependency license collector
## ==============================
## Author : clvs7
## License: CC0 (Public Domain)
## For further details of license, see : https://creativecommons.org/publicdomain/zero/1.0/

declare -ar LICENSE_FILE_PATTERN=("LICENSE*" "COPYING*")
readonly NOTICE_FILE_PATTERN="NOTICE*"
readonly MOD_PATH="${GOPATH}/pkg/mod"

declare -A flag_map

scan_deep=1
go_mod_file="./go.mod"
debug=0

repeat_str() {
    # Expects $1 as string
    # Expects $2 as repeat count
    for i in `seq ${2}`; do
        echo -n "${1}"
    done
    echo ""
}

parse_go_mod() {
    # Expects $1 as go.mod path
    cat ${1} | grep -P '(.+) v(.+)' | tr -d '\t' | awk '{ $0 = gensub(/([A-Z])/, "!\\1", "g"); print tolower($0); }' | tr ' ' ','
}

print_license() {
    # Expects $1 as library's fullname (including version name)
    is_ok=0
    for pat in "${LICENSE_FILE_PATTERN[@]}"; do
        license_path=${MOD_PATH}/${1}/${pat}
        if [ -e ${license_path} ]; then
            repeat_str "=" 60
            echo "Notice for file : ${1%@*}"
            repeat_str "=" 60
            cat ${license_path}
            echo ""
            is_ok=1
            break
        fi
        break
    done
    if [ $is_ok -eq 0 ] && [ $debug -ne 0 ]; then
        echo "No license file found : ${1}" >&2
        return 1
    fi
}

dig_library() {
    # Expects $1 as library name and version (e.g. github.com/***/***, v0.1) array
    for entry in ${1}; do
        entry=(`echo ${entry} | tr ',' ' '`)
        lib=${entry[0]}
        ver=${entry[1]}
        lib_fullname=${lib}@${ver}
        lib_path="${MOD_PATH}/${lib_fullname}"
        if [ "${flag_map["${lib}"]}" = "" ]; then
            print_license ${lib_fullname}
            if [ $? -eq 0 ]; then
                flag_map["${lib}"]=1
            fi
        fi
        if [ -e ${lib_path}/${NOTICE_FILE_PATTERN} ]; then
            repeat_str "=" 60
            echo "Dependencies of ${lib} :"
            repeat_str "=" 60
            cat "${lib_path}/${NOTICE_FILE_PATTERN}"
            echo ""
        elif [ -e "${lib_path}/go.mod" ] && [ ${scan_deep} -ne 0 ]; then
            dig_library "`parse_go_mod "${lib_path}/go.mod"`"
        elif [ $debug -ne 0 ]; then
            echo "No NOTICE file nor go.mod file found. : ${lib}" >&2
        fi
    done
}

if [ ! -e "${GOPATH}" ]; then
    echo "GOPATH is undefined!" >&2
    exit 1
fi

for arg in "$@"
do
    case "${arg}" in
        '-help'|'--help' )
            repeat_str "=" 30
            echo "Usage :"
            repeat_str "=" 30
            echo "-debug, --debug: Enable debug mode (verbose output)"
            echo "-mod, --mod [go.mod path]: Specify go.mod path"
            echo "-disable-deep, --disable-deep: Disable deep scan. Output only licenses for libraries written into YOUR go.mod."
            exit 0
            ;;
        '-debug'|'--debug' )
            debug=1
            shift
            ;;
        '-mod'|'--mod' )
            go_mod_file=${2}
            shift 2
            ;;
        '-disable-deep'|'--disable-deep' )
            scan_deep=0
            shift
            ;;
    esac
done

# Run
dig_library "`parse_go_mod ${go_mod_file}`"
