#!/bin/awk -f 

# Formate json rc, take json_format_render.out and create arguments for 
# writing to a json file

$0 ~ /^\[.*\]$/ {
    printf "%s.json ", substr($0, 2, length($0)-2);
}
$0 == "{" {
    printf "'%d,", NR;
}
$0 == "}" {
    printf "%dp'\n", NR;
}

