# taken from base, which the only difference being the should_resolve = true
# keyword arguments, ref #23251
function entry_pin(pkg::AbstractString, head::AbstractString; should_resolve = true)
    ispath(pkg,".git") || throw(Pkg.PkgError("$pkg is not a git repo"))
    LibGit2.with(LibGit2.GitRepo, pkg) do repo
        id = if isempty(head) # get HEAD commit
            # no need to resolve, branch will be from HEAD
            should_resolve = false
            LibGit2.head_oid(repo)
        else
            LibGit2.revparseid(repo, head)
        end
        commit = LibGit2.GitCommit(repo, id)
        try
            # note: changing the following naming scheme requires a corresponding change in Read.ispinned()
            branch = "pinned.$(string(id)[1:8]).tmp"
            if LibGit2.isattached(repo) && LibGit2.branch(repo) == branch
                info("Package $pkg is already pinned" * (isempty(head) ? "" : " to the selected commit"))
                should_resolve = false
                return
            end
            ref = LibGit2.lookup_branch(repo, branch)
            try
                if !isnull(ref)
                    if LibGit2.revparseid(repo, branch) != id
                        throw(Pkg.PkgError("Package $pkg: existing branch $branch has " *
                            "been edited and doesn't correspond to its original commit"))
                    end
                    info("Package $pkg: checking out existing branch $branch")
                else
                    info("Creating $pkg branch $branch")
                    ref = Nullable(LibGit2.create_branch(repo, branch, commit))
                end

                # checkout selected branch
                LibGit2.with(LibGit2.peel(LibGit2.GitTree, get(ref))) do btree
                    LibGit2.checkout_tree(repo, btree)
                end
                # switch head to the branch
                LibGit2.head!(repo, get(ref))
            finally
                close(get(ref))
            end
        finally
            close(commit)
        end
    end
    should_resolve && Pkg.resolve()
    nothing
end
entry_pin(pkg::AbstractString; should_resolve = true) =
    entry_pin(pkg, "", should_resolve = should_resolve)

function entry_pin(pkg::AbstractString, ver::VersionNumber; should_resolve = true)
    ispath(pkg,".git") || throw(Pkg.PkgError("$pkg is not a git repo"))
    Pkg.Read.isinstalled(pkg) || throw(Pkg.PkgError("$pkg cannot be pinned – not an installed package"))
    avail = Pkg.Read.available(pkg)
    isempty(avail) && throw(Pkg.PkgError("$pkg cannot be pinned – not a registered package"))
    haskey(avail,ver) || throw(Pkg.PkgError("$pkg – $ver is not a registered version"))
    entry_pin(pkg, avail[ver].sha1, should_resolve = should_resolve)
end

splitjl(pkg) = isdefined(Pkg, :splitjl) ? Pkg.splitjl(pkg) : endswith(pkg, ".jl") ? pkg[1:(end-3)] : pkg

my_pin(pkg::AbstractString, ver::VersionNumber; should_resolve = true) = Pkg.cd(splitjl(pkg)) do splitpkg
    if should_resolve
        Pkg.pin(splitpkg, ver)
    else
        entry_pin(splitpkg, ver, should_resolve = should_resolve)
    end
end


function test!(pkg::AbstractString,
               errs::Vector{AbstractString},
               nopkgs::Vector{AbstractString},
               notests::Vector{AbstractString};
               coverage::Bool=false, should_resolve = true)
    reqs_path = abspath(pkg,"test","REQUIRE")
    if should_resolve && Pkg.Reqs.isfile(reqs_path)
        tests_require = Pkg.Reqs.parse(reqs_path)
        if (!isempty(tests_require))
            info("Computing test dependencies for $pkg...")
            Pkg.Entry.resolve(merge(Pkg.Reqs.parse("REQUIRE"), tests_require))
        end
    end
    test_path = abspath(pkg,"test","runtests.jl")
    if !isdir(pkg)
        push!(nopkgs, pkg)
    elseif !isfile(test_path)
        push!(notests, pkg)
    else
        info("Testing $pkg")
        Pkg.cd(dirname(test_path)) do path
            try
                if VERSION >= v"0.7.0-DEV.1335"
                    cmd = ```
                        $(Base.julia_cmd())
                        --code-coverage=$(coverage ? "user" : "none")
                        --color=$(Base.have_color ? "yes" : "no")
                        --compilecache=$(Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
                        --check-bounds=yes
                        --warn-overwrite=yes
                        --startup-file=$(Base.JLOptions().startupfile != 2 ? "yes" : "no")
                        $test_path
                        ```
                    run(cmd)
                else
                    color = Base.have_color? "--color=yes" : "--color=no"
                    codecov = coverage? ["--code-coverage=user"] : ["--code-coverage=none"]
                    compilecache = "--compilecache=" * (Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
                    julia_exe = Base.julia_cmd()
                    run(`$julia_exe --check-bounds=yes $codecov $color $compilecache $test_path`)
                end
                info("$pkg tests passed")
            catch err
                Pkg.Entry.warnbanner(err, label="[ ERROR: $pkg ]")
                push!(errs,pkg)
            end
        end
    end
end

function entry_test(pkgs::Vector{AbstractString};
    coverage::Bool = false, should_resolve = true)
    errs = AbstractString[]
    nopkgs = AbstractString[]
    notests = AbstractString[]
    for pkg in pkgs
        test!(pkg, errs, nopkgs, notests;
            coverage = coverage, should_resolve = should_resolve)
    end
    if !all(isempty, (errs, nopkgs, notests))
        messages = AbstractString[]
        if !isempty(errs)
            push!(messages, "$(join(errs,", "," and ")) had test errors")
        end
        if !isempty(nopkgs)
            msg = length(nopkgs) > 1 ? " are not installed packages" :
                                       " is not an installed package"
            push!(messages, string(join(nopkgs,", ", " and "), msg))
        end
        if !isempty(notests)
            push!(messages, "$(join(notests,", "," and ")) did not provide a test/runtests.jl file")
        end
        throw(Pkg.Entry.PkgTestError(join(messages, "and")))
    end
end

entry_test(; coverage::Bool = false, should_resolve = true) = entry_test(sort!(AbstractString[keys(Pkg.installed())...]);
    coverage = coverage, should_resolve = should_resolve)

my_test(; coverage::Bool = false, should_resolve = true) =
    Pkg.cd(entry_test; coverage = coverage, should_resolve = should_resolve)

my_test(pkgs::AbstractString...; coverage::Bool = false, should_resolve = true) =
    should_resolve ? Pkg.test(pkgs...; coverage = coverage) :
    Pkg.cd(entry_test, AbstractString[splitjl.(pkgs)...];
        coverage = coverage, should_resolve = should_resolve)
