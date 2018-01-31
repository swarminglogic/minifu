#!/bin/bash

show_usage_and_exit() {
    echo "Utility that versions css|js minifaction replacements in code.

USAGE
    $(basename $0)  [--css|--js] -k KEY -p PREFIX -d OUT_DIR FILE_1 [..FILE_N]
    $(basename $0)  [--css|--js] -k KEY -p PREFIX -d OUT_DIR FILE_1 [..FILE_N] [-s SRC_DIR]

    Minifies input files to:
        OUT_DIR/KEY.<MD5>.min.{js|css}
    Where <MD5> is a shortened md5-hash of the generated minimized file.

    Performs code manipulation within SRC_DIR. See: CODE_REPLACEMENT

    Returns path and name of created minimized file

OPTIONS
    -h, --help              show this help text
    -v, --verbose           verbose output
    --js|--css              use either option depending on compression type
    -k, --key=KEY           replacement target for generated file.
    -p, --prefix=PREFIX     replacement prefix (e.g path as used in replacement)
    -o, --outdir=OUT_DIR    output directory to place minified file
    FILE_i                  list of files to process as input files.
                            Regular unix globs are possible, but you might want to
                            control specific ordering.

OPTIONALS
    -s,--src-dir=SRC_DIR    directory from where to recursively search and perform code
                            manipulation. Defaults to CWD if unset.
    --only-create           skips code manipulation process alltogether.

CODE_REPLACEMENT
    The following code manipulation is done for all files within OUT_DIR:

    When using --css flag:
        - Lines containing '{{ minifu:remove:css:KEY }}' are deleted
        - Lines containing '{{ minifu:add:css:KEY }}' is replaced with:
        <link rel=\"stylesheet\" href=\"PREFIX/KEY.<MD5>.min.css\">

    When using --js flag:
        - Lines containing '{{ minifu:remove:js:KEY }}' are deleted
        - Lines containing '{{ minifu:add:js:KEY }}' is replaced with:
        <script src=\"PREFIX/KEY.<MD5>.min.js\"></script>

EXAMPLE
    $(basename $0) --css -k styles -p /css -d web/css src/css/*.css -s web

    This combines and minifies all *.css files in src/css/ into a single file
    file in e.g: ./css/styles.b7ef6cae.min.css,
    using the md5sum of the minified data. If no changes are made, the filename
    will remain unchanged.

    Additionally, it will replace all occurences of {{ minifu:add:css:KEY }} with
    <link rel=\"stylesheet\" href=\"web/css/styles.b7ef6cae.min.css\">

REQUIREMENTS:
    yui-compressor (http://yui.github.io/yuicompressor/)

Author:     Roald Fernandez (contact@swarminglogic.com)
Version:    0.1.1 (2018-01-30)
License:    MIT
"
    exit $1
}

parse_arguments() {
    if test $# -eq 0; then show_usage_and_exit 0 ; fi
    tmp=$@
    src_files=""
    leftovers=""

    while test $# -gt 0; do
        case "$1" in
            -h|--help)
                show_usage_and_exit 0 ;;
            -v|--verbose)
                shift ;
                verbose_flag=true ;;
            --css)
                type_fw="css"
                shift
                ;;
            --js)
                type_fw="js"
                shift
                ;;
            -k)
                shift
                key=$1
                shift
                ;;
            --key*)
                key=$(echo $1 | sed -e 's/^[^=]*=//g')
                shift
                ;;
            -p)
                shift
                prefix=$1
                shift
                ;;
            --prefix*)
                prefix=$(echo $1 | sed -e 's/^[^=]*=//g')
                shift
                ;;
            -s)
                shift
                src_dir=$1
                shift
                ;;
            --src-dir*)
                src_dir=$(echo $1 | sed -e 's/^[^=]*=//g')
                shift
                ;;
            --only-create)
                shift ;
                only_create_flag=true ;;
            -o)
                shift
                out_dir=$1
                shift
                ;;
            --outdir*)
                out_dir=$(echo $1 | sed -e 's/^[^=]*=//g')
                shift
                ;;
            *)
                if [ ! -f "$1" ] ; then
                    echo_stderr "Unsupported arguments, or unknown source: $1"
                    exit 1
                fi
                src_files="$src_files \"$1\""
                shift
                ;;
        esac
    done

    # Handles options with default values
    src_dir=${src_dir:-"."}

    # Check required inputs
    missing_required_args=
    check_required_argument type_fw     "--js|--css"
    check_required_argument src_files   ""
    check_required_argument key         "-k, --key=KEY"
    check_required_argument prefix      "-p, --prefix"
    check_required_argument out_dir     "-o, --outdir=OUT_DIR"
    if test $missing_required_args ; then
        show_usage_and_exit 1
    fi

    # Check input assumptions
    if [ ! -d "$out_dir" ] ; then
        echo_stderr "Not a valid output directory: $out_dir"
        exit 1
    fi
    if [ ! -d "$src_dir" ] ; then
        echo_stderr "Not a valid source directory: $src_dir"
        exit 1
    fi

    # Handle verbosity
    if test $verbose_flag ; then
         set -x
    fi
}

RED="\033[31m"
CLOSE="\033[m"
echo_stderr() {
    (>&2 echo -e "${RED}ERROR: $@${CLOSE}")
}

check_required_argument() {
    if [ -z "${!1}" ] ; then
         echo_stderr "Required argument not set: $2"
         missing_required_args=true
    fi
}

debug_args() {
    for i in "$@" ; do
        echo "${i}: ${!i}"
    done
}

# Main
###################################
parse_arguments "$@"
tmp_file=$(mktemp)
chmod 664 ${tmp_file}

# Minify files
<<<$src_files xargs cat | yui-compressor --type ${type_fw} > $tmp_file
yui_exit_code=$?
if [ $yui_exit_code -ne 0 ] ; then
    echo_stderr "Failed to minify files with yui-compressor"
    if [ -f $tmp_file ] ; then rm $tmp_file ; fi
    exit $yui_exit_code
fi
md5=$(md5sum "${tmp_file}" | head -c 8)

# Create the output file
gen_file="${key}.${md5}.min.${type_fw}"
gen_file_path="${out_dir}/${gen_file}"
if [ ! -f ${gen_file_path} ] ; then
    mv "${tmp_file}" "${gen_file_path}"
fi
echo "${gen_file_path}"

pushd "$src_dir" > /dev/null
    # Remove entries containing {{ minifu:remove }}
    find . -type f -print0 | xargs -0 sed -i "/{{[ ]*minifu:remove:${type_fw}:${key}[ ]*}}/d"
    # Add js|css entries
    out_href="${prefix}/${gen_file}"
    tag_replace=
    if [ "${type_fw}" = "css" ] ; then
        tag_replace="<link rel=\"stylesheet\" href=\"${out_href}\">"
    elif [ "${type_fw}" = "js" ] ; then
        tag_replace="<script src=\"${out_href}\"></script>"
    fi
    find . -type f -print0 | xargs -0 sed -i "s,^.*{{[ ]*minifu:add:${type_fw}:${key}[ ]*}}.*,${tag_replace},"
popd > /dev/null

# Cleanup
if [ -f $tmp_file ] ; then rm $tmp_file ; fi
