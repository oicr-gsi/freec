#!/bin/bash
cd $1

echo ".txt files:"
find . -name "*.txt" | xargs md5sum | sort -V

echo "CNVs files:"
find . -name "*_CNVs" | xargs md5sum | sort -V

echo ".cpn files:"
find . -name "*.cpn" | xargs md5sum | sort -V

echo ".BedGraph files:"
find . -name "*.BedGraph" | xargs md5sum | sort -V

