#!/usr/bin/env bash
set -e

# Test urls
FILE_URL="https://gdindex-demo.maple3142.workers.dev/example.com.html"
FOLDER_URL="https://gdindex-demo.maple3142.workers.dev/%23/"

# Folder
bash idl.sh "${FOLDER_URL}" -d Test
rm -rf Test/
printf "\n"

bash idl.sh "${FOLDER_URL}" -d Test -p 2
printf "\n"

# Do a check for log message when trying to download an existing folder contents
bash idl.sh "${FOLDER_URL}" -d Test
rm -rf Test/
printf "\n"

# File
bash idl.sh "${FILE_URL}" -d Test
printf "\n"

# Do a check for log message when trying to download an existing file
bash idl.sh "${FILE_URL}" -d Test
rm -rf Test/
printf "\n"
