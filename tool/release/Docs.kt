/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.release

import com.typedb.bazel.distribution.common.Logging.Logger
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import com.typedb.bazel.distribution.common.shell.Shell.Command
import com.typedb.bazel.distribution.common.shell.Shell.Command.Companion.arg
import java.io.File
import java.lang.System.getenv
import kotlin.io.path.Path
import kotlin.system.exitProcess

class GitDeploymentException(message: String) : Exception(message)

val logger = Logger(logLevel = LogLevel.DEBUG)

fun main(args: Array<String>) {
    val shell = Shell(logger = logger, verbose = true)
    try {
        // Check required environment variables
        val gitUsername = getenv("RELEASE_DOCS_USERNAME")
            ?: throw GitDeploymentException("Environment variable \$RELEASE_DOCS_USERNAME is not set!")

        val gitEmail = getenv("RELEASE_DOCS_EMAIL")
            ?: throw GitDeploymentException("Environment variable \$RELEASE_DOCS_EMAIL is not set!")

        val releaseDocsToken = getenv("RELEASE_DOCS_TOKEN")
            ?: throw GitDeploymentException("Environment variable \$RELEASE_DOCS_TOKEN is not set!")

        val gitToken = "$gitUsername:$releaseDocsToken"

        // Parse command line arguments
        if (args.size < 6) {
            throw GitDeploymentException("Usage: <git_org> <git_repo> <git_branch> <git_submod_repo> <git_submod_dir> <git_submod_commit>")
        }

        val gitOrg = args[0]
        val gitRepo = args[1]
        val gitBranch = args[2]
        val gitSubmodRepo = args[3]
        val gitSubmodDir = args[4]
        val gitSubmodCommit = args[5]

        val gitRemote = "github.com/$gitOrg/$gitRepo.git"
        val gitCloneDir = File(gitRepo)
        val gitCloneSubmodDir = File(gitCloneDir, gitSubmodDir)

        logger.debug { "Starting the process of deploying $gitSubmodRepo to $gitRepo:$gitBranch" }

        // Remove existing clone directory
        logger.debug { "Cloning $gitRemote to $gitCloneDir" }
        if (gitCloneDir.exists()) {
            gitCloneDir.deleteRecursively()
        }

        val gitClonePath = gitCloneDir.toPath()
        val gitCloneSubmodPath = gitCloneSubmodDir.toPath()

        // Clone repository with submodules
        shell.execute(
            command = Command(arg("git"), arg("clone"), arg("--recursive"), arg("https://$gitToken@$gitRemote", printable = false), arg(gitCloneDir.name)),
            baseDir = Path(".")
        )

        // Configure git user
        shell.execute(listOf("git", "config", "user.email", gitEmail), baseDir = gitClonePath)
        shell.execute(listOf("git", "config", "user.name", gitUsername), baseDir = gitClonePath)
        shell.execute(listOf("git", "checkout", gitBranch), baseDir = gitClonePath)

        // Update submodule
        logger.debug { "Updating submodule $gitSubmodRepo HEAD to $gitCloneSubmodDir" }
        shell.execute(listOf("git", "checkout", gitSubmodCommit), baseDir = gitCloneSubmodPath)
        shell.execute(listOf("git", "add", gitSubmodDir), baseDir = gitClonePath)

        // Check if there are staged changes
        val shouldCommit = shell.execute(listOf("git", "diff", "--staged", "--exit-code"), baseDir = gitClonePath, throwOnError = false).exitValue == 1

        if (shouldCommit) {
            val shortCommit = getShortCommit(gitSubmodCommit)
            val gitCommitMsg = "//ci:release-docs: $gitOrg/$gitSubmodRepo@$shortCommit"
            logger.debug { "Committing $gitRepo:$gitBranch with message $gitCommitMsg" }
            shell.execute(listOf("git", "commit", "-m", gitCommitMsg), baseDir = gitClonePath)
            logger.debug { "Pushing changes to $gitRemote" }
            // TODO: uncomment
            // shell.execute(Command(arg("git"), arg("push"), arg("https://$gitToken@$gitRemote", printable = false), arg(gitBranch)), baseDir = gitClonePath)
            logger.debug { "Done!" }
        } else {
            logger.debug { "$gitOrg/$gitRepo:$gitBranch is up-to-date. Nothing to commit." }
        }
    } catch (e: Exception) {
        println("Error: ${e.message}")
        exitProcess(1)
    }
}

fun getShortCommit(commitSha: String): String {
    return try {
        val buildWorkspaceDir = getenv("BUILD_WORKSPACE_DIRECTORY")?.let { File(it) } ?: File(".")
        val processBuilder = ProcessBuilder("git", "rev-parse", "--short=7", commitSha)
        processBuilder.directory(buildWorkspaceDir)

        val process = processBuilder.start()
        val exitCode = process.waitFor()

        if (exitCode == 0) {
            process.inputStream.bufferedReader().readText().trim()
        } else {
            commitSha.take(7) // Fallback to first 7 characters
        }
    } catch (_: Exception) {
        commitSha.take(7) // Fallback to first 7 characters
    }
}
