# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


google_or_tools = select({
         "@typedb_bazel_distribution//platform:is_mac": [
             "@typedb_maven//:com_google_ortools_ortools_darwin",
             "@typedb_maven//:com_google_ortools_ortools_darwin_java",
         ],
         "@typedb_bazel_distribution//platform:is_linux": [
             "@typedb_maven//:com_google_ortools_ortools_linux_x86_64",
             "@typedb_maven//:com_google_ortools_ortools_linux_x86_64_java"
         ],
         "@typedb_bazel_distribution//platform:is_windows": [
             "@typedb_maven//:com_google_ortools_ortools_win32_x86_64",
             "@typedb_maven//:com_google_ortools_ortools_win32_x86_64_java"
         ],
         "//conditions:default": [
             "@typedb_maven//:com_google_ortools_ortools_darwin",
             "@typedb_maven//:com_google_ortools_ortools_darwin_java",
         ],
     })
