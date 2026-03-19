#requires -Version 7.0

<#
.SYNOPSIS
Cleans Delphi build artifacts from a repository tree running in 3 different modes.

.DESCRIPTION
Runs from the tools location and targets the parent directory by default.
Supports three cleanup profiles:

  lite  - safe, low-risk cleanup of common transient files
  build - removes build outputs and common generated files
  full  - aggressive cleanup including user-local IDE state files

.EXAMPLE
pwsh -File .\delphi-clean.ps1

.EXAMPLE
pwsh -File .\delphi-clean.ps1 -Profile build

.EXAMPLE
pwsh -File .\delphi-clean.ps1 -Profile full -Verbose

.EXAMPLE
pwsh -File .\delphi-clean.ps1 -Profile full -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('lite', 'build', 'full')]
    [string]$Profile = 'build',

    [Parameter()]
    [string]$RootPath,

    [Parameter()]
    [string[]]$ExcludeDirectories = @(
        '.git',
        '.vs',
        '.claude'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ''
    Write-Host ('=' * 70)
    Write-Host $Message
    Write-Host ('=' * 70)
}

function Resolve-CleanRoot {
    param(
        [string]$InputRoot
    )

    if ([string]::IsNullOrWhiteSpace($InputRoot)) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        $resolved = Resolve-Path (Join-Path $scriptDir '..')
        return $resolved.Path
    }

    $resolvedInput = Resolve-Path $InputRoot
    return $resolvedInput.Path
}

function Test-PathUnderExcludedDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$FullName,

        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirectoryNames
    )

    $relative = [System.IO.Path]::GetRelativePath($Root, $FullName)

    if ($relative -eq '.') {
        return $false
    }

    $parts = $relative -split '[\\/]'
    foreach ($part in $parts) {
        if ($ExcludedDirectoryNames -contains $part) {
            return $true
        }
    }

    return $false
}

function Get-ProfileDefinition {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('lite', 'build', 'full')]
        [string]$Name
    )

    switch ($Name) {
        'lite' {
            @{
                FilePatterns = @(
                    '*.dcu',
                    '*.identcache',
                    '*.bak',
                    '*.tmp',
                    '*.dsk',
                    '*.tvsconfig',
                    '*.stat'
                )
                DirectoryNames = @(
                    '__history'
                )
            }
        }

        'build' {
            @{
                FilePatterns = @(
                    '*.bak',
                    '*.tmp',
                    '*.dcu',
                    '*.ddp',
                    '*.dsk',
                    '*.identcache',
                    '*.local',
                    '*.tvsconfig',
                    '*.dproj.local',
                    '*.groupproj.local',
                    '*.drc',
                    '*.map',
                    '*.rsm',
                    '*.tds',
                    '*.bpl',
                    '*.dcp',
                    '*.bpi',
                    '*.dll',
                    '*.exe',
                    '*.obj',
                    '*.hpp',
                    '*.ilc',
                    '*.ild',
                    '*.ilf',
                    '*.ipu',
                    '*.~bpg',
                    '*.~dsk',
                    '*.~pas',
                    '*.~dfm',
                    '*.~ddp',
                    '*.~dpr'
                )
                DirectoryNames = @(
                    '__history',
                    'Win32',
                    'Win64',
                    'Debug',
                    'Release',
                    'dcu'
                )
            }
        }

        'full' {
            @{
                FilePatterns = @(
                    '*.bak',
                    '*.tmp',
                    '*.dcu',
                    '*.ddp',
                    '*.dsk',
                    '*.identcache',
                    '*.local',
                    '*.tvsconfig',
                    '*.dproj.local',
                    '*.groupproj.local',
                    '*.drc',
                    '*.map',
                    '*.rsm',
                    '*.tds',
                    '*.bpl',
                    '*.dcp',
                    '*.bpi',
                    '*.lib',
                    '*.dll',
                    '*.exe',
                    '*.obj',
                    '*.hpp',
                    '*.ilc',
                    '*.ild',
                    '*.ilf',
                    '*.ipu',
                    '*.~bpg',
                    '*.~dsk',
                    '*.~pas',
                    '*.~dfm',
                    '*.~ddp',
                    '*.~dpr'
                )
                DirectoryNames = @(
                    '__history',
                    'Win32',
                    'Win64',
                    'Debug',
                    'Release',
                    'dcu'
                )
            }
        }

        default {
            throw "Unsupported profile: $Name"
        }
    }
}

function Get-FilesToDelete {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$Patterns,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirectoryNames
    )

    $all = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($pattern in $Patterns) {
        Write-Verbose "Scanning for files matching pattern: $pattern"

        $matches = Get-ChildItem -Path $Root -Recurse -File -Filter $pattern -Force -ErrorAction SilentlyContinue |
            Where-Object {
                -not (Test-PathUnderExcludedDirectory -FullName $_.FullName -Root $Root -ExcludedDirectoryNames $ExcludedDirectoryNames)
            }

        foreach ($match in $matches) {
            $all.Add($match)
        }
    }

    $all |
        Sort-Object -Property FullName -Unique
}

function Get-DirectoriesToDelete {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$DirectoryNames,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirectoryNames
    )

    $all = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]

    foreach ($dirName in $DirectoryNames) {
        Write-Verbose "Scanning for directories named: $dirName"

        $matches = Get-ChildItem -Path $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -ieq $dirName -and
                -not (Test-PathUnderExcludedDirectory -FullName $_.FullName -Root $Root -ExcludedDirectoryNames $ExcludedDirectoryNames)
            }

        foreach ($match in $matches) {
            $all.Add($match)
        }
    }

    $all |
        Sort-Object -Property FullName -Unique |
        Sort-Object -Property { $_.FullName.Length } -Descending
}

function Remove-TargetFiles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [System.IO.FileInfo[]]$Files = @(),
        [switch]$ShowDeletedItems
    )

    if (@($Files).Count -eq 0) {
        return 0
    }

    $deleted = 0

    foreach ($file in $Files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Delete file')) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop -WhatIf:$WhatIfPreference

                if ($ShowDeletedItems) {
                    Write-Host "Deleted file: $($file.FullName)"
                }
                else {
                    Write-Host "Deleted file: $($file.FullName)"
                }

                if (-not $WhatIfPreference) {
                    $deleted++
                }
            }
            catch {
                Write-Warning "Failed to delete file: $($file.FullName)"
                Write-Warning $_.Exception.Message
            }
        }
    }

    return $deleted
}

function Remove-TargetDirectories {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [System.IO.DirectoryInfo[]]$Directories = @(),
        [switch]$ShowDeletedItems
    )

    if (@($Directories).Count -eq 0) {
        return 0
    }

    $deleted = 0

    foreach ($dir in $Directories) {
        if (-not (Test-Path -LiteralPath $dir.FullName)) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($dir.FullName, 'Delete directory')) {
            try {
                Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction Stop -WhatIf:$WhatIfPreference

                if ($ShowDeletedItems) {
                    Write-Host "Deleted directory: $($dir.FullName)"
                }
                else {
                    Write-Host "Deleted directory: $($dir.FullName)"
                }

                if (-not $WhatIfPreference) {
                    $deleted++
                }
            }
            catch {
                Write-Warning "Failed to delete directory: $($dir.FullName)"
                Write-Warning $_.Exception.Message
            }
        }
    }

    return $deleted
}

try {
    $cleanRoot = Resolve-CleanRoot -InputRoot $RootPath
    $definition = Get-ProfileDefinition -Name $Profile

    Write-Section "Delphi Cleanup"
    Write-Host "Profile      : $Profile"
    Write-Host "Root         : $cleanRoot"
    Write-Host "Excluded dirs: $($ExcludeDirectories -join ', ')"
    Write-Host "WhatIf mode    : $WhatIfPreference"

    $filesToDelete = @(Get-FilesToDelete -Root $cleanRoot -Patterns $definition.FilePatterns -ExcludedDirectoryNames $ExcludeDirectories)
    $dirsToDelete  = @(Get-DirectoriesToDelete -Root $cleanRoot -DirectoryNames $definition.DirectoryNames -ExcludedDirectoryNames $ExcludeDirectories)

    Write-Host ''
    Write-Host "Files found      : $($filesToDelete.Count)"
    Write-Host "Directories found: $($dirsToDelete.Count)"

    if (($filesToDelete.Count -eq 0) -and ($dirsToDelete.Count -eq 0)) {
        Write-Host ''
        Write-Host 'Nothing to clean.'
        exit 0
    }

    Write-Section "Cleaning"
    $deletedFileCount = Remove-TargetFiles -Files $filesToDelete
    $deletedDirCount  = Remove-TargetDirectories -Directories $dirsToDelete

    Write-Section "Summary"
    Write-Host "Files deleted      : $deletedFileCount"
    Write-Host "Directories deleted: $deletedDirCount"

    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
