#!/usr/bin/env bash

# Find project main branch
find_main_branch() {
	git rev-parse --git-dir &> /dev/null || return
	local ref
	for ref in refs/remotes/origin/{main,master}; do
		if git show-ref -q --verify "$ref"; then
			echo "${ref##*/}"
			return 0
		fi
	done
	echo master
	return 1
}
