import importlib.util
import os
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parent.parent / '.github/scripts/start_xcode_cloud_build.py'
spec = importlib.util.spec_from_file_location('start_xcode_cloud_build', SCRIPT)
module = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {'jwt': types.ModuleType('jwt')}):
    spec.loader.exec_module(module)


class XcodeCloudPRTests(unittest.TestCase):
    def test_finds_pr_on_later_page(self):
        responses = [
            {'data': [], 'links': {'next': 'https://api.appstoreconnect.apple.com/next'}},
            {'data': [{'id': 'pr-id', 'attributes': {'number': 203, 'sourceBranchName': 'feature',
                       'isClosed': False, 'isCrossRepository': False}}]},
        ]
        with patch.object(module, 'call', side_effect=responses) as call:
            self.assertEqual(module.find_pr('repo-id', '203', 'feature')['id'], 'pr-id')
            self.assertEqual(call.call_count, 2)

    def test_rejects_closed_cross_repository_or_wrong_branch(self):
        for attributes in [
            {'number': 203, 'sourceBranchName': 'feature', 'isClosed': True},
            {'number': 203, 'sourceBranchName': 'feature', 'isCrossRepository': True},
            {'number': 203, 'sourceBranchName': 'other'},
        ]:
            with self.subTest(attributes=attributes), patch.object(module, 'call', return_value={'data': [{'attributes': attributes}]}):
                with self.assertRaisesRegex(SystemExit, 'cannot|can.t find'):
                    module.find_pr('repo', '203', 'feature')

    def test_build_request_uses_pull_request_relationship(self):
        responses = [
            {'data': [{'id': 'app'}]}, {'data': {'id': 'product'}},
            {'data': [{'id': 'workflow', 'attributes': {'name': 'PR TestFlight'}}]},
            {'data': [{'id': 'repo'}]},
            {'data': [{'id': 'pr-id', 'attributes': {'number': 203, 'sourceBranchName': 'feature'}}]},
            {'data': {'attributes': {'number': 9}}},
        ]
        env = {'BUNDLE_ID': 'example', 'WORKFLOW_NAME': 'PR TestFlight', 'BRANCH': 'feature', 'PR_NUMBER': '203'}
        with patch.dict(os.environ, env, clear=True), patch.object(module, 'call', side_effect=responses) as call:
            module.main()
        method, endpoint, body = call.call_args.args
        self.assertEqual((method, endpoint), ('POST', '/ciBuildRuns'))
        relationships = body['data']['relationships']
        self.assertEqual(relationships['pullRequest']['data'], {'type': 'scmPullRequests', 'id': 'pr-id'})
        self.assertNotIn('sourceBranchOrTag', relationships)


if __name__ == '__main__':
    unittest.main()
