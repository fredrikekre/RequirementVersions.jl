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

predicted =
    minimum_requirement_versions("SimpleTraits", skips = ["Compat"])["MacroTools"]
actual =
    if VERSION < v"0.7.0-"
        v"0.3.1"
    else
        v"0.3.7"
    end

Test.@test predicted == actual
