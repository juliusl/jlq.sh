#!/bin/awk -f 

# parse.awk - parses the current line

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
    # red -> green
    return sprintf("\033[31m%s\033[39m->\033[32m%s\033[39m", _c, _u);
}

function format_line(_n, _v) {
    return sprintf("\"%s\": \"%s\"", _n, _v);
}

# Parsers

# Parse document
function parse_document() {
    $2 ~ /jlq/;
    # "jlq": "<specify-or-empty-for-PWD>",
    # Start creating index files 
    parse_root();
}

# Parse a root record
function parse_root() {
    # create index entry
    root_id++;
    root_index[root_id]=$0;
}

# Parse the name from the record
function parse_name() {
    if ($2 != "") {
      # forward lookup (index)
      if (names[$2] > 0) {
        name[NR]=names[$2];
      } else {
        # create index entry
        name_id++;
        # index value
        name_index[name_id]=$2;
        # setup reverse lookup
        names[$2]=name_id;
        name[NR]=name_id;
        print name_index[name_id] >> "jlq_name_index";
        close("jlq_name_index");
      }
    }
}

# Parse the value from the record
function parse_value() {
    # setup reverse lookup only (store)
    if ($3 != "") {
        value_id++;
        value_index[value_id]=$3;
        values[$2]=value_id;
        value[NR]=value_id;
        print value_index[value_id] >> "jlq_value_index";
        close("jlq_value_index");
    }
}

# Parse the prompt from the record
function parse_prompt() {
    prompt[NR] = substr($0, match($0, $4));
    if ( prompt[NR] == $0) {
        prompt[NR]="";
    } 
    
    if ( prompt[NR] == "" && $4 != "") {
        prompt[NR]=$4;
    }
}

# Parse the branch information from the record
function parse_branch(_t) {
    branch[NR]=NR;
    root[NR]=root_id;
    _t=$0;
    depth[NR]=gsub(/\t/, " ", _t);
}

# Parse the line information from the record
function parse_line(_l) {
    lines[NR]=_l;
}

function print_context(_r) {
    start=(_r + 5);
    end=(_r - 5);

    for (i = start; i <= end; i++) {
        print_depth(depth[i]);
        print lines[i];
    }
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

function print_string_line_update(_l, _u, _ov, _nv) {
    if ( _l != _u ) {
        print $1, $2, $3, $4, $5, 
          format_update( $6, _ov ),
          format_update( _ov,  get_value_from_index_at( _nv ) ) >> "jlq_string_prompt_out" ;
    }
}
