#!/bin/sh

SV_BENCHMARKS_DIR="../sv-benchmarks/"
OUTPUT_DIR="stats/$(date +"%y-%m-%d")"
FULL_OUT_DIR=""
OUT_FILE=""
RESULTS_FILE=""
VERBOSE=false
JOBS=""
DIR=$(pwd)

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help          Display this help message."
    echo "  -d, --directory     Specify the SV-Comp benchmarks directory. Default is '../sv-benchmarks/'."
    echo "  -o, --output        Specify the output directory for result files."
    echo "  -j, --jobs          Specify the number of jobs/threads to use for building. Default is the number of available processors."
    echo "  -v, --verbose       Enable verbose output."
}

parse_options() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--directory)
                SV_BENCHMARKS_DIR="$2"
                shift
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift
                ;;
            -j|--jobs)
                JOBS="$2"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

log() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

initialize() {
    log "Initializing..."
    if [ -n "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR" || exit 1
    fi

    FULL_OUT_DIR=$(readlink -f "${OUTPUT_DIR}")
    RESULTS_FILE="${FULL_OUT_DIR}/results.txt"
    OUT_FILE="${FULL_OUT_DIR}/$(date +"out-k%H%M%S.txt")"
}

build() {
    log "Building sv-comp benchmarks..."
    log "Current working directory: $(pwd)"
    cd "$SV_BENCHMARKS_DIR/c" || exit 1
    # make clean || exit 1

    make CC=vast-front CC.Arch=64 EMIT_MLIR=hl REPORT_CC_FILE=1 -j "${JOBS:-$(nproc --all)}" 2>/dev/null | tee "${OUT_FILE}"
}

process() {
    log "Processing build artifacts..."
    log "Current working directory: $(pwd)"
    cd "$FULL_OUTPUT_DIR" || exit 1
    mkdir -p data || exit 1
    cd data || exit 1

    csplit -z --digits=3 "../${OUT_FILE}" "/Entering/" {*} 1>/dev/null || exit 1

    for x in xx*; do
        local file_path=$(head -n 1 "$x" | sed -n -e "s;.*'.*\(sv-benchmarks/c/.*\)';\1;p")
        local ok_count=$(grep "OK" "$x" | wc -l)
        local other_count=$(grep -v "make\|OK" "$x" | wc -l)
        echo "${file_path} ${ok_count}/${other_count}"
    done > $RESULTS_FILE || exit 1

    echo "Total" >> "../$RESULTS_FILE"
    echo "$(grep "OK" "../${OUT_FILE}" | wc -l)/$(grep -v "make.*directory\|OK" "../${OUT_FILE}" | wc -l)" >> "../$RESULTS_FILE"
}

cleanup() {
    log "Cleaning up..."
    cd ..
    rm -rf data
}

main() {

    parse_options "$@"
    initialize
    build
    process
    cleanup
    echo "You can find the stats in $RESULTS_FILE"
    log "Script execution completed."
}

main "$@"
