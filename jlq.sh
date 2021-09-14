#!/bin/sh
# shellcheck disable=SC3043

# Just for fun until it's really useful

# Input
# {
#"jlq":"test23",
#\t"name":"t43d",
#\t"phone":"234=24350023",
#"test":"fas5g345-34t34",
#\t"name": {testt423t4},
#\t\t\t"phone":"",
# }
# {
# 	"test": "test"
# }

# Expecting Tokens
# LineNo TokenType {Token}
# R   Root token
# Content
# -   Default token
# tree name, depth, key, value
# ERR Error token
#
# 2 R "jlq":"test23",
# 2 - jlq 0 jlq test23
# 3 - jlq 1 name t43d
# 4 - jlq 1 phone 234=24350023
# 5 R "test":"fas5g345-34t34",
# 5 - test 0 test fas5g345-34t34
# 6 ERR test 1 name : {testt423t4},<-<-
# ERR Invalid Content
# 7 ERR test 2 phone :
# ERR Invalid Content
# END

# Tokenizer V1
# tokenize takes a json file and parses the jlq tree

_tokenize() {
	local jlq=$1
	if ( ./parse.awk "$jlq" > ./_index ); then
		echo ./_index
		return 0;
	fi
	return 1;
}
alias tokenize=_tokenize

_render() {
	local index=$1
	if ( ./render.awk "$index" ); then
		cat ./render.record.out ./render.field.out > render.out
	fi
}
alias render=_render

_interpret() {
	local jlq=$1
	i=$(_tokenize "$jlq")
	_render "$i"
}
alias interpret=_interpret

_print_json() {
	local renderoutput=$1
	local json_format_out='./json_format_render.out'
	if [ -f "$renderoutput" ]; then 
		./format_json.awk "$renderoutput" > $json_format_out
	fi 

	# 
	./format_json_rc.awk $json_format_out | 
	awk '{ print $1, $2; }' |
	while read -r f; do
		mkdir -p "$(dirname "$f")"

		out="$(echo "$f" | cut -d ' ' -f1 )"
		echo "$f" | awk '{print $2}' | tr -d "'" |
		if read -r l; then
			sed -n "$l" "$json_format_out" > "$out"
		fi 
	done
	 

}
alias print_json=_print_json


#  cat render.out render.line.out


# Nice to have features 
# {
# "jlq":"", <- all files must start with this
# "hello": "", <- This is a root
# 	"world": "you are round", <- This is a child of "hello"
# 	"earth": "you are blue", <^- This is another child of "hello" and sibling of world
# 	"family": "you are cool", <^- This is another child of hello and sibling of earth and world
# "hello2": "", 
# 	"world": "you are rounder",
# 	"earth": "you are bluer",
# 	"family": "you are cooler"
# }
# <- this syntax could be proccessed to guide or even create a wizard?