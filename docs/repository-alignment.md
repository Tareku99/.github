# Repository alignment status

Snapshot: 2026-11-24

## Repository roles

| Repository | Owns | Distribution |
| --- | --- | --- |
| AMP-v3-dockerized | AMP 3 image, panel smoke test, runtime settings, and Unraid template | GHCR and Unraid |
| AniList-MAL-Sync | Python sync service, OAuth setup, tests, Compose, and Unraid template | GHCR and Unraid; native Python development |
| ACELink | Python service, prebuilt web UI, device setup, mock smoke test, and Compose | Linux Docker Compose first; native development and hardware testing |
| Tareku99/.github | Account-wide community defaults, reusable workflows, and actions | GitHub community defaults and SHA-pinned workflow/action references |
| snapmaker_u1_obico | Snapmaker U1 Obico integration | GitHub Actions CI |
| unraid-nct6687-driver | Unraid NCT6687 driver | GitHub Actions CI |

## Implemented

- AMP and AniList use the shared GHCR build/publish workflows. Pull requests test and build; default-branch pushes and eligible version tags publish. Manual beta runs start from the default branch and select a source branch.
- The shared repository has pinned Docker build/publish actions and CI summaries, plus account-wide issue forms, support policies, funding, and pull request defaults.
- ACELink has a non-root Linux image, Compose setup, Python tests, and a mock container smoke test. The current Compose path builds locally.
- Snapmaker U1 Obico and Unraid NCT6687 adopted the shared community files and now require their CI check before merging.
- All six repositories have zero collaborators, read-only default workflow-token permissions, and require owner approval for workflow runs from external contributors.
- All six default-branch workflows passed on 2026-11-24. Current repository rules require pull requests, block force pushes/deletion, require up-to-date checks, and allow merge commits only. Required checks are listed below.

## Current merge checks

| Repository | Required checks | Merge method |
| --- | --- | --- |
| Tareku99/.github | validate | Merge commit |
| AMP-v3-dockerized | test; build / build | Merge commit |
| AniList-MAL-Sync | test; build / build | Merge commit |
| ACELink | test; build / build | Merge commit |
| snapmaker_u1_obico | test | Merge commit |
| unraid-nct6687-driver | test | Merge commit |

GitHub stores each repository's ruleset separately. This account-wide repository cannot make a ruleset automatically apply to the other five repositories.

## Remaining work

- Merge the shared source-checkout action and form-validation changes in this PR, then pin the action in AMP, AniList, and ACELink.
- Run ACE Pro and ACE 2 Pro serial adapters through the Linux container. Confirm device status and settings after container recreation; use a separate copy of a native configuration for the first migration test.
- ACELink GHCR publishing is being prepared behind opt-in repository variables. Keep beta and production publishing disabled until those container hardware checks pass. Then publish beta, verify pull and upgrade, and enable production tags.
- Advertise only the tested image architecture. The shared publisher currently targets linux/amd64; validate arm64 before adding it.
- Retire shared-devops only after the live workflow-reference and maintained-branch audit. Historical workflow reruns that pin it need the repository to remain available.
- Remove the old Docker Hub ACE image only after a verified GHCR pull/upgrade and any active Unraid templates move to the replacement.

## Release rollback

Record the previous image digest before rollout. If an update fails, restore the known-good digest while keeping the application's data volume. If a shared workflow regresses, restore its previous pinned commit through a follow-up pull request.
