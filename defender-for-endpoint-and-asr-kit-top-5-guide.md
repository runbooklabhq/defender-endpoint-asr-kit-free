# Defender for Endpoint and ASR Kit: Top 5

_Version 1.0 (2026-10-28; facts re-read on Microsoft Learn 2026-10-28; validated: quality gate, read-only guard, PowerShell 7.4 parse, Excel recalc)_

Five controls that decide whether Microsoft Defender for Endpoint actually protects your Windows devices: every device onboarded, Defender Antivirus active with cloud protection, tamper protection on, ASR rules rolled out from Audit, and network protection blocking bad domains. Free. Each control has why, steps, impact, rollback, a read-only PowerShell check, how to verify, licence, effort and the Microsoft Learn page it is based on. The checks read the local Defender configuration, so run them on a sample of devices.

Read-only checks: run `defender-for-endpoint-and-asr-kit-top-5-readonly-checks.ps1` (read-only, changes nothing).

| # | Control | Area | Sprint | Priority | Effort |
|---|---|---|---|---|---|
| DE01 | Check every device is onboarded and its sensor is healthy | Onboarding and antivirus baseline | Sprint 1 - Endpoint baseline | Highest | 1 h |
| DE02 | Make sure Defender Antivirus is active with cloud protection and block at first sight | Onboarding and antivirus baseline | Sprint 1 - Endpoint baseline | Highest | 1 h |
| DE03 | Turn on tamper protection tenant-wide | Onboarding and antivirus baseline | Sprint 1 - Endpoint baseline | Highest | 30 min |
| DE04 | Put all ASR rules in Audit and block the three standard protection rules | Attack surface reduction | Sprint 1 - Endpoint baseline | High | 2 h + 2-4 weeks audit |
| DE05 | Turn on network protection (audit, then block) | Network and web protection | Sprint 1 - Endpoint baseline | High | 1 h + 2 weeks audit |

## DE01. Check every device is onboarded and its sensor is healthy

**Why:** A device that is not onboarded, or whose sensor stopped reporting, is invisible to Defender: no alerts, no ASR reports, no response actions. Microsoft calls out impaired communications and missing sensor data as risks that warrant investigation.

**Steps:**
1. Microsoft Defender portal > Reports > Device health and compliance > Sensor health & OS: filter on Inactive, Impaired communications and No sensor data. Export the list.
2. Compare the device count with Intune (or your CMDB): every Windows device you manage should appear in Defender.
3. On a sample device, run the read-only check: the Sense service should be Running and the onboarding status should be 1.
4. Fix each gap (re-run the onboarding package or Intune onboarding policy) and record it in the tracker.

**Impact:** None. Reports and the check only read data.

**Rollback:** Nothing to roll back.

**Check (read-only PowerShell):**

```powershell
Get-Service -Name Sense | Select-Object Name, Status, StartType | Format-List | Out-String; $s = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status' -ErrorAction SilentlyContinue; "OnboardingState (1 = onboarded): $($s.OnboardingState)"
```

**Verify:** No managed Windows device is missing from Defender or shows Inactive / Impaired communications / No sensor data for more than 7 days.

**Licence:** Microsoft Defender for Endpoint Plan 1 or Plan 2, or Defender for Business. Sensor health report: View Data permission under TVM. · **Effort:** 1 h · **Priority:** Highest · **Sprint 1 - Endpoint baseline**

**Microsoft Learn:** https://learn.microsoft.com/en-us/defender-endpoint/device-health-sensor-health-os · https://learn.microsoft.com/en-us/defender-endpoint/troubleshoot-onboarding

## DE02. Make sure Defender Antivirus is active with cloud protection and block at first sight

**Why:** ASR rules, network protection and indicators only work when Defender Antivirus runs in active mode. Block at first sight, which Microsoft says can cut the response time for new malware from hours to seconds, needs cloud protection on and samples sent automatically.

**Steps:**
1. Intune > Endpoint security > Antivirus > Create policy > Windows > Microsoft Defender Antivirus: Allow cloud protection = Allowed; Submit samples consent = Send safe samples automatically (or all samples).
2. Keep real-time protection on and don't disable block at first sight.
3. Assign to all Windows devices.
4. Run the read-only check on sample devices: AMRunningMode should be Normal (active), MAPSReporting 2, SubmitSamplesConsent 1 or 3, DisableBlockAtFirstSeen False.

**Impact:** Files new to Microsoft can be held for a cloud check before they run. Microsoft says 'Never send' for samples stops block at first sight from working.

**Rollback:** Change the Antivirus policy settings back in Intune.

**Check (read-only PowerShell):**

```powershell
Get-MpComputerStatus | Select-Object AMRunningMode, RealTimeProtectionEnabled, AMProductVersion, AntivirusSignatureLastUpdated | Format-List | Out-String; Get-MpPreference | Select-Object MAPSReporting, SubmitSamplesConsent, DisableBlockAtFirstSeen | Format-List | Out-String
```

**Verify:** Sample devices report active mode, real-time protection on, MAPSReporting 2, automatic sample submission and block at first sight not disabled.

**Licence:** Microsoft Defender Antivirus (Windows); management through Intune or another tool. Defender for Endpoint Plan 1/2 or Defender for Business for central reporting. · **Effort:** 1 h · **Priority:** Highest · **Sprint 1 - Endpoint baseline**

**Microsoft Learn:** https://learn.microsoft.com/en-us/defender-endpoint/configure-block-at-first-sight-microsoft-defender-antivirus · https://learn.microsoft.com/en-us/defender-endpoint/edr-in-block-mode

## DE03. Turn on tamper protection tenant-wide

**Why:** Attackers who reach admin rights try to switch off real-time protection or add exclusions first. With tamper protection on, those settings can't be changed on the device, and exclusions can't be added or modified locally.

**Steps:**
1. Microsoft Defender portal > Settings > Endpoints > Advanced features: turn on Tamper protection for the tenant (or use Intune for selected devices).
2. Run the read-only check on sample devices: IsTamperProtected should be True.
3. Tell the desktop team: changes to protected settings may appear to succeed but are silently blocked; use troubleshooting mode for legitimate changes.
4. Note: Microsoft is renaming tamper protection to controlled configuration in management experiences, with no change in behaviour.

**Impact:** Local and Group Policy changes to protected antivirus settings and exclusions are ignored. Changes must come from your management tool or troubleshooting mode.

**Rollback:** Turn tamper protection off in the portal or exclude a device in Intune (this lowers protection; prefer troubleshooting mode).

**Check (read-only PowerShell):**

```powershell
Get-MpComputerStatus | Select-Object IsTamperProtected, RealTimeProtectionEnabled | Format-List
```

**Verify:** IsTamperProtected is True on sample devices of every type.

**Licence:** Defender for Endpoint Plan 1/2, Defender for Business or Microsoft Defender Antivirus (per Learn 'Applies to'). · **Effort:** 30 min · **Priority:** Highest · **Sprint 1 - Endpoint baseline**

**Microsoft Learn:** https://learn.microsoft.com/en-us/defender-endpoint/prevent-changes-to-security-settings-with-tamper-protection

## DE04. Put all ASR rules in Audit and block the three standard protection rules

**Why:** Attack surface reduction rules stop Office macros, scripts and credential theft before they run. Turned on in Block all at once they also stop legitimate tools. Microsoft groups three rules as standard protection; the rest should run in Audit first so you see what would break.

**Steps:**
1. Intune > Endpoint security > Attack surface reduction > create an Attack Surface Reduction Rules policy: all rules on Audit, assigned to all Windows devices.
2. In the same policy set the three standard protection rules to Block: abuse of exploited vulnerable signed drivers (56a863a9-875e-4185-98a7-b882c64b5ce5), credential stealing from LSASS (9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2), persistence through WMI event subscription (e6db77e5-3df2-4cf1-b95a-636979351e5b). Audit them for a week first if you run unusual management tools.
3. Leave the rest in Audit for 2-4 weeks so month-end jobs show up too.
4. Run the read-only check on sample devices to confirm the policy arrived (actions: 0 off, 1 Block, 2 Audit, 6 Warn).

**Impact:** Audit has no user impact. Block on the standard rules rarely affects business apps but can block old drivers or management tools that use WMI persistence. If LSA protection is on, the LSASS rule adds nothing extra.

**Rollback:** Set the rule back to Audit or Not configured in the Intune policy.

**Check (read-only PowerShell):**

```powershell
$p = Get-MpPreference; $ids = @($p.AttackSurfaceReductionRules_Ids); $act = @($p.AttackSurfaceReductionRules_Actions); "ASR rules configured: $($ids.Count)"; for ($i = 0; $i -lt $ids.Count; $i++) { "$($ids[$i]) = $($act[$i])" }
```

**Verify:** Every Windows device reports all ASR rules in Audit (2) and the three standard protection rules in Block (1).

**Licence:** Defender for Endpoint Plan 1/2 or Defender for Business. Advanced hunting for audit events: Plan 2 / E5. · **Effort:** 2 h + 2-4 weeks audit · **Priority:** High · **Sprint 1 - Endpoint baseline**

**Microsoft Learn:** https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference

## DE05. Turn on network protection (audit, then block)

**Why:** Network protection stops apps, not just browsers, from connecting to domains that host phishing, exploits and malware. It is also a prerequisite for web content filtering and indicators in browsers other than Edge.

**Steps:**
1. Intune > Endpoint security > Antivirus > Microsoft Defender Antivirus policy: Enable network protection = Enabled (audit mode) for two weeks.
2. Review blocked-in-audit connections with the security team.
3. Switch to Enabled (block mode).
4. Windows Server: network protection is opt-in (AllowNetworkProtectionOnWinServer); on DNS, file servers and domain controllers set AllowDatagramProcessingOnWinServer to false.

**Impact:** Block mode stops connections to malicious or suspicious domains for every app on the device. Users see a notification.

**Rollback:** Set Enable network protection back to audit mode or Disabled.

**Check (read-only PowerShell):**

```powershell
Get-MpPreference | Select-Object EnableNetworkProtection | Format-List | Out-String; '0 = off, 1 = block, 2 = audit'
```

**Verify:** EnableNetworkProtection is 1 (block) on sample devices after the audit period.

**Licence:** Defender for Endpoint Plan 1/2 (Defender Antivirus active mode with real-time, behaviour monitoring and cloud protection on). Windows 10 1709+ / Windows 11 Pro or Enterprise. · **Effort:** 1 h + 2 weeks audit · **Priority:** High · **Sprint 1 - Endpoint baseline**

**Microsoft Learn:** https://learn.microsoft.com/en-us/defender-endpoint/enable-network-protection

---
Not affiliated with or endorsed by Microsoft. Test every change in Report-only or on a pilot group first. Licence names and portal paths change; check Microsoft Learn if a menu has moved.
