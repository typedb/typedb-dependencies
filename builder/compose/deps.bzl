load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def deps():
    http_file(
        name = "org_jetbrains_compose_compiler",
        urls = ["https://maven.pkg.jetbrains.space/public/p/compose/dev/org/jetbrains/compose/compiler/compiler-hosted/1.0.0-alpha2/compiler-hosted-1.0.0-alpha2.jar"],
        sha256 = "cdf70c76d9ae44cfa1c261a74f69379446dae72580da35a415fd1ac06ed14d4c",
        downloaded_file_path = "compiler-hosted-1.0.0-alpha2.jar",
    )

    http_file(
        name = "jdk16_mac",
        urls = ["https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_osx-x64_bin.tar.gz"],
        sha256 = "e65f2437585f16a01fa8e10139d0d855e8a74396a1dfb0163294ed17edd704b8",
    )

    http_file(
        name = "jdk16_windows",
        urls = ["https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_windows-x64_bin.zip"],
        sha256 = "9df98be05fe674066cc39144467c47b1503cfa3de059c09cc4ccc3da9c253b9a",
    )

    http_file(
        name = "jdk16_linux",
        urls = ["https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz"],
        sha256 = "6c714ded7d881ca54970ec949e283f43d673a142fda1de79b646ddd619da9c0c",
    )

    http_file(
        name = "jdk17_linux",
        urls = ["https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz"],
        sha256 = "aef49cc7aa606de2044302e757fa94c8e144818e93487081c4fd319ca858134b",
    )