# Repository and Release Plan

Status checked on 2026-11-24. This is the single plan for the six repositories in this project: what is already in place, what remains, and what must be true before an image is published or removed.

## Goal

- Keep shared community files and reusable CI in `Tareku99/.github`.
- Keep each application's code, Docker settings, release tags, and deployment guidance in its own repository.
- Build and test images on pull requests without publishing them. Publish only from approved release events.
- Keep each default branch protected with the same merge and workflow controls.

## Repositories and current state

| Repository | Current state | Distribution / next gate |
| --- | --- | --- |
| `Tareku99/.github` | Shared issue forms, support/security files, reusable Docker workflows, CI summary, source-checkout action, and validation are merged. | Source of shared files and SHA-pinned Actions references. Rulesets remain configured separately in each repo. |
| `Tareku99/AMP-v3-dockerized` | Production image is published to GHCR; release and checkout workflows are merged. | GHCR and Unraid. Verify the post-merge image on Unraid with data retained. |
| `Tareku99/AniList-MAL-Sync` | Production image is published to GHCR; release and checkout workflows are merged. | GHCR and Unraid. Manual beta release path has not been exercised. |
| `Tareku99/ACELink` | Dockerfile, mock smoke test, release workflow, and settings migration instructions are merged. Publishing is gated and no image exists yet. | Linux Docker first. Test ACE Pro and ACE 2 Pro hardware before publishing. |
| `Tareku99/snapmaker_u1_obico` | Shared community setup and CI are merged; CI is green. | Source repository; no image publishing is planned here. |
| `Tareku99/unraid-nct6687-driver` | Shared community setup and CI are merged; CI is green. | Unraid plugin repository; no image publishing is planned here. |

## Completed work

### Shared community and contribution files

- `Tareku99/.github` provides the default bug form, feature form, issue chooser, pull request template, support policy, security policy, and funding link.
- The bug form asks for hardware model, adapter, and connection type where relevant. The app repositories have no duplicate issue forms.
- The `.github` repository has a `CODEOWNERS` file for itself. GitHub does not inherit that file into other repositories; all six repositories are owner-only with no collaborators.
- AMP keeps one `LICENSE` file using the MIT license. No duplicate upstream license file is needed; upstream attribution remains in the project materials.

### Shared CI and Docker release code

- `Tareku99/.github` contains the shared checkout action, CI summary action, Docker build workflow, Docker publish workflow, and validation workflow.
- Shared Actions references use full commit SHAs.
- AMP, AniList, and ACELink use shared Docker build/publish workflows. Pull request builds run tests and image checks but skip publishing.
- Snapmaker and the Unraid driver use the shared CI summary action for their validation checks.
- The shared issue forms and the checkout action are validated by the `.github` workflow.

### Branch and workflow protections

- All six repositories have active default-branch rulesets. Pull requests and required status checks are required; deletion and force pushes are blocked.
- The only allowed PR merge method is GitHub's merge-commit method. Squash and rebase merging are disabled. The rulesets do not require linear history.
- Required checks: `.github` `validate`; AMP, AniList, and ACELink `test` plus `build / build`; Snapmaker and Unraid driver `test`.
- All six repositories have zero collaborators, Actions' default token permissions are read-only, and workflows from external contributors require owner approval.
- A personal account's `.github` repository cannot apply branch rulesets automatically. The same ruleset was configured per repository.
- The four implementation PRs were merged as two-parent merge commits, not squashed. Keep PR branches free of merge commits from merging the base branch into them.

### Current image and CI evidence

| Repository | Latest verified run | Result |
| --- | --- | --- |
| `.github` | [45509961578](https://github.com/Tareku99/.github/actions/runs/45509961578) | `validate` passed |
| AMP | [45510141918](https://github.com/Tareku99/AMP-v3-dockerized/actions/runs/45510141918) | Tests and production publish passed |
| AniList | [45510164666](https://github.com/Tareku99/anilist-mal-sync/actions/runs/45510164666) | Tests and production publish passed |
| ACELink | [45510177073](https://github.com/Tareku99/ACELink/actions/runs/45510177073) | Tests passed; publish skipped by its hardware gate |
| Snapmaker | [45502535188](https://github.com/Tareku99/snapmaker_u1_obico/actions/runs/45502535188) | CI passed |
| Unraid driver | [45502531499](https://github.com/Tareku99/unraid-nct6687-driver/actions/runs/45502531499) | CI passed |

| Published image | Current verified tags | Digest |
| --- | --- | --- |
| `ghcr.io/tareku99/amp-v3-dockerized` | `master`, `master-amd64`, `latest` | `sha256:346d1d55c5d6296e244e2611bb6979c5ed7725f3b5f8f03f5060f1b70199af42` |
| `ghcr.io/tareku99/anilist-mal-sync` | `main`, `sha-7095e46`, `latest` | `sha256:9a6d0b42ab26bffda043c2596fb6fb639f9e1088283456c8b283a307be49293f` |
| `ghcr.io/tareku99/acelink` | No tags | No image published; publishing remains disabled |

Both released images target the platforms configured in their workflows. ACELink currently targets `linux/amd64`; do not advertise arm64 until it is tested.

## Remaining work, in order

### 1. Verify AMP on Unraid

**Status:** The current Unraid template points to GHCR. Valheim installation and startup were previously confirmed, but the post-merge image still needs recreation and restart testing on the user's Unraid host.

- Confirm the container's Repository field is `ghcr.io/tareku99/amp-v3-dockerized:latest`.
- Back up or otherwise preserve the existing AMP data mapping. Recreate the container using the current image without changing the data path or required runtime settings.
- Verify the panel starts, a game server starts and restarts, and AMP reports no shard-agent or `.docker-machine-id` permission error.
- Record the image digest used and keep the previous known-good digest available for rollback.

**Done when:** the current GHCR image survives container recreation with the existing data and a game-server restart succeeds.

### 2. Test ACELink on real hardware

**Status:** Not done. The mock-mode container and Python tests pass, but neither real serial adapter has been validated through Docker.

- On a Linux Docker host, test an ACE Pro and an ACE 2 Pro separately with their real serial adapters.
- Confirm the configured device path and device group are mapped into the non-root container, and verify device detection or explicit serial selection plus live device status in the UI.
- Use a separate copy of the native settings file for the first migration. Follow the copy instructions in the ACELink README; verify the UI reads the settings and that edits survive restart and container recreation.
- Record the adapter type, model, device path behavior, settings result, and any errors for each unit.

**Done when:** both models are usable in the Linux container and settings survive container recreation. Do not enable ACELink publishing before this gate passes.

### 3. Publish the first ACELink image

**Status:** Workflow is merged; its beta and production repository variables are unset, so no image can publish.

- After step 2 passes, set `ACELINK_BETA_PUBLISH_ENABLED=true` and dispatch the workflow from `main`, selecting the tested source branch.
- Verify the beta tag and digest, pull the image, test startup and settings persistence, and verify an upgrade from the prior beta.
- Only after beta verification, set `ACELINK_PRODUCTION_PUBLISH_ENABLED=true`. Verify the production tags and digest.
- Then change `compose.yaml` from local build to `ghcr.io/tareku99/acelink:latest`, and verify a clean pull and upgrade.
- Keep `linux/amd64` as the advertised platform until arm64 is tested.

**Done when:** a beta pull/upgrade succeeds, production tags point to the tested image, and Compose uses the published image.

### 4. Exercise the AMP and AniList beta paths

**Status:** Production releases passed. The manual beta workflow has not been run.

- When a beta release is intentionally requested, dispatch the workflow from its default branch and select the tested source branch.
- Confirm the commit-specific beta tag and `beta` tag identify the expected image digest.
- Confirm `latest` and the normal production tag do not move.

**Done when:** the beta image is pullable and production tags remain unchanged. This creates public beta tags, so run it only as an intentional release.

### 5. Decide when to remove the old Docker Hub image

**Status:** Not deleted. The exact legacy Docker Hub repository/tag has not been confirmed.

- Current AMP Compose and Unraid template use GHCR. Existing Docker Hub installations still need a manual Repository-field change to GHCR.
- Confirm the exact Docker Hub image name and tag, verify the user's Unraid container has switched to GHCR, and identify any other active installs that still need the Hub image.
- Keep the old image until known installs are migrated. Then either leave it with a deprecation notice or delete it if legacy pulls and updates are no longer needed.

**Decision:** Do not delete the Docker Hub image yet. Removing it can break pulls or updates for installations still configured to use it.

### 6. Optional end-to-end ruleset failure check

**Status:** Ruleset configuration and passing PR checks are verified. No deliberately failing PR was created to demonstrate the merge-block UI.

- If explicit proof is needed, use a temporary branch and harmless failing required check. Confirm GitHub blocks merge until the check passes and that the check can be rerun; then close the PR without merging.
- Ordinary PR image builds already showed publish jobs skipped. Do not test failure behavior on a production branch.

## Retired repository and retained tooling

- `Tareku99/shared-devops` was deleted by the owner. No active branch or release workflow references it. Historical workflow runs that pinned it may no longer be rerunnable.
- Keep ACELink's native installer scripts while they support desktop use and hardware testing. Revisit their removal only if the native audience no longer needs them.

## Rollback

- Record the previous known-good image digest before each rollout.
- If an image fails, restore the previous digest and keep the existing data volume.
- If a shared workflow regresses, pin its caller back to the previous full SHA in a follow-up PR.