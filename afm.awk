#!/usr/bin/gawk -f

BEGIN {
	# Directory separator and number of them initially
	DS="\t"
	CDS=0
	EMPTY="-_-EMPTY-_-"

	opened	= "-> "
	closed	= "<> "
	file	= "   "

	cmds = "DotDot"
	cmds = cmds" Hidden"
	cmds = cmds" List"

	print_hidden = "no"

	main()
	exit
}

@include "./acme.awk"

func gettree(tree, dir,		arr, i, j) {
	ls(arr, dir)

	tree["type"] = "dir"
	tree["cached"] = "yes"	# Got files from this directory to structure?
	tree["print"] = "yes"	# Should print content of directory?

	if (arr[0] <= 1) {
		delete tree["nodes"]
		tree["nodes"][EMPTY]["type"] == "file"
		return
	}

	for (i = 1; i < arr[0]; i++) {
		if (isdir(dir"/"arr[i]) == "yes") {
			if (tree["nodes"][arr[i]]["cached"] == "yes") {
				# Update files in tree
				gettree(tree["nodes"][arr[i]], dir"/"arr[i])
				continue
			}

			tree["nodes"][arr[i]]["type"] = "dir"
			tree["nodes"][arr[i]]["cached"] = "no"
			tree["nodes"][arr[i]]["print"] = "no"
		} else
			tree["nodes"][arr[i]]["type"] = "file"
	}

	for (i in tree["nodes"]) {
		flag = 0

		for (j = 1; j < arr[0]; j++) {
			if (arr[j] != i)
				continue

			flag = 1
			break
		}

		if (flag == 0)
			delete tree["nodes"][i]
	}
}

func parsenode(nd, wi, start,		cmd1, chn, lnn, ln_depth,
														cur_depth, prev_ln, ln) {
	cmd1 = "9p read acme/"wi"/body"
	lnn = 1
	chn = 0

	nd[0] = 1
	cur_depth = CDS

	prev_ln = ""

	while (cmd1 | getline ln > 0) {
		chn += length(ln) + 1

		ln_depth = get_depth(ln)
		sub("^("DS")*(("opened")|("closed")|("file"))", "", ln)

		if (cur_depth < ln_depth) {
			nd[nd[0]++] = prev_ln
			cur_depth++
		} else if (cur_depth > ln_depth) {
			nd[0]--
			cur_depth--
		}

		if (start < chn)
			break

		prev_ln = ln
		sub("/$", "", prev_ln)
	}
	close(cmd1)

	nd[nd[0]++] = ln
}

func sort(arr,		i, j, tmp) {
	for (i = 1; i < arr[0] - 1; i++) {
		k = i
		for (j = i + 1; j < arr[0]; j++) {
			if (toupper(arr[k]) > toupper(arr[j]))
				k = j
		}
		tmp = arr[k]
		arr[k] = arr[i]
		arr[i] = tmp
	}
}

func getnodes(tree, nodes,		i) {
	nodes[0] = 1

	for (i in tree["nodes"])
		nodes[nodes[0]++] = i

	sort(nodes)
}

func printtree(wi, tree, off, root,		i, pref, nodes, nm) {
	pref = strmul(DS, off)

	if (tree["type"] != "dir" || \
			tree["cached"] == "no" || \
				tree["print"] == "no")
		return

	getnodes(tree, nodes)

	for (i = 1; i < nodes[0]; i++) {
		nm = nodes[i]

		if (nm ~ /^\./ && print_hidden == "no")
			continue

		if (tree["nodes"][nodes[i]]["type"] == "dir") {
			if (tree["nodes"][nodes[i]]["print"] == "no") {
				out = out pref closed nm "/\n"
				continue
			}

			out = out pref opened nm "/\n"

			if (tree["nodes"][nodes[i]]["cached"] == "no")
				gettree(tree["nodes"][nodes[i]], root"/"nm)

			printtree(wi, tree["nodes"][nodes[i]], off + 1, root"/"nm)
		}
		else
			out = out pref file nm "\n"
	}
}

func parseevent(arr, ev) {
	arr["dev"] = substr(ev, 1, 1) == "M" ? "mouse" : "keyboard"
	sub(/^./, "", ev)

	switch (substr(ev, 1, 1)) {
		case "X":
			arr["place"] = "body"
			arr["act"] = "execute"
			break
		case "x":
			arr["place"] = "tag"
			arr["act"] = "execute"
			break
		case "L":
			arr["place"] = "body"
			arr["act"] = "look"
			break
		case "l":
			arr["place"] = "tag"
			arr["act"] = "look"
			break
	}

	sub(/^./, "", ev)

	match(ev, /^[0-9]+ /)
	arr["start"] = substr(ev, RSTART, RLENGTH - 1)
	sub(/^[0-9]+ /, "", ev)

	match(ev, /^[0-9]+ /)
	arr["end"] = substr(ev, RSTART, RLENGTH - 1)
	sub(/^[0-9]+ /, "", ev)

	match(ev, /^[0-9]+ /)
	arr["flag"] = substr(ev, RSTART, RLENGTH - 1)
	sub(/^[0-9]+ /, "", ev)

	match(ev, /^[0-9]+ /)
	arr["count"] = substr(ev, RSTART, RLENGTH - 1)
	sub(/^[0-9]+ /, "", ev)

	arr["content"] = ev

}

func events(	cmd, cmd1, ln, ev) {
	cmd = "9p read acme/"wi"/event"

	while (cmd | getline ln > 0) {
		win_sendcmd(wi, "clean")

		parseevent(ev, ln)

		if (ev["dev"] != "mouse" || !ev["content"])
			continue

		switch (ev["act"]) {
		case "execute":
			if (ev["place"] == "tag") {
				switch (ev["content"]) {
				case "Del":
					close(cmd)
					win_sendcmd(wi, "del")
					return
				case "DotDot":
					root = getl("readlink -f \""root"/..\"")
					gettree(tree, root)
					print_stuff(wi)
					break
				case "Hidden":
					print_hidden = (print_hidden == "yes") ? "no" : "yes"
					print_stuff(wi)
					break
				case "List":
					gettree(tree, root)
					print_stuff(wi)
					break
				default:
					system(ev["content"])
				}
			} else {
				parsenode(nd, wi, int(ev["start"]))

				if (nd[nd[0] - 1] == EMPTY)
					continue

				# if directory
				if (nd[nd[0] - 1] !~ "/$")
					continue

				root = root "/" getdir(nd)
				root = getl("readlink -f '"root"'")
				gettree(tree, root)
				print_stuff(wi)
			}
			break
		case "look":
			if (ev["place"] == "tag")
				continue

			parsenode(nd, wi, int(ev["start"]))

			if (nd[nd[0] - 1] == EMPTY)
				continue

			# if directory
			if (nd[nd[0] - 1] ~ "/$") {
				sub("/$", "", nd[nd[0] - 1])
				switchprintdir(tree, nd, 1)
				print_stuff(wi)
				win_showaddr(wi, "#"ev["start"])
			} else {
				fp = root"/"getdir(nd)

				if (isfile(fp) == "yes")
					system("plumb \""esc(fp)"\"")
				else {
					twi = win_new()
					win_sendcmd(twi, "name "getl("readlink -f \""esc(fp)"\""))
				}
			}
			break
		}
	}

	close(cmd)
}

func switchprintdir(tree, dir, idx,		i, arr) {
	for (i in tree["nodes"]) {
		if (i != dir[idx])
			continue

		idx++

		if (idx != dir[0]) {
			switchprintdir(tree["nodes"][i], dir, idx)
			return
		}

		if (tree["nodes"][i]["print"] == "yes")
			tree["nodes"][i]["print"] = "no"
		else {
			tree["nodes"][i]["cached"] = "no"
			tree["nodes"][i]["print"] = "yes"

			delete tree["nodes"][i]["nodes"]
		}

		return
	}
}

func getdir(dir,	i, res) {
	res = dir[1]
	for (i = 2; i < dir[0]; i++)
		res = res "/" dir[i]
	return res
}

func get_depth(ln,		res) {
	while (ln ~ "^" DS) {
		res += 1
		sub("^" DS, "", ln)
	}

	return res
}

func esc(s) {
	gsub("\\", "\\\\", s)
	gsub("'", "\\'", s)
	gsub("\"", "\\\"", s)

	return s
}

func isdir(dir) {
	return system("test -d \""esc(dir)"\"") == 0 ? "yes" : "no"
}

func isfile(file) {
	return system("test -f \""esc(file)"\"") == 0 ? "yes" : "no"
}

func strmul(s, n,	out) {
	while (n--)
		out = out s

	return out
}

func ls(arr, dir,	i, cmd, tmp) {
	cmd = "ls -A \""esc(dir)"\""
	i = 1

	while (cmd | getline tmp > 0)
		arr[i++] = tmp

	arr[0] = i
	close(cmd)
}

func win_getdir(wi,		fl) {
	fl = getl("9p read acme/"wi"/tag|sed 's/ Del Snarf.*$//'")

	return isdir(fl) == "yes" ? fl : getl("dirname \""fl"\"")
}

func print_stuff(wi) {
	win_sendcmd(wi, "name "root)
	win_clear(wi)

	printtree(wi, tree, CDS, root)
	win_writebody(wi, out)
	out = ""
	win_sendcmd(wi, "clean")
	win_showaddr(wi, "#0")
}

func main(		cmd, ln) {
	rwi = ENVIRON["winid"]
	wi = win_new()
	root = rwi ? win_getdir(rwi) : ARGV[1] ? ARGV[1] : ENVIRON["HOME"]
	root = getl("readlink -f '"root"'")

	win_addtotag(wi, cmds)

	gettree(tree, root)
	print_stuff(wi)
	events()
}

