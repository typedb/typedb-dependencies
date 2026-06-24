/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.release.notes

import java.nio.file.Paths
import kotlin.io.path.notExists

fun main(args: Array<String>) {
    val bazelWorkspaceDir = Paths.get(getEnv("BUILD_WORKSPACE_DIRECTORY"))
    val githubToken = getEnv("NOTES_VALIDATE_TOKEN")
    if (args.size < 3 || args.size > 4) throw RuntimeException("Args: <org> <repo> <release notes file> [release tag prefix]")

    val org = args[0]
    val repo = args[1]
    val releaseNotesFile = args[2]
    val releaseNotesPath = bazelWorkspaceDir.resolve(releaseNotesFile)
    if (releaseNotesPath.notExists()) throw RuntimeException("Release notes file '$releaseNotesPath' does not exist.")
    val releasePrefix = if (args.size > 3) args.get(3) else null

    val lastTag = getLastVersion(org, repo, githubToken)

    val result = bash("git diff --exit-code --quiet $lastTag HEAD -- $releaseNotesFile", bazelWorkspaceDir, false)
    if (result.getExitValue() == 0) {
        println("Error: the release notes file '$releaseNotesFile' has not changed since the last release (tag '$lastTag').")
    }
}
