import base64
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"


def private_key():
    raw = os.environ["ASC_PRIVATE_KEY"].strip()
    # The secret may hold the .p8 as-is or base64-encoded.
    if "BEGIN" not in raw:
        raw = base64.b64decode(raw).decode()
    return raw


TOKEN = jwt.encode(
    {
        "iss": os.environ["ASC_ISSUER_ID"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 900,
        "aud": "appstoreconnect-v1",
    },
    private_key(),
    algorithm="ES256",
    headers={"kid": os.environ["ASC_KEY_ID"]},
)


def call(method, path, body=None, **query):
    url = path if path.startswith("http") else f"{API}{path}"
    if query:
        url += "?" + urllib.parse.urlencode(query)
    req = urllib.request.Request(
        url,
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        sys.exit(f"{method} {url} -> {err.code}: {err.read().decode()}")


bundle_id = os.environ["BUNDLE_ID"]
workflow_name = os.environ["WORKFLOW_NAME"]
branch = os.environ["BRANCH"]

apps = call("GET", "/apps", **{"filter[bundleId]": bundle_id})["data"]
if not apps:
    sys.exit(f"No app with bundle id {bundle_id}")

product = call("GET", f"/apps/{apps[0]['id']}/ciProduct")["data"]

workflows = call("GET", f"/ciProducts/{product['id']}/workflows", limit=200)["data"]
workflow = next((w for w in workflows if w["attributes"]["name"] == workflow_name), None)
if workflow is None:
    names = ", ".join(w["attributes"]["name"] for w in workflows)
    sys.exit(f"No Xcode Cloud workflow named '{workflow_name}'. Found: {names}")

repos = call("GET", f"/ciProducts/{product['id']}/primaryRepositories")["data"]
# The endpoint has no name filter, so page through until the branch turns up.
repo_id = repos[0]["id"]
ref = None
page = call("GET", f"/scmRepositories/{repo_id}/gitReferences", limit=200)
while ref is None:
    ref = next((r for r in page["data"] if r["attributes"]["name"] == branch and r["attributes"]["kind"] == "BRANCH"), None)
    next_url = page.get("links", {}).get("next")
    if ref is not None or not next_url:
        break
    page = call("GET", next_url)
if ref is None:
    sys.exit(f"Xcode Cloud can't see branch '{branch}' yet; is it pushed?")

run = call(
    "POST",
    "/ciBuildRuns",
    {
        "data": {
            "type": "ciBuildRuns",
            "relationships": {
                "workflow": {"data": {"type": "ciWorkflows", "id": workflow["id"]}},
                "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": ref["id"]}},
            },
        }
    },
)["data"]

message = f"Started Xcode Cloud build #{run['attributes'].get('number', '?')} of '{branch}' with workflow '{workflow_name}'."
print(message)
with open(os.environ.get("GITHUB_STEP_SUMMARY", os.devnull), "a") as summary:
    summary.write(message + "\n")
