#!/bin/bash
base_dir="${PWD}"
target_directory=".git"
for dir in "$base_dir"/*/
do
  if [ ! -d "${dir}${target_directory}" ]; then
    echo "${dir} does not have ${target_directory}"
  fi
done
