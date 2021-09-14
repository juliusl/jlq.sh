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

# format the update, _c is the cursor value and _u is the new value
function format_update(_c, _u) {
    return sprintf("\033[31m%s\033[39m->\033[32m%s\033[39m", _c, _u);
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

function prompt_default(_i, _v) {
    printf "%s ", get_line_from_index();
    print_prompt_from_line();

	getline _v < "-";
}

function prompt_string(_cl, _v) {
    printf " %s %s", get_line_from_index(), format_input_cursor( "<< " );
	getline _v < "-";

    # replace value
    value_id++;
    value_index[value_id] = sprintf("%s", _v);
    
    # return update
    return sprintf("\"%s\": \"%s\"", name_index[$5], value_index[value_id]);
}

function load_names() {
    name_id=0;
    while ( (getline n < "jlq_name_index" ) > 0 ) {
        if ( n != "" ) {
          name_id++;
          name_index[name_id]=n;
          names[n]=name_id;
        }
    }
}

function load_values() {
    value_id=0;
    while ( (getline v < "jlq_value_index" ) > 0 ) {
        if (v !=  "") {
          value_id++;
          value_index[value_id]=v;
          values[v]=value_id;
        }
    }
}

function get_line_from_index() {
    return get_line_from_index_at($5, $6);
}

function get_line_from_index_at( _nid, _vid ) {
    return sprintf("\"%s\": \"%s\"", 
        get_name_from_index_at( _nid ), 
        get_value_from_index_at( _vid ));
}

function get_name_from_index() {
    return get_name_from_index_at( $5 );
}

function get_name_from_index_at( _nid ) {
    return name_index[ _nid ];
}

function get_value_from_index() {
    return get_value_from_index_at( $6 );
}

function get_value_from_index_at( _vid, _v ) {
    return value_index[ _vid ];
}

function print_prompt_from_line() {
    printf "- ";
    for (i = 8; i <= NF; i++) {
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

    current=get_value_from_index();

    # print out the prompt
    print_prompt_from_line();
    updated=prompt_string( line );

    # output old value and updated value
    if ( get_line_from_index() != updated ) {
        print $1, $2, $3, $4, $5, 
          format_update( $6, value_id ), 
          format_update( get_value_from_index(),  get_value_from_index_at( value_id ) ) >> "jlq_string_prompt_out" ;
    }
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
