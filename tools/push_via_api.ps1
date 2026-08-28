# Push the local HEAD commit to GitHub via the GitHub REST API (gh api).
#
# Why: in the DSH sandbox, git's schannel TLS fails
# (schannel: SEC_E_NO_CREDENTIALS — the Windows cert store is blocked),
# but the GitHub API is reachable. This script mirrors local HEAD to the
# remote branch without using git's network stack.
#
# Modes:
#  - Empty remote: creates the first commit via the Contents API (the only
#    endpoint that works on a brand-new repo), then pushes the remaining
#    files as one commit via the Git Data API (blob -> tree -> commit -> ref).
#  - Remote with commits: pushes local HEAD's tree as a new commit on top
#    of the remote HEAD (parents = [remote HEAD]).
#
# NOTE: gh api prints the error body to STDOUT on failure, so every call is
# checked against $LASTEXITCODE — never trust the output alone.
param([string]$Repo = "vl4dt/meow-command", [string]$Branch = "main")
$ErrorActionPreference = "Stop"

# Always run git from the repo root (ls-tree output is cwd-relative).
$root = (git rev-parse --show-toplevel).Trim()
Set-Location $root

$msg = (git log -1 --format=%B).Trim()
$authorName = (git log -1 --format=%an).Trim()
$authorEmail = (git log -1 --format=%ae).Trim()
$allFiles = @(git ls-tree -r HEAD --name-only | ForEach-Object { $_.Trim() })

function New-GitBlob([string]$Path) {
	$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root $Path)))
	$sha = gh api "repos/$Repo/git/blobs" -f content=$b64 -f encoding=base64 --jq ".sha"
	if ($LASTEXITCODE -ne 0 -or -not $sha) { throw "blob creation failed for ${Path}: ${sha}" }
	return $sha
}

function New-RemoteCommit([string[]]$Paths, [string]$Message, [string]$ParentSha) {
	$entries = @()
	foreach ($p in $Paths) {
		$entries += [pscustomobject]@{ path = $p; mode = "100644"; type = "blob"; sha = (New-GitBlob $p) }
	}
	$treePayload = @{ tree = $entries } | ConvertTo-Json -Depth 5
	$treeSha = $treePayload | gh api "repos/$Repo/git/trees" -X POST --input - --jq ".sha"
	if ($LASTEXITCODE -ne 0 -or -not $treeSha) { throw "tree creation failed: $treeSha" }
	$commit = [ordered]@{
		message = $Message
		tree    = $treeSha
		authors = @(@{ name = $authorName; email = $authorEmail })
	}
	if ($ParentSha) { $commit.parents = @($ParentSha) }
	$commitPayload = $commit | ConvertTo-Json -Depth 5
	$commitSha = $commitPayload | gh api "repos/$Repo/git/commits" -X POST --input - --jq ".sha"
	if ($LASTEXITCODE -ne 0 -or -not $commitSha) { throw "commit creation failed: $commitSha" }
	# refs/heads/$Branch already exists (seed or prior push) -> PATCH it.
	$refPayload = @{ sha = $commitSha } | ConvertTo-Json
	$refOut = $refPayload | gh api "repos/$Repo/git/refs/heads/$Branch" -X PATCH --input -
	if ($LASTEXITCODE -ne 0) { throw "ref update failed: $refOut" }
	return $commitSha
}

# --- remote state ---------------------------------------------------------
$remoteHead = gh api "repos/$Repo/branches/$Branch" --jq ".commit.sha"
if ($LASTEXITCODE -ne 0) { $remoteHead = $null }

if (-not $remoteHead) {
	# Empty repo: seed the first commit with one file via the Contents API.
	$seed = $allFiles[0]
	$seedB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root $seed)))
	$seedPayload = [ordered]@{
		message = "Initial commit (sandbox push)"
		content = $seedB64
		branch  = $Branch
	} | ConvertTo-Json
	$seedOut = $seedPayload | gh api "repos/$Repo/contents/$seed" -X PUT --input -
	if ($LASTEXITCODE -ne 0) { throw "seed commit failed: $seedOut" }
	Write-Host "seeded first commit via Contents API ($seed)"
	$remoteHead = gh api "repos/$Repo/branches/$Branch" --jq ".commit.sha"
	if ($LASTEXITCODE -ne 0 -or -not $remoteHead) { throw "branch not found after seed" }
	$rest = $allFiles | Select-Object -Skip 1
	Write-Host "pushing remaining $($rest.Count) files..."
	$sha = New-RemoteCommit -Paths $rest -Message $msg -ParentSha $remoteHead
} else {
	Write-Host "pushing $($allFiles.Count) files on top of remote $remoteHead..."
	$sha = New-RemoteCommit -Paths $allFiles -Message $msg -ParentSha $remoteHead
}

Write-Host "remote $Branch -> $sha"
Write-Host "PUSHED OK"
