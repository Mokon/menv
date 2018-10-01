#!/bin/bash
while IFS='' read -r line || [[ -n "$line" ]]; do
    code="${line,,}"
    #echo -e "        case KEY_${code^^}:\n            return Key::${code^};"
    echo -e "${code^}"
done < infile > outfile
