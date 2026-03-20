# tests/PSScriptAnalyzerSettings.psd1
# PSScriptAnalyzer settings for delphi-clean.

@{
  ExcludeRules = @(
    # This is a script tool rather than a public module API.
    'PSUseOutputTypeCorrectly'
    'PSAvoidUsingWriteHost',
    'PSUseShouldProcessForStateChangingFunctions',
    'PSUseSingularNouns'
  )
}
