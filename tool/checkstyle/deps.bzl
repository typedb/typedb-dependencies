# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")


# Use http_file instead of jvm_maven_import_external to match the Bzlmod
# (MODULE.bazel) structure and avoid java_import targets that trigger
# unnecessary toolchain resolution (CC/Rust) in downstream consumers.
def deps(
    omit = [],
    versions = {
      "antlr_antlr": "2.7.7",
      "org_antlr_antlr4_runtime": "4.5.1-1",
      "com_puppycrawl_tools_checkstyle": "8.15",
      "commons_beanutils_commons_beanutils": "1.9.3",
      "info_picocli_picocli": "3.8.2",
      "commons_collections_commons_collections": "3.2.2",
      "com_google_guava_guava30jre": "30.1-jre",
      "org_slf4j_slf4j_api": "1.7.7",
      "org_slf4j_slf4j_jcl": "1.7.7",
    }
):
  if not "antlr_antlr" in omit:
    http_file(
        name = "antlr_antlr",
        urls = ["https://repo1.maven.org/maven2/antlr/antlr/" + versions["antlr_antlr"] + "/antlr-" + versions["antlr_antlr"] + ".jar"],
        sha256 = "88fbda4b912596b9f56e8e12e580cc954bacfb51776ecfddd3e18fc1cf56dc4c",
        downloaded_file_path = "antlr.jar",
    )
  if not "org_antlr_antlr4_runtime" in omit:
    http_file(
        name = "org_antlr_antlr4_runtime",
        urls = ["https://repo1.maven.org/maven2/org/antlr/antlr4-runtime/" + versions["org_antlr_antlr4_runtime"] + "/antlr4-runtime-" + versions["org_antlr_antlr4_runtime"] + ".jar"],
        sha256 = "ffca72bc2a25bb2b0c80a58cee60530a78be17da739bb6c91a8c2e3584ca099e",
        downloaded_file_path = "antlr4-runtime.jar",
    )
  if not "com_puppycrawl_tools_checkstyle" in omit:
    http_file(
        name = "com_puppycrawl_tools_checkstyle",
        urls = ["https://repo1.maven.org/maven2/com/puppycrawl/tools/checkstyle/" + versions["com_puppycrawl_tools_checkstyle"] + "/checkstyle-" + versions["com_puppycrawl_tools_checkstyle"] + ".jar"],
        sha256 = "ac3602c4d50c3113b14614a6ac38ec03c63d9839e4316e057c4bb66d97183087",
        downloaded_file_path = "checkstyle.jar",
    )
  if not "commons_beanutils_commons_beanutils" in omit:
    http_file(
        name = "commons_beanutils_commons_beanutils",
        urls = ["https://repo1.maven.org/maven2/commons-beanutils/commons-beanutils/" + versions["commons_beanutils_commons_beanutils"] + "/commons-beanutils-" + versions["commons_beanutils_commons_beanutils"] + ".jar"],
        sha256 = "c058e39c7c64203d3a448f3adb588cb03d6378ed808485618f26e137f29dae73",
        downloaded_file_path = "commons-beanutils.jar",
    )
  if not "info_picocli_picocli" in omit:
    http_file(
        name = "info_picocli_picocli",
        urls = ["https://repo1.maven.org/maven2/info/picocli/picocli/" + versions["info_picocli_picocli"] + "/picocli-" + versions["info_picocli_picocli"] + ".jar"],
        sha256 = "b16786a3817530151ccc44ac44f1f803b9a1b4069e98c4d1ed2fc0ece12d6de7",
        downloaded_file_path = "picocli.jar",
    )
  if not "commons_collections_commons_collections" in omit:
    http_file(
        name = "commons_collections_commons_collections",
        urls = ["https://repo1.maven.org/maven2/commons-collections/commons-collections/" + versions["commons_collections_commons_collections"] + "/commons-collections-" + versions["commons_collections_commons_collections"] + ".jar"],
        sha256 = "eeeae917917144a68a741d4c0dff66aa5c5c5fd85593ff217bced3fc8ca783b8",
        downloaded_file_path = "commons-collections.jar",
    )
  if not "com_google_guava_guava30jre" in omit:
    http_file(
        name = "com_google_guava_guava30jre",
        urls = ["https://repo1.maven.org/maven2/com/google/guava/guava/" + versions["com_google_guava_guava30jre"] + "/guava-" + versions["com_google_guava_guava30jre"] + ".jar"],
        sha256 = "e6dd072f9d3fe02a4600688380bd422bdac184caf6fe2418cfdd0934f09432aa",
        downloaded_file_path = "guava.jar",
    )
  if not "org_slf4j_slf4j_api" in omit:
    http_file(
        name = "org_slf4j_slf4j_api",
        urls = ["https://repo1.maven.org/maven2/org/slf4j/slf4j-api/" + versions["org_slf4j_slf4j_api"] + "/slf4j-api-" + versions["org_slf4j_slf4j_api"] + ".jar"],
        sha256 = "69980c038ca1b131926561591617d9c25fabfc7b29828af91597ca8570cf35fe",
        downloaded_file_path = "slf4j-api.jar",
    )
  if not "org_slf4j_slf4j_jcl" in omit:
    http_file(
        name = "org_slf4j_slf4j_jcl",
        urls = ["https://repo1.maven.org/maven2/org/slf4j/jcl-over-slf4j/" + versions["org_slf4j_slf4j_jcl"] + "/jcl-over-slf4j-" + versions["org_slf4j_slf4j_jcl"] + ".jar"],
        sha256 = "c6472b5950e1c23202e567c6334e4832d1db46fad604b7a0d7af71d4a014bce2",
        downloaded_file_path = "jcl-over-slf4j.jar",
    )
