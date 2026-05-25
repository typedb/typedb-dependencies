/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */


package com.typedb.dependencies.library.maven

import java.lang.System.lineSeparator
import java.nio.file.Files
import java.nio.file.Files.write
import java.nio.file.Paths

fun main() {
    val baseDir = Paths.get(System.getenv("BUILD_WORKSPACE_DIRECTORY"))
    val snapshotCommand = listOf("bazel", "query", "kind(alias, @typedb_maven//...)")
    val snapshotFile = baseDir.resolve("dependencies").resolve("maven").resolve("artifacts.snapshot")

    println("-------------------------")
    println("Regenerating a new '$snapshotFile' from WORKSPACE...")
    val snapshotOld = if (snapshotFile.toFile().exists()) Files.readAllLines(snapshotFile).toSortedSet() else sortedSetOf()
    val snapshotUpdateProc = ProcessBuilder().directory(baseDir.toFile()).command(snapshotCommand).start()
    val snapshotNew = snapshotUpdateProc.inputStream
            .use { inStr -> inStr.reader().readLines() }
            .toSortedSet()
    write(snapshotFile, (snapshotNew.joinToString(lineSeparator()) + lineSeparator()).toByteArray())
    if (snapshotUpdateProc.exitValue() != 0) {
        throw RuntimeException("'$snapshotCommand' failed with exit code '${snapshotUpdateProc.exitValue()}'")
    }

    val added = snapshotNew.minus(snapshotOld)
    val removed = snapshotOld.minus(snapshotNew)
    println("DONE! '$snapshotFile' updated: ${added.count()} dependencies added, ${removed.count()} dependencies removed.")
    print("Added dependencies: ")
    if (added.isNotEmpty()) {
        println()
        added.forEach { dep -> println(" - $dep") }
    }
    else {
        println("none.")
    }
    print("Removed dependencies: ")
    if (removed.isNotEmpty()) {
        println()
        removed.forEach { dep -> println(" - $dep") }
    }
    else {
        println("none.")
    }
    println("-------------------------")
}
