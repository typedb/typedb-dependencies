#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import argparse
import os
import platform
import subprocess
from collections import defaultdict
import re

parser = argparse.ArgumentParser()
parser.add_argument('mode', help="Operational mode", choices=['list', 'remove'])
args = parser.parse_args()


BUILDOZER_PATTERN = re.compile("buildozer 'remove deps (?P<dep>.*)' (?P<target>.*)")


def _get_runfiles_dir():
    """Get the runfiles root directory from environment or __file__ path."""
    runfiles_dir = os.environ.get('RUNFILES_DIR', '')
    if runfiles_dir and os.path.isdir(runfiles_dir):
        return runfiles_dir
    # Derive from __file__: <runfiles>/<repo>/tool/unuseddeps/unused-deps.py
    path = os.path.abspath(__file__)
    while path != os.path.dirname(path):
        path = os.path.dirname(path)
        if path.endswith('.runfiles'):
            return path
    return ''


def find_runfile(repo_name):
    """Find a downloaded binary in runfiles, supporting both WORKSPACE and Bzlmod layouts."""
    workspace_path = os.path.abspath(os.path.join("external", repo_name, "file", "downloaded"))
    if os.path.exists(workspace_path):
        return workspace_path
    runfiles_dir = _get_runfiles_dir()
    if runfiles_dir:
        for entry in os.listdir(runfiles_dir):
            if entry == repo_name or entry.endswith('+' + repo_name):
                path = os.path.join(runfiles_dir, entry, "file", "downloaded")
                if os.path.exists(path):
                    return path
    raise FileNotFoundError("Could not find {} in runfiles".format(repo_name))


UNUSED_DEPS_REPOS = {
    "Darwin": "unused_deps_mac",
    "Linux": "unused_deps_linux",
}

BUILDOZER_REPOS = {
    "Darwin": "buildozer_mac",
    "Linux": "buildozer_linux",
}

system = platform.system()

if system not in UNUSED_DEPS_REPOS:
    raise ValueError('unused_deps does not have binary for {}'.format(system))

if system not in BUILDOZER_REPOS:
    raise ValueError('buildozer does not have binary for {}'.format(system))

unused_deps_binary = find_runfile(UNUSED_DEPS_REPOS[system])
buildozer_binary = find_runfile(BUILDOZER_REPOS[system])


output = subprocess.check_output([
    unused_deps_binary
], cwd=os.getenv('BUILD_WORKSPACE_DIRECTORY'), stderr=subprocess.STDOUT).decode()

unused_deps = defaultdict(set)

output_lines = output.split('\n')
buildozer_commands = []
for line in output_lines:
    match = BUILDOZER_PATTERN.match(line)
    if match:
        buildozer_commands.append(line)
        gd = match.groupdict()
        unused_deps[gd['target']].add(gd['dep'])


if args.mode == 'list':
    if unused_deps:
        print('\033[0;31mERROR: There are unused deps found:\033[0m')
        for target, deps in unused_deps.items():
            print('{}:'.format(target))
            for dep in deps:
                print('--> {}'.format(dep))
        print('You can run "bazel run @typedb_dependencies//tool/unuseddeps:unused-deps -- remove" to fix it')
        exit(1)
    else:
        print('\033[0;32mThere are no unused deps found.\033[0m')
elif args.mode == 'remove':
    for cmd in buildozer_commands:
        subprocess.check_call([
            cmd.replace('buildozer', buildozer_binary)
        ], shell=True, cwd=os.getenv('BUILD_WORKSPACE_DIRECTORY'))
