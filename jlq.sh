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
tokenize() {
	# shellcheck disable=SC3043
	local file=$1
	sed 's/\t/<-/g' "$file" | awk -F '"' '
{

if (NR == 2 && $2 != "jlq") {
	print "Not JQL, line 2 must start with \"jlq\""
	exit 1
}

tabs=length($1)

if (tabs > 1) {
	tabs=length($1)/2
}

# Error checking
OFS=" "
TOKEN="-"
ERR=""
if (NR > 1 && tabs > 1) {
	if (LAST+1 != tabs && LAST+2 != tabs+1) {
		ERR=sprintf("Invalid Transition %d -> %d -> %d", LAST, tabs, tabs+1)
		TOKEN="ERR"
	} else {
		LAST=tabs+1
	}
}
else if (NF%2 == 0 || NF < 5) {
	ERR=sprintf("Unbalanced line %s", $0)
	TOKEN="ERR"
}
else if (tabs == 0) 
{
	ROOT=$2
	LAST=1
	print NR, "R", $0
}

if ($4 != "" && ERR == "" && TOKEN == "-") {
	print NR, NF-1, TOKEN, ROOT, tabs, sprintf("%s:", $2), $4
} else if ($0=="}") {
	print "END"
	exit 0
}

if ($0=="{") {

}

if ($0 != "{" && ERR != "") {
	print NR, "ERR", ROOT, tabs, $0
	print "ERR", ERR
}
}
'
}

tokenize ./database.json
if ! tokenize ./notjql.json; then
	:
fi

query() {
	local file="$1"
	local tree="$2"
	local search="$3"
	tokenize "$file" | 
		grep -E "[\d ]+[-R]|(?:ERR).$tree" |
	    grep -E "$search"
}

query ./nicetohave.json hello

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