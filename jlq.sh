#!/bin/sh
# shellcheck disable=SC3043

#
# JLQ.sh 
# Block tree structure that renders to json, etc
# Includes syntax create prompts on single lines, which can be built to replace values
# This is useful when designing and managing plugin systems 
#

# Environment
JLQ_HOME=${JLQ_HOME:-"$HOME/.config/jlq"}
JLQ_NAMESPACE=${JLQ_NAMESPACE:-"default"}
JLQ_ROOT="$JLQ_HOME/$JLQ_NAMESPACE"
JLQ_SOURCE=${JLQ_SOURCE:-""}


_init() {
  	JLQ_SOURCE="$PWD/src";
	mkdir -p "$JLQ_SOURCE"
}
_setupDemo() {
  _init
  JLQ_NAMESPACE="demo"

  mkdir _demo
  _install
  _documentation
  # TODO add <+ prompt
}

main () {
case "$1" in
  init) 
    shift;
	_init
  ;;
  demo) shift; 
    _setupDemo
  ;;
  help) 
	shift;
	_init;
	_documentation;
	return 0;;
esac

if [ ! -d "$JLQ_SOURCE" ]; then 
  echo "set JLQ_SOURCE to continue or run \`./jlq.sh init\` from repo root"
  return 1
fi
}


_tokenize() {
	local jlq=$1
	if ( "$JLQ_ROOT/parse.awk" "$jlq" > "./jlq_index" ); then
		echo './jlq_index'
		return 0;
	fi
	return 1;
}
alias tokenize=_tokenize

_render() {
	local index=$1
	index=${index:-"./jlq_index"}
	if ( "$JLQ_ROOT/render.awk" "$index" ); then
		cat "./jlq_render_record_out" "./jlq_render_field_out" > "./jlq_render_out"
	fi
	
	echo "./jlq_render_out"
}
alias render=_render

_interpret() {
	"$JLQ_ROOT/prompts.awk" "./jlq_index"

	if [ -f "jlq_string_prompt_out" ]; 
	then
		:
	fi
}
alias interpret=_interpret

_print_json() {
	local renderoutput=$1
	renderoutput=${renderoutput:-"jlq_render_out"}
	local json_format_out="./json_format_render.out"

	if [ -f "$renderoutput" ]; then 
		"$JLQ_ROOT/format_json.awk" "$renderoutput" > "$json_format_out"
	else
		echo "Missing render output"
		return 1;
	fi

	"$JLQ_ROOT/format_json_rc.awk" "$json_format_out" | 
	  awk '{ print $1, $2; }' |
	  while read -r f; do
		mkdir -p "$JLQ_ROOT/$(dirname "$f")"

		out="$(echo "$f" | cut -d ' ' -f1 )"
		  echo "$f" | 
		  awk '{print $2}' | 
		  tr -d "'" |
		  if read -r range; then
		  	outputfile="$JLQ_ROOT/$out"
			sed -n "$range" "$json_format_out" > "$outputfile"
			echo "$outputfile"
		  fi 
	  done
}
alias print_json=_print_json

_install() {
	mkdir -p "$JLQ_ROOT"
	cp -rT "$JLQ_SOURCE" "$JLQ_ROOT"
}
alias install=_install

_documentation() {
	cat << EOF
Title			jlq.sh - JLQ shell

# TODO Add .man headers and summary

# Parse and Tokenize
usage: 		   	tokenize <file>.jlq
description:   	tokenizes a .jlq file to the jlq_index format
(required) 		<file>.jlq - Following are examples of .jlq files and what is getting tokenized

<+
An empty .jlq file looks like this:
{
"jlq": ""	
}
\`\`\`
<+

<+
A empty .jlq file with a prompt looks like this:
\`\`\`
{
"jlq": "" <- This is required
}
\`\`\`
<+

<+
A empty .jlq file with a string prompt looks like this:
\`\`\`
{
"jlq": "" <%s Enter a root name
}
\`\`\`
<+

<+
A empty .jlq file with a root branch looks like this:
\`\`\`
{
"jlq": "", <%s Enter a root name <- and now this one does
"root": "" <- notice that the last line doesn't have a comma 
}
\`\`\`
<+

<+
A empty .jlq file with a root branch with a child looks like:
\`\`\`
{
"jlq": "", <%s Enter a root name <- and now this one does
"root": "",
	"child": "" <- This is a child of "root"
}
\`\`\`
<+

<+
A empty .jlq file with a root branch with three siblings looks like this:
\`\`\`
{
"jlq": "", <%s Enter a root name <- and now this one does
"root": ""
	"child": "" <- This is a child of "root"
	"child2": "" <- This is a child of "root" <- By the way 
	"child": "" <- this is okay too, albiet confusing if you don't make the values different 
}
\`\`\`
<+

<+ <- By the way this is a demo prompt, allows some flexibility and to have an embedded jlq file
A empty .jlq file with a second root like this: 
\`\`\` <- The embedded parsing only starts after this line, so you can write anything in between
{
"jlq": "", <%s Enter a root name <- and now this one does
"root": ""
	"child": "" <- we can have children too
		"child of child": "" <- you can do this too if you really wanted
	"child2": ""
	"child": "" 
"root2": "" <- this doesn't have to be the same name either 
}
\`\`\` <- if you don't set a prompt here 
<+ <- then it won't show up in the demo

<- This is an error. If you had a remote process add this to their logs and ran it through the interpret function.
<- It will stop on lines like this, and allow you to do some diagnostics.
}

Tokenize converts these jlq files to the jlq_index_format. From there we can render or interpret that format for
purposes like interactive config, wizard experiences, presentations, etc. 

# Interpret and Render

usage: 		   	render <jlq_index>
description:   	outputs a jlq_index to a jlq_render format

usage: 		   	interpret <jlq_index>
description:   	interpret prompts and cursors (TODO)

(optional) 		jlq_index - If jlq_index is blank, will use jlq_index in current directory

# Templating

usage: 		   	print_json <jlq_render_out>
description:   	outputs .json files from rendering

usage:			print_golang <jlq_render_out>
description:	outputs .go files from rendering

(optional) 		jlq_render_out - If jlq_render_out is blank, will use jlq_render_out in current directory

If all of this just rushed onto your screen, then type: 

./jlq.sh demo

to receive a guided tour
EOF
}

main "$1"
# EOF