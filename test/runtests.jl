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

Test.@test minimum_requirement_versions("SimpleTraits", skips = ["Compat"]) ==
           Dict("MacroTools" => v"0.3.1");

Test.@test_throws ErrorException minimum_requirement_versions("FakePackage")
