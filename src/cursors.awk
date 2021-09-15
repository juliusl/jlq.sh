#!/bin/awk -f

# cursors
# print the token name for the leftmost cursor

# OUTPUT_STRING_BUFFER(%s)
{
    printf "OUTPUT_STRING_BUFFER(%s)\n", $0;
}

# OUTPUT_STRING_BUFFER_TO_FILE(%s)
/^%s>".*"/ {
    gsub(/%s|>|"/, "", $0);
    printf "OUTPUT_STRING_BUFFER_TO_FILE(%s)\n", $0;
    next;
}