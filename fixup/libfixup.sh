#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

extract() {
    local tar_file="$1" target="$2"
    tar --to-stdout -xf "$tar_file" "./$target" > "./$(basename "$target")"
}

replace() {
    local tar_file="$1" target="$2"
    tar --delete -f "$tar_file" "./$target" # avoid duplicate members
    tar --append --owner=root --group=root -f "$tar_file" "./$(basename "$target")"
    rm "./$(basename "$target")"
}

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
            unxz -T 0 control.tar.xz data.tar.xz # because tar --append does not work with compression
            extract control.tar control

            fixup_callback "$file_name"

            replace control.tar control
            xz -T 0 control.tar data.tar
            ar r "$file_name" debian-binary control.tar.xz data.tar.xz
            rm debian-binary control.tar.xz data.tar.xz

        popd
    done
}
