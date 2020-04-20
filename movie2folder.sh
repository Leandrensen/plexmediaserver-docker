#!/bin/bash

for file in *.mkv *.mp4 *.wmv *.avi; do
        if [ -f "$file" ] # does file exist?
        then
                dir=$(echo "${file%.*}") # extract filename from filename.extention
                echo $dir;
                if [ "$dir" ] # check if string found
                then
                        mkdir -p "$dir"  # create dir
                        mv "$file" "$dir"     # move file into new dir
                else
                        echo "INCORRECT FILE FORMAT: \""$file"\"" # print error if file format is unexpected
                fi
        fi
done