find_main_branch() {
	if ! lib::exec git rev-parse --git-dir >/dev/null; then
		log::error "Not in git dir"
		exit 2
	fi
	local ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
		if lib::exec git show-ref -q --verify "$ref" &>/dev/null; then
			local main_branch="${ref##*/}"
			log::info "Found main branch: $main_branch"
			echo "$main_branch"
			return 0
		fi
	done
	echo master
	return 1
}

find_current_branch() {
	lib::exec git rev-parse --abbrev-ref HEAD
}
