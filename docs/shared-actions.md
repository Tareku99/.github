## Shared Docker release workflows

Use these reusable workflows from the caller repository:

- `.github/workflows/docker-build.yml` builds the caller's Dockerfile and optionally runs its smoke-test script. It has `contents: read` only and never publishes.
- `.github/workflows/docker-publish.yml` builds the image, runs the same optional smoke test, and publishes that tested image to GHCR. It requests `packages: write` only in the publishing job.
- Both workflows use the pinned `.github/actions/docker-release` composite action for the build, smoke-test, publish, and summary steps.

Application-specific tests stay in each application repository. The caller must make the reusable workflow depend on its test job so a failed test prevents the image workflow from starting.

### Caller requirements

- Pin the reusable workflow reference to a full 40-character commit SHA. Do not use `@main` or a floating version tag.
- Grant `contents: read` to the build workflow call. Grant `packages: write` only to the publishing workflow call.
- Pass `GITHUB_TOKEN` only to the publishing workflow, after application tests pass.
- Use a GHCR image path under `ghcr.io/tareku99/`.
- Pass the exact `source_sha` checked out by the app test job. The tested commit must match the commit that triggered the release.
- GitHub runs the caller workflow defined on the selected branch. It must contain the updated caller and the pinned shared references. If a beta smoke-test script is configured, the publish job takes that script from the caller's default branch.
- When updating from an older pin, remove the caller's typed branch dispatch input, the checkout action's `branch` and `default-branch` inputs, and the publish workflow's `beta_branch` input in the same change.
- The workflow checks out the caller repository. The exact built image is smoke-tested and pushed from the same runner. One platform is supported per invocation; AMP 3 requires `linux/amd64`.

### Release triggers and image tags

| Trigger | GHCR tags |
| --- | --- |
| Push or merge to the default branch | `latest` and the default branch name, with an optional `sha-<commit>` tag |
| Manually select a non-default branch in **Run workflow** | `beta` and `beta-<commit>` |
| Push a `v*` Git tag that points to a commit reachable from the default branch | The version tag, with an optional `sha-<commit>` tag |
| Push to a non-default branch, or manually run on the default branch or a tag | No publish |

Configure the caller with `workflow_dispatch` and push triggers for the default branch and `v*` tags. A version tag push does not move `latest`.

Example validation call:

```yaml
jobs:
  build:
    name: build
    needs: tests
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
    uses: Tareku99/.github/.github/workflows/docker-build.yml@<full-commit-sha>
    with:
      image: ghcr.io/tareku99/example
      source_image: example:ci
      smoke_test_script: tests/smoke.sh
```

Example publishing call:

```yaml
jobs:
  publish:
    name: publish
    needs: tests
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    uses: Tareku99/.github/.github/workflows/docker-publish.yml@<full-commit-sha>
    with:
      image: ghcr.io/tareku99/example
      source_image: example:ci
      source_sha: ${{ needs.tests.outputs.source_sha }}
      smoke_test_script: tests/smoke.sh
    secrets:
      ghcr_token: ${{ secrets.GITHUB_TOKEN }}
```

For advanced cases, the composite action can still be called directly. Its action reference must also use a full commit SHA.

## CI reports

Call the pinned composite action at `Tareku99/.github/.github/actions/ci-summary@<full-commit-sha>`.
In the test job, pass the test step outcome, checked-out commit, and optional JUnit path.
In an informational final job, pass the results from `toJSON(needs)`. Successful publish
jobs expose their GHCR tags and digest to the report.

Maintain the same required check names in app callers when updating these pins.
