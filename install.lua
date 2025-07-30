local files = {
	"xevious.lua",
	"tilemap1.txt"
}

local git = "https://raw.githubusercontent.com/stuin/Xevious/refs/heads/main/"

--Install files
for i = 1,#files do
	fs.delete(shell.resolve(files[i]))
	shell.run("wget "..git..files[i])
end

fs.delete(shell.resolve("xevious-map.txt"))
fs.move(shell.resolve("tilemap1.txt"), shell.resolve("xevious-map.txt"))