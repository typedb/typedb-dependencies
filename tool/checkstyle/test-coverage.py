#!/usr/bin/env python
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


from __future__ import print_function
import tool.common.common as tc
import os
import sys
from xml.etree import ElementTree


def try_decode(s):
    if type(s) == bytes:
        return s.decode()
    return s


if __name__ == '__main__':
    print('Checking if there are any workspace files not covered by checkstyle...')

    workspace_dir = os.getenv("BUILD_WORKSPACE_DIRECTORY")

    # Read .bazelignore to exclude directories that can't have checkstyle_test targets
    bazelignore_dirs = []
    bazelignore_path = os.path.join(workspace_dir, '.bazelignore')
    if os.path.exists(bazelignore_path):
        with open(bazelignore_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    bazelignore_dirs.append(line)

    prune_args = [
        '(', '-name', '.git',
            '-o', '-name', '.DS_Store',
            '-o', '-name', '.idea',
            '-o', '-name', '.ijwb',
            '-o', '-name', '.github',
            '-o', '-name', '.bazelversion',
            '-o', '-name', '.gitkeep',
            '-o', '-name', 'VERSION',
            '-o', '-name', '*.md',
            '-o', '-name', 'node_modules',
            '-o', '-name', 'target',
    ]
    for ignored_dir in bazelignore_dirs:
        prune_args.extend(['-o', '-name', ignored_dir])
    prune_args.extend([')', '-prune', '-o', '-type', 'f', '-print'])

    workspace_files, _ = tc.shell_execute(
        ['find', '.'] + prune_args,
        cwd=workspace_dir,
    )
    workspace_files = workspace_files.strip().split("\n")

    checkstyle_targets_xml, _ = tc.shell_execute([
        'bazel', 'query', 'kind(checkstyle_test, //...)', '--output', 'xml'
    ], cwd=os.getenv("BUILD_WORKSPACE_DIRECTORY"))
    checkstyle_targets_tree = ElementTree.fromstring(checkstyle_targets_xml)
    included_checkstyle_files = checkstyle_targets_tree.findall(".//list[@name='include']//label[@value]")
    excluded_checkstyle_files = checkstyle_targets_tree.findall(".//list[@name='exclude']//label[@value]")
    # examples:
    # - '//test/behaviour:BUILD' transforms to './test/behaviour/BUILD'
    # - '//:README.md' transforms to './README.md'
    checkstyle_files = list(map(lambda x: x.get('value').replace('//:', './').replace('//', './').replace(':', '/'), included_checkstyle_files + excluded_checkstyle_files))
    unique_included_checkstyle_files = set(included_checkstyle_files)
    unique_excluded_checkstyle_files = set(excluded_checkstyle_files)

    if len(unique_included_checkstyle_files) != len(included_checkstyle_files):
        non_unique_checkstyle_file = set([x for x in included_checkstyle_files if included_checkstyle_files.count(x) > 1])
        non_unique_checkstyle_file_count = len(non_unique_checkstyle_file)
        print('ERROR: Found %d workspace files which are included more than once:' % non_unique_checkstyle_file_count)
        for i, target_label in enumerate(non_unique_checkstyle_file, start=1):
            print('%d: %s' % (i, target_label))
        sys.exit(1)

    if len(unique_excluded_checkstyle_files) != len(excluded_checkstyle_files):
        non_unique_checkstyle_file = set([x for x in excluded_checkstyle_files if excluded_checkstyle_files.count(x) > 1])
        non_unique_checkstyle_file_count = len(non_unique_checkstyle_file)
        print('ERROR: Found %d workspace files which are excluded more than once:' % non_unique_checkstyle_file_count)
        for i, target_label in enumerate(non_unique_checkstyle_file, start=1):
            print('%d: %s' % (i, target_label))
        sys.exit(1)

    workspace_files_with_no_checkstyle = set(workspace_files) - set(checkstyle_files)
    file_count = len(workspace_files_with_no_checkstyle)

    if workspace_files_with_no_checkstyle:
        print('ERROR: Found %d workspace files which are not covered by a `checkstyle_test`. They must be placed in either `include` or `exclude` in a `checkstyle_test`.' % file_count)
        for i, file_label in enumerate(workspace_files_with_no_checkstyle, start=1):
            print('%d: %s' % (i, file_label))
        sys.exit(1)

    print('SUCCESS: Every workspace file is covered by a `checkstyle_test`!')
