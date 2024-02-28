#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

fixup_loop() {
    while (( $# > 0))
    do
        local file_path file_name dir_path

        file_path="$1"
        file_name="$(basename "$file_path")"
        dir_path="$(dirname "$file_path")"
        shift

        pushd "$dir_path"

            ar x "$file_name"
            unxz control.tar.xz # because tar --append does not work with compression
            tar --to-stdout -xf control.tar ./control > control

            fixup_callback "$file_name"

            tar --delete -f control.tar ./control # avoid duplicate members
            tar --append --owner=root --group=root -f control.tar ./control
            xz control.tar
            ar r "$file_name" debian-binary control.tar.xz data.tar.xz
            rm control debian-binary control.tar.xz data.tar.xz

        popd
    done
}
