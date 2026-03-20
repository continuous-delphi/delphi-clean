# tools/tag-release.ps1
# Creates and pushes a vX.Y.Z release tag for delphi-clean.
# Requires: PowerShell 7+, git (on PATH)
#
# Usage:
#   pwsh tools/tag-release.ps1 -Version 1.0.0
#
# The script validates preconditions before touching git:
#   - Version argument matches X.Y.Z semver format
#   - $script:Version in delphi-clean.ps1 matches the Version argument
#   - CHANGELOG.md has an entry for the version
#   - Working tree is clean (no uncommitted changes)
#   - Current branch matches the default branch on origin
#   - Local HEAD is up-to-date with origin/<default branch>
#   - Tag does not already exist locally or on origin

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
  Justification = 'Write-Host is required for colored interactive console output.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '',
  Justification = 'Invoke-Git uses ValueFromRemainingArguments for variadic git args; positional use is intentional.')]
param(
  [Parameter(Mandatory=$true, HelpMessage='Semantic version to tag, e.g. 1.0.0')]
  [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
  [string] $Version,

  [Parameter(HelpMessage='Skip the branch check (use when hotfixing from a non-default branch)')]
  [switch] $SkipBranchCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Step([string]$Message) {
  Write-Host "  $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
  Write-Host "  ok  $Message" -ForegroundColor Green
}

function Fail([string]$Message) {
  Write-Host ""
  Write-Host "FAIL  $Message" -ForegroundColor Red
  Write-Host ""
  throw $Message
}

function Invoke-Git {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments)][string[]] $GitArgs)

  $result = & git @GitArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    Fail "git $($GitArgs -join ' ') failed (exit $LASTEXITCODE):`n$result"
  }
  return $result
}

# ---------------------------------------------------------------------------
# Resolve paths relative to the repo root (script is in tools/)
# ---------------------------------------------------------------------------

$repoRoot      = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$scriptFile    = Join-Path $repoRoot 'source' 'delphi-clean.ps1'
$changelogFile = Join-Path $repoRoot 'CHANGELOG.md'
$tag           = "v$Version"

Write-Host ""
Write-Host "delphi-clean  tag-release" -ForegroundColor White
Write-Host "===========================" -ForegroundColor White
Write-Host "  Version : $Version"
Write-Host "  Tag     : $tag"
Write-Host "  Repo    : $repoRoot"
Write-Host ""

# ---------------------------------------------------------------------------
# Precondition 1: script version matches the Version argument
# ---------------------------------------------------------------------------

Write-Step "Checking script version..."

if (-not (Test-Path -LiteralPath $scriptFile)) {
  Fail "Script not found: $scriptFile"
}

$scriptContent = Get-Content -LiteralPath $scriptFile -Raw
if ($scriptContent -notmatch '\$script:Version\s*=\s*''([^'']+)''') {
  Fail "Could not find '`$script:Version = ''...''' in delphi-clean.ps1."
}

$scriptVersion = $Matches[1]
if ($scriptVersion -ne $Version) {
  Fail "`$script:Version in delphi-clean.ps1 is '$scriptVersion' but -Version arg is '$Version'.`n       Update `$script:Version in the script and commit before tagging."
}

Write-Ok "script version matches ($scriptVersion)"

# ---------------------------------------------------------------------------
# Precondition 2: CHANGELOG.md has an entry for the version
# ---------------------------------------------------------------------------

Write-Step "Checking CHANGELOG.md..."

if (-not (Test-Path -LiteralPath $changelogFile)) {
  Fail "CHANGELOG.md not found: $changelogFile"
}

$changelogContent = Get-Content -LiteralPath $changelogFile -Raw
if ($changelogContent -notmatch "(?m)^\#\# \[$([regex]::Escape($Version))\]") {
  Fail "No entry for version $Version found in CHANGELOG.md.`n       Add a '## [$Version]' section before tagging."
}

Write-Ok "CHANGELOG.md has entry for $Version"

# ---------------------------------------------------------------------------
# Precondition 3: git is available
# ---------------------------------------------------------------------------

Write-Step "Checking git..."

try {
  $gitVersion = & git --version 2>&1
  if ($LASTEXITCODE -ne 0) { throw }
} catch {
  Fail "git is not available on PATH."
}

Write-Ok "git found ($gitVersion)"

Push-Location $repoRoot
try {

  # -------------------------------------------------------------------------
  # Precondition 4: inside a git repository
  # -------------------------------------------------------------------------

  Write-Step "Checking git repository..."

  $null = & git rev-parse --git-dir 2>&1
  if ($LASTEXITCODE -ne 0) {
    Fail "Not inside a git repository: $repoRoot"
  }

  Write-Ok "inside git repository"

  # -------------------------------------------------------------------------
  # Precondition 5: current branch matches origin's default branch
  # -------------------------------------------------------------------------

  Write-Step "Checking branch..."

  $branch = (Invoke-Git rev-parse --abbrev-ref HEAD).Trim()

  $originHead = & git rev-parse --abbrev-ref origin/HEAD 2>$null
  $defaultBranch = if ($LASTEXITCODE -eq 0 -and $originHead) {
    $originHead.Trim() -replace '^origin/', ''
  } else {
    Write-Host "  warn  origin/HEAD not set; assuming default branch is 'main'" -ForegroundColor Yellow
    'main'
  }

  if (-not $SkipBranchCheck -and $branch -ne $defaultBranch) {
    Fail "Must be on '$defaultBranch' branch to tag a release (currently on '$branch').`n       Switch to $defaultBranch, or use -SkipBranchCheck to override (not recommended)."
  }

  if ($SkipBranchCheck -and $branch -ne $defaultBranch) {
    Write-Host "  warn  Not on '$defaultBranch' (on '$branch'); -SkipBranchCheck override active" -ForegroundColor Yellow
  } else {
    Write-Ok "on branch '$defaultBranch'"
  }

  # -------------------------------------------------------------------------
  # Precondition 6: working tree is clean
  # -------------------------------------------------------------------------

  Write-Step "Checking working tree..."

  $status = Invoke-Git status --porcelain
  if ($status) {
    Fail "Working tree is not clean. Commit or stash all changes before tagging.`n`n$status"
  }

  Write-Ok "working tree is clean"

  # -------------------------------------------------------------------------
  # Precondition 7: origin remote exists
  # -------------------------------------------------------------------------

  Write-Step "Checking for origin remote..."

  $remotes = (Invoke-Git remote).Trim().Split([Environment]::NewLine)
  if ($remotes -notcontains 'origin') {
    Fail "Remote 'origin' not found. Add it or run this script in a clone with an origin remote."
  }

  Write-Ok "origin remote found"

  # -------------------------------------------------------------------------
  # Fetch tags from origin so the local tag list is current
  # -------------------------------------------------------------------------

  Write-Step "Fetching tags from origin..."
  Invoke-Git fetch --tags origin | Out-Null
  Write-Ok "tags fetched"

  # -------------------------------------------------------------------------
  # Precondition 8: local HEAD is not behind origin/<defaultBranch>
  # -------------------------------------------------------------------------

  Write-Step "Checking HEAD is up-to-date with origin/$defaultBranch..."

  $localRev  = (Invoke-Git rev-parse HEAD).Trim()
  $remoteRev = (Invoke-Git rev-parse "origin/$defaultBranch").Trim()

  if ($localRev -ne $remoteRev) {
    $behind = (Invoke-Git rev-list --count "HEAD..origin/$defaultBranch").Trim()
    $ahead  = (Invoke-Git rev-list --count "origin/$defaultBranch..HEAD").Trim()

    if ([int]$behind -gt 0 -and [int]$ahead -eq 0) {
      Fail "Local HEAD is $behind commit(s) behind origin/$defaultBranch. Run 'git pull' before tagging."
    } elseif ([int]$ahead -gt 0 -and [int]$behind -eq 0) {
      Fail "Local HEAD is $ahead commit(s) ahead of origin/$defaultBranch. Push your changes before tagging."
    } else {
      Fail "Local HEAD has diverged from origin/$defaultBranch ($ahead ahead, $behind behind). Reconcile before tagging."
    }
  }

  Write-Ok "HEAD is up-to-date with origin/$defaultBranch"

  # -------------------------------------------------------------------------
  # Precondition 9: tag does not already exist (local or origin)
  # -------------------------------------------------------------------------

  Write-Step "Checking for existing tag..."

  & git show-ref --tags --verify --quiet "refs/tags/$tag" 2>$null
  if ($LASTEXITCODE -eq 0) {
    Fail "Tag '$tag' already exists (local or origin).`n       To delete locally:  git tag -d $tag`n       To delete on origin: git push origin --delete $tag"
  }

  Write-Ok "tag '$tag' does not exist"

  # -------------------------------------------------------------------------
  # All preconditions passed - confirm and tag
  # -------------------------------------------------------------------------

  $tagMsg = "Release $tag"

  Write-Host ""
  Write-Host "All checks passed." -ForegroundColor Green
  Write-Host ""

  if ($PSCmdlet.ShouldProcess(
        "origin  (tag: $tag  message: '$tagMsg')",
        "Create annotated tag and push")) {

    try {

      Write-Step "Creating tag $tag..."
      Invoke-Git tag -a $tag -m $tagMsg
      Write-Ok "tag created"

      Write-Step "Pushing tag to origin..."
      Invoke-Git push origin $tag | Out-Null
      Write-Ok "tag pushed"

      Write-Host ""
      Write-Host "Released: $tag" -ForegroundColor Green
      Write-Host "The GitHub Actions release workflow should run for this tag." -ForegroundColor Green
      Write-Host ""

    } catch {

      Write-Host ""
      Write-Host "ERROR: Tag/push failed." -ForegroundColor Red
      Write-Host $_ -ForegroundColor DarkRed
      Write-Host ""
      Write-Host "Partial failure - check the state and clean up if needed:" -ForegroundColor Yellow

      & git show-ref --tags --verify --quiet "refs/tags/$tag" 2>$null
      if ($LASTEXITCODE -eq 0) {
        Write-Host "  Local tag exists. If the push failed, delete it with:" -ForegroundColor Yellow
        Write-Host "    git tag -d $tag" -ForegroundColor Yellow
      }

      Write-Host "  Verify origin does not have a partial push:" -ForegroundColor Yellow
      Write-Host "    git ls-remote --tags origin refs/tags/$tag" -ForegroundColor Yellow
      Write-Host ""
      throw

    }

  } else {
    Write-Host "  WhatIf: would create annotated tag and push to origin" -ForegroundColor Yellow
    Write-Host "    Tag    : $tag" -ForegroundColor Yellow
    Write-Host "    Message: $tagMsg" -ForegroundColor Yellow
    Write-Host ""
  }

} finally {
  Pop-Location
}
