#!/bin/awk -f 

# Formatter
function format_prompt(_c) {
    # orange
    return sprintf("\033[33m%s\033[39m", _c);
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
function parse_branch() {
    branch[NR]=NR;
    root[NR]=root_id;
    depth[NR]=gsub(/\t/," ",$0);
}

# Parse the line information from the record
function parse_line(_l) {
    lines[NR]=_l;
}

BEGIN {
    # Tokenizer
    # /t+\"/        - beginning of line
    # /\":.?\"/     - the beginning of the value
    # /\",[^\b]*</  - the beginning of the prompt
    # /:?\"\"/      - skip empty values
    # /".</         - the beginning of a prompt on the last line
    FS="\t+\"|\":.?\"|\",[^\b]?<|\",?\b?|.?<-\"|:?\"\",|\".<";
    root_id=0;
    name_id=0;
    value_id=0;
    offset=0;

    # Clear output
    print "" > "jlq_name_index";
    close("jlq_name_index");
    print "" > "jlq_value_index";
    close("jlq_value_index");
}
/^#/{
    # Comment
    parse_line($0);
}
/^{|}/ {
    # Begin/End document
    parse_line($0);
}
/^".*$/ {
    # Root record start
    parse_line(sprintf("\"%s\": \"%s\"", $2, $3));
    
    # Create index files
    if (root_id == 1) {
        parse_document();
    } else {
        parse_root();
    }
    
    parse_branch();
    parse_name();
    parse_value();
    parse_prompt();
}
/\t+/ {
    # Branch start    
    line=NR;
    parse_line(sprintf("\"%s\": \"%s\"", $2, $3));

    # Parse depth
    parse_branch();
    parse_name();
    parse_value();
    parse_prompt();
}
END { 
    current_root=root_index[1];
    # Document Root
    print current_root;
    for ( line in lines ) {
        print_document(line);
    }
}

function print_document(_i, _r, _b, _d, _n, _v) {
      _b=branch[_i];
      if (_b != 0) { 
        _r=root[_b];
        _d=depth[_b];
        _n=name[_b];
        _v=value[_b];

        cursor=root_index[_r];

        print_document_root(_r, _b, _d, _n, _v);
      }
}

function print_document_root(_r, _b,_d, _n, _v) {
      if (cursor != current_root) {
        current_root=cursor;
        offset=0;
        printf "%d, %s\n", _r, current_root;
      }

      if ( current_root == cursor && _b > 0) {
          print_coordinates(_r, offset, _b, _d, _n, _v);
          offset++;
      }
}

function print_coordinates(_r, _o, _b,  _d, _n, _v) {
        if (_v == 0) {
            _v = 0;
        }
        if ( prompt[_b] ) {
            print _r, _o, _b, _d, _n, _v, format_prompt( prompt[_b] );
        } else {
            # Tree branch coordinates
            print _r, _o, _b, _d, _n, _v;
        }
}
