# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

filegroup(
    name = "templates",
    srcs = glob(["Lib/**/*.i", "Lib/**/*.swg"], allow_empty = True),
    visibility = ["//visibility:public"],
)

genrule(
    name = "swigconfig",
    outs = ["Source/Include/swigconfig.h"],
    cmd = '''cat >$@ <<EOF
#define PACKAGE_BUGREPORT "http://www.swig.org"
#define PACKAGE_VERSION "4.1.1"
#define SWIG_CXX "unknown"
#define SWIG_LIB "external/swig/Lib"
#define SWIG_LIB_WIN_UNIX SWIG_LIB
#define SWIG_PLATFORM "unknown"
EOF
    ''',
)

cc_binary(
    name = "swig",
    srcs = [":swigconfig"] + glob([
        "Source/**/*.h",
        "Source/**/*.c",
        "Source/**/*.cc",
        "Source/**/*.cxx",
    ], allow_empty = True),
    copts = ["-fexceptions"],
    data = [":templates"],
    includes = [
        "Source/CParse",
        "Source/DOH",
        "Source/Doxygen",
        "Source/Include",
        "Source/Modules",
        "Source/Preprocessor",
        "Source/Swig",
    ],
    visibility = ["//visibility:public"],
)
