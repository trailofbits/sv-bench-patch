#!/bin/sh

SV_BENCHMARKS_DIR="../sv-benchmarks/"
OUTPUT_DIR="stats/"
FULL_OUT_DIR=""
OUT_FILE=""
RESULTS_FILE=""
VERBOSE=false
JOBS=""
COMPILER="vast-front"
TARGET_IR="hl"
DISABLE_UNSUP=false
DIR=$(pwd)

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help          Display this help message."
    echo "  -d, --directory     Specify the SV-Comp benchmarks directory. Default is '../sv-benchmarks/'."
    echo "  -o, --output        Specify the output directory for result files."
    echo "  -j, --jobs          Specify the number of jobs/threads to use for building. Default is the number of available processors."
    echo "  -c, --compiler      Specify the compiler binary used to build the benchmarks. Default is vast-front."
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
            -c|--compiler)
                COMPILER="$2"
                shift
                ;;
            -t|--target)
                TARGET_IR="$2"
                shift
                ;;
            --disable-unsup)
                DISABLE_UNSUP=true
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
    OUT_FILE="${FULL_OUT_DIR}/$(date +"out-%H%M%S.txt")"
}

build() {
    log "Building sv-comp benchmarks..."
    log "Current working directory: $(pwd)"
    cd "$SV_BENCHMARKS_DIR/c" || exit 1
    make clean || exit 1

    make CC=${COMPILER} CC.Arch=64 EMIT_MLIR=${TARGET_IR} REPORT_CC_FILE=1 DISABLE_UNSUPPORTED=${DISABLE_UNSUP} -j "${JOBS:-$(nproc --all)}" 2>/dev/null | tee "${OUT_FILE}"
}

process() {
    log "Processing build artifacts..."
    log "Current working directory: $(pwd)"
    cd "$FULL_OUT_DIR" || exit 1
    mkdir -p data || exit 1
    cd data || exit 1

    log "Out file: ${OUT_FILE}"
    awk '
        /.*Entering.*/ {
        ++part;
        if (output_file) close(output_file);
        output_file=sprintf("xx-%03d.txt", part)
    }
    {print >output_file}
    ' ${OUT_FILE}

    for x in xx*; do
        local file_path=$(head -n 1 "$x" | sed -n -e "s;.*'.*\(sv-benchmarks/c/.*\)';\1;p")
        local ok_count=$(grep -c "OK" "$x")
        local other_count=$(grep -v -c "make\|OK" "$x")
        echo "${file_path} ${ok_count}/${other_count}"
    done > "$RESULTS_FILE" || exit 1

    echo "Total $(grep -c "OK" "${OUT_FILE}")/$(grep -v -c "make.*directory\|OK" "${OUT_FILE}")" >> "$RESULTS_FILE"
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
