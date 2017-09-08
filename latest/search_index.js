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
    "location": "index.html#RequirementVersions.copy_with_permissions-Tuple{Any,Any}",
    "page": "Home",
    "title": "RequirementVersions.copy_with_permissions",
    "category": "Method",
    "text": "copy_with_permissions(source, destination; remove_destination = false)\n\nCopy source to destination, preserving permissions\n\n\n\n"
},

{
    "location": "index.html#RequirementVersions.fix_permissions-Tuple{Any,Any}",
    "page": "Home",
    "title": "RequirementVersions.fix_permissions",
    "category": "Method",
    "text": "fix_permissions(source, destination)\n\nEnsure destination has same permissions as source\n\n\n\n"
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
