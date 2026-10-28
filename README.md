# Defender for Endpoint and ASR Kit: Top 5 (free)

Defender for Endpoint only protects a Windows device when five things are true: the device is onboarded and reporting, Defender Antivirus runs in active mode with cloud protection, tamper protection stops attackers switching it off, attack surface reduction (ASR) rules are rolled out, and network protection blocks bad domains. This kit checks those five and turns them into a project.

| File | What it is |
|---|---|
| `defender-for-endpoint-and-asr-kit-top-5-guide.md` | Why, steps, impact, rollback, check, verify, licence, effort and the Microsoft Learn source for each control |
| `defender-for-endpoint-and-asr-kit-top-5-jira-import.csv` | Jira Cloud import: epics + stories with parent links, priority, sprint and labels |
| `defender-for-endpoint-and-asr-kit-top-5-tracker.csv` | Same backlog for Planner, Azure DevOps, Excel or Linear |
| `defender-for-endpoint-and-asr-kit-top-5-project-plan.xlsx` | Excel project plan for teams without Jira: owner, dates, status drop-down, % complete and a progress dashboard |
| `defender-for-endpoint-and-asr-kit-top-5-readonly-checks.ps1` | Get-* cmdlets only, run locally on a sample device. Changes nothing. Writes `hardening-check-results.csv` |

| # | Control |
|---|---|
| DE01 | Check every device is onboarded and its sensor is healthy |
| DE02 | Make sure Defender Antivirus is active with cloud protection and block at first sight |
| DE03 | Turn on tamper protection tenant-wide |
| DE04 | Put all ASR rules in Audit and block the three standard protection rules |
| DE05 | Turn on network protection (audit, then block) |

## Run the checks
On 3-5 sample Windows devices per device type, in an elevated PowerShell:
```powershell
./defender-for-endpoint-and-asr-kit-top-5-readonly-checks.ps1
```
No tenant connection is needed; the script reads the local Defender configuration. Tenant-wide views (sensor health, ASR events) are in the Microsoft Defender portal as described in the guide.

## Scope and limits
- Built from Microsoft Learn pages re-read on 28 October 2026 (links in the guide). Validated before release: every control has why, steps, impact, rollback, verify, licence and a Learn source; the script contains read commands only and parses cleanly in PowerShell 7.4; the Excel plan recalculates with no errors. If a check misreads your setup, open an issue.
- Free step-by-step page for the ASR rollout: https://runbooklabhq.github.io/guide-defender-asr-rules-audit-to-block.html

## Complete kit
All 15 controls plus ASR rings and hunting queries: https://runbooklab.gumroad.com/l/defender-asr-kit?utm_source=github&utm_campaign=mde-free-repo

MIT licence. Not affiliated with or endorsed by Microsoft. Test changes on IT devices first, then a pilot ring.
