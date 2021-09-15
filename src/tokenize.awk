#!/bin/awk

BEGIN {
    # Tokenizer
    # /t+\"/        - beginning of line
    # /\":.?\"/     - the beginning of the value
    # \",?\b?       - end of a value
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
    parse_line(format_line($2, $3));
    
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
    
    parse_line(format_line($2, $3));
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

        if ( _n == 0 ) {
            return;
        }

        if ( prompt[_b] ) {
            print _r, _o, _b, _d, _n, _v, format_prompt( prompt[_b] );
        } else {
            # Tree branch coordinates
            print _r, _o, _b, _d, _n, _v;
        }
}
