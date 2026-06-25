/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.release.notes

import com.typedb.dependencies.tool.common.Version
import java.nio.file.Path
import java.nio.file.Paths
import kotlin.io.path.notExists
import kotlin.text.Regex.Companion.escapeReplacement

fun main(args: Array<String>) {
    val bazelWorkspaceDir = Paths.get(getEnv("BUILD_WORKSPACE_DIRECTORY"))
    val githubToken = getEnv("NOTES_CREATE_TOKEN")
    if (args.size < 6) throw RuntimeException("org, repo, commit, version, template, and output destination must be supplied")

    operator fun <T> Array<T>.component6() = this[5]
    val (org, repo, commit, version, templateFileLocation, outputFileLocation) = args
    var releaseTagPrefix: String? = null
    val excludedPaths = mutableListOf<String>()
    val includedPaths = mutableListOf<String>()
    var nextAction: String? = null
    args.drop(6).forEachIndexed { index, arg ->
        if (nextAction == null) {
            if (arg == "--include" || arg == "--exclude" || arg == "--tag-prefix") nextAction = arg
            else throw RuntimeException("Invalid arg: $arg")
        } else if (nextAction == "--include") {
            includedPaths.add(arg)
            nextAction = null
        } else if (nextAction == "--exclude") {
            excludedPaths.add(arg)
            nextAction = null
        } else {
            if (releaseTagPrefix != null) throw RuntimeException("Cannot set --tag-prefix multiple times")
            releaseTagPrefix = arg
            nextAction = null
        }
    }

    if (nextAction != null) throw RuntimeException("Missing input value for $nextAction")

    val templateFile = bazelWorkspaceDir.resolve(templateFileLocation)
    if (templateFile.notExists()) throw RuntimeException("Template file '$templateFile' does not exist.")
    val outputFile = bazelWorkspaceDir.resolve(outputFileLocation)

    println("Commit: $org/$repo@$commit")
    println("Version: $version")

    val commits = collectCommits(org, repo, commit, Version.parse(version), bazelWorkspaceDir, githubToken, releaseTagPrefix, excludedPaths, includedPaths)
    println("Found ${commits.size} commits to be collected into the release note.")
    val notes = collectNotes(org, repo, commits.reversed(), githubToken)
    writeNotesMd(notes, templateFile, outputFile, version)
}


private fun writeNotesMd(notes: List<Note>, releaseTemplateFile: Path, releaseNotesFile: Path, version: String) {
    val template = releaseTemplateFile.toFile().readText()
    if (!template.matches(".*${Constant.releaseTemplateRegex.pattern}.*".toRegex(RegexOption.DOT_MATCHES_ALL)))
        throw RuntimeException("The release-template does not contain the '${Constant.releaseTemplateRegex}' placeholder")
    val markdown = template.replace(Constant.releaseTemplateRegex, escapeReplacement(Note.toMarkdown(notes)))
            .replace("{version}", version)
    releaseNotesFile.toFile().writeText(markdown)
}
