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
    should_resolve && resolve()
    nothing
end
entry_pin(pkg::AbstractString; should_resolve = true) = entry_pin(pkg, "", should_resolve = should_resolve)

function entry_pin(pkg::AbstractString, ver::VersionNumber; should_resolve = true)
    ispath(pkg,".git") || throw(Pkg.PkgError("$pkg is not a git repo"))
    Pkg.Read.isinstalled(pkg) || throw(Pkg.PkgError("$pkg cannot be pinned – not an installed package"))
    avail = Pkg.Read.available(pkg)
    isempty(avail) && throw(Pkg.PkgError("$pkg cannot be pinned – not a registered package"))
    haskey(avail,ver) || throw(Pkg.PkgError("$pkg – $ver is not a registered version"))
    entry_pin(pkg, avail[ver].sha1, should_resolve = should_resolve)
end

my_pin(pkg::AbstractString; should_resolve = true) = Pkg.cd(Pkg.splitjl(pkg)) do splitpkg
    entry_pin(splitpkg, should_resolve = should_resolve)
end


my_pin(pkg::AbstractString, ver::VersionNumber; should_resolve = true) =  Pkg.cd(Pkg.splitjl(pkg)) do splitpkg
    entry_pin(splitpkg, ver, should_resolve = should_resolve)
end
