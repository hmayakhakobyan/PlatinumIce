<#
.SYNOPSIS
    Platinum Ice local asset sync - imports new files from the local asset
    inbox into the WordPress Media Library, deduplicated by content hash.

.DESCRIPTION
    Scans an asset inbox tree (00-INBOX\<Category>\...), computes a SHA-256
    for every supported file, skips anything already recorded in the local
    manifest (dev-tools/asset-sync.local.json, gitignored), and imports
    everything new via WP-CLI (`wp media import`). Records the resulting
    WordPress attachment ID/URL/category/source filename/hash/timestamp back
    into the manifest.

    This script only imports into the Media Library - it never assigns an
    asset to an Elementor element. Assigning an imported asset to a specific
    section (e.g. the hero) is a separate, explicit, surgical step.

    Safe to re-run at any time: already-imported files (by content hash) are
    skipped, never re-imported, and never overwrite existing WordPress state.

    SEO-FRIENDLY FILENAMES: the user's original file in 00-INBOX is never
    renamed, moved, or modified. Instead, a normalized "platinum-ice-..."
    filename is computed and the file is imported from a temporary copy
    under that name, so the file that lands in WordPress's Media Library
    (and its URL) uses the clean name while the original on disk is
    untouched. The normalized name is derived ONLY from words already
    present in the original filename (mechanical cleanup: lowercased,
    hyphenated, camera/generic junk tokens like "img"/"dsc"/"screenshot"
    stripped) plus the category - it never invents a subject/description
    that isn't already in the filename. If nothing usable survives that
    cleanup, the fallback name uses the category plus a short hash
    fragment (e.g. platinum-ice-hero-3f9a2b1c.jpg) rather than guessing.
    Alt text is never auto-generated here - see docs/HOMEPAGE-ASSET-MAP.md
    and the "Platinum Ice Asset Inbox" section of CLAUDE.md for how/when
    alt text and SEO filenames get manually reviewed and proposed once
    someone (or Claude, visually inspecting the actual image) knows what's
    really in the picture.

.PARAMETER AssetRoot
    Root folder containing 00-INBOX\<Category>\... Defaults to
    "<your Pictures folder>\PlatinumIce", or dev-tools/asset-sync.local.psd1's
    AssetRoot value if set.

.PARAMETER SitePath
    Absolute path to the WordPress install (the "app/public" folder). No
    default is hardcoded in this tracked script - required either as a
    parameter or via dev-tools/asset-sync.local.psd1 (gitignored; copy
    dev-tools/asset-sync.local.psd1.example to create it).

.PARAMETER SiteUrl
    Site URL passed to WP-CLI's --url. Same rule as SitePath - configure it
    via -SiteUrl or dev-tools/asset-sync.local.psd1, not a hardcoded default.

.PARAMETER LocalSitesJson
    Path to Local by Flywheel's sites.json, used to auto-discover the
    site's current MySQL port (Local can reassign this between restarts).

.PARAMETER PhpPath / WpCliPath / MysqlPort
    Explicit overrides. Checked in this order: -Parameter > this machine's
    dev-tools/asset-sync.local.psd1 > auto-discovery from the Local by
    Flywheel install. Auto-discovery covers PhpPath/WpCliPath/MysqlPort;
    SitePath/SiteUrl are never auto-discovered/hardcoded since they're
    specific to which site you're targeting.

.PARAMETER DryRun
    Report what would be imported without importing anything or writing
    to the manifest.

.PARAMETER Category
    Optional: only process one category folder (e.g. "Hero").

.EXAMPLE
    powershell -File dev-tools\sync-assets.ps1 -DryRun

.EXAMPLE
    powershell -File dev-tools\sync-assets.ps1 -Category Hero
#>

[CmdletBinding()]
param(
    [string]$AssetRoot,
    [string]$SitePath,
    [string]$SiteUrl,
    [string]$LocalSitesJson = (Join-Path $env:APPDATA "Local\sites.json"),
    [string]$PhpPath,
    [string]$WpCliPath,
    [int]$MysqlPort,
    [switch]$DryRun,
    [string]$Category,
    # Manual naming override for specific files, keyed by original filename
    # (e.g. the exact name a downloaded/AI-generated file arrived with),
    # value = the desired SEO filename (with extension). Use this when a
    # human or Claude has actually looked at the image and knows a better,
    # accurate name than the mechanical original-name-normalized/hash-fallback
    # logic could ever produce on its own - it never invents a subject
    # itself, so this is the supported way to supply one deliberately.
    [hashtable]$FilenameOverrides = @{}
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Local, gitignored, machine-specific configuration. Nothing machine-specific
# (usernames, absolute site paths, site URLs) is hardcoded in this tracked
# script - see dev-tools/asset-sync.local.psd1.example for the expected
# shape. Precedence: explicit parameter > dev-tools/asset-sync.local.psd1 >
# generic env-var-based default (AssetRoot only) > auto-discovery (PHP /
# WP-CLI / MySQL port) > a clear error telling you what to configure.
# ---------------------------------------------------------------------------
$LocalConfigPath = Join-Path $PSScriptRoot "asset-sync.local.psd1"
$LocalConfig = @{}
if (Test-Path $LocalConfigPath) {
    try {
        $LocalConfig = Import-PowerShellDataFile -Path $LocalConfigPath
    } catch {
        Write-Warning "Could not parse $LocalConfigPath - ignoring it. ($($_.Exception.Message))"
    }
}

if (-not $AssetRoot) { $AssetRoot = $LocalConfig.AssetRoot }
if (-not $AssetRoot) { $AssetRoot = Join-Path $env:USERPROFILE "Pictures\PlatinumIce" }

if (-not $SitePath) { $SitePath = $LocalConfig.SitePath }
if (-not $SitePath) {
    throw "SitePath is not set. Pass -SitePath, or create $LocalConfigPath (copy dev-tools\asset-sync.local.psd1.example and fill in SitePath)."
}

if (-not $SiteUrl) { $SiteUrl = $LocalConfig.SiteUrl }
if (-not $SiteUrl) {
    throw "SiteUrl is not set. Pass -SiteUrl, or create $LocalConfigPath (copy dev-tools\asset-sync.local.psd1.example and fill in SiteUrl)."
}

if (-not $PhpPath -and $LocalConfig.PhpPath) { $PhpPath = $LocalConfig.PhpPath }
if (-not $WpCliPath -and $LocalConfig.WpCliPath) { $WpCliPath = $LocalConfig.WpCliPath }
if ((-not $MysqlPort -or $MysqlPort -eq 0) -and $LocalConfig.MysqlPort) { $MysqlPort = [int]$LocalConfig.MysqlPort }

# ---------------------------------------------------------------------------
# Section-folder -> Elementor CSS class mapping (authoritative; keep in sync
# with docs/HOMEPAGE-CONTENT-MAP.md and docs/HOMEPAGE-ASSET-MAP.md).
# This mapping is informational/reporting only - sync-assets.ps1 never
# assigns an asset to Elementor itself.
# ---------------------------------------------------------------------------
$SectionMap = [ordered]@{
    "Hero"        = "platinum-hero (Elementor container background image/video - the one intentionally decorative/cinematic layer)"
    "Signature"   = "platinum-signature-image (native Elementor Image widget, inside the platinum-signature-media container)"
    "Custom"      = "platinum-custom-image (native Elementor Image widget, inside the platinum-custom-media container)"
    "Hospitality" = "platinum-hospitality-image (native Elementor Image widget, inside the platinum-hospitality-media container)"
    "Events"      = "platinum-events-image (native Elementor Image widget, inside the platinum-events-media container)"
    "Shop"        = "platinum-shop-slot-media (product photography slots - real <img> assignment not yet built)"
    "Craft"       = "platinum-craft-image (native Elementor Image widget, inside the platinum-craft-media container)"
    "Logos"       = "(handled separately - global Alukas logo settings, not an Elementor element)"
    "Unsorted"    = "(unassigned - needs manual classification into a homepage section before use)"
}

$SupportedExtensions = @(".jpg", ".jpeg", ".png", ".webp", ".avif", ".mp4", ".webm")

$ManifestPath = Join-Path $PSScriptRoot "asset-sync.local.json"

# ---------------------------------------------------------------------------
# Whether a category's images are currently used as CSS/Elementor background
# images (no alt attribute applies - decorative in the accessibility sense,
# even though they're meaningful brand photography) or as real semantic <img>
# content elements that need real descriptive alt text once reviewed. This
# reflects the CURRENT homepage implementation (all of these are Elementor
# Container background images today) - revisit if that changes.
# ---------------------------------------------------------------------------
$AltTextGuidanceMap = @{
    "Hero"          = "decorative-background"
    "Signature"     = "content-image"
    "Custom"        = "content-image"
    "Hospitality"   = "content-image"
    "Events"        = "content-image"
    "Craft"         = "content-image"
    "Shop"          = "product-content"
    "Logos"         = "logo-specific"
    "Unsorted"      = "unassigned"
    "Uncategorized" = "unassigned"
}

# Generic camera/download/AI-tool tokens that carry no real descriptive
# meaning - stripped out rather than treated as "subject" words.
$JunkWords = @(
    "img", "image", "imagegen", "photo", "pic", "picture", "shot",
    "dsc", "dscn", "screenshot", "screengrab", "capture",
    "unsplash", "pexels", "pixabay", "download", "downloaded",
    "file", "untitled", "final", "finalv", "copy", "edited", "edit",
    "export", "exported", "render", "rendered", "raw", "original",
    "draft", "new", "v1", "v2", "v3", "v4", "v5",
    # AI image-generation tool names - not a real subject/description
    "chatgpt", "gpt", "dalle", "midjourney", "stablediffusion", "sdxl",
    "gemini", "copilot", "firefly", "leonardo", "ideogram",
    # Timestamp fragments that survive filename normalization
    "am", "pm",
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "sept", "oct", "nov", "dec"
)

function Get-CleanSubjectTokens {
    param([string]$BaseName)
    $normalized = $BaseName.ToLowerInvariant() -replace '[^a-z0-9]+', ' '
    $tokens = $normalized -split '\s+' | Where-Object { $_ -ne '' }
    $clean = @()
    foreach ($t in $tokens) {
        if ($t -match '^\d+$') { continue }          # pure numbers (dates, camera serials) - not a subject
        if ($JunkWords -contains $t) { continue }     # generic camera/AI/download tokens
        if ($t.Length -lt 2) { continue }
        $clean += $t
    }
    return $clean
}

function Get-SeoFilenameInfo {
    param([string]$BaseName, [string]$CategoryName, [string]$Sha256, [string]$Extension, [string]$OriginalFileName, [hashtable]$Overrides = @{})

    if ($OriginalFileName -and $Overrides.ContainsKey($OriginalFileName)) {
        $overrideName = $Overrides[$OriginalFileName]
        $overrideBase = [System.IO.Path]::GetFileNameWithoutExtension($overrideName)
        $overrideExt = [System.IO.Path]::GetExtension($overrideName)
        if (-not $overrideExt) { $overrideExt = $Extension }
        $titleWords = $overrideBase -split '-'
        $mediaTitle = ($titleWords | ForEach-Object {
            if ($_.Length -gt 0) { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1) } else { $_ }
        }) -join ' '
        return [PSCustomObject]@{
            SeoFilename  = "$overrideBase$overrideExt"
            NamingSource = "manual-override"
            MediaTitle   = $mediaTitle
            NeedsReview  = $false
        }
    }

    $categoryToken = $CategoryName.ToLowerInvariant()
    $tokens = Get-CleanSubjectTokens -BaseName $BaseName

    if ($tokens.Count -gt 0) {
        if ($tokens -notcontains $categoryToken) {
            $allTokens = @($categoryToken) + $tokens
        } else {
            $allTokens = $tokens
        }
        # Keep filenames concise per the naming convention - cap total tokens.
        if ($allTokens.Count -gt 6) { $allTokens = $allTokens[0..5] }
        $seoBase = "platinum-ice-" + ($allTokens -join "-")
        $namingSource = "original-name-normalized"
    } else {
        $shortHash = $Sha256.Substring(0, 8)
        $seoBase = "platinum-ice-$categoryToken-$shortHash"
        $namingSource = "hash-fallback"
    }

    $titleWords = ($seoBase -replace '^platinum-ice-', 'platinum-ice-') -split '-'
    $mediaTitle = ($titleWords | ForEach-Object {
        if ($_.Length -gt 0) { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1) } else { $_ }
    }) -join ' '

    return [PSCustomObject]@{
        SeoFilename  = "$seoBase$Extension"
        NamingSource = $namingSource
        MediaTitle   = $mediaTitle
        NeedsReview  = ($namingSource -eq "hash-fallback")
    }
}

# ---------------------------------------------------------------------------
# Auto-discovery: Local by Flywheel's bundled PHP / WP-CLI / MySQL port.
# Overridable via parameters for portability to another machine/environment.
# ---------------------------------------------------------------------------
function Find-LocalPhp {
    $base = Join-Path $env:APPDATA "Local\lightning-services"
    if (-not (Test-Path $base)) { return $null }
    $dirs = Get-ChildItem -Path $base -Directory -Filter "php-*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($d in $dirs) {
        $candidate = Join-Path $d.FullName "bin\win64\php.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Find-WpCli {
    $candidate = Join-Path $env:LOCALAPPDATA "Programs\Local\resources\extraResources\bin\wp-cli\wp-cli.phar"
    if (Test-Path $candidate) { return $candidate }
    return $null
}

function Get-LocalSiteMysqlPort {
    param([string]$SitesJsonPath, [string]$TargetSitePath)
    if (-not (Test-Path $SitesJsonPath)) { return $null }
    try {
        $json = Get-Content $SitesJsonPath -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
    foreach ($prop in $json.PSObject.Properties) {
        $site = $prop.Value
        $sitePathExpanded = $site.path -replace '^~', $env:USERPROFILE
        if ($TargetSitePath -like "$sitePathExpanded*") {
            return [int]$site.services.mysql.ports.MYSQL[0]
        }
    }
    return $null
}

if (-not $PhpPath) { $PhpPath = Find-LocalPhp }
if (-not $WpCliPath) { $WpCliPath = Find-WpCli }
if (-not $MysqlPort -or $MysqlPort -eq 0) {
    $discovered = Get-LocalSiteMysqlPort -SitesJsonPath $LocalSitesJson -TargetSitePath $SitePath
    if ($discovered) { $MysqlPort = $discovered }
}

if (-not $PhpPath -or -not (Test-Path $PhpPath)) {
    throw "Could not locate PHP (Local by Flywheel). Pass -PhpPath explicitly."
}
if (-not $WpCliPath -or -not (Test-Path $WpCliPath)) {
    throw "Could not locate wp-cli.phar (Local by Flywheel). Pass -WpCliPath explicitly."
}
if (-not $MysqlPort) {
    throw "Could not determine the site's MySQL port from Local's sites.json. Pass -MysqlPort explicitly."
}

$ExtDir = Join-Path (Split-Path $PhpPath -Parent) "ext"

function Invoke-WPCLI {
    param([string[]]$Arguments)
    $allArgs = @(
        "-d", "extension_dir=$ExtDir",
        "-d", "extension=php_mysqli.dll",
        "-d", "extension=php_gd.dll",
        "-d", "mysqli.default_port=$MysqlPort",
        $WpCliPath,
        "--path=$SitePath",
        "--url=$SiteUrl"
    ) + $Arguments
    $output = & $PhpPath @allArgs 2>&1
    return [PSCustomObject]@{
        Output   = ($output -join "`n")
        ExitCode = $LASTEXITCODE
    }
}

# ---------------------------------------------------------------------------
# Manifest load/save
# ---------------------------------------------------------------------------
function Load-Manifest {
    if (Test-Path $ManifestPath) {
        try {
            $raw = Get-Content $ManifestPath -Raw | ConvertFrom-Json
            $assets = @{}
            if ($raw.assets) {
                foreach ($prop in $raw.assets.PSObject.Properties) {
                    $assets[$prop.Name] = $prop.Value
                }
            }
            return $assets
        } catch {
            Write-Warning "Manifest at $ManifestPath could not be parsed; starting a fresh manifest. ($($_.Exception.Message))"
            return @{}
        }
    }
    return @{}
}

function Save-Manifest {
    param([hashtable]$Assets)
    $obj = [PSCustomObject]@{
        version = 2
        assets  = $Assets
    }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $ManifestPath -Encoding utf8
}

# ---------------------------------------------------------------------------
# Inbox setup + scan
# ---------------------------------------------------------------------------
$InboxRoot = Join-Path $AssetRoot "00-INBOX"

if (-not (Test-Path $InboxRoot)) {
    Write-Host "Inbox not found at $InboxRoot - nothing to sync." -ForegroundColor Yellow
    exit 0
}

$manifest = Load-Manifest

$scanRoot = $InboxRoot
if ($Category) {
    $scanRoot = Join-Path $InboxRoot $Category
    if (-not (Test-Path $scanRoot)) {
        Write-Host "Category folder not found: $scanRoot" -ForegroundColor Yellow
        exit 0
    }
}

$files = Get-ChildItem -Path $scanRoot -Recurse -File -ErrorAction SilentlyContinue

$results = @()
$skippedUnsupported = 0
$seenThisRun = @{}

foreach ($file in $files) {
    $ext = $file.Extension.ToLowerInvariant()
    if ($SupportedExtensions -notcontains $ext) {
        $skippedUnsupported++
        continue
    }

    $relative = $file.FullName.Substring($InboxRoot.Length).TrimStart("\", "/")
    $segments = $relative -split '[\\/]'
    $categoryName = if ($segments.Length -gt 1) { $segments[0] } else { "Uncategorized" }

    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($manifest.ContainsKey($hash) -and $manifest[$hash].status -eq "imported") {
        $existing = $manifest[$hash]
        $note = ""
        if ($existing.category -ne $categoryName) {
            $note = " (NOTE: current folder is '$categoryName', originally imported as '$($existing.category)')"
        }
        $results += [PSCustomObject]@{
            File          = $relative
            Category      = $categoryName
            Status        = "duplicate (skipped)$note"
            AttachmentId  = $existing.attachmentId
            Url           = $existing.url
            Sha256        = $hash
        }
        continue
    }

    if ($seenThisRun.ContainsKey($hash)) {
        $results += [PSCustomObject]@{
            File          = $relative
            Category      = $categoryName
            Status        = "duplicate of '$($seenThisRun[$hash])' (same content, skipped within this run)"
            AttachmentId  = $null
            Url           = $null
            Sha256        = $hash
        }
        continue
    }
    $seenThisRun[$hash] = $relative

    $seoInfo = Get-SeoFilenameInfo -BaseName $file.BaseName -CategoryName $categoryName -Sha256 $hash -Extension $ext -OriginalFileName $file.Name -Overrides $FilenameOverrides
    $altGuidance = if ($AltTextGuidanceMap.ContainsKey($categoryName)) { $AltTextGuidanceMap[$categoryName] } else { "decorative-background" }

    if ($DryRun) {
        $results += [PSCustomObject]@{
            File          = $relative
            Category      = $categoryName
            Status        = "[DRY RUN] would import as '$($seoInfo.SeoFilename)'$(if ($seoInfo.NeedsReview) { ' [needs review: no usable words in original name]' })"
            AttachmentId  = $null
            Url           = $null
            Sha256        = $hash
        }
        continue
    }

    # Import from a temporary copy under the SEO-friendly name so WordPress's
    # media library (and the file that lands in uploads/) uses the clean
    # name, while the user's original file in 00-INBOX is never touched.
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "platinum-ice-import"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $tempFile = Join-Path $tempDir $seoInfo.SeoFilename
    Copy-Item -Path $file.FullName -Destination $tempFile -Force

    try {
        $importResult = Invoke-WPCLI -Arguments @("media", "import", $tempFile, "--title=$($seoInfo.MediaTitle)", "--porcelain")
    } finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }

    if ($importResult.ExitCode -eq 0 -and $importResult.Output -match '^\d+\s*$') {
        $attachmentId = [int]($importResult.Output.Trim())
        $urlResult = Invoke-WPCLI -Arguments @("post", "get", "$attachmentId", "--field=guid")
        $url = $urlResult.Output.Trim()

        $manifest[$hash] = [PSCustomObject]@{
            originalFilename = $file.Name
            sourcePath       = $relative
            seoFilename      = $seoInfo.SeoFilename
            namingSource     = $seoInfo.NamingSource
            needsReview      = $seoInfo.NeedsReview
            category         = $categoryName
            attachmentId     = $attachmentId
            url              = $url
            mediaTitle       = $seoInfo.MediaTitle
            altText          = $null
            altTextGuidance  = $altGuidance
            sha256           = $hash
            importedAt       = (Get-Date).ToUniversalTime().ToString("o")
            status           = "imported"
        }

        $results += [PSCustomObject]@{
            File         = $relative
            Category     = $categoryName
            Status       = "imported as '$($seoInfo.SeoFilename)'$(if ($seoInfo.NeedsReview) { ' [needs review]' })"
            AttachmentId = $attachmentId
            Url          = $url
            Sha256       = $hash
        }
    } else {
        $manifest[$hash] = [PSCustomObject]@{
            originalFilename = $file.Name
            sourcePath       = $relative
            seoFilename      = $seoInfo.SeoFilename
            namingSource     = $seoInfo.NamingSource
            needsReview      = $seoInfo.NeedsReview
            category         = $categoryName
            attachmentId     = $null
            url              = $null
            mediaTitle       = $seoInfo.MediaTitle
            altText          = $null
            altTextGuidance  = $altGuidance
            sha256           = $hash
            importedAt       = (Get-Date).ToUniversalTime().ToString("o")
            status           = "failed"
            error            = $importResult.Output
        }

        $results += [PSCustomObject]@{
            File         = $relative
            Category     = $categoryName
            Status       = "FAILED: $($importResult.Output)"
            AttachmentId = $null
            Url          = $null
            Sha256       = $hash
        }
    }
}

if (-not $DryRun) {
    Save-Manifest -Assets $manifest
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Platinum Ice Asset Sync ===" -ForegroundColor Cyan
Write-Host "Inbox: $InboxRoot"
Write-Host "Mode:  $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })"
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "No supported files found." -ForegroundColor Yellow
} else {
    $results | Format-Table -AutoSize File, Category, Status, AttachmentId
}

if ($skippedUnsupported -gt 0) {
    Write-Host "$skippedUnsupported unsupported file(s) ignored (not in: $($SupportedExtensions -join ', '))." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Section mapping reference:" -ForegroundColor Cyan
foreach ($key in $SectionMap.Keys) {
    Write-Host "  $key -> $($SectionMap[$key])"
}
