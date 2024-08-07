#!/usr/bin/env bash
set -euxo pipefail

readonly drc_args_file="$1"
readonly sample_rate="$2"
readonly out_filter_file="$3"
readarray -t drc_args <"${drc_args_file}"

function run_drc() {
    drc "${drc_args[@]}" \
        --BCInFile="./tmp/$1-speaker-impulse-response.pcm" \
        --PSOutFile="./tmp/$1-speaker-convolver-filter.pcm" \
        --TCOutFile=./tmp/rtc.pcm \
        2>"./tmp/drc-output-$1.log" > >(tee /dev/tty >&2)
}

run_drc left
impulse_center=$(sed -nr 's/^Impulse center found at sample ([^\.]*)\./\1/p' ./tmp/drc-output-left.log)
if [ -z "${impulse_center}" ]; then
    echo 'error: Could not find impulse center from DRC output'
    exit 1
fi
drc_args+=(--BCImpulseCenterMode=M "--BCImpulseCenter=${impulse_center}")
run_drc right

sox \
    -M \
    -t raw \
    -b 32 \
    -c 1 \
    -e floating-point \
    -r "${sample_rate}" \
    ./tmp/left-speaker-convolver-filter.pcm \
    -t raw \
    -b 32 \
    -c 1 \
    -e floating-point \
    -r "${sample_rate}" \
    ./tmp/right-speaker-convolver-filter.pcm \
    -t wav \
    -b 32 \
    -e floating-point \
    -r "${sample_rate}" \
    "${out_filter_file}"
