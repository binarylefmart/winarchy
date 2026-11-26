<#
  Garde l'écran de verrouillage identique au fond d'écran.

  Toutes les $Intervalle secondes, compare le fond d'écran (HKCU\Control Panel\Desktop\WallPaper)
  et l'image de l'écran de verrouillage (WinRT LockScreen.OriginalImageFile). S'ils diffèrent
  deux contrôles de suite (laisse finir un `winarchy theme set`, qui change les deux), l'image
  de verrouillage est remplacée par le fond. Couvre tous les chemins : winarchy background,
  theme set, Paramètres de Windows, clic droit « Définir comme arrière-plan ».

  Lancé à l'ouverture de session par la tâche planifiée \Winarchy\fond (installée par
  setup-winarchy.ps1). Windows PowerShell 5.1 : WinRT y est disponible directement.
  Journal : %LOCALAPPDATA%\Winarchy\fond.log
#>
param([int]$Intervalle = 5)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:LOCALAPPDATA 'Winarchy'
$log = Join-Path $logDir 'fond.log'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log([string]$m) {
    "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m | Out-File -FilePath $log -Append -Encoding utf8
}

$mutex = New-Object System.Threading.Mutex($false, 'Local\WinarchyFond')
if (-not $mutex.WaitOne(0)) { exit 0 }

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTask = $asTask.MakeGenericMethod([Windows.Storage.StorageFile])
$asAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]

function Get-Fond {
    (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
}

function Get-Verrouillage {
    try { $u = [Windows.System.UserProfile.LockScreen]::OriginalImageFile; if ($u) { $u.LocalPath } } catch { $null }
}

function Set-Verrouillage([string]$image) {
    $f = $asTask.Invoke($null, @([Windows.Storage.StorageFile]::GetFileFromPathAsync($image))).Result
    $asAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($f))).Wait()
}

Write-Log "Démarrage (intervalle $Intervalle s)"
$ecartPrecedent = $null
while ($true) {
    try {
        $fond = Get-Fond
        $verrou = Get-Verrouillage
        $ecart = $null
        if ($fond -and (Test-Path -LiteralPath $fond) -and -not [string]::Equals($fond, $verrou, [StringComparison]::OrdinalIgnoreCase)) {
            $ecart = "$fond|$verrou"
        }
        if ($ecart -and $ecart -eq $ecartPrecedent) {
            Set-Verrouillage $fond
            Write-Log "Verrouillage : $(Split-Path $fond -Leaf) (était : $verrou)"
            $ecart = $null
        }
        $ecartPrecedent = $ecart
    } catch {
        Write-Log "Erreur : $($_.Exception.Message)"
        $ecartPrecedent = $null
    }
    Start-Sleep -Seconds $Intervalle
}
