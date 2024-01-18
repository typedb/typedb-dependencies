#!/usr/bin/env python
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

"""
sync-dependencies.py updates bazel dependencies between @vaticle repositories

Example usage:
bazel run @vaticle_dependencies//tool/sync:dependencies -- \
--source typedb-driver@1a2b3c4d1a2b3c4d1a2b3c4d1a2b3c4d1a2b3c4g
"""

import argparse
import tool.common.common as tc
import github
import hashlib
import hmac
import json
import os
import re
import subprocess as sp
import sys


IS_CIRCLE_ENV = os.getenv('CIRCLECI')
if IS_CIRCLE_ENV is None:
    IS_CIRCLE_ENV = False

GITHUB_TOKEN = os.getenv('SYNC_DEPENDENCIES_TOKEN')
if GITHUB_TOKEN is None:
    raise Exception("$SYNC_DEPENDENCIES_TOKEN is not set!")

BOT_HOST = 'https://bot.vaticle.com'
if not IS_CIRCLE_ENV:
    BOT_HOST = 'http://localhost:8000'

BOT_SYNC_DEPS = '{0}/sync/dependencies'.format(BOT_HOST)

CMDLINE_PARSER = argparse.ArgumentParser(description='Automatic updater for Vaticle inter-repository dependencies')
CMDLINE_PARSER.add_argument('--dry-run', help='Do not perform any real actions')  # TODO(vmax): support this argument
CMDLINE_PARSER.add_argument('--source', required=True)
CMDLINE_PARSER.add_argument('--targets', nargs='+', required=True)

COMMIT_SUBJECT_PREFIX = "//ci:sync-dependencies:"
regex_git_commit = r'[0-9a-f]{40}'
regex_git_tag = r'([0-9]+\.[0-9]+\.[0-9]+)'

vaticle = 'vaticle'
github_connection = github.Github(GITHUB_TOKEN)
github_org = github_connection.get_organization(vaticle)


def is_building_upstream():
    """ Returns False is running in a forked repo"""
    return vaticle in os.getenv('CIRCLE_REPOSITORY_URL', '')


def exception_handler(fun):
    """ Decorator printing additional message on CalledProcessError """

    def wrapper(*args, **kwargs):
        # pylint: disable=missing-docstring
        try:
            fun(*args, **kwargs)
        except sp.CalledProcessError as ex:
            print('An error occurred when running {ex.cmd}. '
                  'Process exited with code {ex.returncode} '
                  'and message {ex.output}'.format(ex=ex))
            print()
            raise ex

    return wrapper


def short_commit(commit_sha):
    return sp.check_output(['git', 'rev-parse', '--short=7', commit_sha],
                                   cwd=os.getenv("BUILD_WORKSPACE_DIRECTORY")).decode().replace('\n', '')


@exception_handler
def main():
    if not is_building_upstream():
        print('//ci:sync-dependencies aborted: not building the upstream repo on @vaticle')
        exit(0)

    arguments = CMDLINE_PARSER.parse_args(sys.argv[1:])
    targets = {}
    source_repo, source_ref = arguments.source.split('@')

    if re.match(regex_git_commit, source_ref) is not None:
        source_ref_short = short_commit(source_ref)
    elif re.match(regex_git_tag, source_ref) is not None:
        source_ref_short = source_ref
    else:
        raise ValueError

    for target in arguments.targets:
        target_repo, target_branch = target.split(':')
        targets[target_repo] = target_branch

    github_repo = github_org.get_repo(source_repo)
    github_commit = github_repo.get_commit(source_ref)
    source_message = github_commit.commit.message

    # TODO: Check that the commit author is @vaticle-bot
    if not source_message.startswith(COMMIT_SUBJECT_PREFIX):
        sync_message = '{0} {1}/{2}@{3}'.format(COMMIT_SUBJECT_PREFIX, vaticle, source_repo, source_ref_short)
    else:
        sync_message = source_message

    print('Requesting the synchronisation of dependency to {0}/{1}@{2} in the following repos:'
          .format(vaticle, source_repo, source_ref_short))
    for target_repo in targets:
        print('- {0}/{1}:{2}'.format(vaticle, target_repo, targets[target_repo]))

    print('Constructing request payload:')
    sync_data = {
        'source-repo': source_repo,
        'source-ref': source_ref,
        'sync-message': sync_message,
        'targets': targets
    }
    print(str(sync_data))

    sync_data_json = json.dumps(sync_data)
    signature = hmac.new(GITHUB_TOKEN.encode(), sync_data_json.encode(), hashlib.sha1).hexdigest()

    print('Sending post request to: ' + BOT_SYNC_DEPS)
    tc.shell_execute([
        'curl', '-X', 'POST', '--data', sync_data_json, '-H', 'Content-Type: application/json', '-H', 'X-Hub-Signature: ' + signature, BOT_SYNC_DEPS
    ])
    print('DONE!')


if __name__ == '__main__':
    main()