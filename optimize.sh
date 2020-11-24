#!/bin/bash
for file in $(find _site/ -name "*.html")
do
    echo $file
    sed -i -f optimize.sed $file
done
