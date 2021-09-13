#!/bin/awk -f 

# Formatters

function format_prompt(_c) {
    # orange
    return sprintf("\033[33m%s\033[39m", _c);
}

function format_input_cursor(_c) {
    # blue
    return sprintf("\033[36m%s\033[39m", _c);
}

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

function print_context() {
}

function prompt_default(_i, _v) {
    printf "%s ", get_line_from_index();
    print_prompt_from_line();

	getline _v < "-";
}

function prompt_string(_cl, _v) {
    printf " %s %s", get_line_from_index(), format_input_cursor("<< ");
	getline _v < "-";
    # replace value
    value_id++;
    value_index[value_id] = sprintf("%s", _v);
    # return update
    return sprintf("\"%s\": \"%s\"", name_index[$4], value_index[value_id]);
}

function load_names() {
    name_id=0;
    while ( (getline n < "name_index" ) > 0 ) {
        if ( n != "" ) {
          name_id++;
          name_index[name_id]=n;
        }
    }
}

function load_values() {
    value_id=0;
    while ( (getline v < "value_index" ) > 0 ) {
        if (v !=  "") {
          value_id++;
          value_index[value_id]=v;
        }
    }
}

function get_line_from_index() {
    return get_line_from_index_at($4, $5);
}

function get_line_from_index_at(_nid, _vid) {
    return sprintf("\"%s\": \"%s\"", name_index[_nid], value_index[_vid]);
}

function print_prompt_from_line() {
    printf "- ";
    for (i = 7; i <= NF; i++) {
        printf "%s ", format_prompt( $i );
    }
    printf "\n";;
}

BEGIN {
    FS=" ";
    load_names();
    load_values();
}

# Columns 
# 1 root-id, 
# 2 line-number, 
# 3 depth, 
# 4 name_index, 
# 5 value_index, 
# 6 prompt

# Document line
$1 ~ /jlq/ {
    root[$1] = 0;
}

# Root line
# 3 "hello2": "",
$2 ~ /.?\b?"\w+":/ {
    root[$1] = 0;
}

# Prompt for a string value
# 2 7 1 6 0  %s Enter a description this will set the value of family
$6 ~ /.*%s/ {
    line=get_line_from_index();
    lines[$2]=line;
    depth[$2]=$3;
    if (root[$1] == 0) {
        root[$1]=$2;
    }

    # print out the prompt
    print_prompt_from_line();
    updated=prompt_string(line);

    # output old value and updated value
    if (get_line_from_index() != updated) {
        printf "\n\n\033[31m%s\033[39m -> \033[32m%s\033[39m\n\n", get_line_from_index(), updated;
    }
}

# Default prompt
$6 ~ /.*-/ {
    line=get_line_from_index();
    lines[$2]=line;
    depth[$2]=$3;
    if (root[$1] == 0) {
        root[$1]=$2;
    }
    prompt_default();
    
}
# EOF