#!/usr/bin/env bash

# Find project main branch
find_main_branch() {
	lib::exec git rev-parse --git-dir &>/dev/null || return
	local ref
	for ref in refs/remotes/origin/{main,master}; do
		if lib::exec git show-ref -q --verify "$ref" 2>/dev/null; then
			echo "${ref##*/}"
			return 0
		fi
	done
	echo master
	return 0
}

find_current_branch() {
	lib::exec git rev-parse --abbrev-ref HEAD
}
