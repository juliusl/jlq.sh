#!/bin/awk -f 

# format_json
# format render.out to json content

# Example input 
# [output-record]
# 1 default jlq
# 2 default/julius work
# 3 default/bobo home

# [output-field]
# 2 1 official yi
# 2 2 alternative yi jun
# 2 3 backup yi jun liu
# 3 1 introuble notjulius

# Example output
# [default/julius/work]
# {
# "official": "yi",
# "official/alternative": "yi jun",
# "official/alternative/backup": "yi jun liu"
# }
# [default/bobo/home]
# {
# "introuble": "notjulius"
# }

BEGIN {
    last_field="";
    last_depth=0;
}

$0 == "[output-record]" {
}

$2 !~ /[0-9]+/ {
    record_name[$1]=sprintf("%s/%s", $2, $3);
}

$0 == "[output-field]" {
}

$2 ~ /[0-9]+/ {
    if (last_depth == $2-1) {
      # Track hierarchy
        if (last_field == "") {
            last_field=$3;
        } else {
            last_field=sprintf("%s/%s", last_field, $3);
            printf ",\n";
        }
    } else {
        printf "\n}";
        # Reset registers
        last_field=$3;
        last_depth=0;
    }

    if ( record_name[$1] > 0 && record_name[$1] != current_record ) {
        current_record=record_name[$1];
        printf "\n[%s]\n{\n", current_record;
    }

    printf "\"%s\": \"", last_field;
    for (i=4; i<=NF; i++) {
        printf "%s", $i;
        if (i != NF) {
            printf OFS;
        }
    }

    printf "\"";
    last_depth=$2;
}
END {
    printf "\n}\n";
}

