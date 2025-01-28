#!/usr/bin/env bash

# Find project main branch
find_main_branch() {
	lib::exec git rev-parse --git-dir &> /dev/null || return
	local ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
		if lib::exec git show-ref -q --verify "$ref" 2>/dev/null
		then
			echo "${ref##*/}"
			return 0
		fi
	done
	echo master
	return 1
}


find_current_branch() {
	lib::exec git rev-parse --abbrev-ref HEAD
}
