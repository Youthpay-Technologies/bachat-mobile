# Private Android tester release

Version: **0.1.2 (build 3)**. Release tag: `v0.1.2`.

The repository must remain private. The GitHub release and its APK asset are available to signed-in collaborators who already have repository access. Share the release page with the tester; no repository visibility change is required.

The tester downloads `bachat-0.1.2-android.apk` from the release assets and opens it on Android. Android may request permission for the browser or file manager to install the APK. Use a verified teen account; parent registration and Learn are unavailable in this release. The release includes a SHA-256 checksum file for verifying the downloaded asset.

This is a release-mode internal tester build using the project's existing development signing configuration. Keeping the existing signing key allows in-place updates of matching development installations. Signing keys, credentials and APK output are not committed to Git.

The release artifact is built from the merged `main` commit after the receipt savings and frosted navigation PR passes the required checks. The release tag must resolve to that same commit. The release notes record the source commit, version, validation and signing configuration.

The navigation pill has a 12-pixel gap above the bottom safe area. Home, Activity and Plan still extend behind the compact pill, with enough scroll-end padding to expose final controls.

Build command after merging:

```powershell
. ./scripts/env.ps1
flutter build apk --release
```

Upload the resulting APK and `SHA256SUMS.txt` as assets on a private GitHub prerelease. Verify the APK signature and package/version metadata before publishing, and confirm the repository is still private afterward. iOS is not included in this Android release.
