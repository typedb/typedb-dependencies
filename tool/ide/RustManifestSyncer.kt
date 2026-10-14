/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package com.typedb.dependencies.tool.ide

import com.eclipsesource.json.Json
import com.eclipsesource.json.JsonObject
import com.electronwill.nightconfig.core.Config
import com.electronwill.nightconfig.core.InMemoryFormat
import com.electronwill.nightconfig.toml.TomlWriter
import com.typedb.bazel.distribution.common.Logging.LogLevel.DEBUG
import com.typedb.bazel.distribution.common.Logging.LogLevel.ERROR
import com.typedb.bazel.distribution.common.Logging.Logger
import com.typedb.bazel.distribution.common.shell.Shell
import com.typedb.bazel.distribution.common.util.FileUtil.listFilesRecursively
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.ASPECTS
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.BAZEL
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.BAZEL_BIN
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.BUILD
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.CQUERY
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.INFO
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.OUTPUT_BASE
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.OUTPUT_FILES
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.OUTPUT_GROUPS
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.QUERY
import com.typedb.dependencies.tool.ide.RustManifestSyncer.ShellArgs.RUST_TARGETS_QUERY
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.Paths.CARGO_TOML
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.Paths.GITHUB_TYPEDB
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.Paths.MANIFEST_PROPERTIES_SUFFIX
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.CRATE_TYPE
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.DEPS_PREFIX
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.EDITION
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.ENABLED_FEATURES
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.ENTRY_POINT_PATH
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.FEATURES
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.NAME
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.PATH
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.REPO_PATH
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.TARGET_NAME
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.TYPE
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.VERSION
import com.typedb.dependencies.tool.ide.RustManifestSyncer.WorkspaceSyncer.TargetProperties.Keys.WORKSPACE_NAME

import picocli.CommandLine
import java.io.File
import java.io.FileInputStream
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import java.util.Properties
import java.util.concurrent.Callable
import kotlin.io.path.Path
import kotlin.system.exitProcess

fun main(args: Array<String>): Unit = exitProcess(CommandLine(RustManifestSyncer()).execute(*args))

@CommandLine.Command(name = "sync", mixinStandardHelpOptions = true)
class RustManifestSyncer : Callable<Unit> {

    @CommandLine.Option(names = ["--verbose", "-v"], required = false)
    private var verbose: Boolean = false

    @CommandLine.Parameters(index = "0")
    private var workspaceRefsLabel: String = ""

    private lateinit var logger: Logger
    private lateinit var shell: Shell
    private val workspaceDir = Path(System.getenv("BUILD_WORKSPACE_DIRECTORY"))

    override fun call() {
        logger = Logger(logLevel = if (verbose) DEBUG else ERROR)
        shell = Shell(logger, verbose)

        val workspaceRefs = loadWorkspaceRefs();
        val rustTargets = rustTargets(shell, workspaceDir)
        validateTargets(rustTargets)
        loadRustToolchainAndExternalDeps(rustTargets)
        WorkspaceSyncer(workspaceDir, workspaceRefs, logger, shell).sync()
    }

    private fun validateTargets(targets: List<String>) {
        shell.execute(command = listOf(BAZEL, BUILD) + targets + "--build=false", baseDir = workspaceDir)
    }

    private fun loadRustToolchainAndExternalDeps(rustTargets: List<String>) {
        shell.execute(
            command = listOf(BAZEL, BUILD) + rustTargets + "--keep_going",
            baseDir = workspaceDir,
            throwOnError = false
        )
    }

    private fun loadWorkspaceRefs(): JsonObject {
        shell.execute(command = listOf(BAZEL, BUILD, workspaceRefsLabel), baseDir = workspaceDir);
        val workspaceRefsFile =
            shell.execute(command = listOf(BAZEL, CQUERY, OUTPUT_FILES, workspaceRefsLabel), baseDir = workspaceDir)
                .outputString().trim();

        val bazelOutputBase = shell.execute(listOf(BAZEL, INFO, OUTPUT_BASE), workspaceDir).outputString().trim();
        return Json.parse(File(bazelOutputBase, workspaceRefsFile).readText()).asObject();
    }

    companion object {
        private fun orderedConfig(): Config = Config.of({ LinkedHashMap() }, InMemoryFormat.defaultInstance())

        private fun rustTargets(shell: Shell, workspace: Path): List<String> {
            return shell.execute(listOf(BAZEL, QUERY, RUST_TARGETS_QUERY), workspace)
                .outputString().split(System.lineSeparator()).filter { it.isNotBlank() }
        }
    }

    private class WorkspaceSyncer(
        private val workspace: Path,
        private val workspaceRefs: JsonObject,
        private var logger: Logger,
        private var shell: Shell,
    ) {

        fun sync() {
            logger.debug { "Syncing $workspace" }
            cleanupOldSyncProperties()
            runCargoProjectAspect()
            val bazelBin = workspace.resolve(BAZEL_BIN).toRealPath().toFile()
            generateManifests(bazelBin);
            logger.debug { "Sync completed in $workspace" }
        }

        private fun cleanupOldSyncProperties() {
            logger.debug { "Cleaning up old cargo sync properties under $workspace" }
            val bazelBin = File(shell.execute(listOf(BAZEL, INFO, BAZEL_BIN), workspace).outputString().trim())
            bazelBin.listFilesRecursively().filter { it.name.endsWith(MANIFEST_PROPERTIES_SUFFIX) }
                .forEach { it.delete() }
        }

        private fun runCargoProjectAspect() {
            val rustTargets = rustTargets(shell, workspace)
            shell.execute(listOf(BAZEL, BUILD) + rustTargets + listOf(ASPECTS, OUTPUT_GROUPS), workspace)
        }

        fun generateManifests(bazelBin: File) {
            val rootTomlPath = workspace.resolve(CARGO_TOML);
            Files.deleteIfExists(rootTomlPath);

            val targets = loadSyncProperties(bazelBin);
            val manifests = targets.filter { shouldGenerateManifest(it) }
                .map { ManifestGenerator(it).generateManifest(bazelBin) }
                .toMutableList()

            // append Cargo Workspace to root Cargo Manifest, or create it if it does not exist
            val workspaceManifest = manifests.stream().filter { it.toPath().parent.equals(workspace) }
                .findFirst()
            val cargoWorkspaceConfig = createCargoWorkspace(manifests, targets);
            val cargoWorkspaceString = (if (workspaceManifest.isPresent) "\n" else GENERATED_FILE_NOTICE) + writeSortedToml(cargoWorkspaceConfig)

            Files.newOutputStream(rootTomlPath, StandardOpenOption.APPEND, StandardOpenOption.CREATE).use {
                it.write(cargoWorkspaceString.toByteArray(StandardCharsets.UTF_8))
            }

            if (!workspaceManifest.isPresent) {
                manifests.add(rootTomlPath.toFile())
            }
            println(manifests.joinToString(System.lineSeparator()))
        }

        private fun createCargoWorkspace(manifests: List<File>, targets: List<TargetProperties>): Config {
            val manifestPaths = manifests.map { workspace.relativize(it.toPath().parent).toString() }
                .filter { it.isNotBlank() }
                .distinct()
                .toList()

            val cargoToml = orderedConfig()
            val subConfig = cargoToml.createSubConfig()
            subConfig.set<List<String>>("members", manifestPaths)
            subConfig.set<String>("resolver", "2")

            subConfig.createSubConfig().apply {
                subConfig.set<Config>("dependencies", this)
                mergedWorkspaceDependencies(targets).forEach { set<Config>(it.name, it.toToml()) }
            }

            cargoToml.set<Config>("workspace", subConfig)
            return cargoToml
        }

        // the same dependency may be requested with different feature sets by different targets,
        // the workspace-level entry is their union
        private fun mergedWorkspaceDependencies(targets: List<TargetProperties>): List<TargetProperties.Dependency> {
            return targets
                .flatMap { crate ->
                    (listOf(crate) + crate.tests + crate.benches).flatMap { it.deps }
                        .filter { it.name != crate.name }
                        .map { crate.name to it }
                }
                .distinct()
                .groupBy { (_, dep) -> dep.name }
                .map { (name, requests) ->
                    requests.map { it.second }.distinct().reduce { merged, next ->
                        merged.mergeWith(next) ?: throw IllegalStateException(
                            "Crates request dependency '$name' at conflicting versions or sources: " +
                                requests.groupBy({ it.second }, { it.first }).entries.joinToString("; ") { (dep, crates) -> "$dep by ${crates.joinToString()}" }
                        )
                    }
                }
        }

        private fun writeSortedToml(config: Config): String {
            val copy = orderedConfig()
            config.valueMap().forEach { (key, value) -> copy.valueMap()[key] = valueDeepSorted(key, value) }
            return TomlWriter().writeToString(copy.unmodifiable()).trim() + "\n"
        }

        private fun valueDeepSorted(key: String, value: Any?): Any? = when (value) {
            is Config -> configDeepSorted(value)
            is List<*> -> value.map { valueDeepSorted(key, it) }
                .let { list -> if (key in UNORDERED_LISTS) list.sortedBy { elementSortKey(it) } else list }
            else -> value
        }

        private fun configDeepSorted(config: Config): Config {
            val copy = orderedConfig()
            config.valueMap().entries.sortedBy { it.key }
                .forEach { copy.valueMap()[it.key] = valueDeepSorted(it.key, it.value) }
            return copy
        }

        private fun elementSortKey(value: Any?): String = when (value) {
            is Config -> value.get<String?>("name") ?: ""
            else -> value.toString()
        }

        private fun loadSyncProperties(bazelBin: File): List<TargetProperties> {
            return findSyncPropertiesFiles(bazelBin)
                .map { TargetProperties.fromPropertiesFile(it, workspaceRefs) }
                .groupBy { Triple(it.name, it.cratePath, it.type) }.values
                .map { TargetProperties.mergeList(it) }
                .run { attachTestsAndBenches(this) }
        }

        private fun findSyncPropertiesFiles(bazelBin: File): List<File> {
            val bazelBinContents = bazelBin.listFiles() ?: throw IllegalStateException()
            val filesToCheck = bazelBinContents.filter { it.isFile } + bazelBinContents
                .filter { it.isDirectory && it.name != Paths.EXTERNAL }.flatMap { it.listFilesRecursively() }
            return filesToCheck.filter { it.name.endsWith(MANIFEST_PROPERTIES_SUFFIX) }.sortedBy { it.path }
        }

        private fun attachTestsAndBenches(properties: Collection<TargetProperties>): List<TargetProperties> {
            val TESTS_DIR = "tests"
            val BENCHES_DIR = "benches" // we translate Bazel Tests in 'benches' into Cargo benchmarks
            val (testProperties, nonTestProperties) = properties.partition { it.type == TargetProperties.Type.TEST }
            testProperties.forEach { tp ->
                // attach tests deps to the parent properties
                var path = tp.path.toPath()
                while (
                    path.parent != null && path.fileName != null &&
                    (!path.fileName.toString().equals(TESTS_DIR) && !path.fileName.toString().equals(BENCHES_DIR))
                ) {
                    path = path.parent
                }
                val isTest: Boolean
                if (path.fileName == null) {
                    logger.debug { "Could not find directory named '$TESTS_DIR' for test '${tp.name}', assuming unit test..." }
                    path = tp.path.toPath()
                    isTest = true
                } else if (path.fileName.toString().equals(TESTS_DIR)) {
                    isTest = true
                } else if (path.fileName.toString().equals(BENCHES_DIR)) {
                    isTest = false
                } else {
                    throw RuntimeException("Could not find directory named '$TESTS_DIR' or '$BENCHES_DIR' for Bazel test target '${tp.name}'.");
                }
                var parent = nonTestProperties.filter { it.path.parentFile.toPath().equals(path.parent) };
                if (parent.size > 1) {
                    logger.debug { "Found ${parent.size} parents to attach test '${tp.name}' to, discarding binaries..." }
                    parent = parent.filter { it.type != TargetProperties.Type.BIN };
                }
                if (parent.size != 1) {
                    throw RuntimeException("Found ${parent.size} parents to attach test '${tp.name}' to: ${parent.map { it.name }}.")
                }

                if (isTest) {
                    parent[0].tests += tp
                } else {
                    parent[0].benches += tp
                }
            }

            val packages =
                properties.filter { it.type == TargetProperties.Type.LIB || it.type == TargetProperties.Type.BIN }
                    .groupBy { it.cratePath }.values
                    .map { TargetProperties.mergePackage(it) }

            return packages;
        }

        private fun shouldGenerateManifest(properties: TargetProperties): Boolean {
            return properties.type in listOf(TargetProperties.Type.LIB, TargetProperties.Type.BIN)
        }

        private inner class ManifestGenerator(private val properties: TargetProperties) {
            fun generateManifest(bazelBin: File): File {
                val outputPath = manifestOutputPath(bazelBin)
                Files.newOutputStream(outputPath).use {
                    it.write(manifestContent().toByteArray(StandardCharsets.UTF_8))
                }
                return outputPath.toFile()
            }

            private fun manifestOutputPath(bazelBin: File): Path {
                return workspace.resolve(bazelBin.toPath().relativize(Path(properties.path.parent)).resolve(CARGO_TOML))
            }

            private fun manifestContent(): String {
                val cargoToml = orderedConfig()

                cargoToml.createSubConfig().apply {
                    cargoToml.set<Config>("package", this)
                    set<String>("name", properties.name)
                    set<String>("edition", properties.edition)
                    set<String>("version", properties.version)
                }

                val features = (properties.enabledFeatures + properties.features).distinct()
                if (features.isNotEmpty()) {
                    cargoToml.createSubConfig().apply {
                        cargoToml.set<Config>("features", this)
                        features.forEach { set<Config>(it, emptyList<String>()) }
                    }
                }

                cargoToml.createEntryPointSubConfig()

                if (properties.deps.isNotEmpty()) {
                    cargoToml.createSubConfig().apply {
                        cargoToml.set<Config>("dependencies", this)
                        properties.deps.forEach { set<Config>(it.name, workspaceInherited()) }
                    }
                }

                cargoToml.addDevDependencies()
                cargoToml.addBins()
                cargoToml.addBenches()
                cargoToml.addTests()

                return GENERATED_FILE_NOTICE + writeSortedToml(cargoToml)
            }

            private fun workspaceInherited(): Config {
                return orderedConfig().apply { set<Boolean>("workspace", true) }
            }

            private fun Config.createEntryPointSubConfig() {
                val entryPointPath = properties.entryPointPath.toString()

                when (properties.type) {
                    TargetProperties.Type.LIB -> {
                        createSubConfig().apply {
                            this@createEntryPointSubConfig.set<Config>("lib", this)
                            set<String>("path", entryPointPath)
                            set<List<String>>("crate-type", properties.crateTypes)
                        }
                    }

                    TargetProperties.Type.BIN -> {
                        createSubConfig().apply {
                            this@createEntryPointSubConfig.set<List<Config>>("bin", listOf(this))
                            set<String>("name", properties.name)
                            set<String>("path", entryPointPath)
                        }
                    }

                    TargetProperties.Type.TEST -> throw IllegalStateException(
                        "$CARGO_TOML should not be generated for sync properties of type ${properties.type}"
                    )
                }
            }

            private fun Config.addDevDependencies() {
                val devDependencyNames = (properties.tests + properties.benches)
                    .flatMap { it.deps }
                    .map { it.name }
                    .distinct()
                    .filter { name -> name != properties.name && properties.deps.none { it.name == name } }
                if (devDependencyNames.isNotEmpty()) {
                    createSubConfig().apply {
                        this@addDevDependencies.set<Config>("dev-dependencies", this)
                        devDependencyNames.forEach { set<Config>(it, workspaceInherited()) }
                    }
                }
            }

            private fun Config.addBins() {
                if (properties.bins.isNotEmpty()) {
                    val mapped = properties.bins.map {
                        if (it.entryPointPath != null) {
                            val path =
                                Path(properties.cratePath).relativize(Path(it.cratePath)).resolve(it.entryPointPath)
                            createSubConfig().apply {
                                this.set<String>("name", it.name);
                                this.set<String>("path", path.toString());
                            }
                        } else {
                            null
                        }
                    }.filterNotNull()
                    this.set<List<Config>>("bin", mapped)
                }
            }

            private fun Config.addBenches() {
                if (properties.benches.isNotEmpty()) {
                    val mapped = properties.benches.map {
                        createSubConfig().apply {
                            this.set<String>("name", it.name);
                            this.set<String>("harness", false);
                        }
                    }
                    this.set<List<Config>>("bench", mapped)
                }
            }

            private fun Config.addTests() {
                val mapped = properties.tests.map {
                    if (it.entryPointPath != null) {
                        val path = Path(properties.cratePath).relativize(Path(it.cratePath)).resolve(it.entryPointPath)
                        createSubConfig().apply {
                            this.set<String>("name", it.name)
                            this.set<String>("path", path.toString());
                        }
                    } else {
                        null
                    }
                }.filterNotNull()
                if (mapped.isNotEmpty()) {
                    this.set<List<Config>>("test", mapped)
                }
            }
        }

        data class TargetProperties(
            val path: File,
            val name: String,
            val targetName: String,
            val cratePath: String,
            val type: Type,
            val crateTypes: Collection<String>,
            val enabledFeatures: Collection<String>,
            val features: Collection<String>,
            val version: String,
            val edition: String?,
            val entryPointPath: Path?,
            val deps: Collection<Dependency>,
            val bins: MutableCollection<TargetProperties>,
            val tests: MutableCollection<TargetProperties>,
            val benches: MutableCollection<TargetProperties>,
        ) {
            sealed class Dependency(open val name: String) {
                abstract fun toToml(): Config

                abstract fun mergeWith(other: Dependency): Dependency?

                data class Crate(override val name: String, val version: String, val features: List<String>) :
                    Dependency(name) {
                    override fun mergeWith(other: Dependency): Dependency? {
                        if (other !is Crate || other.version != version) return null
                        return copy(features = (features + other.features).distinct())
                    }

                    override fun toToml(): Config {
                        return orderedConfig().apply {
                            set<String>("version", version)
                            set<List<String>>("features", features)
                            set<Boolean>("default-features", false)
                        }
                    }
                }

                data class Local(
                    override val name: String,
                    val local_path: String,
                    val features: List<String>,
                ) : Dependency(name) {
                    override fun mergeWith(other: Dependency): Dependency? {
                        if (other !is Local || other.local_path != local_path) return null
                        return copy(features = (features + other.features).distinct())
                    }

                    override fun toToml(): Config {
                        return orderedConfig().apply {
                            set<String>("path", local_path)
                            set<List<String>>("features", features)
                            set<Boolean>("default-features", false)
                        }
                    }
                }

                data class Git(
                    override val name: String,
                    val repoName: String,
                    val commit: String?,
                    val tag: String?,
                    val features: List<String>,
                ) : Dependency(name) {
                    override fun mergeWith(other: Dependency): Dependency? {
                        if (other !is Git || other.repoName != repoName || other.commit != commit || other.tag != tag) {
                            return null
                        }
                        return copy(features = (features + other.features).distinct())
                    }

                    override fun toToml(): Config {
                        return orderedConfig().apply {
                            set<String>("git", GITHUB_TYPEDB + repoName);
                            if (commit != null) {
                                set<String>("rev", commit);
                            } else if (tag != null) {
                                set<String>("tag", tag);
                            } else {
                                throw IllegalStateException();
                            }
                            set<List<String>>("features", features)
                            set<Boolean>("default-features", false)
                        }
                    }
                }

                companion object {
                    fun of(name: String, rawValue: String, workspaceRefs: JsonObject): Dependency {
                        val rawValueProps = rawValue.split(";")
                            .associate { it.split("=", limit = 2).let { parts -> parts[0] to parts[1] } }
                        val features =
                            rawValueProps[ENABLED_FEATURES]?.split(",")?.filter { it != "bazel" } ?: emptyList();
                        return if (VERSION in rawValueProps) {
                            Crate(
                                name = name,
                                version = rawValueProps[VERSION]!!,
                                features = features,
                            )
                        } else if (WORKSPACE_NAME in rawValueProps) {
                            // WARN: we rely on this naming scheme:
                            //       any internal git dependency is named "@{workspaceName}" where all hyphens in the name are replaced by underscores
                            val workspaceName = rawValueProps[WORKSPACE_NAME]!!;
                            val repoName = workspaceName.removeSuffix("+").replace("_", "-");
                            Git(
                                name = name,
                                repoName = repoName,
                                commit = workspaceRefs["commits"].asObject()[workspaceName]?.asString(),
                                tag = workspaceRefs["tags"].asObject()[workspaceName]?.asString(),
                                features = features,
                            )
                        } else {
                            Local(
                                name = name,
                                local_path = rawValueProps[REPO_PATH] ?: rawValueProps[PATH]!!,
                                features = features,
                            )
                        }
                    }
                }
            }

            enum class Type {
                LIB,
                BIN,
                TEST;

                companion object {
                    fun of(value: String): Type {
                        return when (value) {
                            "lib" -> LIB
                            "bin" -> BIN
                            "test" -> TEST
                            else -> throw IllegalArgumentException()
                        }
                    }
                }
            }

            companion object {
                fun fromPropertiesFile(path: File, workspaceRefs: JsonObject): TargetProperties {
                    val props = Properties().apply { load(FileInputStream(path.toString())) }
                    try {
                        return TargetProperties(
                            path = path,
                            name = props.getProperty(NAME),
                            targetName = props.getProperty(TARGET_NAME),
                            type = Type.of(props.getProperty(TYPE)),
                            crateTypes = listOf(props.getProperty(CRATE_TYPE)),
                            enabledFeatures = props.getProperty(ENABLED_FEATURES).split(",").filter { it.isNotBlank() },
                            features = props.getProperty(FEATURES).split(",").filter { it.isNotBlank() },
                            version = props.getProperty(VERSION),
                            edition = props.getProperty(EDITION, "2024"),
                            deps = parseDependencies(extractDependencyEntries(props), workspaceRefs),
                            entryPointPath = props.getProperty(ENTRY_POINT_PATH)?.let { Path(it) },
                            cratePath = props.getProperty(PATH),
                            bins = mutableListOf(),
                            tests = mutableListOf(),
                            benches = mutableListOf(),
                        )
                    } catch (e: Exception) {
                        throw IllegalStateException("Failed to parse Manifest Sync properties file at $path", e)
                    }
                }

                fun mergeList(all_properties: List<TargetProperties>): TargetProperties {
                    var base = all_properties.get(0);
                    all_properties.subList(1, all_properties.size).forEach { properties ->
                        base = base.copy(
                            crateTypes = (base.crateTypes + properties.crateTypes).distinct(),
                            enabledFeatures = (base.enabledFeatures + properties.enabledFeatures).distinct(),
                            features = (base.features + properties.features).distinct(),
                            deps = (base.deps + properties.deps).distinct(),
                        )
                    };
                    return base;
                }

                fun mergePackage(package_properties: List<TargetProperties>): TargetProperties {
                    if (package_properties.size == 1) {
                        return package_properties.get(0);
                    }
                    val (libs, bins) = package_properties.partition { it.type == TargetProperties.Type.LIB }
                    if (libs.size > 1) {
                        throw IllegalStateException("Found too many distinct libs post-merge at ${libs[0].cratePath}: ${libs.map { it.name }}")
                    }
                    val lib = libs.firstOrNull()
                    val base = lib ?: bins[0].copy(name = bins[0].cratePath.replace('/', '-'))
                    return base.copy(
                        deps = package_properties.flatMap { it.deps }.filter { it.name != lib?.name }.distinct(),
                        bins = bins.toMutableList(),
                    )
                }

                private fun extractDependencyEntries(props: Properties): Map<String, String> {
                    return props.entries
                        .map { it.key.toString() to it.value.toString() }
                        .filter { it.first.startsWith("$DEPS_PREFIX.") }
                        .associate { it.first.removePrefix("$DEPS_PREFIX.") to it.second }
                }

                private fun parseDependencies(
                    raw: Map<String, String>,
                    workspaceRefs: JsonObject
                ): Collection<Dependency> {
                    return raw.map { Dependency.of(it.key, it.value, workspaceRefs) }
                }
            }

            private object Keys {
                const val CRATE_TYPE = "crate_type"
                const val DEPS_PREFIX = "deps"
                const val EDITION = "edition"
                const val ENTRY_POINT_PATH = "entry.point.path"
                const val ENABLED_FEATURES = "enabled.features"
                const val FEATURES = "features"
                const val TARGET_NAME = "target.name"
                const val NAME = "name"
                const val PATH = "path"
                const val REPO_PATH = "repopath"
                const val TYPE = "type"
                const val VERSION = "version"
                const val WORKSPACE_NAME = "workspace_name"
            }
        }

        private object Paths {
            const val CARGO_TOML = "Cargo.toml"
            const val EXTERNAL = "external"
            const val MANIFEST_PROPERTIES_SUFFIX = ".cargo.properties"
            const val GITHUB_TYPEDB = "https://github.com/typedb/"
        }

        companion object {
            // lists whose order cargo ignores; any other list is written in the order it was built
            val UNORDERED_LISTS = setOf("members", "crate-type", "features", "bin", "test", "bench")
            const val GENERATED_FILE_NOTICE =
                """# Generated by TypeDB Cargo sync tool.
# Do not modify this file.

"""
        }
    }

    private object ShellArgs {
        const val ASPECTS =
            "--aspects=@typedb_dependencies//builder/rust/cargo:project_aspect.bzl%rust_cargo_properties_aspect"
        const val BAZEL = "bazel"
        const val BAZEL_BIN = "bazel-bin"
        const val BUILD = "build"
        const val INFO = "info"
        const val OUTPUT_GROUPS = "--output_groups=rust_cargo_properties"
        const val QUERY = "query"
        const val CQUERY = "cquery"
        const val OUTPUT_FILES = "--output=files"
        const val OUTPUT_BASE = "output_base"
        const val RUST_TARGETS_QUERY = "kind(rust_*, //...)"
    }
}
