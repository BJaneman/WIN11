# -------------------------------
# Mega Virtual Drive Setup Script
# -------------------------------

# ---------- 0. Set execution policy ----------
try {
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Host "✅ Execution policy set to Unrestricted."
} catch {
    Write-Warning "Unable to set execution policy. Run as Administrator."
}

# ---------- 1. Check & install dependencies ----------
function Install-IfMissing($pkg, $wingetName) {
    if (-not (Get-Command $pkg -ErrorAction SilentlyContinue)) {
        Write-Host "$pkg not found. Installing..."
        winget install $wingetName -e --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "$pkg is already installed."
    }
}

# Install rclone and WinFSP
Install-IfMissing "rclone" "rclone.rclone"
Install-IfMissing "winfsp" "WinFsp.WinFsp"

# ---------- 2. Configure Mega ----------
# Replace these with your Mega credentials
$MegaEmail = "YOUR_EMAIL_HERE"
$MegaPass  = "YOUR_PASSWORD_HERE"
$RemoteName = "mega"

# rclone config automation
$ConfigExists = Test-Path "$env:USERPROFILE\.config\rclone\rclone.conf"
if (-not $ConfigExists) {
    Write-Host "Creating rclone config for Mega..."
    $RcloneConfig = @"
[$RemoteName]
type = mega
user = $MegaEmail
pass = $(rclone obscure $MegaPass)
"@
    $ConfigDir = "$env:USERPROFILE\.config\rclone"
    if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force }
    $RcloneConfig | Out-File "$ConfigDir\rclone.conf" -Encoding ASCII
} else {
    Write-Host "rclone config already exists. Skipping."
}

# ---------- 3. Mount Mega as Z: ----------
Write-Host "Mounting Mega as Z: drive..."
Start-Process "rclone" -ArgumentList "mount $RemoteName: Z: --vfs-cache-mode full" -WindowStyle Hidden

# ---------- 4. Add Auto-Mount at login ----------
$StartupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\mountMega.ps1"
$ScriptContent = @"
Start-Process 'rclone' -ArgumentList 'mount $RemoteName: Z: --vfs-cache-mode full' -WindowStyle Hidden
"@
$ScriptContent | Out-File $StartupScript -Encoding ASCII
Write-Host "✅ Auto-mount script created at Startup folder."

Write-Host "✅ Setup complete! Mega will now appear as Z: and auto-mount on login."