<#
  setup-dns.ps1  —  Point cigmas.org at the live GitHub Pages site.

  The site is ALREADY built, hosted, and verified on GitHub Pages
  (repo: gamesforloveorg/cigmas-site, custom domain: cigmas.org).
  The ONLY thing left is DNS. This script does it for you via the
  Porkbun API. It only touches the apex A/ALIAS records and the
  www record — it leaves MX, TXT, and everything else untouched.

  HOW TO GET KEYS (one-time, ~2 min):
    1. Porkbun -> Account -> "API Access" -> create an API key.
       You'll get an API key (pk1_...) and a secret key (sk1_...).
    2. Porkbun -> Domain Management -> cigmas.org -> "Details" ->
       toggle "API Access" to ON for this domain.
    3. ALSO on cigmas.org: turn OFF "URL Forwarding" if it is on
       (that is what currently points www -> pixie.porkbun.com).

  RUN:
    powershell -ExecutionPolicy Bypass -File .\setup-dns.ps1 -ApiKey "pk1_xxx" -SecretKey "sk1_xxx"
#>

param(
  [Parameter(Mandatory = $true)][string]$ApiKey,
  [Parameter(Mandatory = $true)][string]$SecretKey
)

$ErrorActionPreference = "Stop"
$domain   = "cigmas.org"
$base     = "https://api.porkbun.com/api/json/v3"
$ghIPs    = @("185.199.108.153","185.199.109.153","185.199.110.153","185.199.111.153")
$wwwTarget = "gamesforloveorg.github.io"

function Invoke-Pb($path, $extra = @{}) {
  $body = @{ apikey = $ApiKey; secretapikey = $SecretKey }
  foreach ($k in $extra.Keys) { $body[$k] = $extra[$k] }
  $json = $body | ConvertTo-Json -Compress
  return Invoke-RestMethod -Method Post -Uri "$base/$path" -Body $json -ContentType "application/json"
}

Write-Host "Verifying credentials..." -ForegroundColor Cyan
$ping = Invoke-Pb "ping"
if ($ping.status -ne "SUCCESS") { throw "Auth failed: $($ping.message)" }
Write-Host ("  OK (your IP: {0})" -f $ping.yourIp) -ForegroundColor Green

Write-Host "Reading existing records..." -ForegroundColor Cyan
$records = (Invoke-Pb "dns/retrieve/$domain").records

# Delete only apex A/ALIAS/CNAME and the www A/ALIAS/CNAME (preserve MX, TXT, CAA, NS, SOA).
$toKill = $records | Where-Object {
  ($_.type -in @("A","ALIAS","CNAME")) -and
  ($_.name -eq $domain -or $_.name -eq "www.$domain")
}
foreach ($r in $toKill) {
  Write-Host ("  deleting {0,-6} {1} -> {2}" -f $r.type, $r.name, $r.content) -ForegroundColor Yellow
  Invoke-Pb "dns/delete/$domain/$($r.id)" | Out-Null
}

Write-Host "Creating GitHub Pages apex A records..." -ForegroundColor Cyan
foreach ($ip in $ghIPs) {
  Invoke-Pb "dns/create/$domain" @{ name = ""; type = "A"; content = $ip; ttl = "600" } | Out-Null
  Write-Host ("  + A   @   -> {0}" -f $ip) -ForegroundColor Green
}

Write-Host "Creating www CNAME..." -ForegroundColor Cyan
Invoke-Pb "dns/create/$domain" @{ name = "www"; type = "CNAME"; content = $wwwTarget; ttl = "600" } | Out-Null
Write-Host ("  + CNAME www -> {0}" -f $wwwTarget) -ForegroundColor Green

Write-Host "`nDone. DNS updated. Propagation is usually minutes (up to ~1 hour)." -ForegroundColor Green
Write-Host "Then visit https://cigmas.org  (GitHub auto-issues the HTTPS cert once DNS resolves)." -ForegroundColor Green
Write-Host "`nFinal record set:" -ForegroundColor Cyan
(Invoke-Pb "dns/retrieve/$domain").records |
  Where-Object { $_.type -in @("A","CNAME","ALIAS") } |
  Format-Table type, name, content, ttl -AutoSize
