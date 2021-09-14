#!/bin/awk -f 

# render - renders the output from interpret.awk w/ the output from parse.awk
# Input files:
# _index, name_index, value_index, string_prompt_out
# Output files:
#

function load_names() {
    name_id=0;
    while ( (getline n < "jlq_name_index" ) > 0 ) {
        if ( n != "" ) {
          name_id++;
          name_index[name_id]=n;
        }
    }
}

function load_values() {
    value_id=0;
    while ( (getline v < "jlq_value_index" ) > 0 ) {
        if (v !=  "") {
          value_id++;
          value_index[value_id]=v;
        }
    }
}

function create_output_record(basename, namespace) {
    # output record format
    # each root, (offset == 0) is a "basename": "namespace" so the output record is 
    # namespace basename <extension: example .json>
    #
    print $1, namespace, basename >> "jlq_render_record_out";
    close("jlq_render_record_out");
}

function create_output_record_line() {

}

BEGIN {
    print "[output-record]" > "jlq_render_record_out";
    close("render.record.out");
    print "" > "jlq_render_field_out";
    print "[output-field]" > "jlq_render_field_out";
    close("jlq_render_field_out");
    load_names();
    load_values();
    root_dir="";
}

# easy to remember if you look at it as:
# _r _o _b _d _n _v 
# rob-dnv
# 1 - root id
# 2 - offset
# 3 - line (branch)
# 4 - depth
# 5 - name id
# 6 - value id 
#

# root is when offset is 0 
$2 == 0 {
    basename=name_index[$5];
    namespace=value_index[$6];

    if (namespace == "") {
        namespace="default";
    }

    if ( root_dir == "" ) {
        root_dir = namespace;
    } else if ( root_dir != "" ) {
        namespace = sprintf("%s/%s", root_dir,  namespace);
    }

    create_output_record(basename, namespace);
    current_record=sprintf("[%s/%s]", namespace, basename);
}

$2 > 0 {
    name=name_index[$5];
    value=value_index[$6];

    record[NR]=current_record;
    field[NR]=sprintf("%d %d %s %s", $1, $4, name, value);
}

END {
    for (i in record ) {
        if (record[i] != "") {
            print field[i] >> "jlq_render_field_out";
            close("jlq_render_field_out");
        }
    }
}
# 
