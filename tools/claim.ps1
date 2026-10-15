# Dang ky / giai phong claim chong dam chan (xem .agents/COLLAB.md).
# Dung:
#   tools/claim.ps1 -Owner "ten-agent" -Id "T2.01-neon-env" -Paths "vfx/" -Branch "feature/t2-01" -Status active
#   tools/claim.ps1 -Owner "ten-agent" -Id "T2.01-neon-env" -Status done   # sau khi PR merge
param(
  [Parameter(Mandatory=$true)][string]$Owner,
  [Parameter(Mandatory=$true)][string]$Id,
  [string]$Paths = "",
  [string]$Branch = "",
  [ValidateSet("active","done")][string]$Status = "active"
)
$ErrorActionPreference = "Stop"
$File = Join-Path (Split-Path -Parent $PSScriptRoot) ".agents\ownership.json"
if (-not (Test-Path -LiteralPath $File)) {
  Write-Error "Khong thay $File"
}
$data = (Get-Content -Raw -LiteralPath $File) | ConvertFrom-Json
if ($data.claims -eq $null) { $data | Add-Member -NotePropertyName "claims" -NotePropertyValue @() }

function Norm-Path([string]$p) { return $p.Trim().TrimEnd("/") }

$existing = $data.claims | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if ($existing -ne $null) {
  $existing.status = $Status
  if ($Owner -ne "") { $existing.owner = $Owner }
  if ($Branch -ne "") { $existing.branch = $Branch }
  if ($Paths -ne "") { $existing.paths = @($Paths.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) }
  $existing.updated = (Get-Date).ToString("yyyy-MM-dd")
  Write-Host "Da cap nhat claim '$Id' -> $Status"
} else {
  if ($Paths -eq "") { Write-Error "Claim moi bat buoc co -Paths (vd. -Paths 'vfx/,components/spike_hazard.tscn')" }
  $claim = [pscustomobject]@{
    id = $Id
    owner = $Owner
    branch = $Branch
    paths = @($Paths.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    status = $Status
    updated = (Get-Date).ToString("yyyy-MM-dd")
  }
  $data.claims += $claim
  Write-Host "Da them claim '$Id' ($Status)"
}

# Canh bao overlap voi claim active khac (test tu dong se do neu co overlap that)
if ($Status -eq "active") {
  $mine = $data.claims | Where-Object { $_.id -eq $Id } | Select-Object -First 1
  foreach ($c in $data.claims) {
    if (($c.id -eq $Id) -or ($c.status -ne "active")) { continue }
    foreach ($x in $mine.paths) {
      foreach ($y in $c.paths) {
        $nx = Norm-Path($x); $ny = Norm-Path($y)
        if (($nx -eq $ny) -or $nx.StartsWith($ny + "/") -or $ny.StartsWith($nx + "/")) {
          Write-Warning ("Overlap voi claim active '{0}' cua '{1}' tai '{2}' <> '{3}'" -f $c.id, $c.owner, $x, $y)
        }
      }
    }
  }
}

$data | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $File -Encoding UTF8
Write-Host "Da ghi $File"
