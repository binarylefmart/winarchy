<#
  Surveille le branchement et le retrait des écrans et range les fenêtres.

  Retrait d'un écran : komorebi garde en cache l'écran disparu et ses fenêtres restent
  masquées, et Windows réduit certaines fenêtres. Le script fait réapparaître les fenêtres
  masquées, redémarre komorebi (via la tâche \Winarchy\komorebi, en administrateur) et
  remet en taille normale les fenêtres qui n'étaient pas réduites avant le retrait.
  Tout se retrouve sur l'écran restant.

  Branchement d'un écran : quand komorebi voit le nouvel écran, s'il y a plus de $Garder
  fenêtres sur l'écran qui en porte le plus, le surplus est réparti sur les autres écrans.

  Toutes les $Intervalle secondes ; un changement doit être stable deux contrôles de suite
  (sortie de veille, écrans qui clignotent). Lancé à l'ouverture de session par la tâche
  planifiée \Winarchy\ecrans (installée par setup-winarchy.ps1).
  Journal : %LOCALAPPDATA%\Winarchy\ecrans.log
#>
param(
    [int]$Intervalle = 3,
    [int]$Garder = 2,
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:LOCALAPPDATA 'Winarchy'
$log = Join-Path $logDir 'ecrans.log'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log([string]$m) {
    "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m | Out-File -FilePath $log -Append -Encoding utf8
}

$mutex = New-Object System.Threading.Mutex($false, 'Local\WinarchyEcrans')
if (-not $mutex.WaitOne(0)) { exit 0 }

Add-Type -Namespace PersoWinarchy -Name Fen -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
public delegate bool MonitorEnumProc(System.IntPtr h, System.IntPtr hdc, ref RECT r, System.IntPtr d);
public delegate bool WndEnumProc(System.IntPtr h, System.IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumDisplayMonitors(System.IntPtr hdc, System.IntPtr clip, MonitorEnumProc cb, System.IntPtr d);
[DllImport("user32.dll")] public static extern bool EnumWindows(WndEnumProc cb, System.IntPtr l);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr h);
[DllImport("user32.dll")] public static extern bool IsIconic(System.IntPtr h);
[DllImport("user32.dll")] public static extern bool IsWindow(System.IntPtr h);
[DllImport("user32.dll")] public static extern System.IntPtr GetWindow(System.IntPtr h, uint c);
[DllImport("user32.dll")] public static extern int GetWindowTextLength(System.IntPtr h);
[DllImport("user32.dll")] public static extern int GetWindowLong(System.IntPtr h, int i);
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int c);
public static int NbEcrans() {
  int n = 0;
  EnumDisplayMonitors(System.IntPtr.Zero, System.IntPtr.Zero, (System.IntPtr h, System.IntPtr hdc, ref RECT r, System.IntPtr d) => { n++; return true; }, System.IntPtr.Zero);
  return n;
}
// Fenêtres d'application visibles et non réduites (sans propriétaire, pas d'outil, avec titre).
public static System.Collections.Generic.List<long> Ouvertes() {
  var l = new System.Collections.Generic.List<long>();
  EnumWindows((h, x) => {
    if (!IsWindowVisible(h) || IsIconic(h) || GetWindow(h, 4) != System.IntPtr.Zero || GetWindowTextLength(h) == 0) return true;
    if ((GetWindowLong(h, -20) & 0x80) != 0) return true;   // WS_EX_TOOLWINDOW
    l.Add(h.ToInt64()); return true; }, System.IntPtr.Zero);
  return l;
}
'@

$komorebic = Join-Path $env:ProgramFiles 'komorebi\bin\komorebic.exe'
$flagJeu = Join-Path $Root 'state\game-mode.flag'

function Get-Etat {
    foreach ($i in 1..3) {
        $raw = (& $komorebic state 2>$null) -join "`n"
        if ($raw.Trim()) { try { return $raw | ConvertFrom-Json } catch { } }
        Start-Sleep -Milliseconds 500
    }
    $null
}

function Restart-Komorebi {
    & $komorebic restore-windows *> $null
    & $komorebic stop *> $null
    $fin = (Get-Date).AddSeconds(10)
    while ((Get-Process komorebi -ErrorAction SilentlyContinue) -and (Get-Date) -lt $fin) { Start-Sleep -Milliseconds 300 }
    & schtasks.exe /Run /TN '\Winarchy\komorebi' *> $null
    if ($LASTEXITCODE -ne 0) { & $komorebic start *> $null }
    $fin = (Get-Date).AddSeconds(15)
    while (-not (Get-Etat) -and (Get-Date) -lt $fin) { Start-Sleep -Milliseconds 500 }
}

function Invoke-Retrait([long[]]$avant) {
    Write-Log 'écran retiré : fenêtres ramenées sur les écrans restants'
    Restart-Komorebi
    Start-Sleep -Seconds 1
    $n = 0
    foreach ($h in $avant) {
        $p = [IntPtr]$h
        if ([PersoWinarchy.Fen]::IsWindow($p) -and [PersoWinarchy.Fen]::IsIconic($p)) {
            [PersoWinarchy.Fen]::ShowWindow($p, 9) | Out-Null   # SW_RESTORE
            $n++
        }
    }
    Start-Sleep -Seconds 1
    & $komorebic retile *> $null
    Write-Log "  $n fenêtre(s) remise(s) en taille normale"
}

function Invoke-Branchement([int]$nb) {
    # Attendre que komorebi voie tous les écrans, sinon le redémarrer.
    $etat = $null
    $fin = (Get-Date).AddSeconds(12)
    do {
        Start-Sleep -Seconds 1
        $etat = Get-Etat
    } while ((-not $etat -or @($etat.monitors.elements).Count -lt $nb) -and (Get-Date) -lt $fin)
    if (-not $etat -or @($etat.monitors.elements).Count -lt $nb) {
        Write-Log 'komorebi ne voit pas le nouvel écran : redémarrage'
        Restart-Komorebi
        $etat = Get-Etat
    }
    if (-not $etat) { Write-Log 'komorebi ne répond pas'; return }
    $ecrans = @($etat.monitors.elements)
    if ($ecrans.Count -lt 2) { return }

    # Écran source : celui dont l'espace de travail affiché porte le plus de fenêtres.
    $compte = foreach ($m in $ecrans) {
        $ws = @($m.workspaces.elements)[$m.workspaces.focused]
        @($ws.containers.elements).Count
    }
    $source = 0
    for ($i = 1; $i -lt $compte.Count; $i++) { if ($compte[$i] -gt $compte[$source]) { $source = $i } }
    $surplus = $compte[$source] - $Garder
    if ($surplus -le 0) { Write-Log "écran branché : $($compte[$source]) fenêtre(s) sur l'écran $source, rien à déplacer"; return }

    $cibles = @(0..($ecrans.Count - 1) | Where-Object { $_ -ne $source })
    Write-Log "écran branché : $surplus fenêtre(s) déplacée(s) de l'écran $source vers $($cibles -join ', ')"
    for ($k = 0; $k -lt $surplus; $k++) {
        & $komorebic focus-monitor $source *> $null
        Start-Sleep -Milliseconds 150
        & $komorebic move-to-monitor $cibles[$k % $cibles.Count] *> $null
        Start-Sleep -Milliseconds 250
    }
    & $komorebic focus-monitor $source *> $null
}

Write-Log "--- surveillance des écrans démarrée (PID $PID) ---"
$nbStable = [PersoWinarchy.Fen]::NbEcrans()
$ouvertes = [PersoWinarchy.Fen]::Ouvertes()
$candidat = $nbStable
$vu = 0

while ($true) {
    Start-Sleep -Seconds $Intervalle
    try {
        $nb = [PersoWinarchy.Fen]::NbEcrans()
        if ($nb -eq $nbStable) {
            $vu = 0
            $ouvertes = [PersoWinarchy.Fen]::Ouvertes()   # photo d'avant le prochain changement
            continue
        }
        if ($nb -ne $candidat) { $candidat = $nb; $vu = 1; continue }
        $vu++
        if ($vu -lt 2) { continue }

        $ancien = $nbStable
        $nbStable = $nb; $vu = 0
        if ((Test-Path $flagJeu) -or -not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
            Write-Log "écrans : $ancien -> $nb (komorebi arrêté ou mode jeu : rien à faire)"
            continue
        }
        Write-Log "écrans : $ancien -> $nb"
        if ($nb -lt $ancien) { Invoke-Retrait $ouvertes } else { Invoke-Branchement $nb }
        $ouvertes = [PersoWinarchy.Fen]::Ouvertes()
    } catch {
        Write-Log "erreur : $($_.Exception.Message)"
    }
}
