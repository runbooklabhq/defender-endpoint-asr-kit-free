<#
 Defender for Endpoint and ASR Kit: Top 5 - read-only checks (Runbook Lab)
 Read-only: Get-* cmdlets only (Get-MpComputerStatus, Get-MpPreference, Get-Service, Get-ItemProperty). Changes nothing. Run in an elevated PowerShell on a sample device.
 Requires: Windows with Microsoft Defender Antivirus (Defender PowerShell module is built in). No tenant connection.
 Run on 3-5 sample devices per device type (laptops, kiosks, servers) as administrator.
 Tenant-wide views are in the Microsoft Defender portal (Reports > Device health; Advanced hunting) as described in each control.
 Output: .\hardening-check-results.csv (ID, Control, Status, Output).
#>
$ErrorActionPreference = 'Stop'
$results = @()
function Invoke-Check($Id, $Title, [scriptblock]$Block) {
  try { $o = & $Block | Out-String -Width 400; $s = 'OK' } catch { $o = $_.Exception.Message; $s = 'ERROR' }
  Write-Host "[$Id] $Title -> $s"
  $script:results += [pscustomobject]@{ ID = $Id; Control = $Title; Status = $s; Output = $o.Trim() }
}

Invoke-Check 'DE01' 'Check every device is onboarded and its sensor is healthy' { Get-Service -Name Sense | Select-Object Name, Status, StartType | Format-List | Out-String; $s = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status' -ErrorAction SilentlyContinue; "OnboardingState (1 = onboarded): $($s.OnboardingState)" }
Invoke-Check 'DE02' 'Make sure Defender Antivirus is active with cloud protection and block at first sight' { Get-MpComputerStatus | Select-Object AMRunningMode, RealTimeProtectionEnabled, AMProductVersion, AntivirusSignatureLastUpdated | Format-List | Out-String; Get-MpPreference | Select-Object MAPSReporting, SubmitSamplesConsent, DisableBlockAtFirstSeen | Format-List | Out-String }
Invoke-Check 'DE03' 'Turn on tamper protection tenant-wide' { Get-MpComputerStatus | Select-Object IsTamperProtected, RealTimeProtectionEnabled | Format-List }
Invoke-Check 'DE04' 'Put all ASR rules in Audit and block the three standard protection rules' { $p = Get-MpPreference; $ids = @($p.AttackSurfaceReductionRules_Ids); $act = @($p.AttackSurfaceReductionRules_Actions); "ASR rules configured: $($ids.Count)"; for ($i = 0; $i -lt $ids.Count; $i++) { "$($ids[$i]) = $($act[$i])" } }
Invoke-Check 'DE05' 'Turn on network protection (audit, then block)' { Get-MpPreference | Select-Object EnableNetworkProtection | Format-List | Out-String; '0 = off, 1 = block, 2 = audit' }

$results | Export-Csv -NoTypeInformation -Encoding UTF8 .\hardening-check-results.csv
Write-Host "Done: $($results.Count) checks -> hardening-check-results.csv"
