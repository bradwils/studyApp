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


def call(method, path, body=None, **query):
    url = path if path.startswith("http") else f"{API}{path}"
    if query:
        url += "?" + urllib.parse.urlencode(query)
    req = urllib.request.Request(
        url,
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        sys.exit(f"{method} {url} -> {err.code}: {err.read().decode()}")


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900,
         "aud": "appstoreconnect-v1"},
        private_key(), algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]},
    )


def find_pr(repo_id, number, branch):
    page = call("GET", f"/scmRepositories/{repo_id}/pullRequests", limit=200)
    while True:
        for pr in page["data"]:
            attrs = pr["attributes"]
            if (str(attrs.get("number")) == str(number) and not attrs.get("isClosed")
                    and not attrs.get("isCrossRepository") and attrs.get("sourceBranchName") == branch):
                return pr
        next_url = page.get("links", {}).get("next")
        if not next_url:
            sys.exit(f"Xcode Cloud can't find open PR #{number} from '{branch}'; check repository access and sync")
        page = call("GET", next_url)


def main():
    bundle_id = os.environ["BUNDLE_ID"]
    workflow_name = os.environ["WORKFLOW_NAME"]
    branch = os.environ["BRANCH"]
    number = os.environ["PR_NUMBER"]

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
    if not repos:
        sys.exit("Xcode Cloud product has no primary repository")
    pr = find_pr(repos[0]["id"], number, branch)
    run = call("POST", "/ciBuildRuns", {"data": {
        "type": "ciBuildRuns",
        "relationships": {
            "workflow": {"data": {"type": "ciWorkflows", "id": workflow["id"]}},
            "pullRequest": {"data": {"type": "scmPullRequests", "id": pr["id"]}},
        },
    }})["data"]
    message = f"Started Xcode Cloud build #{run['attributes'].get('number', '?')} for PR #{number} ('{branch}') with workflow '{workflow_name}'."
    print(message)
    with open(os.environ.get("GITHUB_STEP_SUMMARY", os.devnull), "a") as summary:
        summary.write(message + "\n")


if __name__ == "__main__":
    main()
