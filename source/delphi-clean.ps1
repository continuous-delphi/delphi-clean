#requires -Version 5.1

<#
.SYNOPSIS
Cleans Delphi build artifacts from a repository tree using three cleanup levels.

.DESCRIPTION
Targets the current working directory by default.
Supports three cleanup levels:

  basic  - safe, low-risk cleanup of common transient files
  standard - removes build outputs and common generated files
  deep  - aggressive cleanup including user-local IDE state files

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level standard

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level deep -Verbose

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level deep -WhatIf

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level standard -PassThru

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level standard -Json

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level basic -IncludeFilePattern '*.res'

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level basic -IncludeFilePattern '*.res','*.mab' -ExcludeDirectoryPattern 'assets','vendor*'

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Version

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Version -Format json

.EXAMPLE
powershell.exe -File .\delphi-clean.ps1 -Level standard -RecycleBin
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Clean')]
param(
    [Parameter(ParameterSetName = 'Version', Mandatory)]
    [switch]$Version,

    [Parameter(ParameterSetName = 'Version')]
    [ValidateSet('text', 'json')]
    [string]$Format = 'text',

    [Parameter(ParameterSetName = 'Clean')]
    [ValidateSet('basic', 'standard', 'deep')]
    [string]$Level = 'basic',

    [Parameter(ParameterSetName = 'Clean')]
    [string]$RootPath,

    [Parameter(ParameterSetName = 'Clean')]
    [string[]]$ExcludeDirectoryPattern = @(
        '.git',
        '.vs',
        '.claude'
    ),

    [Parameter(ParameterSetName = 'Clean')]
    [string[]]$IncludeFilePattern = @(),

    [Parameter(ParameterSetName = 'Clean')]
    [switch]$PassThru,

    [Parameter(ParameterSetName = 'Clean')]
    [switch]$Json,

    [Parameter(ParameterSetName = 'Clean')]
    [switch]$RecycleBin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ToolVersion = '0.7.0'

if ($Version) {
    if ($Format -eq 'json') {
        [PSCustomObject]@{
            ok      = $true
            command = 'version'
            tool    = [PSCustomObject]@{
                name    = 'delphi-clean'
                version = $ToolVersion
            }
        } | ConvertTo-Json -Depth 3 -Compress
    }
    else {
        Write-Output "delphi-clean $ToolVersion"
    }
    exit 0
}

function Write-Section {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($Json) {
        return
    }

    Write-Information '' -InformationAction Continue
    Write-Information ('=' * 70) -InformationAction Continue
    Write-Information $Message -InformationAction Continue
    Write-Information ('=' * 70) -InformationAction Continue
}

function Get-TrashDestination {
    param(
        [Parameter(Mandatory)]
        [string]$TrashFilesDir,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $dest = Join-Path $TrashFilesDir $Name
    if (-not (Test-Path -LiteralPath $dest)) {
        return $dest
    }

    $base    = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    $ext     = [System.IO.Path]::GetExtension($Name)
    $counter = 2
    do {
        $uniqueName = if ($ext) { "$base $counter$ext" } else { "$Name $counter" }
        $dest = Join-Path $TrashFilesDir $uniqueName
        $counter++
    } while (Test-Path -LiteralPath $dest)

    return $dest
}

function Send-ToMacTrash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $trashDir = Join-Path $HOME '.Trash'
    if (-not (Test-Path -LiteralPath $trashDir)) {
        New-Item -ItemType Directory -Path $trashDir | Out-Null
    }

    $name = Split-Path -Path $Path -Leaf
    $dest = Get-TrashDestination -TrashFilesDir $trashDir -Name $name
    Move-Item -LiteralPath $Path -Destination $dest
}

function Send-ToLinuxTrash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $trashRoot = Join-Path $HOME '.local/share/Trash'
    $filesDir  = Join-Path $trashRoot 'files'
    $infoDir   = Join-Path $trashRoot 'info'

    foreach ($dir in @($filesDir, $infoDir)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
    }

    $name      = Split-Path -Path $Path -Leaf
    $destPath  = Get-TrashDestination -TrashFilesDir $filesDir -Name $name
    $destName  = Split-Path -Path $destPath -Leaf
    $infoFile  = Join-Path $infoDir "$destName.trashinfo"
    $absPath   = [System.IO.Path]::GetFullPath($Path)
    $timestamp = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')

    $trashInfoContent = "[Trash Info]`nPath=$absPath`nDeletionDate=$timestamp`n"
    [System.IO.File]::WriteAllText($infoFile, $trashInfoContent)

    try {
        Move-Item -LiteralPath $Path -Destination $destPath
    }
    catch {
        Remove-Item -LiteralPath $infoFile -Force -ErrorAction SilentlyContinue
        throw
    }
}

function Send-ToRecycleBin {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('File', 'Directory')]
        [string]$Type
    )

    if ($IsWindows) {
        Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
        if ($Type -eq 'File') {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $Path,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )
        }
        else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                $Path,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )
        }
    }
    elseif ($IsMacOS) {
        Send-ToMacTrash -Path $Path
    }
    elseif ($IsLinux) {
        Send-ToLinuxTrash -Path $Path
    }
    else {
        throw 'Unsupported platform for -RecycleBin.'
    }
}

function Get-RelativePathCompat {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$TargetPath
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath)
    $targetFull = [System.IO.Path]::GetFullPath($TargetPath)

    if (-not $baseFull.EndsWith([string][System.IO.Path]::DirectorySeparatorChar)) {
        $baseFull += [string][System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = New-Object System.Uri($baseFull)
    $targetUri = New-Object System.Uri($targetFull)
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString()) -replace '/', [System.IO.Path]::DirectorySeparatorChar

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        return '.'
    }

    return $relativePath
}

function Resolve-CleanRoot {
    param(
        [string]$InputRoot
    )

    if ([string]::IsNullOrWhiteSpace($InputRoot)) {
        return (Get-Location).Path
    }

    $resolvedInput = Resolve-Path $InputRoot
    return $resolvedInput.Path
}

function Test-SafeCleanRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    $rootOfRoot = [System.IO.Path]::GetPathRoot($fullRoot)

    if ($fullRoot -eq $rootOfRoot) {
        throw "Refusing to clean an unsafe root path: $fullRoot"
    }

    $resolved = Resolve-Path -LiteralPath $fullRoot
    if (-not $resolved) {
      throw "Invalid root path: $fullRoot"
    }
}

function Test-PathUnderExcludedDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$FullName,

        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirPatterns
    )

    $relative = Get-RelativePathCompat -BasePath $Root -TargetPath $FullName

    if ($relative -eq '.') {
        return $false
    }

    $parts = $relative -split '[\\\/]'
    foreach ($part in $parts) {
        foreach ($pattern in $ExcludedDirPatterns) {
            if ($part -ilike $pattern) {
                return $true
            }
        }
    }

    return $false
}

function Get-LevelDefinition {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('basic', 'standard', 'deep')]
        [string]$Name
    )

    # --- base (basic) ---
    $basicFiles = @(
        '*.dcu',
        '*.identcache',
        '*.bak',
        '*.tmp',
        '*.dsk',
        '*.tvsconfig',
        '*.stat'
    )

    $basicDirs = @(
        '__history'
    )

    # --- standard additions ---
    $standardFilesExtra = @(
        '*.drc',
        '*.map',
        '*.rsm',
        '*.tds',
        '*.bpl',
        '*.dcp',
        '*.bpi',
        '*.so',
        '*.exe',
        '*.hpp',
        '*.dres',
        '*.ilc',
        '*.ild',
        '*.ilf',
        '*.ipu',
        '*.ddp',
        '*.prjmgc',
        '*.vlb',
        'dunitx-results.xml'
    )

    $standardDirsExtra = @(
        'Win32',
        'Win64',
        'Debug',
        'Release',
        'OSX64',
        'OSXARM64',
        'Android',
        'Android64',
        'iOSDevice64',
        'Linux64',
        'TMSWeb'
    )

    # --- deep additions ---
    $deepFilesExtra = @(
        '*.local',
        '*.dproj.local',
        '*.groupproj.local',
        '*.projdata',
        '*.~*',
        '*.lib',
        '*.fbpInf',
        '*.fbl8',
        '*.fbpbrk',
        '*.fb8lck',
        'TestInsightSettings.ini'
    )

    $deepDirsExtra = @(
        '__recovery'
    )

    # --- compose ---
    switch ($Name) {
        'basic' {
            $files = $basicFiles
            $dirs  = $basicDirs
        }

        'standard' {
            $files = $basicFiles + $standardFilesExtra
            $dirs  = $basicDirs + $standardDirsExtra
        }

        'deep' {
            $files = $basicFiles + $standardFilesExtra + $deepFilesExtra
            $dirs  = $basicDirs + $standardDirsExtra + $deepDirsExtra
        }
    }

    # --- dedupe ---
    $files = $files | Sort-Object -Unique
    $dirs  = $dirs  | Sort-Object -Unique

    return @{
        FilePatterns  = $files
        DirectoryNames = $dirs
    }
}

function Get-FilesToDelete {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$Patterns,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirPatterns
    )

    Write-Verbose 'Scanning for matching files.'

    $allFiles = Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            -not (Test-PathUnderExcludedDirectory -FullName $_.FullName -Root $Root -ExcludedDirPatterns $ExcludedDirPatterns)
        }

    $allFiles |
        Where-Object {
            $file = $_
            foreach ($pattern in $Patterns) {
                if ($file.Name -like $pattern) {
                    return $true
                }
            }
            return $false
        } |
        Sort-Object -Property FullName -Unique
}

function Get-DirectoriesToDelete {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$DirectoryNames,

        [Parameter(Mandatory)]
        [string[]]$ExcludedDirPatterns
    )

    Write-Verbose 'Scanning for matching directories.'

    $nameSet = @{}
    foreach ($dirName in $DirectoryNames) {
        $nameSet[$dirName.ToUpperInvariant()] = $true
    }

    Get-ChildItem -Path $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $nameSet.ContainsKey($_.Name.ToUpperInvariant()) -and
            -not (Test-PathUnderExcludedDirectory -FullName $_.FullName -Root $Root -ExcludedDirPatterns $ExcludedDirPatterns)
        } |
        Sort-Object -Property FullName -Unique |
        Sort-Object -Property { $_.FullName.Length } -Descending
}

function ConvertTo-DeletionRecord {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('File', 'Directory')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [bool]$Deleted
    )

    [PSCustomObject]@{
        Type    = $Type
        Path    = $Path
        Deleted = $Deleted
    }
}

function Remove-FileList {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [System.IO.FileInfo[]]$Files = @(),
        [switch]$ReturnRecords,
        [switch]$RecycleBin
    )

    $result = [PSCustomObject]@{
        DeletedCount = 0
        FailedCount  = 0
        Records      = New-Object System.Collections.Generic.List[object]
    }

    if (@($Files).Count -eq 0) {
        return $result
    }

    $action = if ($RecycleBin) { 'Recycle file' } else { 'Delete file' }
    $verb   = if ($RecycleBin) { 'Recycled' } else { 'Deleted' }

    foreach ($file in $Files) {
        Write-Verbose "Evaluating file: $($file.FullName)"

        if ($PSCmdlet.ShouldProcess($file.FullName, $action)) {
            try {
                if ($RecycleBin) {
                    Send-ToRecycleBin -Path $file.FullName -Type 'File'
                }
                else {
                    Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                }
                $result.DeletedCount++
                Write-Information "$verb file: $($file.FullName)" -InformationAction Continue

                if ($ReturnRecords) {
                    $result.Records.Add((ConvertTo-DeletionRecord -Type File -Path $file.FullName -Deleted $true))
                }
            }
            catch {
                $result.FailedCount++
                Write-Warning "Failed to $($action.ToLower()): $($file.FullName) - $($_.Exception.Message)"

                if ($ReturnRecords) {
                    $result.Records.Add((ConvertTo-DeletionRecord -Type File -Path $file.FullName -Deleted $false))
                }
            }
        }
        elseif ($WhatIfPreference) {
            Write-Information "Would $($action.ToLower()): $($file.FullName)" -InformationAction Continue
            if ($ReturnRecords) {
                $result.Records.Add((ConvertTo-DeletionRecord -Type File -Path $file.FullName -Deleted $false))
            }
        }
    }

    return $result
}

function Remove-DirectoryList {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [System.IO.DirectoryInfo[]]$Directories = @(),
        [switch]$ReturnRecords,
        [switch]$RecycleBin
    )

    $result = [PSCustomObject]@{
        DeletedCount = 0
        FailedCount  = 0
        Records      = New-Object System.Collections.Generic.List[object]
    }

    if (@($Directories).Count -eq 0) {
        return $result
    }

    $action = if ($RecycleBin) { 'Recycle directory' } else { 'Delete directory' }
    $verb   = if ($RecycleBin) { 'Recycled' } else { 'Deleted' }

    foreach ($dir in $Directories) {
        if (-not (Test-Path -LiteralPath $dir.FullName)) {
            continue
        }

        Write-Verbose "Evaluating directory: $($dir.FullName)"

        if ($PSCmdlet.ShouldProcess($dir.FullName, $action)) {
            try {
                if ($RecycleBin) {
                    Send-ToRecycleBin -Path $dir.FullName -Type 'Directory'
                }
                else {
                    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction Stop
                }

                # Verify the directory is actually gone. On some PowerShell versions
                # Remove-Item -Recurse can silently partial-succeed when a handle is open
                # (e.g. an open shell session in the directory), deleting children but
                # leaving the directory itself without throwing.
                if (Test-Path -LiteralPath $dir.FullName) {
                    throw "Directory still exists after removal attempt (a process may have an open handle): $($dir.FullName)"
                }

                $result.DeletedCount++
                Write-Information "$verb directory: $($dir.FullName)" -InformationAction Continue

                if ($ReturnRecords) {
                    $result.Records.Add((ConvertTo-DeletionRecord -Type Directory -Path $dir.FullName -Deleted $true))
                }
            }
            catch {
                $result.FailedCount++
                Write-Warning "Failed to $($action.ToLower()): $($dir.FullName) - $($_.Exception.Message)"

                if ($ReturnRecords) {
                    $result.Records.Add((ConvertTo-DeletionRecord -Type Directory -Path $dir.FullName -Deleted $false))
                }
            }
        }
        elseif ($WhatIfPreference) {
            Write-Information "Would $($action.ToLower()): $($dir.FullName)" -InformationAction Continue
            if ($ReturnRecords) {
                $result.Records.Add((ConvertTo-DeletionRecord -Type Directory -Path $dir.FullName -Deleted $false))
            }
        }
    }

    return $result
}

try {
    $cleanRoot = Resolve-CleanRoot -InputRoot $RootPath
    Test-SafeCleanRoot -Root $cleanRoot

    $definition = Get-LevelDefinition -Name $Level
    $mode = if ($WhatIfPreference) { 'WhatIf (no changes)' } else { 'Execute' }
    $disposition = if ($RecycleBin) { 'Recycle Bin' } else { 'Permanent' }
    $returnRecords = ($PassThru -or $Json)

    $allFilePatterns = @($definition.FilePatterns) + @($IncludeFilePattern) | Sort-Object -Unique

    Write-Section 'Delphi Clean'

    if (-not $Json) {
        Write-Information ('Level           : {0}' -f $Level) -InformationAction Continue
        Write-Information ('Root            : {0}' -f $cleanRoot) -InformationAction Continue
        Write-Information ('Excluded dirs   : {0}' -f ($ExcludeDirectoryPattern -join ', ')) -InformationAction Continue
        if ($IncludeFilePattern.Count -gt 0) {
            Write-Information ('Extra patterns  : {0}' -f ($IncludeFilePattern -join ', ')) -InformationAction Continue
        }
        Write-Information ('Mode            : {0}' -f $mode) -InformationAction Continue
        Write-Information ('Disposition     : {0}' -f $disposition) -InformationAction Continue
    }

    $filesToDelete = @(Get-FilesToDelete -Root $cleanRoot -Patterns $allFilePatterns -ExcludedDirPatterns $ExcludeDirectoryPattern)
    $dirsToDelete  = @(Get-DirectoriesToDelete -Root $cleanRoot -DirectoryNames $definition.DirectoryNames -ExcludedDirPatterns $ExcludeDirectoryPattern)

    if (-not $Json) {
        Write-Information '' -InformationAction Continue
        Write-Information ('Files found      : {0}' -f $filesToDelete.Count) -InformationAction Continue
        Write-Information ('Directories found: {0}' -f $dirsToDelete.Count) -InformationAction Continue
    }

    if (($filesToDelete.Count -eq 0) -and ($dirsToDelete.Count -eq 0)) {

        if ($Json) {
            [PSCustomObject]@{
                Level               = $Level
                Root                = $cleanRoot
                ExcludeDirectoryPattern = @($ExcludeDirectoryPattern)
                IncludeFilePattern      = @($IncludeFilePattern)
                Mode                    = $mode
                Disposition             = $disposition
                RecycleBin              = $RecycleBin.IsPresent
                FilesFound              = 0
                DirectoriesFound    = 0
                FilesDeleted        = 0
                DirectoriesDeleted  = 0
                FilesFailed         = 0
                DirectoriesFailed   = 0
                Items               = @()
            } | ConvertTo-Json -Depth 5
        }
        else {
            Write-Information '' -InformationAction Continue
            Write-Information 'Nothing to clean.' -InformationAction Continue
        }

        Write-Verbose 'Exit code = 0'
        exit 0
    }

    Write-Section 'Cleaning'
    $fileRemovalResult = Remove-FileList -Files $filesToDelete -ReturnRecords:$returnRecords -RecycleBin:$RecycleBin
    $dirRemovalResult  = Remove-DirectoryList -Directories $dirsToDelete -ReturnRecords:$returnRecords -RecycleBin:$RecycleBin

    $allRecords = New-Object System.Collections.Generic.List[object]
    $allRecords.AddRange([object[]]$fileRemovalResult.Records)
    $allRecords.AddRange([object[]]$dirRemovalResult.Records)

    $totalFailed = $fileRemovalResult.FailedCount + $dirRemovalResult.FailedCount

    if ($Json) {
        [PSCustomObject]@{
            Level               = $Level
            Root                = $cleanRoot
            ExcludeDirectoryPattern = @($ExcludeDirectoryPattern)
            IncludeFilePattern      = @($IncludeFilePattern)
            Mode                    = $mode
            Disposition         = $disposition
            RecycleBin          = $RecycleBin.IsPresent
            FilesFound          = $filesToDelete.Count
            DirectoriesFound    = $dirsToDelete.Count
            FilesDeleted        = $fileRemovalResult.DeletedCount
            DirectoriesDeleted  = $dirRemovalResult.DeletedCount
            FilesFailed         = $fileRemovalResult.FailedCount
            DirectoriesFailed   = $dirRemovalResult.FailedCount
            Items               = $allRecords
        } | ConvertTo-Json -Depth 5
    }
    else {
        $removedLabel = if ($RecycleBin) { 'recycled' } else { 'deleted' }
        Write-Section 'Summary'

        if ($WhatIfPreference) {
            Write-Information ('Files would be {0}     : {1}' -f $removedLabel, $filesToDelete.Count) -InformationAction Continue
            Write-Information ('Directories would be {0}: {1}' -f $removedLabel, $dirsToDelete.Count) -InformationAction Continue
        }
        else {
            Write-Information ('Files {0}               : {1}' -f $removedLabel, $fileRemovalResult.DeletedCount) -InformationAction Continue
            Write-Information ('Directories {0}         : {1}' -f $removedLabel, $dirRemovalResult.DeletedCount) -InformationAction Continue

            if ($totalFailed -gt 0) {
                Write-Warning ('Items failed to {0}: {1}' -f $removedLabel, $totalFailed)
            }
        }
    }

    if ($PassThru -and -not $Json) {
        $allRecords
    }

    # Exit codes:
    #   0 = success: every matched item was removed (or WhatIf run, or nothing to clean)
    #   1 = fatal:   unhandled exception before or during the scan phase - bad root path,
    #                unsupported platform for -RecycleBin, scan error, etc. (catch block below)
    #   2 = partial: the script reached the removal phase but at least one item could not
    #                be deleted or recycled; successfully removed items are not rolled back
    if ($totalFailed -gt 0) {
      Write-Verbose 'Exit code = 2'
      exit 2
    }

    Write-Verbose 'Exit code = 0'
    exit 0
}
catch {
    Write-Error -ErrorRecord $_
    Write-Verbose 'Exit code = 1'
    exit 1
}
