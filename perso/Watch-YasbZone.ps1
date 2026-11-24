<#
  Surveille la zone de travail réservée par la barre YASB sur chaque écran.

  YASB (v2.0.7) repositionne sa barre quand la géométrie d'un écran change (branchement,
  résolution, mise à l'échelle, sortie de veille) mais n'enregistre pas toujours de nouveau
  son AppBar : l'écran perd sa zone réservée et komorebi tile les fenêtres sous la barre.

  Toutes les $Intervalle secondes : si YASB tourne (et pas en mode jeu) et qu'un écran n'a
  rien de réservé en haut deux contrôles de suite, YASB est relancé proprement (Start-Yasb.ps1
  de Winarchy) puis komorebi retile. Une relance au plus toutes les $Pause secondes.

  Lancé à l'ouverture de session par la tâche planifiée \Winarchy\yasb-zone
  (installée par setup-winarchy.ps1). Journal : %LOCALAPPDATA%\Winarchy\yasb-zone.log
#>
param(
    [int]$Intervalle = 10,
    [int]$Pause = 120,
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:LOCALAPPDATA 'Winarchy'
$log = Join-Path $logDir 'yasb-zone.log'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log([string]$m) {
    "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m | Out-File -FilePath $log -Append -Encoding utf8
}

# Une seule instance (la tâche peut être relancée à la main).
$mutex = New-Object System.Threading.Mutex($false, 'Local\WinarchyYasbZone')
if (-not $mutex.WaitOne(0)) { exit 0 }

# Lecture directe Win32 : Screen.AllScreens de WinForms garde un cache sans boucle de messages.
Add-Type -Namespace PersoWinarchy -Name Ecrans -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct MONITORINFOEX { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string szDevice; }
public delegate bool MonitorEnumProc(System.IntPtr h, System.IntPtr hdc, ref RECT r, System.IntPtr d);
[DllImport("user32.dll")] public static extern bool EnumDisplayMonitors(System.IntPtr hdc, System.IntPtr clip, MonitorEnumProc cb, System.IntPtr d);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool GetMonitorInfo(System.IntPtr h, ref MONITORINFOEX mi);
public static System.Collections.Generic.List<string> SansZone() {
  var l = new System.Collections.Generic.List<string>();
  EnumDisplayMonitors(System.IntPtr.Zero, System.IntPtr.Zero, (System.IntPtr h, System.IntPtr hdc, ref RECT r, System.IntPtr d) => {
    var mi = new MONITORINFOEX(); mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
    if (GetMonitorInfo(h, ref mi) && mi.rcWork.Top == mi.rcMonitor.Top) l.Add(mi.szDevice);
    return true; }, System.IntPtr.Zero);
  return l;
}
'@

$startYasb = Join-Path $Root 'scripts\Start-Yasb.ps1'
$yasbc = Join-Path $env:ProgramFiles 'YASB\yasbc.exe'
$komorebic = Join-Path $env:ProgramFiles 'komorebi\bin\komorebic.exe'
$flagJeu = Join-Path $Root 'state\game-mode.flag'
$fichierBarre = Join-Path $Root 'state\bar'

Write-Log "--- surveillance démarrée (PID $PID) ---"
$suspects = 0
$derniere = [datetime]::MinValue

while ($true) {
    Start-Sleep -Seconds $Intervalle
    try {
        $barre = if (Test-Path $fichierBarre) { ([IO.File]::ReadAllText($fichierBarre)).Trim() } else { 'yasb' }
        if ($barre -ne 'yasb' -or (Test-Path $flagJeu) -or -not (Get-Process yasb -ErrorAction SilentlyContinue)) {
            $suspects = 0; continue
        }
        $sans = [PersoWinarchy.Ecrans]::SansZone()
        if ($sans.Count -eq 0) { $suspects = 0; continue }
        $suspects++
        if ($suspects -lt 2) { continue }   # laisse YASB finir un repositionnement en cours
        if (((Get-Date) - $derniere).TotalSeconds -lt $Pause) { continue }

        Write-Log "zone non réservée sur $($sans -join ', ') : relance de YASB"
        $derniere = Get-Date
        $suspects = 0
        Stop-Process -Name yasb -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        & powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $startYasb `
            -YasbExe $yasbc -YasbConfigHome (Join-Path $Root 'config\yasb')
        # Laisse YASB enregistrer ses AppBar avant que komorebi recalcule les zones.
        Start-Sleep -Seconds 8
        if (Test-Path $komorebic) { & $komorebic retile *> $null }
        $reste = [PersoWinarchy.Ecrans]::SansZone()
        if ($reste.Count) { Write-Log "toujours sans zone après relance : $($reste -join ', ')" }
        else { Write-Log 'zones rétablies, komorebi retilé' }
    } catch {
        Write-Log "erreur : $($_.Exception.Message)"
    }
}
