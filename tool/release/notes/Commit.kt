/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.release.notes

import com.eclipsesource.json.Json
import com.eclipsesource.json.JsonValue
import com.typedb.dependencies.tool.release.notes.Constant.github
import com.typedb.dependencies.tool.common.Version
import java.nio.file.Path

fun collectCommits(org: String, repo: String, commit: String, version: Version, baseDir: Path, githubToken: String): List<String> {
    println("Determining the commits to be collected...")
    val preceding = getPrecedingVersion(org, repo, version, githubToken)
    if (preceding != null) {
        println("The script will collect commits down to the preceding version '$preceding'.")
        val response = httpGet("$github/repos/$org/$repo/compare/$preceding...$commit", githubToken)
        val body = Json.parse(response.parseAsString())
        return body.asObject().get("commits").asArray().map { cmt -> cmt.asObject().get("sha").asString() }
    }
    else {
        val gitRevList = bash("git rev-list --max-parents=0 HEAD", baseDir)
        val firstCommit = gitRevList.outputString().trim()
        println("No preceding version found. The script will collect all commits down to the first one: '$firstCommit'.")
        val response = httpGet("$github/repos/$org/$repo/compare/$firstCommit...$commit", githubToken)
        val body = Json.parse(response.parseAsString())
        val commits =
            body.asObject().get("commits").asArray().map { cmt -> cmt.asObject().get("sha").asString() }.toList()
        return listOf(firstCommit) + commits
    }
}

private fun getPrecedingVersion(org: String, repo: String, version: Version, githubToken: String): Version? {
    val response = httpGet("$github/repos/$org/$repo/releases", githubToken)
    val body = Json.parse(response.parseAsString())
    val tags = mutableListOf<Version>()
    tags.add(version)
    tags.addAll(body.asArray().map { release -> Version.parse(release.asObject().get("tag_name").asString()) })
    tags.sort()
    val currentIdx = tags.indexOf(version)
    val preceding = when {
        currentIdx < 0 -> throw IllegalStateException("Version '$version' not found: currentIdx = '$currentIdx'")
        currentIdx == 0 -> null
        version.isPrerelease() -> tags[currentIdx - 1]
        else -> {
            var previousRelease = currentIdx - 1
            while (previousRelease >= 0 && tags[previousRelease].isPrerelease()) previousRelease--

            if (previousRelease < 0) null
            else tags[previousRelease]
        }
    }
    return preceding
}

fun getLastVersion(org: String, repo: String, githubToken: String, tagPrefix: String?): Version? {
    val response = httpGet("$github/repos/$org/$repo/releases", githubToken)
    val body = Json.parse(response.parseAsString())
    val tags = mutableListOf<Version>()
    tags.addAll(body.asArray().mapNotNull { parseTagVersion(it, tagPrefix) })
    tags.sort()
    return tags.lastOrNull()
}

private fun parseTagVersion(release: JsonValue, tagPrefix: String?): Version? {
    val baseTag = release.asObject().get("tag_name").asString()
    if (tagPrefix.isNullOrBlank()) return Version.parse(baseTag)
    if (!baseTag.startsWith(tagPrefix)) return null
    return Version.parse(baseTag.removePrefix(baseTag))
}
