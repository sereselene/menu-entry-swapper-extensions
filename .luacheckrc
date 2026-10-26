std = "max"

max_line_length = 200

ignore = {
	"212/self",
}

read_globals = {
	"ui",
	"id",
	"Event",
	"Plugin",
	"PersistentDB",
	"config",
	"prettyui",
}

globals = {
	"PluginShutdown",
}

exclude_files = {
	"lua_modules",
}

files["spec"] = {
	std = "+busted",
	globals = { "print" },
}
