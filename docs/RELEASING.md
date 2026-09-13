This manual covers publishing reviewed changes; [TESTING.md](TESTING.md) owns
verification and [CHANGELOG.md](../CHANGELOG.md) records user-visible changes.

# Releasing

This plugin is installed from Git. There is no package build or registry upload,
and no release script or version manifest is currently maintained.

1. Review the exact diff, run the automated suite from the testing manual, and run
   `git diff --check`. Record any unperformed MATLAB integration checks explicitly.
2. Update the changelog and affected manuals. Verify configuration and command
   examples still match the code.
3. Push the reviewed branch and require its CI checks to pass before merging.
   A green Lua suite is not evidence that live MATLAB integration passed.
4. If a versioned release is explicitly requested, choose and review its tag and
   release notes separately. Publishing code does not itself create a tagged release.

If a published change regresses behavior, fix it through a tested follow-up or revert
commit. Avoid rewriting shared history; users can pin an earlier known-good commit
while the correction is reviewed.
