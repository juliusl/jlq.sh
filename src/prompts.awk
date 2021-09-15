#!/bin/awk -f 

# # Prompt interpreter 
# # - Uses: 
# # - prompt
# # - depth
# # - name_index
# # - value_index
# # - lines
# #

function print_depth(_d, _t) {
    for (_t = 1; _t <= _d; _t++) {
        printf " ";
    }
}

function prompt_default(_i, _v) {
    printf "%s ", get_line_from_index();
    print_prompt_from_line();

	getline _v < "-";
}

function prompt_string(_cl, _v) {
    print_prompt_from_line();
    
    printf " %s %s", get_line_from_index(), format_input_cursor( "<< " );
	getline _v < "-";

    # replace value
    value_id++;
    value_index[value_id] = sprintf("%s", _v);
    
    # return update
    return sprintf("\"%s\": \"%s\"", name_index[$5], value_index[value_id]);
}

BEGIN {
    FS=" ";
    load_names();
    load_values();
}

# Columns 
# 1 root-id,
# 2 offset
# 3 line-number, 
# 4 depth, 
# 5 name_index, 
# 6 value_index, 
# 7 prompt

# Document line
$1 ~ /jlq/ {
    root[$1] = 0;
}

# Root line
# 3 "hello2": "",
$3 ~ /.?\b?"\w+":/ {
    root[$1] = 0;
}

# String prompt
# 2 1 7 1 6 0  %s Enter a description this will set the value of family
$7 ~ /.*%s/ {
    line=get_line_from_index();
    lines[$3]=line;
    depth[$3]=$4;
    if (root[$1] == 0) {
        root[$1]=$3;
    }

    # print out the prompt
}

# Note prompt
$7 ~ /.*-/ {
    line=get_line_from_index();
    lines[$3]=line;
    depth[$3]=$4;
    if (root[$1] == 0) {
        root[$1]=$3;
    }
    prompt_default();
}
# EOF
