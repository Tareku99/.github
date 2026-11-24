# Repository alignment plan

## Target layout

| Repository | Owns | Distribution |
| --- | --- | --- |
| AMP-v3-dockerized | AMP image, panel smoke test, Linux runtime settings, and Unraid template | GHCR and Unraid |
| anilist-mal-sync | Python sync service, OAuth setup, tests, Compose, and Unraid template | GHCR and Unraid; native Python development |
| ACELink | Python service, prebuilt web UI, device setup, mock smoke test, and Compose | Linux Docker Compose first; native development and desktop hardware testing |
| Tareku99/.github | Account-wide community defaults, reusable workflows, and actions | GitHub's native fallback and SHA-pinned Actions references |

Keep Docker image values, supported platforms, secrets, runtime permissions, licenses, and hardware requirements with the app that owns them.

## 1. Document the current release flow

- [ ] Describe production pushes, eligible version tags, and manual beta dispatch in the AMP and AniList READMEs.
- [ ] Update AMP's production Compose example to pull GHCR. Keep local image builds available through an explicit override.
- [ ] Update AniList's README to use Docker Compose v2, explain persistent data, and show how native Python runs the same CLI as the container.
- [ ] Split ACELink's documented paths into Compose deployment and direct Python development. Mark the Compose image as local-build-only until the first GHCR release exists.

## 2. Prepare ACELink for Docker

- [ ] Build the frontend with the npm lockfile in a separate image stage. Ship Python, runtime dependencies, and built frontend assets in the final image.
- [ ] Keep one runtime entry point and preserve mock mode. Use a writable data volume for the settings file; retain the native settings location.
- [ ] Map only the serial adapter in Compose, with the device group available to the non-root container user. Keep the web UI on port 8765 by default.
- [ ] Run the Python suite on PRs and use the shared Docker build workflow to smoke-test the UI and settings in mock mode.
- [ ] On Linux, test ACE Pro and ACE 2 Pro on real adapters. Confirm detection or explicit serial configuration, device status, and settings after container recreation. Use a separate config copy for the first migration from a native install.
- [ ] Verify arm64 on actual hardware or a suitable runner before advertising it. Begin with the tested architecture; add shared multi-platform publishing as a separate change.
- [ ] After hardware checks, enable ACELink GHCR publishing through the shared workflows in Tareku99/.github. Publish beta first, verify pull and upgrade, then enable production tags and switch Compose to a published image.
- [ ] Once the Docker path is proven, retire systemd and Scheduled Task installer automation if the native audience no longer needs it. Keep direct Python instructions for development and desktop hardware testing.

## 3. Centralize summaries

- [ ] Build one shared test report action. Accept an outcome and optional JUnit XML. Show counts when available, and report missing or invalid reports without obscuring the real test result.
- [ ] Add a shared final report job that reads test, build, and publish results. Include source commit, ref, release channel, status, and reported image tags and digest when applicable.
- [ ] Run the final report on test failure and skipped publishing. Keep the summary separate from required merge checks.
- [ ] Roll out reporting first, then consolidate repeated checkout, branch validation, source commit capture, and job dependencies where doing so preserves the release permission boundary.
- [ ] Verify the required check names and sources before updating any ruleset. Verify PR, production, and manual beta behavior after adoption.

## 4. Align contribution files and repository rules

- [ ] Draft one bug report, feature request, issue chooser config, and default PR template. Include ACELink hardware details where they help diagnose a report.
- [ ] Merge the shared defaults PR in [Tareku99/.github](https://github.com/Tareku99/.github) before the app PRs retire duplicates.
- [ ] Preserve useful AniList template fields. Migrate its issue forms and chooser together if switching to native inheritance.
- [ ] Compare funding links and shared support policies before deduplicating them. Keep app-specific support routing and ownership local.
- [ ] Document the ruleset baseline and audit it repo by repo. Verify that an open PR can rerun checks, failed checks block merge, and ordinary branch pushes do not publish.

## Release verification and rollback

- Merge and verify one app at a time. Compare the image's registry digest with the publish log and confirm that a beta run does not move the production tag.
- For an app documentation change that triggers a production build, wait for the publish result before treating the new image as released.
- Record the previous known-good image digest before rollout. Restore it if a new image fails, retaining the existing data volume. Restore the previous workflow pin through a follow-up PR when a shared workflow regresses.

## Retire the previous automation repository

- Land the reusable workflows in this repository, then merge each caller change after its checks pass.
- Verify the AMP and AniList production releases and the supported manual beta path from their default branches. Check ACELink's tests and mock container build.
- Audit live workflow references and any maintained release branches before deleting the old repository. Historical reruns that pin the old repository will require it to remain available. Record the last working image digests before retirement.
