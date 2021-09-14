#!/bin/awk -f 

# format_golang.awk
# format output from format_json.awk to a golang struct type definition

# Example input
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

function add_package_header(_n) {
    printf "package %s\n", _n >> "golang_format_render.out";
    close("golang_format_render.out");
}

function begin_type_struct_definition(_t) {
    printf "type %s struct {\n", _t  >> "golang_format_render.out"; 
    close("golang_format_render.out");
}

function add_json_field(_n, _t) {
    printf "\t%s\tstring\t`json:\"%s\"`\n", _n, _t >> "golang_format_render.out";
    close("golang_format_render.out");
}

function end_type_struct_definition(_f) {
    printf "}\n%%s>\"%s.go\"\n", _f  >> "golang_format_render.out"; 
    close("golang_format_render.out");
}

function add_comment(_c) {
    printf "// %s\n", _c >> "golang_format_render.out";
    close("golang_format_render.out");  
}

BEGIN {
    printf "" > "golang_format_render.out";
    close("golang_format_render.out");  
}

$0 ~ /^\[.*\]$/ {
    num=split(substr($0, 2, length($0)-2), array, "/");
    root_namespace=array[1];
    root=array[3];
    namespace=array[2];
    add_package_header(root_namespace);
    begin_type_struct_definition(root);

    line[NR]=$0;
}

$0 ~ /^".*":/ {
    tag=substr($1, 2, length($1)-3);
    base_index=split(tag, array, "/");
    base=array[base_index];
    add_json_field(base, tag);

    line[NR]=$0;
}

$0 == "}" {
    end_type_struct_definition(namespace);

    line[NR]=$0;
}

# Example output
# package default
# # Generated, but feel free to tinker
# # Example content:
# # [default/julius/work]
# # {
# # "official": "yi",
# # "official/alternative": "yi jun",
# # "official/alternative/backup": "yi jun liu"
# # }
# type work struct {
#     official 			string `json:"official"`
#     alternative 		string `json:"official/alternative"`
#     official/alternative/backup string `json:"official/alternative/backup"`
# }
# %s>"julius.go"

# package default
# # Generated, but feel free to tinker
# # Example content:
# # [default/bobo/home]
# # {
# # "introuble": "notjulius"
# # }
# type home struct {
#   introuble string `json:"introuble"`
# }
# %s>"bobo.go"
