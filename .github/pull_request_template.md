## Change type

- [ ] Development change from a `{solution}/spr-N` or `{solution}/vX.Y.Z` branch
- [ ] Documentation change from a `docs/*` branch
- [ ] Repository configuration change from a `project/*` branch

The pull request is automatically labeled `dev`, `docs`, or `project` from its branch type.

## Verification

- [ ] I tested or reviewed the changed behavior.
- [ ] Development branches only modify their own `solutions/ppat_*/` folder, `docs/`, `package.json`, `package-lock.json`, or `.gitignore`.
- [ ] Documentation branches only modify `docs/`, `package.json`, `package-lock.json`, or `.gitignore`.
- [ ] Project branches don't modify files below `solutions/`.
- [ ] Issues included in a solution release are closed and labeled `release:{solution}-vX.Y.Z`.

## Summary

Describe the change and any relevant test results.