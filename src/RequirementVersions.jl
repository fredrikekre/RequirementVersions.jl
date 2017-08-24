module RequirementVersions

include("pin.jl")

extract_requirements(args...) = begin
    path = joinpath(args...)
    if ispath(path)
        path |> Pkg.Reqs.parse |> keys |> collect
    else
        String[]
    end
end

export minimum_requirement_versions
"""
    minimum_requirement_versions(package_name, package_directory = Pkg.dir())

Automatically finds the minimum versions of required packages that will still
allow your tests to pass.

Makes the assumption that if a certain profile of versions work, all profiles
with versions greater or equal will also work.

```jldoctest
julia> using RequirementVersions

julia> minimum_requirement_versions("ChainRecursive") ==
            Dict("Documenter" => v"0.8.5", "NumberedLines" => v"0.0.2", "MacroTools" => v"0.3.1")
true
```
"""
minimum_requirement_versions(package_name, package_directory = Pkg.dir()) = begin
    package_file = joinpath(package_directory, package_name)
    requirements = setdiff(union(
        extract_requirements(package_file, "REQUIRE"),
        extract_requirements(package_file, "test", "REQUIRE")
    ), ["julia"])
    requirement = first(requirements)

    version_numbers = map(requirements) do requirement
        versions = VersionNumber.(
            joinpath(package_directory, requirement) |>
            LibGit2.GitRepo |>
            LibGit2.tag_list)

        while length(versions) > 1
            try
                my_pin(requirement, versions[end - 1], should_resolve = false)
                my_test(package_name, should_resolve = false)
                pop!(versions)
            catch
                break
            end
        end
        last_version = last(versions)
        my_pin(requirement, last_version, should_resolve = false)
        last_version
    end
    Pkg.free.(requirements)
    Dict(zip(requirements, version_numbers))
end

end
