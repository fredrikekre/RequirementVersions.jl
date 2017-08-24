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
    minimum_requirement_versions(package_name; package_directory = Pkg.dir(), skips = String[])

Automatically finds the minimum versions of required packages that will still
allow your tests to pass. List any packages you want to skip in `skips`.

Makes the assumption that if a certain profile of versions work, all profiles
with versions greater or equal will also work.
"""
minimum_requirement_versions(package_name; package_directory = Pkg.dir(), skips = String[]) = begin
    package_file = joinpath(package_directory, package_name)
    if !ispath(package_file)
        error("Can't find package $package_file")
    end
    requirements = setdiff(union(
        extract_requirements(package_file, "REQUIRE"),
        extract_requirements(package_file, "test", "REQUIRE")
    ), union(skips, ["julia"]))

    version_numbers = map(requirements) do requirement
        versions = sort(collect(keys(Pkg.Read.available(requirement))))

        while length(versions) > 1
            try
                previous_version = versions[end - 1]
                info("Downgrading to $requirement $previous_version")
                my_pin(requirement, previous_version, should_resolve = false)
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
