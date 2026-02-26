<#
.SYNOPSIS
    This PowerShell script configures the 'Deny access to this computer from the network' user right.
.NOTES
    Author          : Symone-Marie Priester
    LinkedIn        : linkedin.com/in/symone-mariepriester
    GitHub          : github.com/Symone-Marie
    Date Created    : 2026-02-25
    Last Modified   : 2026-02-25
    Version         : Microsoft Windows [Version 10.0.26200.7623]
    CVEs            : N/A
    Vuln-ID         : V-253491
    STIG-ID         : WN11-UR-000070
.TESTED ON
    Date(s) Tested  : 2026-02-25
    Tested By       : Symone-Marie Priester
    Systems Tested  : Windows 11 Pro OS
    PowerShell Ver. : 5.1
    Manual Test     : Yes, remediated via Local Group Policy Editor (gpedit.msc) with screenshot documentation
.USAGE
    Configures the 'Deny access to this computer from the network' user right to include
    required accounts per STIG guidance.
    Example syntax:
    PS C:\> .\remediation_WN11-UR-000070.ps1
#>

Write-Host "Configuring Deny access to this computer from the network user right..."

# Export current security policy
secedit /export /cfg "$env:TEMP\secpol.cfg" | Out-Null

# Read the current config
$secpol = Get-Content "$env:TEMP\secpol.cfg"

# Define the setting and required accounts
$settingName = "SeDenyNetworkLogonRight"
$requiredAccounts = "*S-1-5-32-546,*S-1-2-0"  # Guests, Local account

# Check if setting exists and update it
if ($secpol -match $settingName) {
    $secpol = $secpol -replace "($settingName\s*=.*)", "$settingName = $requiredAccounts"
    Write-Host "Updated existing $settingName entry"
} else {
    $secpol += "`r`n$settingName = $requiredAccounts"
    Write-Host "Added new $settingName entry"
}

# Write updated config back
$secpol | Set-Content "$env:TEMP\secpol.cfg"

# Apply the updated security policy
secedit /configure /db secedit.sdb /cfg "$env:TEMP\secpol.cfg" /areas USER_RIGHTS

# Verify the change
Write-Host "`nVerifying configuration..."
secedit /export /cfg "$env:TEMP\secpol_verify.cfg" | Out-Null
$verify = Get-Content "$env:TEMP\secpol_verify.cfg" | Select-String $settingName

if ($verify) {
    Write-Host "SUCCESS: WN11-UR-000070 remediated - Deny access to this computer from the network is configured" -ForegroundColor Green
    Write-Host "`nCurrent setting:"
    Write-Host $verify
} else {
    Write-Host "ERROR: Failed to configure user right" -ForegroundColor Red
}

# Apply Group Policy changes immediately
Write-Host "`nApplying Group Policy update..."
gpupdate /force
