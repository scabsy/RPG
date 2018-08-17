# README #

## Corona SDK Utilities

### What is this repository for? ###

A collection of useful Corona SDK modules I use every day.
These collection is free to use.

### How do I get set up? ###

Create a new folder in your Corona project root called devilsquid
Download and copy the contents into the devilsquid project folder.
Even better: use something like SourceTree to clone the repository directly into your project folder.

I.e. the path to this README.md must be:
YourCoronaProject/devilsquid/util/Readme.md

Since revision 43 you can setup a global configuration table. This is needed if you want to place the devilsquid/ folder somewhere else (i.e. plugin development). Best would be to setup the table in the main.lua file. You need a **devilsquid.requirepath** and **devilsquid.filepath** like this:

''devilsquid = {
''    requirepath = "path.to.devilsquid.",
''    filepath = "path/to/devilsquid/"
''}

Thsi way the whole utils can easily be adapted to create pure Lua plugins.

### Documentation

I started to document these modules. This project contains a *doc* folder which contains docs in HTML format.

### Contribution ###

Not all of the code is written by me. Especially most of the math module is a collection I found on the internet. Contributions are in the files.