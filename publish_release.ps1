#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PyImport2Pkg Release Publisher Script
    
.DESCRIPTION
    Automates the GitHub Release creation process for PyImport2Pkg
    
.PARAMETER Username
    GitHub username for repository URL
    
.PARAMETER SkipPush
    Skip pushing code and tags to GitHub
    
.EXAMPLE
    .\publish_release.ps1 -Username "your-github-username"
#>

param(
    [string]$Username = "",
    [switch]$SkipPush = $false
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "📝 $Message" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Invoke-Command-Safe {
    param(
        [string]$Command,
        [string]$Description,
        [switch]$IgnoreError = $false
    )
    
    Write-Host "`nCommand: $Command" -ForegroundColor Gray
    
    try {
        Invoke-Expression $Command
        Write-Success $Description
        return $true
    }
    catch {
        if ($IgnoreError) {
            Write-Warning-Custom "$Description (non-critical, continuing...)"
            return $false
        }
        else {
            Write-Error-Custom "Failed: $Description"
            throw $_
        }
    }
}

# Main Script
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║        PyImport2Pkg Release Publisher Script              ║" -ForegroundColor Magenta
Write-Host "║                      v0.3.0                               ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

$projectRoot = Get-Location
$releaseNote = Join-Path $projectRoot "RELEASE_NOTE.md"

Write-Header "Pre-flight Checks"

# Check if RELEASE_NOTE.md exists
if (-not (Test-Path $releaseNote)) {
    Write-Error-Custom "RELEASE_NOTE.md not found at $releaseNote"
    exit 1
}
Write-Success "RELEASE_NOTE.md found"

# Check Git
try {
    $gitVersion = git --version
    Write-Success "Git installed: $gitVersion"
}
catch {
    Write-Error-Custom "Git not found. Please install Git first."
    exit 1
}

# Check for gh CLI
try {
    $ghVersion = gh --version
    Write-Success "GitHub CLI installed: $ghVersion"
    $hasGhCli = $true
}
catch {
    Write-Warning-Custom "GitHub CLI not installed (required for automatic Release creation)"
    Write-Host "Install from: https://cli.github.com" -ForegroundColor Yellow
    $hasGhCli = $false
}

Write-Header "Repository Setup"

# Check if remote is configured
try {
    $remoteUrl = git remote get-url origin 2>$null
    Write-Success "Git remote already configured: $remoteUrl"
}
catch {
    if (-not $Username) {
        $Username = Read-Host "🔑 Enter your GitHub username"
    }
    
    if (-not $Username) {
        Write-Error-Custom "GitHub username required"
        exit 1
    }
    
    $remoteUrl = "https://github.com/$Username/pyimport2pkg.git"
    Invoke-Command-Safe "git remote add origin '$remoteUrl'" `
        "Added Git remote: $remoteUrl"
}

if (-not $SkipPush) {
    Write-Header "Pushing to GitHub"
    
    try {
        Invoke-Command-Safe "git push -u origin master" `
            "Pushed master branch" `
            -IgnoreError
    }
    catch {
        Write-Warning-Custom "Master branch push failed (may already be pushed)"
    }
    
    try {
        Invoke-Command-Safe "git push origin v0.3.0" `
            "Pushed version tag" `
            -IgnoreError
    }
    catch {
        Write-Warning-Custom "Tag push failed (may already be pushed)"
    }
}

if ($hasGhCli) {
    Write-Header "Creating Release on GitHub"
    
    try {
        $cmd = @(
            "gh release create v0.3.0",
            "-F RELEASE_NOTE.md",
            '--title "PyImport2Pkg v0.3.0"'
        ) -join " "
        
        Invoke-Expression $cmd
        Write-Success "GitHub Release created successfully"
        
        Write-Host "`n" -NoNewline
        Write-Host ("=" * 60) -ForegroundColor Green
        Write-Host "🎉 Release Published Successfully!" -ForegroundColor Green
        Write-Host ("=" * 60) -ForegroundColor Green
        
        if ($remoteUrl -match "github.com/(.+?)/") {
            $repoOwner = $matches[1]
            $releaseUrl = "https://github.com/$repoOwner/pyimport2pkg/releases/tag/v0.3.0"
            Write-Host "`n📢 Your release is now live:" -ForegroundColor Cyan
            Write-Host "   $releaseUrl" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error-Custom "Failed to create release via gh CLI: $_"
        Write-Host "`n📝 Manual step: Create release at:" -ForegroundColor Yellow
        Write-Host "   https://github.com/YOUR_USERNAME/pyimport2pkg/releases" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Header "Manual Release Creation Required"
    
    Write-Host "`n📝 Since GitHub CLI is not installed, please create release manually:" -ForegroundColor Yellow
    Write-Host "`n1. Go to: https://github.com/YOUR_USERNAME/pyimport2pkg/releases" -ForegroundColor Yellow
    Write-Host "2. Click 'Draft a new release'" -ForegroundColor Yellow
    Write-Host "3. Select tag: v0.3.0" -ForegroundColor Yellow
    Write-Host "4. Title: PyImport2Pkg v0.3.0" -ForegroundColor Yellow
    Write-Host "5. Copy contents of RELEASE_NOTE.md as description" -ForegroundColor Yellow
    Write-Host "6. Click 'Publish release'" -ForegroundColor Yellow
    
    # Open release page if possible
    $repoOwner = if ($remoteUrl -match "github.com/(.+?)/") { $matches[1] } else { "YOUR_USERNAME" }
    $releaseUrl = "https://github.com/$repoOwner/pyimport2pkg/releases"
    
    Write-Host "`n🌐 Opening GitHub in browser..." -ForegroundColor Cyan
    try {
        Start-Process $releaseUrl
        Write-Success "Browser opened to: $releaseUrl"
    }
    catch {
        Write-Host "📍 Please visit manually: $releaseUrl" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Release process complete!`n" -ForegroundColor Green
