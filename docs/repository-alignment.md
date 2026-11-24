# Repository alignment tracker

Status checked on 2026-11-24. This file records completed work and the remaining release gates across the six maintained repositories.

## Target layout

| Repository | Owns | Distribution |
| --- | --- | --- |
| AMP-v3-dockerized | AMP 3 image, panel smoke test, Linux runtime settings, Unraid template | GHCR and Unraid |
| AniList-MAL-Sync | Python sync service, OAuth, tests, Compose, Unraid template | GHCR and Unraid; native Python development |
| ACELink | Python service, prebuilt web UI, device setup, mock smoke test, Compose | Linux Docker Compose first; native development and hardware testing |
| Tareku99/.github | Community defaults, reusable workflows, and composite actions | Shared files and SHA-pinned GitHub Actions references |

Keep image names, supported platforms, secrets, runtime permissions, licenses, and hardware requirements with the repository that owns the application.

## Completed

### Community files and repository policy

- Shared bug and feature issue forms, issue chooser, pull request template, support policy, security policy, funding link, and CODEOWNERS are present in Tareku99/.github.
- The shared bug form asks for hardware model, adapter, and connection type when device issues are reported. The application repositories do not keep duplicate issue forms.
- GitHub inherits these community files, but a personal account's .github repository cannot apply branch rulesets automatically. The equivalent ruleset was configured separately in each repository.
- All six repositories use active default-branch rulesets. Pull requests and current required checks must pass; deletion and force pushes are blocked.
- Merge commits are the only allowed PR merge method. Squash and rebase merges are disabled; the rulesets do not require linear history.
- Required checks: .github `validate`; AMP, AniList, and ACELink `test` plus `build / build`; Snapmaker and Unraid driver `test`.
- All six repositories have no collaborators, default Actions tokens are read-only, and workflows from external contributors require owner approval.

### Shared CI and release workflows

- The shared CI summary action reports test outcomes and optional JUnit counts. The shared Docker build and publish workflows are pinned to full commit SHAs.
- AMP and AniList report test, build, and publish outcomes, including image tags and digest. ACELink reports test and mock-container build results; its publish job is gated.
- Snapmaker and Unraid driver CI report their single validation job.
- The latest default-branch CI runs succeeded in all six repositories.
- AMP README and Compose use GHCR. AniList README and Compose document Compose v2, persistent data, native Python development, beta releases, and production releases.
- ACELink's Dockerfile uses a locked frontend build stage, a non-root Python runtime, and a writable `/data` settings volume. Compose maps only the configured serial device and device group. CI runs Python tests and a mock-mode container smoke test.

### Production image snapshot

| Image | Verified production digest | Status |
| --- | --- | --- |
| `ghcr.io/tareku99/amp-v3-dockerized:latest` | `sha256:346d1d55c5d6296e244e2611bb6979c5ed7725f3b5f8f03f5060f1b70199af42` | Published by successful post-merge `master` run [45510141918](https://github.com/Tareku99/AMP-v3-dockerized/actions/runs/45510141918) |
| `ghcr.io/tareku99/anilist-mal-sync:latest` | `sha256:9a6d0b42ab26bffda043c2596fb6fb639f9e1088283456c8b283a307be49293f` | Published by successful post-merge `main` run [45510164666](https://github.com/Tareku99/anilist-mal-sync/actions/runs/45510164666) |
| `ghcr.io/tareku99/acelink` | None | No image has been published |

## Merged follow-up PRs

- [.github#3](https://github.com/Tareku99/.github/pull/3) added the shared source-checkout action and inherited issue-form validation. Post-merge `validate` run [45509961578](https://github.com/Tareku99/.github/actions/runs/45509961578) passed.
- [AMP#5](https://github.com/Tareku99/AMP-v3-dockerized/pull/5) and [AniList#11](https://github.com/Tareku99/AniList-MAL-Sync/pull/11) now use the pinned shared source-checkout action. Their post-merge production runs passed and published the digests above.
- [ACELink#7](https://github.com/Tareku99/ACELink/pull/7) added gated GHCR release paths and native settings migration steps. Post-merge checks passed; publishing was skipped because the hardware gate remains off.
- All four PRs were merged using merge commits; squash merging was not used.

## Remaining work

### ACELink real-device validation

- ACELink#7 is merged, but publishing stays disabled until ACE Pro and ACE 2 Pro adapters pass through the Linux container.
- Validate real device detection or explicit serial configuration, live status in the UI, settings persistence after container recreation, and migration using a copy of a native settings file.
- After validation, enable beta publishing first, verify pulling and upgrading the beta image, then enable production publishing. Keep `linux/amd64` as the only advertised platform until arm64 is tested.
- Keep the Compose example on local builds until the first published image has been pulled and upgraded successfully.

### AMP Unraid runtime

- Valheim installation and startup were confirmed on Unraid with AMP's permission fallback. Recreate the container while retaining the data volume, then verify panel startup and a game-server restart against the current GHCR image.

### Release-path checks

- Post-merge production workflows for AMP and AniList passed and published the digests above. The default-branch ACELink workflow passed its tests; its publish job was skipped by the hardware gate.
- The manual beta path has not been exercised during this follow-up because it changes the public beta tag. Exercise it when a beta release is requested and verify that production tags remain unchanged.

### Docker Hub cleanup

- Do not remove the legacy Docker Hub image until its exact repository and tag are confirmed and any remaining consumer or Unraid template has been moved to GHCR.
- The exact Docker Hub repository and tag for the legacy AMP 3 image still need confirmation. No package has been deleted.

## Retired automation repository

- `Tareku99/shared-devops` was deleted and now returns 404. No active branch or release workflow in the six repositories references it.
- Historical workflow runs that pinned `shared-devops` may not be rerunnable now that the repository is unavailable.

## Rollback

- Retain the previous known-good image digest and persistent data before rollout. If an update fails, restore the known-good image while keeping the data volume. If a shared workflow regresses, pin the caller back to its previous SHA in a follow-up PR.