using RequirementVersions

import Documenter
Documenter.makedocs(
    modules = [RequirementVersions],
    format = :html,
    sitename = "RequirementVersions.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)

Test.@test minimum_requirement_versions("MacroTools") ==
           Dict("Compat" => v"0.9.5");
