/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.github

import java.lang.System.getenv
import org.kohsuke.github.GitHub
import picocli.CommandLine
import java.util.concurrent.Callable
import kotlin.system.exitProcess

object OpenPR: Callable<Int> {
    private const val DEFAULT_USERNAME = "typedb-bot"

    @CommandLine.Option(names = ["--repo"], description = ["The repository to open the PR on"])
    private lateinit var repo: String

    @CommandLine.Option(names = ["--head-branch"], description = ["The merging branch"])
    private lateinit var headBranch: String

    @CommandLine.Option(names = ["--base-branch"], description = ["The branch being merged into"])
    private lateinit var baseBranch: String

    @CommandLine.Option(names = ["--title"], description = ["The title of the PR"])
    private lateinit var title: String

    @CommandLine.Option(names = ["--body"], description = ["The body of the PR"])
    private var body: String = ""

    @CommandLine.Option(names = ["--username"], description = ["The GitHub username of the user opening the PR"])
    private var username: String = DEFAULT_USERNAME

    private var token: String = getenv("OPEN_PR_GITHUB_TOKEN") ?: throw RuntimeException("OPEN_PR_GITHUB_TOKEN environment variable must be set")

    @JvmStatic
    fun main(args: Array<String>): Unit = exitProcess(CommandLine(OpenPR).execute(*args))

    override fun call(): Int {
        val gh = GitHub.connect(username, token)
        gh.getRepository(repo).createPullRequest(title, headBranch, baseBranch, body)
        return 0
    }
}
