import Documenter

Documenter.deploydocs(
    julia = "nightly",
    repo = "github.com/bramtayl/RequirementVersions.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
