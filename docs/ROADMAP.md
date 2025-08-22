# semv Roadmap

This document outlines potential future features and improvements for the `semv` semantic versioning helper tool. These are ideas for discussion and prioritization.

## Potential Future Features

*   ### Full SemVer 2.0.0 Support
    *   **Description:** Extend the `semv bump` command to support pre-release identifiers (e.g., `1.2.3-alpha.1`, `1.2.3-rc.2`) and build metadata (e.g., `1.2.3+build.456`).
    *   **Commands:** `semv bump prerelease`, `semv bump preminor`, etc.

*   ### Automated Changelog Generation
    *   **Description:** Introduce a `semv changelog` command that automatically generates or updates a `CHANGELOG.md` file based on the commit messages since the last version tag.

*   ### Project-level Configuration File
    *   **Description:** Add support for a `.semvrc` configuration file to allow users to customize default behaviors.
    *   **Configurable options:**
        *   Default commit message format for version bumps.
        *   Version tag prefix (e.g., `v1.2.3` vs. `1.2.3`).
        *   Default branch.

*   ### Expanded Language Support
    *   **Description:** Add detection and version syncing support for more programming languages and package managers.
    *   **Examples:**
        *   Python (`pyproject.toml`)
        *   Go (`go.mod`)
        *   Java (`pom.xml` or `build.gradle`)
