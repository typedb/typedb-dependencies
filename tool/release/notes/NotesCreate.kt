/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.release.notes

import com.typedb.dependencies.tool.common.Version
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.Callable
import picocli.CommandLine
import kotlin.io.path.notExists
import kotlin.system.exitProcess
import kotlin.text.Regex.Companion.escapeReplacement

object NotesCreate: Callable<Int> {

    @CommandLine.Parameters(index = "0")
    lateinit var org: String

    @CommandLine.Parameters(index = "1")
    lateinit var repo: String

    @CommandLine.Parameters(index = "2")
    lateinit var commit: String

    @CommandLine.Parameters(index = "3")
    lateinit var version: String

    @CommandLine.Parameters(index = "4")
    lateinit var templateFileLocation: String

    @CommandLine.Parameters(index = "5")
    lateinit var outputFileLocation: String

    @CommandLine.Option(names = ["-p", "--tag-prefix"])
    var releaseTagPrefix: String? = null

    @CommandLine.Option(names = ["-e", "--exclude"])
    var excludedPaths: List<String> = emptyList()

    @CommandLine.Option(names = ["-i", "--include"])
    var includedPaths: List<String> = emptyList()

    @JvmStatic
    fun main(args: Array<String>): Unit = exitProcess(CommandLine(NotesCreate).execute(*args))

    override fun call(): Int {
        val bazelWorkspaceDir = Paths.get(getEnv("BUILD_WORKSPACE_DIRECTORY"))
        val githubToken = getEnv("NOTES_CREATE_TOKEN")

        val templateFile = bazelWorkspaceDir.resolve(templateFileLocation)
        if (templateFile.notExists()) throw RuntimeException("Template file '$templateFile' does not exist.")
        val outputFile = bazelWorkspaceDir.resolve(outputFileLocation)

        println("Commit: $org/$repo@$commit")
        println("Version: $version")

        val commits = collectCommits(org, repo, commit, Version.parse(version), bazelWorkspaceDir, githubToken, releaseTagPrefix, excludedPaths, includedPaths)
        println("Found ${commits.size} commits to be collected into the release note.")
        val notes = collectNotes(org, repo, commits.reversed(), githubToken)
        writeNotesMd(notes, templateFile, outputFile, version)
        return 0
    }

    private fun writeNotesMd(notes: List<Note>, releaseTemplateFile: Path, releaseNotesFile: Path, version: String) {
        val template = releaseTemplateFile.toFile().readText()
        if (!template.matches(".*${Constant.releaseTemplateRegex.pattern}.*".toRegex(RegexOption.DOT_MATCHES_ALL)))
            throw RuntimeException("The release-template does not contain the '${Constant.releaseTemplateRegex}' placeholder")
        val markdown = template.replace(Constant.releaseTemplateRegex, escapeReplacement(Note.toMarkdown(notes)))
            .replace("{version}", version)
        releaseNotesFile.toFile().writeText(markdown)
    }

}
