load("@aspect_rules_ts//ts:defs.bzl", aspect_ts_project = "ts_project")

def ts_project(name, env = {}, **kwargs):
    # Merge user-supplied env with our required BAZEL_BINDIR override
    merged_env = dict(env)
    merged_env["BAZEL_BINDIR"] = "$(BINDIR)"

    aspect_ts_project(
        name = name,
        env = merged_env,
        **kwargs,
    )
