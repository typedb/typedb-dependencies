# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

cc_import(
   name = "lib",
   static_library = "lib/ortools.lib",
   visibility = ["//visibility:public"]
)
cc_library(
  name = "incl",
  hdrs = glob([
      "include/ortools/**/*.h",
      "include/absl/**/*.h",
      "include/absl/**/*.inc",
      "include/google/protobuf/**/*.inc",
      "include/google/protobuf/**/*.h",
  ]),
  strip_include_prefix = "include/",
  visibility = ["//visibility:public"]
)
