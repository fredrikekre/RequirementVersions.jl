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
    minimum_requirement_versions(package_name; package_directory = Pkg.dir(), should_resolve = true, skips = String[])

Automatically finds the minimum versions of required packages that will still
allow your tests to pass. List any packages you want to skip in `skips`.
Set `should_resolve` to `false` to prevent `Pkg.pin` and `Pkg.test` from running `Pkg.resolve()`.

Makes the assumption that if a certain profile of versions work, all profiles
with versions greater or equal will also work.
"""
minimum_requirement_versions(package_name; package_directory = Pkg.dir(), should_resolve = true, skips = String[]) = begin
    package_file = joinpath(package_directory, package_name)
    if !ispath(package_file)
        error("Can't find package $package_file")
    end
    requirements = setdiff(union(
        extract_requirements(package_file, "REQUIRE"),
        extract_requirements(package_file, "test", "REQUIRE")
    ), union(skips, ["julia"]))
    reqbounds = Pkg.Reqs.parse(joinpath(package_file, "REQUIRE"))
    archive = mktempdir(package_directory)
    info("Making archive folder $archive to archive your pacakges. If anything goes wrong please run `restore($archive)`")
    version_numbers = map(requirements) do requirement
        info("Archiving $requirement")
        cp_withperms(joinpath(package_directory, requirement), joinpath(archive, requirement))
        versions = Pkg.available(requirement)
        # start by testing at existing lower bound from REQUIRE file, if present
        if requirement in keys(reqbounds)
            lowerbound = reqbounds[requirement].intervals[1].lower
            if lowerbound in versions
                try
                    info("Downgrading to $requirement $lowerbound")
                    my_pin(requirement, lowerbound, should_resolve = should_resolve)
                    my_test(package_name, should_resolve = should_resolve, coverage = false)
                    # if tests pass at existing lower bound, skip testing all higher versions
                    filter!(v -> v <= lowerbound, versions)
                catch err
                    warn("$package_name fails tests at existing lower bound of $requirement $lowerbound")
                    warn(err)
                end
            end
        end
        while length(versions) > 1
            try
                previous_version = versions[end - 1]
                info("Downgrading to $requirement $previous_version")
                my_pin(requirement, previous_version, should_resolve = should_resolve)
                my_test(package_name, should_resolve = should_resolve, coverage = false)
                pop!(versions)
            catch err
                warn(err)
                break
            end
        end
        last_version = last(versions)
        if should_resolve
            cp_withperms(joinpath(archive, requirement), joinpath(package_directory, requirement), remove_destination = true)
            Pkg.resolve()
        else
            my_pin(requirement, last_version, should_resolve = should_resolve)
        end
        last_version
    end
    restore(archive, package_directory)
    Dict(zip(requirements, version_numbers))
end

"""
    restore(archive, package_directory = Pkg.dir())

Restore all the files in the archive to your package directory.
"""
restore(archive, package_directory = Pkg.dir()) = begin
    foreach(readdir(archive)) do file
        cp_withperms(joinpath(archive, file), joinpath(package_directory, file), remove_destination = true)
    end
    rm(archive, recursive = true)
end

"""
    cp_withperms(src, dest; remove_destination = false)

Copy `src` to `dest`, preserving permissions
"""
cp_withperms(src, dest; remove_destination = false) = begin
    cp(src, dest; remove_destination = remove_destination)
    is_unix() && fix_perms(src, dest)
end

"""
   fix_perms(src, dest)

Ensure `dest` has same permissions as `src`
"""
fix_perms(src, dest) = begin
    if isdir(dest)
        foreach(readdir(dest)) do file
            fix_perms(joinpath(src, file), joinpath(dest, file))
        end
    else
        if filemode(src) != filemode(dest)
            chmod(dest, filemode(src))
        end
    end
end

end
