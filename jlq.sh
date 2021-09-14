#!/bin/sh
# shellcheck disable=SC3043

#
# JLQ.sh 
# Flat tree structure that renders to json
# Includes tools to annotate and create setup prompts
# This is useful when designing and managing plugin systems 
#

# Environment
JLQ_HOME=${JLQ_HOME:-"$HOME/.config/jlq"}
JLQ_NAMESPACE=${JLQ_NAMESPACE:-"default"}
JLQ_ROOT="$JLQ_HOME/$JLQ_NAMESPACE"
JLQ_SOURCE=${JLQ_SOURCE:-""}

if [ "$1" = "init" ]; then 
  JLQ_SOURCE="$PWD/src"
  shift;
fi 

if [ ! -d "$JLQ_SOURCE" ]; then 
  echo "set JLQ_SOURCE to continue or run \`./jlq.sh init\` from repo root"
  return 1
fi

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
	"$JLQ_ROOT/interpret.awk" "./jlq_index"

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

# EOF