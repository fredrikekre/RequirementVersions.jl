var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#RequirementVersions.minimum_requirement_versions-Tuple{Any}",
    "page": "Home",
    "title": "RequirementVersions.minimum_requirement_versions",
    "category": "Method",
    "text": "minimum_requirement_versions(package_name; package_directory = Pkg.dir(), should_resolve = true, skips = String[])\n\nAutomatically finds the minimum versions of required packages that will still allow your tests to pass. List any packages you want to skip in skips. Set should_resolve to false to prevent Pkg.pin and Pkg.test from running Pkg.resolve().\n\nMakes the assumption that if a certain profile of versions work, all profiles with versions greater or equal will also work.\n\n\n\n"
},

{
    "location": "index.html#RequirementVersions.cp_withperms-Tuple{Any,Any}",
    "page": "Home",
    "title": "RequirementVersions.cp_withperms",
    "category": "Method",
    "text": "cp_withperms(src, dest; remove_destination = false)\n\nCopy src to dest, preserving permissions\n\n\n\n"
},

{
    "location": "index.html#RequirementVersions.fix_perms-Tuple{Any,Any}",
    "page": "Home",
    "title": "RequirementVersions.fix_perms",
    "category": "Method",
    "text": "fix_perms(src, dest)\n\nEnsure dest has same permissions as src\n\n\n\n"
},

{
    "location": "index.html#RequirementVersions.restore",
    "page": "Home",
    "title": "RequirementVersions.restore",
    "category": "Function",
    "text": "restore(archive, package_directory = Pkg.dir())\n\nRestore all the files in the archive to your package directory.\n\n\n\n"
},

{
    "location": "index.html#RequirementVersions.jl-1",
    "page": "Home",
    "title": "RequirementVersions.jl",
    "category": "section",
    "text": "Modules = [RequirementVersions]"
},

]}
