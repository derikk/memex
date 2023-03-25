using REPL.TerminalMenus
import TOML
import Configurations: from_toml, to_toml

function study()
	print("Enter the filename of a deck to study: ")
	filename = readline()

	if !endswith(filename, ".toml")
		filename *= ".toml"
	end

	if !isfile(filename)
		@warn "No deck by that name exists."
		return study()
	end

	deck = try
		deckversion = VersionNumber(TOML.parse(readline(filename))["version"])
		if deckversion >= VersionNumber(version.major, version.minor+1, 0)
			@warn "Deck was created with a newer version of Memex. There may be incompatibilities."
		end
		from_toml(Deck, filename)
	catch
		printstyled("Error: Could not read deck format.\n", color=:red)
		return
	end

	review!(deck)
	to_toml(filename, deck)
end

function createdeck()
	print("Enter a name for the new deck: ")
	name = readline()
	filename = replace(name, r"\W" => "_") * ".toml"

	if isfile(filename)
		println("A deck with that name already exists. We'll study the existing deck.")
		return filename
	end

	deck = Deck(name=name)
	to_toml(filename, deck)
	println("Created $filename")
	return filename
end

printstyled("Memex v$version\n", bold=true, color=:blue)

options = ["Study deck", "New deck", "Quit"]

while true
	opt = request("Select an option:", RadioMenu(options))

	if opt == 1
		study()
	elseif opt == 2
		createdeck()
	elseif opt == 3 || opt == -1
		exit()
	end
end

