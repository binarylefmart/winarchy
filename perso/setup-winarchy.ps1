<#
  Raccourcis et réglages perso Omarchy -> Winarchy (komorebi + YASB + AutoHotkey v2).

  Winarchy vient de ton fork github.com/binarylefmart/winarchy (C:\winarchy), qui suit le
  projet d'origine github.com/guidonaselli/winarchy (remote « upstream »). Ce script est
  versionné dans le fork (perso\setup-winarchy.ps1) ; la copie sur kDrive n'est qu'un
  lanceur qui fournit aussi le dossier profils\ (réglages Claude / gh, privés).

  À lancer dans un PowerShell normal (pas administrateur) :
      powershell -ExecutionPolicy Bypass -File "setup-winarchy.ps1"
  Tout est automatique :
   - Winarchy absent : installation depuis le fork (boot.ps1), activée au démarrage de session ;
   - Winarchy présent : remotes vérifiés, mises à jour du projet d'origine fusionnées avec
     tes fix et réglages (perso\Sync-Upstream.ps1), migration, push sur le fork ;
   - puis réglages et raccourcis ci-dessous appliqués, et le résultat poussé sur le fork.
  Utilise ce script À LA PLACE de « winarchy update --self » (fast-forward seulement : il
  échoue dès qu'il y a des commits perso).
  Sans la mise à jour de Winarchy :
      powershell -ExecutionPolicy Bypass -File "setup-winarchy.ps1" -SansMiseAJour
  Pour tout retirer :
      powershell -ExecutionPolicy Bypass -File "setup-winarchy.ps1" -Desinstaller

  Relançable sans risque : il remplace ses propres ajouts.

  Réglages dans les modèles de Winarchy (repatchés à chaque lancement) :
        Fenêtre seule en pleine largeur par défaut (Super+F la centre)
        Barre YASB : groupes toujours dépliés, sans compteur Codex
        Barre YASB : icônes de la zone de notification renvoyées à chaque redémarrage de YASB
        komorebi : tout est tilé (ShareX, Gestionnaire des tâches, Panneau de configuration, applis
          ignorées ou flottantes de la liste communautaire ASC, lanceurs de jeux) ; 4 écrans décrits
          (portable + 3 externes), 10 bureaux chacun ; relancé par sa tâche planifiée, en administrateur

  Raccourcis (ils passent devant ceux de Winarchy) :
        Super+Backspace            Claude Code (Foxis)
        Super+Shift+Backspace      Claude Code (perso)
        Super+Ctrl+Shift+Backspace Claude Desktop (ouvre / affiche / replie ; Super+Shift+A ne fait plus rien)
        Super+Ctrl+Alt+Shift+Backspace  idem (Claude Desktop pro)
        Super+Ctrl+Alt+Shift+Entrée  Claude Desktop perso (2e instance, compte perso ; ouvre / affiche / replie)
        Super+A / Super+Alt+Tab    Exposé (Vue des tâches de Windows)
        Super+O                    Outlook classique (Obsidian n'a plus de raccourci ; Super+Shift+O ne fait plus rien)
        Super+M                    Deezer
        Super+Y / X / C / G        Supprimés (applis web YouTube, X, Calendar, WhatsApp de Winarchy)
        Super+Shift+N              Bloc-notes
        Super+R                    Exécuter (Run)
        Super+I                    Paramètres Windows
        Super (seul)               Lanceur d'applis Winarchy (à la place du menu Démarrer)
        Super+Espace               Menu Démarrer de Windows
        Super+Q                    Menu Winarchy (reste aussi sur Super+Alt+Espace)
        Super+Ctrl+Alt+flèches     Fenêtre -> écran voisin (position réelle des écrans)
        Super+Alt+1..4             Aller sur l'écran N (numérotés de gauche à droite)
        Super+Alt+Shift+1..4       Envoyer la fenêtre sur l'écran N
        Super+F                    Plein : fenêtre seule = pleine largeur (défaut) <-> centrée ;
                                   plusieurs fenêtres = monocle (l'active remplit le bureau)
        Super+Shift+T              Tout retiler : flottantes remises en tuiles, monocle quitté,
                                   tuiles à parts égales (bureau actif). Thème suivant : menu Super+Q
        Super+Ctrl+R               Retile simple (remet les fenêtres mal redimensionnées dans leur tuile)
        Super+Alt+flèches          Caler la fenêtre : moitiés, coins en combinant (← puis ↑ = haut gauche).
                                   Elle passe en flottant ; Super+T la remet dans le tiling.
        Super+Z                    Mode redimensionnement (flèches / hjkl, Maj = fin,
                                   Échap ou Entrée pour sortir)
        Super+S                    Réduire la fenêtre active (à chaque appui)
        Super+Shift+S              Ramener toutes les fenêtres réduites par Super+S
        Super+P                    Projeter, le menu de Windows (Winarchy y mettait la pause du tiling)
  Et le focus suit la souris (survol = fenêtre active, comme sous Omarchy).
  komorebi tourne en administrateur pour tiler aussi les fenêtres admin (une fenêtre UAC
  au premier lancement ; -Desinstaller le remet en droits limités).
#>
param(
    [switch]$Desinstaller,
    [switch]$SansMiseAJour,
    # Dossier des réglages Claude / gh à copier dans le profil (passé par le lanceur kDrive).
    [string]$Profils = (Join-Path $PSScriptRoot 'profils')
)
$ErrorActionPreference = 'Stop'

$Fork     = 'binarylefmart/winarchy'
$Amont    = 'guidonaselli/winarchy'
$Perso    = Join-Path $env:USERPROFILE '.winarchy-perso'
$AhkDebut = '; >>> raccourcis-perso (setup-winarchy.ps1) >>>'
$AhkFin   = '; <<< raccourcis-perso <<<'
# Modèles suivis par git que ce script patche (et que Sync-Upstream.ps1 sait reprendre).
# Posé quand des règles komorebi changent : relance en fin de script (Set-KomorebiAdmin).
$script:RedemarrerKomorebi = $false
$ModelesPatches = @('templates\komorebi.json.tpl', 'templates\yasb-config.yaml.tpl', 'templates\yasb-styles.css.tpl', 'games.toml', 'vendor\asc\applications.json', 'module\Winarchy\Private\Util.ps1')

# Corps de ~\.winarchy-perso\devant.ahk (voir Write-DevantScript).
$script:CorpsDevant = @'
; --- Fenêtres flottantes toujours devant -----------------------------------------
; Le focus au survol remonte les tuiles par-dessus tout ce que komorebi ne tuile pas.
; Règle par défaut : toute fenêtre que komorebi ne tuile pas passe au-dessus jusqu'à sa
; fermeture (notifications, popups, désinstalleurs…), sans voler le focus. Exclus :
; plein écran, maximisées, réduites, minuscules, jeux de games.toml, éléments système.
; Une fenêtre que komorebi finit par tuiler redevient normale.
; Cas particuliers, traités tout de suite :
;  - boîtes de dialogue #32770 RATTACHÉES à une autre, TOUTES celles de l'Explorateur
;    (« Supprimer plusieurs éléments » n'est rattachée à rien) et installeurs /
;    désinstalleurs (PersoEstInstalleur) : devant ET activées ; les « Propriétés » de
;    l'Explorateur sont en plus centrées ;
;  - progression de copie de l'Explorateur, popups Steam, rappels Outlook : devant.
global PersoVues := Map()      ; hwnd -> 0 ignorée, 1 devant, 2 flottante devant (tant que non tuilée)
global PersoAttente := Map()   ; hwnd -> A_TickCount de première vue (laisse komorebi la prendre)
SetTimer(PersoDevant, 250)
PersoDevant() {
    static dernierControle := 0
    for hwnd in WinGetList() {
        if (PersoVues.Has(hwnd) || PersoAttente.Has(hwnd))
            continue
        PersoVues[hwnd] := 0
        try PersoClasse(hwnd)
    }
    ; Fenêtres vues depuis plus d'1 s : si komorebi ne les a pas tuilées, devant.
    if PersoAttente.Count {
        tuilees := ''
        for hwnd, debut in PersoAttente.Clone() {
            if (A_TickCount - debut < 1000)
                continue
            PersoAttente.Delete(hwnd)
            PersoVues[hwnd] := 0
            try {
                if !PersoFlottanteEligible(hwnd)
                    continue
                if (tuilees = '')
                    tuilees := PersoTuilees()
                if PersoEstTuilee(tuilees, hwnd)
                    continue
                PersoVues[hwnd] := 2
                WinSetAlwaysOnTop(1, hwnd)
            }
        }
    }
    ; Toutes les 2 s : une flottante que komorebi a fini par tuiler redevient normale.
    if (A_TickCount - dernierControle > 2000) {
        dernierControle := A_TickCount
        tuilees := ''
        for hwnd, etat in PersoVues.Clone() {
            if (etat != 2)
                continue
            if (tuilees = '')
                tuilees := PersoTuilees()
            if (tuilees != '*' && PersoEstTuilee(tuilees, hwnd)) {
                PersoVues[hwnd] := 0
                try WinSetAlwaysOnTop(0, hwnd)
            }
        }
    }
    ; À chaque passage : oublie les fenêtres fermées, et remet devant (sans focus) celles
    ; qui ont perdu le « toujours au-dessus » (le premier réglage ne tient pas toujours).
    for hwnd, etat in PersoVues.Clone() {
        if !WinExist(hwnd) {
            PersoVues.Delete(hwnd)
            continue
        }
        if !etat
            continue
        try {
            if !(WinGetExStyle(hwnd) & 0x8)                  ; WS_EX_TOPMOST
                WinSetAlwaysOnTop(1, hwnd)
        }
    }
}
PersoClasse(hwnd) {
    classe := WinGetClass(hwnd)
    if (classe = 'OperationStatusWindow') {
        PersoVues[hwnd] := 1                         ; progression : devant, sans focus
        return
    }
    if (WinGetExStyle(hwnd) & 0x80)                  ; WS_EX_TOOLWINDOW : pas une vraie fenêtre
        return
    if PersoEstNotification(hwnd, classe) {          ; notification : devant, sans focus
        PersoVues[hwnd] := 1
        WinSetAlwaysOnTop(1, hwnd)
        return
    }
    installeur := PersoEstInstalleur(hwnd, classe)
    explorateur := (WinGetProcessName(hwnd) = 'explorer.exe')
    if (installeur || (classe = '#32770' && (explorateur || DllCall('GetWindow', 'Ptr', hwnd, 'UInt', 4, 'Ptr')))) {
        PersoVues[hwnd] := 1
        titre := WinGetTitle(hwnd)
        if (explorateur && (InStr(titre, 'Propriétés') || InStr(titre, 'Properties')))
            PersoCentre(hwnd)
        WinSetAlwaysOnTop(1, hwnd)
        WinActivate(hwnd)
        return
    }
    PersoVues.Delete(hwnd)                           ; candidate flottante : décision dans 1 s
    PersoAttente[hwnd] := A_TickCount
}
PersoFlottanteEligible(hwnd) {
    static classes := '|Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|#32768|tooltips_class32|Windows.UI.Core.CoreWindow|XamlExplorerHostIslandWindow|TopLevelWindowForOverflowXamlIsland|NotifyIconOverflowWindow|MultitaskingViewFrame|ForegroundStaging|TaskListThumbnailWnd|ApplicationManager_ImmersiveShellWindow|'
    static exes := '|komorebi.exe|komorebic.exe|yasb.exe|Flow.Launcher.exe|ShellExperienceHost.exe|StartMenuExperienceHost.exe|SearchHost.exe|TextInputHost.exe|LockApp.exe|NVIDIA Overlay.exe|ScreenClippingHost.exe|SnippingTool.exe|'
    if (!WinExist(hwnd) || !DllCall('IsWindowVisible', 'Ptr', hwnd))
        return false
    if (WinGetMinMax(hwnd) != 0)                     ; réduite ou maximisée
        return false
    if (WinGetExStyle(hwnd) & 0x88)                  ; fenêtre outil, ou déjà au-dessus
        return false
    classe := WinGetClass(hwnd)
    if (InStr(classes, '|' classe '|') || InStr(classe, 'komoborder'))
        return false
    exe := WinGetProcessName(hwnd)
    if (InStr(exes, '|' exe '|') || PersoEstJeu(exe))
        return false
    cache := 0
    DllCall('dwmapi\DwmGetWindowAttribute', 'Ptr', hwnd, 'UInt', 14, 'Int*', &cache, 'UInt', 4)   ; DWMWA_CLOAKED
    if cache
        return false
    WinGetPos(&x, &y, &l, &h, hwnd)
    if (l < 80 || h < 40)
        return false
    MonitorGet(PersoEcran(x, y, l, h), &g, &t, &d, &b)
    return !(l >= (d - g) * 0.9 && h >= (b - t) * 0.9)   ; quasi plein écran : pas une flottante
}
; Jeux de Winarchy (games.toml / games.user.toml) : jamais forcés devant.
PersoEstJeu(exe) {
    static jeux := ''
    if (jeux = '') {
        jeux := '|'
        for f in ['C:\winarchy\games.toml', 'C:\winarchy\games.user.toml'] {
            try {
                txt := FileRead(f, 'UTF-8')
                pos := 1
                while (pos := RegExMatch(txt, 'm)^\s*exe\s*=\s*"([^"]+)"', &m, pos)) {
                    j := m[1]
                    jeux .= (RegExMatch(j, 'i)\.exe$') ? j : j '.exe') '|'
                    pos += m.Len
                }
            }
        }
    }
    return InStr(jeux, '|' exe '|')
}
; hwnd tuilés par komorebi (« |123|456| »), fenêtres flottantes de komorebi exclues ;
; « * » si komorebi ne répond pas (alors rien n'est forcé devant).
PersoTuilees() {
    f := A_Temp '\perso-komorebi-state.json'
    try {
        RunWait(A_ComSpec ' /c komorebic state > "' f '" 2>nul', , 'Hide')
        txt := FileRead(f, 'UTF-8')
    } catch
        return '*'
    if !InStr(txt, '"monitors"')
        return '*'
    res := '|', section := '', pos := 1
    while (pos := RegExMatch(txt, '"(containers|monocle_container|maximized_window|floating_windows)"|"hwnd":\s*(\d+)', &m, pos)) {
        if (m[1] != '')
            section := m[1]
        else if (section != 'floating_windows')
            res .= m[2] '|'
        pos += m.Len
    }
    return res
}
PersoEstTuilee(tuilees, hwnd) => (tuilees = '*' || InStr(tuilees, '|' hwnd '|'))
; Notifications que komorebi ignore : popups de Steam (toutes ses fenêtres sauf la
; principale « Steam ») et rappels Outlook. Devant sans délai, sans voler le focus.
PersoEstNotification(hwnd, classe) {
    exe := WinGetProcessName(hwnd)
    titre := WinGetTitle(hwnd)
    if (exe = 'steamwebhelper.exe')
        return (titre != 'Steam' && titre != '')
    return (exe = 'OUTLOOK.EXE' && RegExMatch(titre, 'i)^\d+ (rappel|reminder)'))
}
; Installeurs et désinstalleurs : MSI, Inno Setup (installe et désinstalle depuis un
; « …\is-XXXX.tmp\nom.tmp » ou « _iuXXXX.tmp »), WiX, InstallShield par leur classe ou
; leur processus ; NSIS et les autres par le nom du processus ou le titre.
PersoEstInstalleur(hwnd, classe) {
    static classes := '|MsiDialogCloseClass|MsiDialogNoCloseClass|TWizardForm|TSetupForm|TSelectLanguageForm|TNewDiskForm|TUninstallProgressForm|TUninstSharedFileForm|WixStdBA|InstallShield_Win|'
    if InStr(classes, '|' classe '|')
        return true
    exe := WinGetProcessName(hwnd)
    if RegExMatch(exe, 'i)^(msiexec\.exe|unins\d*\.exe|.*\.tmp|.*(setup|install|updat).*\.exe)$')
        return true
    return (classe = '#32770' && RegExMatch(WinGetTitle(hwnd), 'i)setup|install|désinstall|uninstall|assistant d|wizard|updat|mise à jour'))
}
PersoEcran(x, y, l, h) {
    ecran := MonitorGetPrimary()                     ; écran qui contient le centre de la fenêtre
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &g, &t, &d, &b)
        if (x + l // 2 >= g && x + l // 2 < d && y + h // 2 >= t && y + h // 2 < b)
            ecran := A_Index
    }
    return ecran
}
PersoCentre(hwnd) {
    WinGetPos(&x, &y, &l, &h, hwnd)
    MonitorGetWorkArea(PersoEcran(x, y, l, h), &g, &t, &d, &b)
    WinMove(g + (d - g - l) // 2, t + (b - t - h) // 2, , , hwnd)
}
'@

function Ok([string]$m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Info([string]$m) { Write-Host "  --  $m" -ForegroundColor DarkGray }
function Warn([string]$m) { Write-Host "  !!  $m" -ForegroundColor Yellow }
function Err([string]$m)  { Write-Host "  XX  $m" -ForegroundColor Red }

function Write-Utf8Bom([string]$path, [string]$text) {
    $text = $text -replace "`r?`n", "`r`n"
    # Inchangé : on ne touche pas au fichier (les scripts de la barre YASB peuvent être en cours
    # d'exécution, donc verrouillés). Sinon on réessaie quelques fois si le fichier est occupé.
    if ((Test-Path $path) -and [IO.File]::ReadAllText($path) -ceq $text) { return }
    for ($i = 1; ; $i++) {
        try { [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $true)); return }
        catch { if ($i -ge 10) { throw }; Start-Sleep -Milliseconds 300 }
    }
}

function Assert-PasAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ((New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Err 'PowerShell est lancé en administrateur. Relance ce script dans un PowerShell normal.'
        exit 1
    }
    Ok "Session normale ($($id.Name))"
}

function Find-AhkV2 {
    @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# Réglages Claude / gh (dossier profils\), sans jetons. Jamais écrasés s'ils existent.
function Copy-Profils {
    if (-not (Test-Path $Profils)) { Info "Pas de dossier profils ($Profils) : réglages Claude / gh non copiés"; return }
    Get-ChildItem $Profils -Recurse -File -Force | ForEach-Object {
        $rel  = $_.FullName.Substring($Profils.Length).TrimStart('\', '/')
        $dest = Join-Path $env:USERPROFILE $rel
        if (Test-Path $dest) { Info "Déjà présent, gardé : $dest" }
        else {
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $_.FullName $dest
            Ok "Réglage copié : $dest"
        }
    }
}

function Write-ClaudeLauncher {
    $claudePs1 = Join-Path $Perso 'claude.ps1'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $env:USERPROFILE 'Work') | Out-Null
    Write-Utf8Bom $claudePs1 @'
# Lance Claude Code dans ~\Work avec le compte demandé (foxis ou perso).
param([ValidateSet('foxis', 'perso')][string]$Profil = 'perso')
$env:CLAUDE_CONFIG_DIR = Join-Path $HOME ".claude-$Profil"
$env:GH_CONFIG_DIR     = Join-Path $HOME ".config\gh-$Profil"
Set-Location (Join-Path $HOME 'Work')
$Host.UI.RawUI.WindowTitle = "Claude ($Profil)"
if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude --permission-mode auto
} else {
    Write-Warning "Claude Code n'est pas installé (commande « claude » introuvable)."
}
'@
    Ok "Lanceur Claude : $claudePs1"
}

# Bouton capture de la barre YASB -> Screenpresso (il n'a pas d'option de capture en ligne
# de commande : on le démarre au besoin puis on envoie Impr. écran, son raccourci de capture).
function Write-ScreenpressoLauncher {
    $ahk = Join-Path $Perso 'screenpresso-capture.ahk'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Force
; Lancé par le bouton capture de la barre YASB (setup-winarchy.ps1).
exe := EnvGet('LOCALAPPDATA') '\Learnpulse\Screenpresso\Screenpresso.exe'
if !ProcessExist('Screenpresso.exe') {
    if !FileExist(exe) {
        MsgBox 'Screenpresso introuvable : ' exe, 'Capture', 'Icon!'
        ExitApp
    }
    Run '"' exe '"'
    if !ProcessWait('Screenpresso.exe', 10)
        ExitApp
    Sleep 2500   ; le temps qu'il enregistre son raccourci Impr. écran
}
Sleep 150        ; laisse le clic sur la barre se terminer
Send '{PrintScreen}'
'@
    Ok "Lanceur capture Screenpresso : $ahk"
}

# Bouton presse-papiers de la barre YASB -> historique du presse-papiers de Windows (Win+V).
function Write-PressePapiersLauncher {
    $ahk = Join-Path $Perso 'presse-papiers.ahk'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Remove-Item (Join-Path $Perso 'ditto-historique.ahk') -ErrorAction SilentlyContinue   # ancienne version (Ditto)
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Force
; Lancé par le bouton presse-papiers de la barre YASB (setup-winarchy.ps1).
Sleep 150        ; laisse le clic sur la barre se terminer
Send '#v'
'@
    Ok "Lanceur presse-papiers (Win+V) : $ahk"
}

# Widget « disques » de la barre YASB : % des disques locaux, détail réseau en bulle.
# Boîtes de dialogue et installeurs toujours devant : script séparé lancé en UI Access
# (AutoHotkey64_UIA.exe) par user.ahk, seul moyen de toucher aux fenêtres admin.
function Write-DevantScript {
    $ahk = Join-Path $Perso 'devant.ahk'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    $entete = "#Requires AutoHotkey v2.0`r`n#SingleInstance Force`r`n#NoTrayIcon`r`nPersistent`r`n" +
        "; Lancé en UI Access par user.ahk de Winarchy : écrit par setup-winarchy.ps1, ne pas modifier ici.`r`n"
    Write-Utf8Bom $ahk ($entete + $script:CorpsDevant + "`r`n")
    Ok "Script premier plan (UI Access) : $ahk"
}

function Write-DisquesScript {
    $ps1 = Join-Path $Perso 'disques.ps1'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ps1 @'
# Lancé par le widget « disques » de la barre YASB (setup-winarchy.ps1), en arrière-plan.
# Sortie JSON : local (barre), reseau (libellé alternatif), detail (bulle).
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$icLocal = [char]::ConvertFromUtf32(0xF02CA)    # nf-md-harddisk
$icReseau = [char]::ConvertFromUtf32(0xF0870)   # nf-md-folder_network
function Taille([double]$o) { if ($o -ge 1TB) { '{0:0.#} To' -f ($o / 1TB) } else { '{0:0} Go' -f ($o / 1GB) } }
# Win32_LogicalDisk : un seul appel, borné par un délai (un partage injoignable ne bloque pas).
$disques = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3 OR DriveType=4' -OperationTimeoutSec 8 -ErrorAction SilentlyContinue)
$local = @(); $reseau = @(); $localLibre = @(); $reseauLibre = @(); $detail = @()
foreach ($d in ($disques | Sort-Object DeviceID)) {
    $lettre = $d.DeviceID.TrimEnd(':')
    $nom = if ($d.DriveType -eq 4) { "$($d.VolumeName) ($($d.ProviderName))" } else { $d.VolumeName }
    if ($d.Size -gt 0 -and $null -ne $d.FreeSpace) {
        $pct = [int][math]::Round(100 * ($d.Size - $d.FreeSpace) / $d.Size)
        $court = "$lettre $pct%"; $libre = "$lettre $(Taille $d.FreeSpace)"
        $detail += "$($d.DeviceID) $nom : $pct % utilisé, $(Taille $d.FreeSpace) libres sur $(Taille $d.Size)"
    } else {
        $court = "$lettre ?"; $libre = "$lettre ?"
        $detail += "$($d.DeviceID) $nom : injoignable"
    }
    if ($d.DriveType -eq 4) { $reseau += $court; $reseauLibre += $libre } else { $local += $court; $localLibre += $libre }
}
if (-not $disques) { $detail = @('Disques : lecture impossible (délai dépassé)') }
[pscustomobject]@{
    local  = "$icLocal " + $(if ($local) { $local -join '  ' } else { '?' })
    reseau = "$icReseau " + $(if ($reseau) { $reseau -join '  ' } else { 'aucun' })
    local_libre  = "$icLocal " + $(if ($localLibre) { $localLibre -join '  ' } else { '?' })
    reseau_libre = "$icReseau " + $(if ($reseauLibre) { $reseauLibre -join '  ' } else { 'aucun' })
    detail = $detail -join "`n"
} | ConvertTo-Json -Compress
'@
    Ok "Script disques (barre YASB) : $ps1"
}

# Widgets perf (GPU / CPU / RAM) de la barre YASB : les natifs n'ont pas de bulle au survol.
# Le widget CPU lance perf.ps1, qui écrit perf.json ; GPU et RAM ne font que relire ce fichier
# (un seul PowerShell par relevé au lieu de trois).
function Write-PerfScript {
    $ps1 = Join-Path $Perso 'perf.ps1'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ps1 @'
# Lancé par le widget « cpu » de la barre YASB (setup-winarchy.ps1), en arrière-plan.
# Sortie JSON (aussi écrite dans perf.json, relu par les widgets gpu et memory).
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$inv = [Globalization.CultureInfo]::InvariantCulture
$dossier = Split-Path $MyInvocation.MyCommand.Path
$icCpu = [char]::ConvertFromUtf32(0xF4BC); $icGpu = [char]::ConvertFromUtf32(0xF08AE); $icRam = [char]::ConvertFromUtf32(0xF035B)
function Go([double]$o) { '{0:0.0} Go' -f ($o / 1GB) }
# Infos fixes (Win32_Processor est lent : ~1 s) mises en cache une fois.
$fixe = Join-Path $dossier 'perf-fixe.json'
$f = $null
try { $f = Get-Content $fixe -Raw -ErrorAction Stop | ConvertFrom-Json } catch {}
if (-not $f) {
    $c = Get-CimInstance Win32_Processor | Select-Object -First 1
    $v = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Virtual|Parsec|Remote' } | ForEach-Object Name)
    $f = [pscustomobject]@{ cpu = $c.Name.Trim(); mhz = [int]$c.MaxClockSpeed; coeurs = [int]$c.NumberOfCores; threads = [int]$c.NumberOfLogicalProcessors; gpus = $v }
    $f | ConvertTo-Json -Compress | Set-Content $fixe -Encoding UTF8
}
# Processeur : même mesure que le Gestionnaire des tâches (Processor Utility).
$p = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'"
$cpu = [math]::Min(100, [int]$p.PercentProcessorUtility)
$ghz = $f.mhz * $p.PercentProcessorPerformance / 100000
# Mémoire
$o = Get-CimInstance Win32_OperatingSystem
$tot = $o.TotalVisibleMemorySize * 1KB; $libre = $o.FreePhysicalMemory * 1KB; $util = $tot - $libre
$ram = 100 * $util / $tot
$swapTot = $o.SizeStoredInPagingFiles * 1KB; $swapUtil = $swapTot - $o.FreeSpaceInPagingFiles * 1KB
# Carte graphique : nvidia-smi si présent, sinon compteurs Windows (moteur 3D, mémoire dédiée).
$gpu = $null; $gpuDetail = @()
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($smi) {
    $l = & $smi.Source --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1
    if ($l) {
        $x = $l -split ',\s*'
        $gpu = [int]$x[1]; $vUtil = [double]$x[2] * 1MB; $vTot = [double]$x[3] * 1MB
        $gpuDetail = @("Carte graphique : $($x[0])", "Charge : $gpu %", "Mémoire vidéo : $(Go $vUtil) / $(Go $vTot)", "Température : $([int][double]::Parse($x[4], $inv)) °C")
        $gpuAlt = "$icGpu $(Go $vUtil) / $(Go $vTot)"
    }
}
if ($null -eq $gpu) {
    $e = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -ErrorAction SilentlyContinue | Where-Object Name -like '*engtype_3D')
    $gpu = [math]::Min(100, [int](($e | Measure-Object UtilizationPercentage -Sum).Sum))
    $m = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -ErrorAction SilentlyContinue)
    $vUtil = ($m | Measure-Object DedicatedUsage -Sum).Sum
    $gpuDetail = @("Carte graphique : $($f.gpus -join ', ')", "Charge (3D) : $gpu %", "Mémoire vidéo utilisée : $(Go $vUtil)")
    $gpuAlt = "$icGpu $(Go $vUtil)"
}
$r = [ordered]@{
    cpu = "$icCpu $cpu%"
    cpu_alt = "$icCpu " + $ghz.ToString('0.00', $inv) + ' GHz'
    cpu_detail = (@("Processeur : $($f.cpu)", "Charge : $cpu %", ('Fréquence : {0:0.00} GHz (max {1:0.00})' -f $ghz, ($f.mhz / 1000)), "Cœurs : $($f.coeurs) ($($f.threads) threads)", "Processus : $((Get-Process).Count)") -join "`n")
    gpu = "$icGpu $gpu%"
    gpu_alt = $gpuAlt
    gpu_detail = $gpuDetail -join "`n"
    ram = "$icRam " + $ram.ToString('0.0', $inv) + '%'
    ram_alt = "$icRam $(Go $libre) libres"
    ram_detail = (@(('Mémoire : {0:0.0} % utilisée' -f $ram), "Utilisée : $(Go $util) / $(Go $tot)", "Libre : $(Go $libre)", "Fichier d'échange : $(Go $swapUtil) / $(Go $swapTot)") -join "`n")
}
$json = $r | ConvertTo-Json -Compress
# Écriture atomique (GPU/RAM lisent le fichier en parallèle).
$tmp = Join-Path $dossier 'perf.json.tmp'
[IO.File]::WriteAllText($tmp, $json, [Text.UTF8Encoding]::new($false))
Move-Item $tmp (Join-Path $dossier 'perf.json') -Force
$json
'@
    Remove-Item (Join-Path $Perso 'perf-fixe.json') -ErrorAction SilentlyContinue   # recalculé (ex. autre PC)
    Ok "Script perf (barre YASB) : $ps1"
}

# Widget réseau (wifi) de la barre YASB : l'icône vient toujours du watcher de Winarchy
# (state\net-icon.flag) ; reseau.ps1 ajoute la bulle (connexion active, IP, débit, VPN).
function Write-ReseauScript {
    $ps1 = Join-Path $Perso 'reseau.ps1'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ps1 @'
# Lancé par le widget « wifi » de la barre YASB (setup-winarchy.ps1), en arrière-plan.
# Sortie JSON : icone (barre, écrite par le watcher Start-NetIcon.ps1 de Winarchy), detail (bulle).
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$flag = Join-Path $env:KOMOREBI_CONFIG_HOME '..\..\state\net-icon.flag'
$icone = if (Test-Path $flag) { ([IO.File]::ReadAllText($flag, [Text.Encoding]::UTF8)).Trim() } else { [char]::ConvertFromUtf32(0xF092E) }
function Debit([double]$o) { $b = $o * 8; if ($b -ge 1e6) { '{0:0.0} Mb/s' -f ($b / 1e6) } else { '{0:0} kb/s' -f ($b / 1e3) } }
function Vitesse([double]$b) { if ($b -ge 1e9) { '{0:0.#} Gb/s' -f ($b / 1e9) } else { '{0:0} Mb/s' -f ($b / 1e6) } }
$detail = @()
# Connexion active = route par défaut de plus faible métrique.
$route = Get-CimInstance Win32_IP4RouteTable -Filter "Destination='0.0.0.0'" -ErrorAction SilentlyContinue | Sort-Object Metric1 | Select-Object -First 1
$configs = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=TRUE' -ErrorAction SilentlyContinue)
if ($route) {
    $cfg = $configs | Where-Object InterfaceIndex -eq $route.InterfaceIndex | Select-Object -First 1
    $ad = Get-CimInstance Win32_NetworkAdapter -Filter "InterfaceIndex=$($route.InterfaceIndex)" -ErrorAction SilentlyContinue
    $wifi = $false
    $w = (netsh wlan show interfaces 2>$null) -join "`n"
    $ssid = if ($w -match '(?m)^\s*SSID\s*:\s*(.+?)\s*$') { $Matches[1] }
    $signal = if ($w -match '(?m)^\s*Signal\s*:\s*(\d+)') { $Matches[1] }
    if ($ssid -and $cfg.Description -match 'Wi-?Fi|Wireless|WLAN|802\.11') { $wifi = $true }
    $detail += if ($wifi) { "Wi-Fi : $ssid ($signal %)" } else { "Ethernet : $($ad.NetConnectionID)" }
    $detail += "Carte : $($cfg.Description)"
    if ($ad.Speed) { $detail += "Vitesse du lien : $(Vitesse $ad.Speed)" }
    $ipv4 = @($cfg.IPAddress | Where-Object { $_ -match '^\d+\.' })
    $detail += "Adresse IP : $($ipv4 -join ', ')"
    $detail += "Passerelle : $($route.NextHop)"
    # IP publique (api.ipify.org) : en cache 10 min, redemandée tout de suite si le réseau change.
    $cache = Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'ip-publique.json'
    $cle = "$($route.NextHop)|$($ipv4 -join ',')"
    $pub = $null
    try { $c = Get-Content $cache -Raw -ErrorAction Stop | ConvertFrom-Json; if ($c.cle -eq $cle -and ((Get-Date) - [datetime]$c.date).TotalMinutes -lt 10) { $pub = $c.ip } } catch {}
    if (-not $pub) {
        try {
            $pub = (Invoke-RestMethod 'https://api.ipify.org' -TimeoutSec 4 -UseBasicParsing).ToString().Trim()
            if ($pub -notmatch '^[\d.:a-fA-F]+$') { throw 'réponse invalide' }
            [pscustomobject]@{ cle = $cle; ip = $pub; date = (Get-Date).ToString('o') } | ConvertTo-Json -Compress | Set-Content $cache -Encoding UTF8
        } catch { $pub = 'indisponible' }
    }
    $detail += "IP publique : $pub"
    if ($cfg.DNSServerSearchOrder) { $detail += "DNS : $($cfg.DNSServerSearchOrder -join ', ')" }
    # Débit instantané (le compteur remplace ( ) par [ ] dans le nom de la carte).
    $inst = $cfg.Description.Replace('(', '[').Replace(')', ']')
    $n = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface -ErrorAction SilentlyContinue | Where-Object Name -eq $inst | Select-Object -First 1
    if ($n) { $detail += "Débit : ↓ $(Debit $n.BytesReceivedPersec)  ↑ $(Debit $n.BytesSentPersec)" }
} else {
    $detail += 'Pas de connexion réseau'
}
# VPN actifs (tunnels avec une adresse IP).
$vpn = @($configs | Where-Object { $_.Description -match 'WireGuard|OpenVPN|TAP-|Wintun|VPN|Tailscale|ZeroTier' } | ForEach-Object { "$($_.Description) ($((@($_.IPAddress | Where-Object { $_ -match '^\d+\.' })) -join ', '))" })
if ($vpn) { $detail += "VPN : $($vpn -join ' ; ')" }
[pscustomobject]@{ icone = $icone; detail = $detail -join "`n" } | ConvertTo-Json -Compress
'@
    Ok "Script réseau (barre YASB) : $ps1"
}

# Les raccourcis Claude Desktop ouvrent la version Store (AppID Claude_pzs8sxrjxfjjc).
function Test-ClaudeDesktop {
    if (Get-StartApps -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'Claude' }) { Ok 'Claude Desktop installé' }
    else { Warn 'Claude Desktop introuvable : installe-le (Microsoft Store) pour les raccourcis Claude Desktop.' }
}

# Focus qui suit la souris : réglage natif de Windows (« activer une fenêtre en la
# survolant »), enregistré dans le profil. Indépendant de Winarchy : ni un changement de
# thème ni un rechargement ne l'effacent.
function Set-Survol([bool]$actif) {
    if (-not ('PersoWinarchy.Spi' -as [type])) {
        Add-Type -Namespace PersoWinarchy -Name Spi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr v, uint c);'
    }
    $enregistrer = 3   # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
    [void][PersoWinarchy.Spi]::SystemParametersInfo(0x1001, 0, [IntPtr][int]$actif, $enregistrer)   # ACTIVEWINDOWTRACKING
    if ($actif) {
        [void][PersoWinarchy.Spi]::SystemParametersInfo(0x100D, 0, [IntPtr]1, $enregistrer)     # premier plan au survol
        [void][PersoWinarchy.Spi]::SystemParametersInfo(0x2003, 0, [IntPtr]150, $enregistrer)   # après 150 ms
        Ok 'Focus qui suit la souris activé (survol = fenêtre active)'
    } else {
        Ok 'Focus qui suit la souris désactivé'
    }
}

# Touche Office (Ctrl+Alt+Maj+Super) : Windows s'en sert pour ouvrir Office / Copilot, ce
# qui vole le focus des raccourcis Hyper (Super+Ctrl+Alt+Maj+…). Désactivée en
# redirigeant le protocole ms-officeapp vers rundll32 (ne fait rien).
function Set-ToucheOffice([bool]$desactivee) {
    $cle = 'HKCU:\Software\Classes\ms-officeapp'
    if ($desactivee) {
        New-Item "$cle\Shell\Open\Command" -Force | Out-Null
        Set-Item "$cle\Shell\Open\Command" -Value 'rundll32'
        Ok 'Touche Office désactivée (Ctrl+Alt+Maj+Super n''ouvre plus Office / Copilot)'
    } elseif (Test-Path $cle) {
        Remove-Item $cle -Recurse -Force
        Ok 'Touche Office rétablie'
    }
}

function Find-WinarchyKomorebi {
    $racines = @()
    $cmd = Get-Command winarchy -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { $racines += (Split-Path (Split-Path $cmd.Source)) }
    $racines += 'C:\winarchy'
    foreach ($r in $racines) {
        if (Test-Path (Join-Path $r 'config\ahk\winarchy.ahk')) { return $r }
    }
    return $null
}

# --- Raccourcis : bloc AutoHotkey dans config\ahk\user.ahk ------------------------

# Bloc perso, quel que soit le nom du script entre parenthèses dans le marqueur : les blocs
# posés sous l'ancien nom (installer-raccourcis-winarchy.ps1) sont aussi reconnus et remplacés.
function Remove-BlocAhk([string]$text) {
    $debut = [regex]::Escape($AhkDebut).Replace([regex]::Escape('(setup-winarchy.ps1)'), '\([^)]*\.ps1\)')
    $motif = '(?s)(\r?\n)*' + $debut + '.*?' + [regex]::Escape($AhkFin) + '[^\r\n]*'
    [regex]::Replace($text, $motif, '')
}

# Écrit user.ahk, le valide avec AutoHotkey, et revient en arrière si ça ne passe pas.
function Save-UserAhk([string]$userAhk, [string]$mainAhk, [string]$ahkExe, [string]$text) {
    $text = ($text -replace "`r?`n", "`r`n").TrimEnd() + "`r`n"
    $avant = if (Test-Path $userAhk) { [IO.File]::ReadAllText($userAhk) } else { $null }
    if ($null -ne $avant) { Copy-Item $userAhk "$userAhk.bak" -Force }
    [IO.File]::WriteAllText($userAhk, $text, (New-Object Text.UTF8Encoding $false))
    $sortie = & $ahkExe /ErrorStdOut /validate $mainAhk 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $sortie.Trim()) {
        if ($null -ne $avant) { [IO.File]::WriteAllText($userAhk, $avant, (New-Object Text.UTF8Encoding $false)) }
        else { Remove-Item $userAhk -Force }
        Err "AutoHotkey refuse le résultat, user.ahk remis comme avant :`n$sortie"
        exit 1
    }
    Ok "user.ahk à jour et validé par AutoHotkey (sauvegarde : $userAhk.bak)"
}

function Restart-WinarchyAhk([string]$mainAhk, [string]$ahkExe) {
    Start-Process $ahkExe -ArgumentList '/restart', "`"$mainAhk`""
    Start-Sleep -Seconds 2
    $ok = Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*winarchy.ahk*' }
    if ($ok) { Ok 'winarchy.ahk relancé avec tes raccourcis' } else { Err 'winarchy.ahk ne tourne pas : lance « winarchy reload ».' }
}

# Fenêtres admin tilées par défaut : komorebi sans droits admin ne peut pas déplacer une
# fenêtre lancée en administrateur (Gestionnaire des tâches, installeurs…). La tâche
# \Winarchy\komorebi passe en « privilèges les plus élevés » (une fenêtre UAC, une seule
# fois). Winarchy la réenregistre sans droits admin à chaque mise à jour : ça échoue et
# l'ancienne tâche reste (Autostart.ps1). -Desinstaller la remet en droits limités.
function Set-KomorebiAdmin([bool]$admin) {
    $tache = '\Winarchy\komorebi'
    $voulu = if ($admin) { 'HighestAvailable' } else { 'LeastPrivilege' }
    $xml = (& schtasks.exe /Query /TN $tache /XML 2>$null) -join "`r`n"
    if ($LASTEXITCODE -ne 0) { Warn "Tâche $tache introuvable : komorebi admin non réglé"; return }
    # RunLevel est absent de l'export quand il vaut LeastPrivilege (défaut).
    $actuel = if ($xml -match '<RunLevel>([^<]+)</RunLevel>') { $Matches[1] } else { 'LeastPrivilege' }
    if ($actuel -ne $voulu) {
        $neuf = $xml -replace '\s*<RunLevel>[^<]*</RunLevel>', ''
        if ($admin) { $neuf = $neuf -replace '(<LogonType>InteractiveToken</LogonType>)', "`$1`r`n      <RunLevel>HighestAvailable</RunLevel>" }
        $tmp = Join-Path $env:TEMP 'winarchy-komorebi-tache.xml'
        Set-Content -Path $tmp -Value $neuf -Encoding Unicode
        $cmd = "& schtasks.exe /Create /TN '$tache' /XML '$tmp' /F | Out-Null; exit `$LASTEXITCODE"
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        Info 'Fenêtre UAC : accepte-la pour régler komorebi (fenêtres admin tilées)'
        try {
            $p = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -WindowStyle Hidden -ArgumentList '-NoProfile', '-EncodedCommand', $enc
            if ($p.ExitCode -ne 0) { throw "schtasks a renvoyé $($p.ExitCode)" }
        } catch {
            Warn "komorebi pas réglé ($($_.Exception.Message)) : les fenêtres admin ne seront pas tilées"
            return
        } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    }
    if ($admin) { Ok 'komorebi lancé en administrateur : fenêtres admin tilées' } else { Ok 'komorebi remis en droits limités' }
    # komorebi lancé avec d'autres droits, ou règles modifiées : relance par la tâche.
    $k = Get-Process komorebi -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $k) {
        if ($admin) { & schtasks.exe /Run /TN $tache *> $null; Ok 'komorebi lancé par sa tâche planifiée' }
        return
    }
    # Sans droits admin, le handle d'un processus élevé est refusé (null ou exception).
    $h = try { $k.Handle } catch { $null }
    $eleve = $null -eq $h
    # komorebi garde les anciennes règles jusqu'au redémarrage (reload ne retire rien).
    if ($eleve -ne $admin -or $script:RedemarrerKomorebi) {
        $komorebic = Join-Path $env:ProgramFiles 'komorebi\bin\komorebic.exe'
        & $komorebic stop *> $null
        Start-Sleep -Seconds 2
        & schtasks.exe /Run /TN $tache *> $null
        $script:RedemarrerKomorebi = $false
        Ok 'komorebi relancé par sa tâche planifiée (règles à jour)'
    }
}

function Install-Raccourcis([string]$Root) {
    $MainAhk = Join-Path $Root 'config\ahk\winarchy.ahk'
    $UserAhk = Join-Path $Root 'config\ahk\user.ahk'
    $Komorebic = Join-Path $env:ProgramFiles 'komorebi\bin\komorebic.exe'
    if (-not (Test-Path $Komorebic)) { $Komorebic = 'komorebic.exe' }

    $ahkExe = Find-AhkV2
    if (-not $ahkExe) { Err 'AutoHotkey v2 introuvable : « winarchy update --core » l''installe.'; exit 1 }
    Ok "AutoHotkey v2 : $ahkExe"
    if (-not (Select-String -Path $MainAhk -SimpleMatch 'user.ahk' -Quiet)) {
        Err "$MainAhk n'inclut pas user.ahk : version de Winarchy inattendue, rien n'est modifié."
        exit 1
    }
    Ok 'winarchy.ahk inclut user.ahk'

    $delta = 50
    if (Get-Process komorebi -ErrorAction SilentlyContinue) {
        Ok 'komorebi tourne'
        try {
            $etat = & $Komorebic state | ConvertFrom-Json
            if ($etat.resize_delta) { $delta = [int]$etat.resize_delta }
            if ($etat.is_paused) {
                & $Komorebic toggle-pause | Out-Null
                Ok 'komorebi était en pause (plus aucune fenêtre tilée) : pause levée'
            }
        } catch { Warn "État de komorebi illisible : $($_.Exception.Message)" }
    } else { Warn 'komorebi ne tourne pas : lance « winarchy reload ».' }

    $texte = if (Test-Path $UserAhk) { [IO.File]::ReadAllText($UserAhk) } else { "; Surcharges perso de Winarchy (survivent aux mises a jour).`r`n" }
    $texte = Remove-BlocAhk $texte
    # Anciennes définitions écrites à la main hors du bloc, maintenant dans le bloc :
    # Super+Shift+A (deux définitions = erreur AutoHotkey) et ToggleClaudeDesktop()
    # (remplacée par PersoClaudeBascule).
    $texte = [regex]::Replace($texte, '(?m)^#\+a::.*(\r?\n)?', '')
    $texte = [regex]::Replace($texte, '(?ms)^ToggleClaudeDesktop\(\)\s*\{.*?^\}[^\r\n]*(\r?\n)?', '')

    if ($Desinstaller) {
        Write-Host '==> Désinstallation des raccourcis perso'
        Save-UserAhk $UserAhk $MainAhk $ahkExe $texte
        Restart-WinarchyAhk $MainAhk $ahkExe
        Set-Survol $false
        Set-ToucheOffice $false
        Set-KomorebiAdmin $false
        if (Test-Path $Perso) { Remove-Item $Perso -Recurse -Force; Ok "Supprimé : $Perso" }
        return
    }

    Write-Host '==> Installation des raccourcis perso'
    Copy-Profils
    Write-ClaudeLauncher
    Write-ScreenpressoLauncher
    Write-PressePapiersLauncher
    Write-DisquesScript
    Write-PerfScript
    Write-ReseauScript
    Write-DevantScript
    Test-ClaudeDesktop
    $shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

    $bloc = @'
; >>> raccourcis-perso (setup-winarchy.ps1) >>>
; Bloc réécrit à chaque lancement de setup-winarchy.ps1 : modifie plutôt
; le script, sinon tes changements sautent. Le #HotIf toujours vrai fait passer ces
; raccourcis devant ceux de winarchy.ahk, qui inclut ce fichier à la fin.
InstallMouseHook()
#HotIf true
; --- Perso : applis -----------------------------------------------------------
#Backspace::PersoClaude('foxis')                  ; Claude Code (Foxis)
#+Backspace::PersoClaude('perso')                 ; Claude Code (perso)
#^+Backspace::PersoClaudeBascule()                ; Claude Desktop : ouvre / affiche / replie
#^!+Backspace::PersoClaudeBascule()               ; Claude Desktop (même chose, avec Alt)
#+a::return                                       ; Supprimé (webapp claude.ai de Winarchy)
#^!+Enter::PersoClaudePerso()                     ; Claude Desktop perso (2e instance, compte perso)
#a::PersoExpose()                                 ; Exposé (Vue des tâches)
#!Tab::PersoExpose()                              ; Exposé (Vue des tâches)
#o::PersoOutlook()                                ; Outlook (remplace Obsidian de Winarchy)
#+o::return                                       ; Supprimé (Outlook est passé sur Super+O)
#m::PersoDeezer()                                 ; Deezer (remplace la musique de Winarchy)
#y::return                                        ; Supprimés : applis web de Winarchy
#x::return                                        ;   (YouTube, X, Google Calendar, WhatsApp)
#c::return
#g::return
#+n::Run('notepad.exe')                           ; Bloc-notes
#r::Run('explorer.exe shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}')   ; Exécuter
#i::Run('ms-settings:')                           ; Paramètres Windows
#Space::Send('^{Esc}')                            ; Menu Démarrer
#q::ShowMainMenu()                                ; Menu Winarchy
; Super seul = lanceur d'applis (Flow, l'ancien Super+Espace) au lieu du menu Démarrer.
; « Seul » = aucune autre touche ni clic pendant l'appui, relâché en moins d'une
; demi-seconde (Super+glisser, Super+chiffre, etc. n'ouvrent donc rien).
~LWin::PersoSuper(true)
LWin up::PersoSuper(false)
; --- Perso : fenêtres ---------------------------------------------------------
#^!Left::PersoVersEcran('left')                   ; Fenêtre vers l'écran voisin (position réelle)
#^!Up::PersoVersEcran('up')
#^!Right::PersoVersEcran('right')
#^!Down::PersoVersEcran('down')
#!1::PersoEcran(1, 'focus')                       ; Aller sur l'écran N (numérotés de gauche à droite)
#!2::PersoEcran(2, 'focus')
#!3::PersoEcran(3, 'focus')
#!4::PersoEcran(4, 'focus')
#!+1::PersoEcran(1, 'move')                       ; Envoyer la fenêtre sur l'écran N (et la suivre)
#!+2::PersoEcran(2, 'move')
#!+3::PersoEcran(3, 'move')
#!+4::PersoEcran(4, 'move')
#f::PersoPlein()                                  ; Plein : seule = centrée <-> pleine largeur ; sinon monocle
#+f::return                                       ; Supprimé (agrandissement Windows de Winarchy)
#+t::PersoToutTiler()                             ; Tout le bureau en tiling, tuiles à parts égales (remplace « thème suivant »)
#^r::PersoKomorebic('retile')                     ; Retile simple
#^Space::return                                   ; Supprimé (fond d'écran suivant de Winarchy, reste dans le menu Super+Q)
#!Left::PersoPlace('left')                        ; Caler : moitiés, puis coins en combinant
#!Right::PersoPlace('right')
#!Up::PersoPlace('up')
#!Down::PersoPlace('down')
#z::PersoResize()                                 ; Mode redimensionnement
#s::PersoCache()                                  ; Réduire la fenêtre active
#+s::PersoRameneTout()                            ; Ramener toutes les fenêtres cachées
#p::Run('ms-settings-displays-topology:projection')   ; Projeter (menu Windows)
#HotIf PersoResizeOn()
Left::PersoResizePas('horizontal', 'decrease', 100)
h::PersoResizePas('horizontal', 'decrease', 100)
Right::PersoResizePas('horizontal', 'increase', 100)
l::PersoResizePas('horizontal', 'increase', 100)
Down::PersoResizePas('vertical', 'increase', 100)
j::PersoResizePas('vertical', 'increase', 100)
Up::PersoResizePas('vertical', 'decrease', 100)
k::PersoResizePas('vertical', 'decrease', 100)
+Left::PersoResizePas('horizontal', 'decrease', 25)
+h::PersoResizePas('horizontal', 'decrease', 25)
+Right::PersoResizePas('horizontal', 'increase', 25)
+l::PersoResizePas('horizontal', 'increase', 25)
+Down::PersoResizePas('vertical', 'increase', 25)
+j::PersoResizePas('vertical', 'increase', 25)
+Up::PersoResizePas('vertical', 'decrease', 25)
+k::PersoResizePas('vertical', 'decrease', 25)
Escape::PersoResizeFin()
Enter::PersoResizeFin()
#HotIf

PersoSuper(bas) {
    static depuis := 0
    SetKeyDelay(-1, -1)
    if bas {
        Send('{Blind}{vkE8}')          ; masque Super seul : Windows n'ouvre pas Démarrer
        if !depuis
            depuis := A_TickCount
        return
    }
    Send('{Blind}{vkE8}{LWin up}')
    seul := (A_PriorKey = 'LWin' && A_TickCount - depuis < 500)
    depuis := 0
    if seul
        ToggleFlow()
}

PersoKomorebic(cmd) {
    global KomorebicExe
    RunWait('"' KomorebicExe '" ' cmd, , 'Hide')
}

; État complet de komorebi (lève une erreur s'il est illisible). Le document HTML qui
; fournit le parseur JSON est gardé : les objets rendus en dépendent.
PersoEtat() {
    global KomorebicExe
    static doc := 0
    if !doc {
        doc := ComObject('htmlfile')
        doc.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
    }
    tmp := A_Temp '\winarchy-perso-state.json'
    RunWait(A_ComSpec ' /c ""' KomorebicExe '" state > "' tmp '""', , 'Hide')
    return doc.parentWindow.JSON.parse(FileRead(tmp))
}

; Écrans de komorebi rangés de gauche à droite (puis de haut en bas) : la numérotation de
; Windows / komorebi ne suit pas la position physique. Renvoie [indices komorebi, état].
PersoEcransTries() {
    state := PersoEtat()
    els := state.monitors.elements
    ecrans := []
    Loop els.length {
        i := A_Index - 1
        s := els.%i%.size
        ecrans.Push({idx: i, x: s.left + s.right / 2, y: s.top + s.bottom / 2, l: s.left, t: s.top})
    }
    ; tri par insertion (4 écrans au plus)
    Loop ecrans.Length - 1 {
        j := A_Index + 1
        e := ecrans[j], k := j - 1
        while k >= 1 && (ecrans[k].l > e.l || (ecrans[k].l = e.l && ecrans[k].t > e.t)) {
            ecrans[k + 1] := ecrans[k], k--
        }
        ecrans[k + 1] := e
    }
    return [ecrans, state]
}

; Super+Alt+N : aller sur l'écran N ; Super+Alt+Maj+N : y envoyer la fenêtre active.
PersoEcran(n, action) {
    try {
        r := PersoEcransTries(), ecrans := r[1]
        if n > ecrans.Length
            return
        PersoKomorebic((action = 'move' ? 'move-to-monitor ' : 'focus-monitor ') ecrans[n].idx)
    }
}

; Super+Ctrl+Alt+flèche : fenêtre vers l'écran le plus proche dans cette direction.
PersoVersEcran(dir) {
    try {
        r := PersoEcransTries(), ecrans := r[1], state := r[2]
        cur := 0
        for e in ecrans
            if e.idx = state.monitors.focused
                cur := e
        if !cur
            return
        best := 0, bestD := 0
        for e in ecrans {
            dx := e.x - cur.x, dy := e.y - cur.y
            ok := (dir = 'left' && dx < 0 && Abs(dx) >= Abs(dy)) || (dir = 'right' && dx > 0 && Abs(dx) >= Abs(dy))
               || (dir = 'up' && dy < 0 && Abs(dy) > Abs(dx)) || (dir = 'down' && dy > 0 && Abs(dy) > Abs(dx))
            d := dx * dx + dy * dy
            if ok && (!best || d < bestD)
                best := e, bestD := d
        }
        if best
            PersoKomorebic('move-to-monitor ' best.idx)
    }
}

; Barres, bureau et YASB : jamais déplacés ni réduits.
PersoIgnoree(h) {
    return WinGetClass('ahk_id ' h) ~= '^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$'
        || WinGetProcessName('ahk_id ' h) = 'yasb.exe'
}

; Super+F : une seule fenêtre en tuile -> bascule centrée / pleine largeur (bureau actif) ;
; plusieurs -> monocle. Si le monocle est déjà actif, Super+F le quitte.
PersoPlein() {
    static coupe := Map()   ; bureaux dont Super+F a coupé le centrage pour le monocle
    try {
        state := PersoEtat()
        im := state.monitors.focused
        m := state.monitors.elements.%im%
        iw := m.workspaces.focused
        w := m.workspaces.elements.%iw%
        cle := im '-' iw
        ; komorebi compte un monocle comme « une fenêtre » : le centrage s'y appliquerait.
        ; On le coupe en entrant en monocle et on le remet en sortant.
        if IsObject(w.monocle_container) {
            PersoKomorebic('toggle-monocle')
            if (coupe.Has(cle) && !w.apply_window_based_work_area_offset)
                PersoKomorebic('toggle-window-based-work-area-offset')
            if coupe.Has(cle)
                coupe.Delete(cle)
            return
        }
        if (w.containers.elements.length <= 1)
            return PersoKomorebic('toggle-window-based-work-area-offset')
        if w.apply_window_based_work_area_offset {
            PersoKomorebic('toggle-window-based-work-area-offset')
            coupe[cle] := true
        }
    }
    PersoKomorebic('toggle-monocle')
}

; Vraie fenêtre d'application : visible, non réduite, sur le bureau affiché (pas « cloaked »),
; avec barre de titre, sans propriétaire, et pas une barre, un overlay ou le bureau.
PersoFenetreApp(h) {
    try {
        if !DllCall('IsWindowVisible', 'Ptr', h) || DllCall('IsIconic', 'Ptr', h)
            return false
        if DllCall('GetWindow', 'Ptr', h, 'UInt', 4, 'Ptr')          ; GW_OWNER
            return false
        cloak := 0
        DllCall('dwmapi\DwmGetWindowAttribute', 'Ptr', h, 'UInt', 14, 'Int*', &cloak, 'UInt', 4)
        if cloak
            return false
        if (WinGetStyle(h) & 0xC00000) != 0xC00000                     ; WS_CAPTION
            return false
        if WinGetExStyle(h) & 0x8000080                                ; TOOLWINDOW / NOACTIVATE
            return false
        if WinGetTitle(h) = ''
            return false
        if WinGetClass(h) ~= '^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|Windows\.UI\.Core\.CoreWindow)$'
            return false
        if WinGetProcessName(h) ~= 'i)^(komorebi.*|yasb|Flow\.Launcher|AutoHotkey.*)\.exe$'
            return false
        return true
    }
    return false
}

; Super+Shift+T : remet tout le bureau actif en tiling. Les fenêtres flottantes (Super+Alt+
; flèches, Super+T) reprennent une tuile, le monocle est quitté, le centrage est coupé, et
; les tailles changées à la main repartent à parts égales. Les fenêtres d'application que
; komorebi ne gérait pas sont aussi reprises.
PersoToutTiler() {
    actif := WinExist('A')
    try {
        state := PersoEtat()
        im := state.monitors.focused
        m := state.monitors.elements.%im%
        iw := m.workspaces.focused
        w := m.workspaces.elements.%iw%
        if IsObject(w.monocle_container)
            PersoKomorebic('toggle-monocle')
        if w.apply_window_based_work_area_offset      ; retour au défaut : pleine largeur
            PersoKomorebic('toggle-window-based-work-area-offset')
        ; Fenêtres d'application que komorebi a ratées (ouvertes pendant une pause, revenues
        ; de la barre des tâches...) : on les lui fait prendre en charge.
        geres := Map()
        Loop state.monitors.elements.length {
            mm := state.monitors.elements.%(A_Index - 1)%
            Loop mm.workspaces.elements.length {
                ww := mm.workspaces.elements.%(A_Index - 1)%
                Loop ww.containers.elements.length {
                    cc := ww.containers.elements.%(A_Index - 1)%
                    Loop cc.windows.elements.length
                        geres[cc.windows.elements.%(A_Index - 1)%.hwnd] := 1
                }
                Loop ww.floating_windows.elements.length
                    geres[ww.floating_windows.elements.%(A_Index - 1)%.hwnd] := 1
                if IsObject(ww.monocle_container) {
                    cc := ww.monocle_container
                    Loop cc.windows.elements.length
                        geres[cc.windows.elements.%(A_Index - 1)%.hwnd] := 1
                }
                if IsObject(ww.maximized_window)
                    geres[ww.maximized_window.hwnd] := 1
            }
        }
        for h in WinGetList() {
            if geres.Has(h) || !PersoFenetreApp(h)
                continue
            WinActivate('ahk_id ' h)
            if WinWaitActive('ahk_id ' h, , 1)
                PersoKomorebic('manage')
        }
        flottantes := []
        Loop w.floating_windows.elements.length {
            i := A_Index - 1
            flottantes.Push(w.floating_windows.elements.%i%.hwnd)
        }
        for h in flottantes {
            if !WinExist('ahk_id ' h)
                continue
            if WinGetMinMax('ahk_id ' h) != 0
                WinRestore('ahk_id ' h)
            WinActivate('ahk_id ' h)
            WinWaitActive('ahk_id ' h, , 1)
            PersoKomorebic('toggle-float')
        }
    }
    vide := A_Temp '\winarchy-perso-resize-vide.json'
    try FileDelete(vide)
    FileAppend('[]', vide)
    PersoKomorebic('load-resize "' vide '"')
    PersoKomorebic('retile')
    if actif && WinExist('ahk_id ' actif)
        try WinActivate('ahk_id ' actif)
}

; Super+Alt+flèches, selon l'état de la fenêtre active :
; - tuilée (au moins 2 tuiles) : échange avec la tuile voisine dans cette direction ;
; - flottante, ou seule tuile : calage sur une grille 2x2, comme le Snap de Windows.
;   La fenêtre passe en flottant (Super+T la remet dans le tiling). Chaque flèche agit sur
;   un axe : ← puis ↑ = coin haut gauche ; depuis la moitié gauche, → = pleine largeur,
;   → encore = moitié droite. Pareil en vertical avec ↑ / ↓.
; (Échanger deux tuiles reste sur Super+Shift+flèches.)
PersoPlace(dir) {
    static pos := Map()   ; hwnd -> [col, ligne, x, y, l, h] ; col/ligne : 0 début, 1 plein, 2 fin
    h := WinExist('A')
    if !h || PersoIgnoree(h)
        return
    try {
        state := PersoEtat()
        im := state.monitors.focused
        m := state.monitors.elements.%im%
        iw := m.workspaces.focused
        w := m.workspaces.elements.%iw%
        a := m.work_area_size
        ax := a.left, ay := a.top, aw := a.right, ah := a.bottom
        flottante := false
        Loop w.floating_windows.elements.length {
            i := A_Index - 1
            if (w.floating_windows.elements.%i%.hwnd = h)
                flottante := true
        }
        tuilee := false
        Loop w.containers.elements.length {
            c := w.containers.elements.%(A_Index - 1)%
            Loop c.windows.elements.length
                if (c.windows.elements.%(A_Index - 1)%.hwnd = h)
                    tuilee := true
        }
        if (tuilee && w.containers.elements.length >= 2) {
            PersoKomorebic('move ' dir)
            return
        }
    } catch {
        ; komorebi illisible : zone de travail Windows, sous la barre
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        ax := l, ay := t + 34, aw := r - l, ah := b - t - 34
        flottante := true
    }

    ; Position précédente, si la fenêtre n'a pas été bougée depuis
    col := 1, lig := 1
    if pos.Has(h) {
        p := pos[h]
        try {
            WinGetPos(&cx, &cy, &cw, &ch, 'ahk_id ' h)
            if (Abs(cx - p[3]) < 40 && Abs(cy - p[4]) < 40 && Abs(cw - p[5]) < 40 && Abs(ch - p[6]) < 40)
                col := p[1], lig := p[2]
        }
    }
    switch dir {
        case 'left':  col := (col = 2) ? 1 : 0
        case 'right': col := (col = 0) ? 1 : 2
        case 'up':    lig := (lig = 2) ? 1 : 0
        case 'down':  lig := (lig = 0) ? 1 : 2
    }

    pad := 6
    dw := aw // 2, dh := ah // 2
    x := ax + (col = 2 ? dw : 0), largeur := (col = 1) ? aw : dw
    y := ay + (lig = 2 ? dh : 0), hauteur := (lig = 1) ? ah : dh
    x += pad, y += pad, largeur -= 2 * pad, hauteur -= 2 * pad

    if !flottante
        PersoKomorebic('toggle-float')
    if WinGetMinMax('ahk_id ' h) != 0
        WinRestore('ahk_id ' h)
    WinMove(x, y, largeur, hauteur, 'ahk_id ' h)
    try WinGetPos(&cx, &cy, &cw, &ch, 'ahk_id ' h)
    catch
        cx := x, cy := y, cw := largeur, ch := hauteur
    pos[h] := [col, lig, cx, cy, cw, ch]
}

PersoResizeOn(v?) {
    static on := false
    if IsSet(v)
        on := v
    return on
}

PersoResize() {
    if PersoResizeOn()
        return PersoResizeFin()
    PersoResizeOn(true)
    ToolTip('Redimensionnement : flèches ou hjkl (Maj = pas fin) — Échap, Entrée ou Super+Z pour sortir')
}

PersoResizeFin() {
    PersoResizeOn(false)
    ToolTip()
    PersoKomorebic('resize-delta __DELTA__')
}

PersoResizePas(axe, sens, px) {
    PersoKomorebic('resize-delta ' px)
    PersoKomorebic('resize-axis ' axe ' ' sens)
}

; Super+S : réduit la fenêtre active, à chaque appui (n'importe quelle fenêtre).
; Super+Shift+S ramène toutes celles réduites ainsi.
; Une fenêtre ramenée autrement (barre des tâches, Alt+Tab) sort de la liste.
PersoCachees() {
    static liste := []
    return liste
}

PersoNettoie(liste) {
    i := liste.Length
    while (i >= 1) {
        h := liste[i]
        if !WinExist('ahk_id ' h) || WinGetMinMax('ahk_id ' h) != -1
            liste.RemoveAt(i)
        i--
    }
}

PersoCache() {
    liste := PersoCachees()
    PersoNettoie(liste)
    h := WinExist('A')
    if !h || PersoIgnoree(h)
        return
    for x in liste
        if x = h
            return WinMinimize('ahk_id ' h)
    liste.Push(h)
    WinMinimize('ahk_id ' h)
}

PersoRameneTout() {
    liste := PersoCachees()
    PersoNettoie(liste)
    dernier := 0
    while liste.Length {
        dernier := liste.Pop()
        WinRestore('ahk_id ' dernier)
    }
    if dernier
        try WinActivate('ahk_id ' dernier)
}

; Exposé = Vue des tâches, ouverte par le vrai Win+Tab (son identifiant shell:::{3080F90E…}
; ne marche plus sur Windows 11). Winarchy prend Win+Tab : coupé le temps de l'envoyer.
PersoExpose() {
    HotIf()
    try Hotkey('#Tab', 'Off')
    Send('#{Tab}')
    Sleep(100)
    try Hotkey('#Tab', 'On')
}

PersoClaude(profil) {
    h := EnvGet('USERPROFILE')
    Run('wt.exe -d "' h '\Work" __SHELL__ -NoExit -NoLogo -ExecutionPolicy Bypass -File "' h '\.winarchy-perso\claude.ps1" ' profil)
}

; Claude Desktop perso : 2e instance avec son propre dossier de données (--user-data-dir),
; donc son propre compte, à côté de l'instance pro. Version Store : Windows range ce
; dossier dans %LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude-perso.
; PID du processus principal de l'instance perso (0 si elle ne tourne pas).
PersoClaudePersoPid() {
    try {
        for p in ComObjGet('winmgmts:').ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name = 'claude.exe' AND CommandLine LIKE '%Claude-perso%' AND NOT CommandLine LIKE '%--type=%'")
            return p.ProcessId
    }
    return 0
}

; Fenêtre visible d'une instance : celle de l'instance perso (perso = true) ou de la pro.
PersoClaudeFenetre(perso) {
    pid := PersoClaudePersoPid()
    for hwnd in WinGetList('Claude ahk_exe claude.exe ahk_class Chrome_WidgetWin_1')
        if ((WinGetPID(hwnd) = pid) = perso)
            return hwnd
    return 0
}

; Ouvre / affiche / replie une instance de Claude Desktop. Repliée, elle part dans la zone
; de notification : relancer le raccourci la fait réapparaître.
PersoClaudeOuvre(hwnd, lancer) {
    if (hwnd && WinActive(hwnd))
        WinClose(hwnd)
    else if hwnd
        WinActivate(hwnd)
    else
        Run(lancer)
}

; Super+Ctrl+Shift+Backspace (ou + Alt) : instance pro (l'instance perso est ignorée).
PersoClaudeBascule() => PersoClaudeOuvre(PersoClaudeFenetre(false), 'explorer.exe shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude')

; Super+Ctrl+Alt+Shift+Entrée : instance perso.
PersoClaudePerso() => PersoClaudeOuvre(PersoClaudeFenetre(true)
    , '"' EnvGet('LOCALAPPDATA') '\Microsoft\WindowsApps\claude-desktop.exe" --user-data-dir="' EnvGet('APPDATA') '\Claude-perso"')

; Outlook classique (OUTLOOK.EXE), pas le nouvel Outlook (olk.exe).
PersoOutlook() {
    if WinExist('ahk_exe OUTLOOK.EXE ahk_class rctrl_renwnd32')
        return WinActivate()
    try Run('outlook.exe')                        ; App Paths -> Office16\OUTLOOK.EXE
    catch
        Run('https://outlook.office.com/mail/')
}

PersoDeezer() {
    if WinExist('ahk_exe Deezer.exe')
        return WinActivate()
    exe := EnvGet('LOCALAPPDATA') '\Programs\deezer-desktop\Deezer.exe'
    if FileExist(exe)
        Run('"' exe '"')
    else
        Run('https://www.deezer.com/')
}

; --- Icônes de la zone de notification dans YASB --------------------------------
; Quand YASB (re)démarre (thème, mise à jour, plantage), les applis déjà lancées ne lui
; renvoient pas toujours leur icône (Ditto, Discord, OpenVPN, iCloud...). À chaque
; nouveau processus yasb.exe, on rediffuse « TaskbarCreated » : chaque appli recrée
; alors son icône, comme après un redémarrage de l'Explorateur.
SetTimer(PersoSurveilleYasb, 3000)
PersoSurveilleYasb() {
    static dernier := 0
    pid := ProcessExist('yasb.exe')
    if (pid && pid != dernier)
        SetTimer(PersoRediffuseTray, -8000)       ; laisse YASB monter son systray
    dernier := pid
}
PersoRediffuseTray() {
    msg := DllCall('RegisterWindowMessage', 'Str', 'TaskbarCreated', 'UInt')
    DllCall('SendMessageTimeout', 'Ptr', 0xFFFF, 'UInt', msg, 'Ptr', 0, 'Ptr', 0
        , 'UInt', 2, 'UInt', 3000, 'Ptr*', 0)     ; HWND_BROADCAST, SMTO_ABORTIFHUNG
}

; --- Focus qui suit la souris : gardien ----------------------------------------
; Un redémarrage de komorebi (ou autre) peut couper le réglage Windows « activer une
; fenêtre en la survolant ». Toutes les 2 s, on vérifie et on le remet si besoin.
SetTimer(PersoSurveilleSurvol, 2000)
PersoSurveilleSurvol() {
    actif := 0
    DllCall('SystemParametersInfo', 'UInt', 0x1000, 'UInt', 0, 'Int*', &actif, 'UInt', 0)  ; GET ACTIVEWINDOWTRACKING
    if actif
        return
    DllCall('SystemParametersInfo', 'UInt', 0x1001, 'UInt', 0, 'Ptr', 1, 'UInt', 3)    ; SET ACTIVEWINDOWTRACKING
    DllCall('SystemParametersInfo', 'UInt', 0x100D, 'UInt', 0, 'Ptr', 1, 'UInt', 3)    ; premier plan au survol
    DllCall('SystemParametersInfo', 'UInt', 0x2003, 'UInt', 0, 'Ptr', 150, 'UInt', 3)  ; après 150 ms
}

; --- Boîtes de dialogue et installeurs toujours devant --------------------------
; Dans un script à part (~\.winarchy-perso\devant.ahk, écrit par setup-winarchy.ps1),
; lancé avec AutoHotkey64_UIA.exe (UI Access) : sans ça Windows interdit de mettre
; devant les fenêtres lancées en administrateur (installeurs Inno Setup, MSI…).
; Relancé (et donc remplacé) à chaque démarrage de winarchy.ahk.
PersoLanceDevant()
PersoLanceDevant() {
    uia := RegExReplace(A_AhkPath, 'i)\.exe$', '_UIA.exe')
    try Run('"' (FileExist(uia) ? uia : A_AhkPath) '" "' EnvGet('USERPROFILE') '\.winarchy-perso\devant.ahk"')
}
; <<< raccourcis-perso <<<
'@
    $bloc = $bloc.Replace('__SHELL__', $shell).Replace('__DELTA__', "$delta")

    Save-UserAhk $UserAhk $MainAhk $ahkExe ($texte.TrimEnd() + "`r`n`r`n" + $bloc)
    Restart-WinarchyAhk $MainAhk $ahkExe
    Set-Survol $true
    Set-ToucheOffice $true
    Set-KomorebiAdmin $true
}

# --- Réglages perso dans les modèles de Winarchy ---------------------------------
# Winarchy régénère komorebi.json et la config YASB depuis templates\ à chaque thème : on
# modifie donc les modèles eux-mêmes. Ils sont versionnés dans le fork ; chaque patch est
# idempotent, et réappliqué si une mise à jour du projet d'origine les a repris.

function Invoke-WinarchyCli([string]$Root, [string[]]$arguments) {
    & (Join-Path $Root 'bin\winarchy.cmd') @arguments 2>&1 | ForEach-Object { "      $_" } | Out-Host
    return ($LASTEXITCODE -eq 0)
}

function Get-ThemeActif([string]$Root) {
    $ligne = & (Join-Path $Root 'bin\winarchy.cmd') theme list 2>$null | Where-Object { $_ -match '^\s*\*\s*(\S+)' } | Select-Object -First 1
    if ($ligne -match '^\s*\*\s*(\S+)') { return $Matches[1] }
    return $null
}

# Fenêtre seule : pleine largeur par défaut ; Super+F la centre (offset = 1/4 de l'écran
# à gauche, réduction de 1/2 : komorebi compte « right » comme une réduction de largeur).
function Edit-ModeleKomorebi([string]$t) {
    $largeur = 1920
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $largeur = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    } catch { }
    $g = [int]($largeur / 4); $d = 2 * $g
    $i = $t.IndexOf('"monitors": [')
    if ($i -lt 0) { throw '« "monitors": [ » introuvable' }
    $w = $t.IndexOf('"workspaces": [', $i)
    $f = $t.IndexOf(']', $w)
    if ($w -lt 0 -or $f -lt 0) { throw 'bureaux du premier écran introuvables' }
    $bureaux = [regex]::Replace($t.Substring($w, $f - $w), '("layout":\s*"[^"]*")\s*\}', '$1, "apply_window_based_work_area_offset": false }')
    $bureaux = $bureaux -replace '(, "apply_window_based_work_area_offset": false)+', '$1'
    $t = $t.Substring(0, $w) + $bureaux + $t.Substring($f)
    $offset = "`"window_based_work_area_offset`": { `"left`": $g, `"top`": 0, `"right`": $d, `"bottom`": 0 },"
    $ecran = $t.Substring($i, $w - $i)
    if ($ecran -match '"window_based_work_area_offset":\s*\{[^}]*\},') {
        $ecran = $ecran.Replace($Matches[0], $offset)
    } else {
        $ecran = [regex]::Replace($ecran, '\{(\s*)$', "{`$1$offset`$1`"window_based_work_area_offset_limit`": 1,`$1")
    }
    $t = $t.Substring(0, $i) + $ecran + $t.Substring($w)
    # Portable + 3 écrans externes : le modèle ne décrit que 2 écrans, on complète jusqu'à 4
    # (10 bureaux chacun, comme le 2e). Un écran absent ne gêne pas komorebi.
    $i = $t.IndexOf('"monitors": [')
    $fin = [regex]::Match($t.Substring($i), '\r?\n  \]')
    if (-not $fin.Success) { throw 'fin de « monitors » introuvable' }
    $n = ([regex]::Matches($t.Substring($i, $fin.Index), '"workspaces": \[')).Count
    if ($n -lt 4) {
        $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
        $ws = (1..10 | ForEach-Object { "        { `"name`": `"$_`", `"layout`": `"BSP`" }" }) -join ",$nl"
        $bloc = ",$nl    {$nl      `"workspaces`": [$nl$ws$nl      ]$nl    }"
        $t = $t.Insert($i + $fin.Index, $bloc * (4 - $n))
    }
    # Tilés comme le reste alors que Winarchy les ignore d'office (ignore_rules) : ShareX
    # (ses surcouches de capture sont sans barre de titre, komorebi ne les gère pas de toute
    # façon), le Gestionnaire des tâches et le Panneau de configuration.
    foreach ($id in 'ShareX\.exe', 'TaskManagerWindow', 'Control Panel') {
        $t = [regex]::Replace($t, "(,\s*)?\{\s*`"kind`":\s*`"\w+`",\s*`"id`":\s*`"$id`",\s*`"matching_strategy`":\s*`"Equals`"\s*\}(?(1)|,?)", '')
    }
    # OrcaSlicer affiche sa fenêtre avant de lui donner son titre « … - OrcaSlicer » : la règle
    # manage par titre ne s'appliquait pas. Avec object_name_change, komorebi réexamine la
    # fenêtre quand son titre change (les panneaux internes n'ont pas ce titre : pas tuilés).
    if ($t -notmatch '"object_name_change_applications":\s*\[[^\]]*"orca-slicer\.exe"') {
        $t = [regex]::Replace($t, '("object_name_change_applications":\s*\[)(\r?\n)', "`$1`$2    { `"kind`": `"Exe`", `"id`": `"orca-slicer.exe`", `"matching_strategy`": `"Equals`" },`$2", 1)
        if ($t -notmatch '"orca-slicer\.exe"') { throw '« object_name_change_applications » introuvable' }
    }
    $t
}

# Winarchy relance komorebi en direct (Start-Process, donc sans droits admin) quand il ne
# tourne pas au moment d'un reload / theme set. On passe par la tâche planifiée, qui le
# lance en administrateur (voir Set-KomorebiAdmin) ; repli sur l'ancien lancement.
function Edit-UtilKomorebi([string]$t) {
    if ($t.Contains('perso : via la tâche planifiée')) { return $t }
    $m = [regex]::Match($t, '(?s)(function Start-WinarchyKomorebi \{.*?)(\r?\n)    Start-Process \$exe -WindowStyle Hidden(\r?\n)\}')
    if (-not $m.Success) { throw 'Start-WinarchyKomorebi introuvable' }
    $nl = $m.Groups[2].Value
    $neuf = $m.Groups[1].Value + $nl +
        "    # perso : via la tâche planifiée (komorebi en administrateur : fenêtres admin tilées)$nl" +
        "    & schtasks.exe /Run /TN '\Winarchy\komorebi' *> `$null$nl" +
        "    if (`$LASTEXITCODE -ne 0) { Start-Process `$exe -WindowStyle Hidden }$nl}"
    $t.Remove($m.Index, $m.Length).Insert($m.Index, $neuf)
}

# Règles de la communauté (ASC) : l'utilisateur veut tout tiler. On retire les « ignore »
# des applis choisies et TOUS les « floating », en gardant leurs autres attributs
# (tray_and_multi_window, layered…). [[disable]] dans rules.toml ferait perdre ces attributs
# et rules.toml ne sait pas viser les règles composées (ex. Steam exe + classe).
$script:AscSansIgnore = @('Zoom', 'Microsoft Teams classic', 'Calculator', '1Password', 'Dropbox', 'Google Drive',
    'paint.net', 'TeraCopy', 'QuickLook', 'Affinity Photo 2', 'Process Hacker', 'System Informer', 'PowerToys',
    'Logi Bolt', 'Logitech Options', 'LogiTune', 'Unity', 'Unreal Engine', 'Task Manager')
function Edit-AscPerso([string]$t) {
    $asc = $t | ConvertFrom-Json -AsHashtable
    if (-not $asc.Contains('Zoom')) { throw 'format ASC inattendu' }
    foreach ($app in @($asc.Keys)) {
        if ($app.StartsWith('$')) { continue }
        $cats = @('floating') + @(if ($app -in $script:AscSansIgnore) { 'ignore' })
        foreach ($c in $cats) { if ($asc[$app].Contains($c)) { $asc[$app].Remove($c) } }
    }
    # Explorateur : on garde ses autres ignore (progression de copie…), pas celui du Panneau de configuration.
    $ex = $asc['Windows Explorer']
    if ($ex -and $ex.Contains('ignore')) { $ex['ignore'] = @($ex['ignore'] | Where-Object { $_.id -ne 'Control Panel' }) }
    ($asc | ConvertTo-Json -Depth 20) + "`n"
}

# Barre YASB : groupes toujours dépliés, et pas de compteur Codex.
function Edit-ModeleYasb([string]$t) {
    $t = [regex]::Replace($t, '(collapse_options:\s*\r?\n\s*enabled:\s*)true', '${1}false')
    $t = $t.Replace('widgets: ["claude_usage", "codex_usage"]', 'widgets: ["claude_usage"]')
    # Bouton capture -> Screenpresso ; pas de boutons d'enregistrement vidéo (ni son « stop »).
    $t = $t.Replace('tooltip_label: "Region capture"', 'tooltip_label: "Capture (Screenpresso)"')
    $t = $t.Replace('on_left: "exec winarchy screenshot region"', 'on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\screenpresso-capture.ahk"')
    $t = $t.Replace('"tool_record", "tool_stop", ', '')
    # Bouton presse-papiers -> historique Windows (Win+V), juste après le bouton capture.
    $t = $t.Replace('ditto-historique.ahk', 'presse-papiers.ahk').Replace('Presse-papiers (Ditto)', 'Presse-papiers (Win+V)').Replace('presse-papiers (perso, setup-winarchy.ps1) -> Ditto.', 'presse-papiers (perso, setup-winarchy.ps1) -> Win+V.')
    if ($t -notmatch '(?m)^  tool_clipboard:') {
        if ($t -notmatch '"tool_region", ' -or $t -notmatch '(?m)^  tool_region:') { throw 'ancre tool_clipboard absente' }
        $t = $t.Replace('"tool_region", ', '"tool_region", "tool_clipboard", ')
        $bloc = (@'
  # Historique du presse-papiers (perso, setup-winarchy.ps1) -> Win+V.
  tool_clipboard:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span>ICONE</span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Presse-papiers (Win+V)"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\presse-papiers.ahk"
        on_middle: "do_nothing"
        on_right: "do_nothing"

'@).Replace('ICONE', [string][char]0xF0EA) -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
        $t = [regex]::Replace($t, '(?m)^(?=  tool_region:)', $bloc.Replace('$', '$$'), 1)
    }
    # Horloge : date + heure toujours visibles (en français) ; clic droit = secondes.
    $t = [regex]::Replace($t, '(?m)^(  clock:\r?\n    type: "yasb\.clock\.ClockWidget"\r?\n    options:\r?\n)      label: "[^"\r\n]*"(\r?\n)      label_alt: "[^"\r\n]*"(\r?\n)(?:      locale: "[^"\r\n]*"\r?\n)?',
        '${1}      label: "{%a %d %b · %H:%M}"${2}      label_alt: "{%A %d %B %Y · %H:%M:%S}"${3}      locale: "fr_FR"${3}')
    if ($t -notmatch 'locale: "fr_FR"') { throw 'ancre horloge absente' }
    # Corbeille (widget natif YASB), juste après le bouton presse-papiers.
    if ($t -notmatch '(?m)^  recycle_bin:') {
        if ($t -notmatch '"tool_clipboard", ' -or $t -notmatch '(?m)^  tool_region:') { throw 'ancre recycle_bin absente' }
        $t = $t.Replace('"tool_clipboard", ', '"tool_clipboard", "recycle_bin", ')
        $bloc = (@'
  # Corbeille (perso, setup-winarchy.ps1) : clic = ouvrir, milieu = nombre/taille, droit = vider.
  recycle_bin:
    type: "yasb.recycle_bin.RecycleBinWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {items_count} ({items_size})"
      class_name: "tool-widget"
      icons:
        bin_empty: "VIDE"
        bin_filled: "PLEINE"
      tooltip: true
      show_confirmation: true
      callbacks:
        on_left: "open_bin"
        on_middle: "toggle_label"
        on_right: "empty_bin"

'@).Replace('VIDE', [string][char]0xF014).Replace('PLEINE', [string][char]0xF1F8) -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
        $t = [regex]::Replace($t, '(?m)^(?=  tool_region:)', $bloc.Replace('$', '$$'), 1)
    }
    # Espace disque : widget natif yasb.disk.DiskWidget abandonné (lecture synchrone sur le
    # fil de la barre : un partage réseau injoignable la gèlerait) ; on retire l'ancien bloc.
    $t = [regex]::Replace($t, '(?ms)^  # Espace disque \(perso[^\r\n]*\r?\n  disk:\r?\n.*?(?=^  \S)', '')
    $t = $t.Replace('"memory", "disk"', '"memory"')
    # Disques : script en arrière-plan (CustomWidget) ; barre = disques locaux en %,
    # bulle = détail de tous les disques (réseau compris), clic droit/milieu = disques réseau.
    # Deux icônes toujours visibles : disques locaux (couleur système) et réseau (couleur réseau).
    # Reconstruites à chaque passage (anciennes versions retirées) pour rester à jour.
    # YASB découpe run_cmd sur les espaces puis Popen réécrit les guillemets : chemin SANS guillemets.
    $t = [regex]::Replace($t, '(?m)^  # Disques[^\n]*\n(?:  #[^\n]*\n)*  disques(?:_reseau)?:\r?\n(?:(?:    [^\n]*)?\r?\n)*', '')
    $t = $t.Replace(', "disques_reseau"', '').Replace(', "disques"', '')
    # Directement dans la barre après le groupe système (même écart qu'entre les groupes).
    if ($t -notmatch '"system", ' -or $t -notmatch '(?m)^  memory:') { throw 'ancre disques absente' }
    $t = $t.Replace('"system", ', '"system", "disques", "disques_reseau", ')
    $modele = @'
  # Disques LIBELLE (perso, setup-winarchy.ps1) : % utilisé, survol = détail de tous les disques,
  # clic = Ce PC, droit/milieu = espace libre. {data[...]} hors <span> (sinon pas substitué).
  CLE:
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "CLASSE"
      label: "{data[DONNEE]}"
      label_alt: "{data[DONNEE_libre]}"
      label_placeholder: "…"
      tooltip: true
      tooltip_label: "{data[detail]}"
      exec_options:
        run_cmd: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\.winarchy-perso\disques.ps1'
        run_interval: 60000
        return_format: "json"
        use_shell: true
        encoding: "utf-8"
      callbacks:
        on_left: "exec explorer.exe shell:MyComputerFolder"
        on_middle: "toggle_label"
        on_right: "toggle_label"
'@
    $bloc = ($modele.Replace('LIBELLE', 'locaux').Replace('CLE', 'disques').Replace('CLASSE', 'disques-widget').Replace('DONNEE', 'local') + "`n" +
             $modele.Replace('LIBELLE', 'réseau').Replace('CLE', 'disques_reseau').Replace('CLASSE', 'disques-reseau-widget').Replace('DONNEE', 'reseau') + "`n") -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
    $t = [regex]::Replace($t, '(?m)^(?=  memory:)', $bloc.Replace('$', '$$'), 1)
    # Perf GPU / CPU / RAM : widgets natifs remplacés par des CustomWidget pour avoir une bulle
    # au survol (les natifs n'en ont pas). cpu lance perf.ps1 (écrit perf.json), gpu/memory relisent
    # perf.json. Clic = Gestionnaire des tâches, droit = libellé alternatif. Remplacés sur place.
    $nlY = if ($t -match "`r`n") { "`r`n" } else { "`n" }
    $modelePerf = @'
  CLE:
    # Perf (perso, setup-winarchy.ps1) : bulle = détail, clic = Gestionnaire des tâches.
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "CLASSE"
      label: "{data[DONNEE]}"
      label_alt: "{data[DONNEE_alt]}"
      label_placeholder: "…"
      tooltip: true
      tooltip_label: "{data[DONNEE_detail]}"
      exec_options:
        run_cmd: 'COMMANDE'
        run_interval: INTERVALLE
        return_format: "json"
        use_shell: true
        encoding: "utf-8"
      callbacks:
        on_left: "exec taskmgr.exe"
        on_middle: "toggle_label"
        on_right: "toggle_label"

'@
    $lancePerf = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\.winarchy-perso\perf.ps1'
    $litPerf = 'cmd.exe /c type %USERPROFILE%\.winarchy-perso\perf.json'
    foreach ($w in @(@('gpu', 'gpu-widget', 'gpu', $litPerf, 4000), @('cpu', 'cpu-widget', 'cpu', $lancePerf, 4000), @('memory', 'memory-widget', 'ram', $litPerf, 4000))) {
        $rx = "(?m)^  $($w[0]):\r?\n(?:(?:    [^\r\n]*)?\r?\n)*"
        if ($t -notmatch $rx) { throw "ancre perf $($w[0]) absente" }
        $b = ($modelePerf.Replace('CLE', $w[0]).Replace('CLASSE', $w[1]).Replace('DONNEE', $w[2]).Replace('COMMANDE', $w[3]).Replace('INTERVALLE', [string]$w[4])) -replace '\r?\n', $nlY
        $t = [regex]::Replace($t, $rx, $b.Replace('$', '$$'), 1)
    }
    # Réseau : même icône (watcher de Winarchy), plus une bulle (connexion, IP, débit, VPN)
    # calculée par reseau.ps1. Bloc « wifi » remplacé sur place.
    $rx = '(?m)^  wifi:\r?\n(?:(?:    [^\r\n]*)?\r?\n)*'
    if ($t -notmatch $rx) { throw 'ancre réseau (wifi) absente' }
    $b = @'
  wifi:
    # Réseau (perso, setup-winarchy.ps1) : icône = state\net-icon.flag, bulle = reseau.ps1.
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "wifi-widget"
      label: "{data[icone]}"
      label_alt: "{data[icone]}"
      label_placeholder: "…"
      tooltip: true
      tooltip_label: "{data[detail]}"
      exec_options:
        run_cmd: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\.winarchy-perso\reseau.ps1'
        run_interval: 15000
        return_format: "json"
        use_shell: true
        encoding: "utf-8"
      callbacks:
        on_left: "exec cmd.exe /c start ms-settings:network"
        on_right: "exec cmd.exe /c start ms-settings:network"

'@ -replace '\r?\n', $nlY
    $t = [regex]::Replace($t, $rx, $b.Replace('$', '$$'), 1)
    # Indicateur des fenêtres ouvertes (icônes cliquables) après l'icône de layout.
    if ($t -notmatch 'yasb\.taskbar\.TaskbarWidget') {
        if ($t -notmatch '"komorebi_active_layout", ' -or $t -notmatch '(?m)^  komorebi_workspaces:') { throw 'ancre taskbar absente' }
        $t = $t.Replace('"komorebi_active_layout", ', '"komorebi_active_layout", "taskbar", ')
        $bloc = @'
  # Fenêtres ouvertes sur cet écran (perso, setup-winarchy.ps1) : clic = focus/réduire.
  taskbar:
    type: "yasb.taskbar.TaskbarWidget"
    options:
      icon_size: 16
      monitor_exclusive: true
      animation:
        enabled: true
      title_label:
        enabled: false
      ignore_apps:
        processes: []
        titles: []
        classes: []
      callbacks:
        on_left: "toggle_window"
        on_middle: "do_nothing"
        on_right: "context_menu"

'@ -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
        $t =[regex]::Replace($t, '(?m)^(?=  komorebi_workspaces:)', $bloc.Replace('$', '$$'), 1)
    }
    $t
}

# Styles de l'indicateur des fenêtres ouvertes (fenêtre active soulignée de l'accent).
function Edit-ModeleYasbStyles([string]$t) {
    $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
    # Bulles d'aide (survol) : fond opaque comme le panneau Claude Usage (sinon transparentes).
    if ($t -notmatch '(?m)^\.tooltip\s*\{') {
        $t = ($t.TrimEnd() + "`n`n" + @'
/* Bulles d'aide (perso, setup-winarchy.ps1) : fond opaque, lisible */
.tooltip {
    background-color: {{colors.background}};
    border: 1px solid {{colors.color8}};
    border-radius: 6px;
    color: {{colors.foreground}};
    padding: 6px 10px;
    font-size: 12px;
}
'@ + "`n") -replace '\r?\n', $nl
    }
    # Icônes disques : locaux = couleur par défaut, réseau = couleur réseau ; widgets des groupes
    # espacés (2 px d'origine : tout collé). Bloc reconstruit à chaque passage.
    $t = [regex]::Replace($t, '(?ms)\r?\n\r?\n/\* Disques \(perso, setup-winarchy\.ps1\).*?(?=\r?\n\r?\n|\s*\z)', '')
    $t = ($t.TrimEnd() + "`n`n" + @'
/* Disques (perso, setup-winarchy.ps1) : réseau = couleur réseau ; widgets des groupes espacés */
.disques-widget .label.alt { color: {{colors.foreground}}; }
.disques-reseau-widget .label,
.disques-reseau-widget .label.alt { color: {{ui.net}}; }
.gpu-widget .label.alt,
.cpu-widget .label.alt,
.memory-widget .label.alt { color: {{ui.system}}; }
.extras-grouper .widget,
.ai-grouper .widget,
.system-grouper .widget,
.connections-grouper .widget { padding: 0 6px; }
'@ + "`n") -replace '\r?\n', $nl
    # Popups Bluetooth et volume : transparents d'origine (illisibles) → même fond que wifi/home.
    $t = [regex]::Replace($t, '(?ms)\r?\n\r?\n/\* Popups opaques \(perso, setup-winarchy\.ps1\).*?(?=\r?\n\r?\n|\s*\z)', '')
    $t = ($t.TrimEnd() + "`n`n" + @'
/* Popups opaques (perso, setup-winarchy.ps1) : tous les popups YASB (noms tirés de library.zip) */
.bluetooth-menu,
.audio-menu,
.open-meteo-card,
.weather-card,
.clock-popup,
.microphone-menu,
.media-menu,
.media-lite-menu,
.brightness-menu,
.language-menu,
.power-plan-menu,
.power-menu-popup,
.komorebi-layout-menu,
.komorebi-control-menu,
.control-center-menu,
.systray-popup,
.notes-menu,
.todo-menu,
.github-menu,
.libre-menu,
.quick-launch-popup,
.whkd-popup,
.window-switcher-popup,
.context-menu {
    background-color: {{colors.background}};
    border: 1px solid {{colors.color8}};
    color: {{colors.foreground}};
    border-radius: 8px;
}
/* Bluetooth : marges + taille mini (d'origine collé aux bords et trop court) */
.bluetooth-menu {
    padding: 10px 12px;
    min-width: 340px;
    min-height: 380px;
}
.bluetooth-menu .header,
.bluetooth-menu .section,
.bluetooth-menu .footer { margin: 0 12px; }
.bluetooth-menu .header { margin-top: 10px; }
.bluetooth-menu .footer { margin-bottom: 10px; }
.bluetooth-menu .section-title {
    font-weight: 600;
    padding: 8px 4px 6px 4px;
}
.bluetooth-menu .bluetooth-list {
    background-color: transparent;
    min-height: 260px;
}
.bluetooth-menu .bluetooth-item {
    padding: 0 6px;
    border-radius: 6px;
}
.bluetooth-menu .bluetooth-item:hover { background-color: {{colors.color8}}; }
.bluetooth-menu .settings-button {
    padding: 8px 4px;
    margin-top: 6px;
}
.audio-menu { padding: 10px 12px; }
'@ + "`n") -replace '\r?\n', $nl
    if ($t -match '\.taskbar-widget') { return $t }
    ($t.TrimEnd() + "`n`n" + @'
/* Fenêtres ouvertes (perso, setup-winarchy.ps1) */
.taskbar-widget { padding: 0 4px; }
.taskbar-widget .app-container {
    margin: 2px 1px;
    padding: 0 4px;
    border-radius: 4px;
    border-bottom: 2px solid transparent;
}
.taskbar-widget .app-container:hover { background-color: {{colors.color8}}; }
.taskbar-widget .app-container.foreground { border-bottom: 2px solid {{ui.accent}}; }
.taskbar-widget .app-container.flashing { background-color: {{colors.accent_ui}}; }
'@ + "`n") -replace '\r?\n', $nl
}

# Lanceurs de jeux (Steam, Epic, GOG…) : Winarchy les met dans games.toml, donc komorebi
# les ignore ET les raccourcis Super sont suspendus quand ils ont le focus. On veut les
# tiler comme n'importe quelle appli : on retire leurs entrées [[launchers]], RustDesk compris
# (choix de l'utilisateur : Super n'est donc plus transmis à la machine distante).
# Les règles ASC restent actives (ex. Steam : seule la fenêtre « Steam » est tuilée,
# pas les popups amis / notifications de steamwebhelper).
function Edit-JeuxLanceurs([string]$t) {
    [regex]::Replace($t, '(?m)^\[\[launchers\]\]\s*\r?\nexe\s*=\s*"[^"]+"[^\r\n]*(\r?\n)+', '')
}

function Set-ReglagesWinarchy([string]$Root) {
    Write-Host '==> Réglages perso dans les modèles de Winarchy'
    $change = $false
    $patchs = @{ 'templates\komorebi.json.tpl' = ${function:Edit-ModeleKomorebi}; 'templates\yasb-config.yaml.tpl' = ${function:Edit-ModeleYasb}; 'templates\yasb-styles.css.tpl' = ${function:Edit-ModeleYasbStyles}; 'games.toml' = ${function:Edit-JeuxLanceurs}; 'vendor\asc\applications.json' = ${function:Edit-AscPerso}; 'module\Winarchy\Private\Util.ps1' = ${function:Edit-UtilKomorebi} }
    foreach ($rel in $ModelesPatches) {
        $p = Join-Path $Root $rel
        if (-not (Test-Path $p)) { Warn "$rel introuvable : réglage ignoré"; continue }
        $avant = [IO.File]::ReadAllText($p)
        try { $apres = & $patchs[$rel] $avant }
        catch { Warn "$rel : modèle inattendu ($($_.Exception.Message)), réglage ignoré"; continue }
        if ($apres -ne $avant) {
            [IO.File]::WriteAllText($p, $apres, (New-Object Text.UTF8Encoding $false))
            Ok "$rel patché"
            $change = $true
            if ($rel -notmatch 'yasb|Util\.ps1') { $script:RedemarrerKomorebi = $true }
        } else { Info "$rel déjà à jour" }
    }
    # Règles komorebi par appli (rules.toml).
    # Claude Desktop se replie dans la zone de notification et komorebi le perdait au retour.
    $rules = Join-Path $Root 'config\komorebi\rules.toml'
    $exemple = Join-Path $Root 'config\komorebi\rules.toml.example'
    if (-not (Test-Path $rules) -and (Test-Path $exemple)) { Copy-Item $exemple $rules }
    $actuel = if (Test-Path $rules) { [IO.File]::ReadAllText($rules) } else { '' }
    # Pas de « manage exe = claude.exe » : komorebi tuilait alors aussi les fenêtres fantômes
    # IME / MSCTFIME UI de Claude et la moitié droite du bureau se redimensionnait. On gère
    # la fenêtre par son titre et on ignore ces fantômes. Une règle manage l'emporte sur
    # ignore : on la retire.
    # Même piège avec OrcaSlicer (ses panneaux internes « control », « Quality »… tuilés).
    $mauvaise = '(?m)^\[\[manage\]\]\s*\r?\n\s*exe\s*=\s*"(claude|orca-slicer)\.exe"\s*(\r?\n)?'
    if ($actuel -match $mauvaise) {
        $actuel = [regex]::Replace($actuel, $mauvaise, '')
        [IO.File]::WriteAllText($rules, $actuel, (New-Object Text.UTF8Encoding $false))
        Info 'Règle komorebi « manage <exe> » retirée'
        $script:RedemarrerKomorebi = $true
    }
    $voulues = @(
        @('manage', 'title', 'Claude'),
        @('tray_and_multi_window', 'exe', 'claude.exe'),
        @('layered', 'exe', 'claude.exe'),
        # OrcaSlicer (wxWidgets) dessine sa propre barre de titre (pas de WS_CAPTION) : ignoré sans ça.
        # Par le titre des fenêtres principales (« … - OrcaSlicer ») : par exe, ses panneaux internes étaient tuilés.
        @('manage', 'title', 'OrcaSlicer', 'EndsWith'),
        @('ignore', 'class', 'MSCTFIME UI'),
        @('ignore', 'class', 'IME')
    )
    foreach ($r in $voulues) {
        $cat, $cle, $val, $strategie = $r
        if ($actuel -match "(?m)^\[\[$cat\]\]\s*\r?\n\s*$cle\s*=\s*`"$([regex]::Escape($val))`"") { continue }
        $argsCli = @('rules', 'add', $cat, $cle, $val) + @($strategie | Where-Object { $_ })
        if (Invoke-WinarchyCli $Root $argsCli) { Ok "Règle komorebi : $cat $cle $val"; $script:RedemarrerKomorebi = $true }
        else { Warn "Règle komorebi $cat $cle $val non ajoutée" }
    }
    if ($change) { Update-ThemeActif $Root }
}

function Update-ThemeActif([string]$Root) {
    $theme = Get-ThemeActif $Root
    if (-not $theme) { Warn 'Thème actif introuvable : lance « winarchy theme set <thème> » pour appliquer.'; return }
    # `theme set` remet le fond du thème : on remet ensuite celui choisi par l'utilisateur,
    # sauf s'il fait partie des fonds du thème ACTIF (themes\<actif>\backgrounds). Un fond
    # rangé dans le dossier d'un autre thème (ex. tokyo-night) est un choix perso : on le garde.
    $fond = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
    $fondsTheme = Join-Path $Root "themes\$theme\backgrounds"
    if (Invoke-WinarchyCli $Root @('theme', 'set', $theme)) { Ok "Thème « $theme » réappliqué" }
    else { Warn "« winarchy theme set $theme » a échoué" }
    if ($fond -and (Test-Path $fond) -and -not $fond.StartsWith($fondsTheme, [StringComparison]::OrdinalIgnoreCase)) {
        if (-not ('PersoWinarchy.SpiFond' -as [type])) {
            Add-Type -Namespace PersoWinarchy -Name SpiFond -MemberDefinition '[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SystemParametersInfo(uint a, uint b, string v, uint c);'
        }
        [void][PersoWinarchy.SpiFond]::SystemParametersInfo(0x14, 0, $fond, 3)   # SPI_SETDESKWALLPAPER
        Ok "Fond d'écran perso conservé : $(Split-Path $fond -Leaf)"
        # `theme set` remet aussi l'écran de verrouillage du thème : même image que le bureau.
        # (Le flou de l'écran de connexion est celui de Windows : transparence activée.)
        Set-VerrouillagePerso $Root $fond
    }
}

# Écran de verrouillage = image donnée (via la fonction de Winarchy, WinRT, sans admin).
function Set-VerrouillagePerso([string]$Root, [string]$Image) {
    try {
        $m = Import-Module (Join-Path $Root 'module\Winarchy\Winarchy.psm1') -PassThru -Force -ErrorAction Stop
        & $m { param($i) Set-WinarchyLockScreen -ImagePath $i } $Image
        Ok "Écran de verrouillage : $(Split-Path $Image -Leaf)"
    } catch { Warn "Écran de verrouillage non modifié : $($_.Exception.Message)" }
}

# --- Fork : remotes, mise à jour, sauvegarde ----------------------------------------

# origin = ton fork, upstream = projet d'origine. Une installation faite depuis le projet
# d'origine (origin = guidonaselli) est convertie.
function Set-RemotesWinarchy([string]$Root) {
    $urlFork  = "https://github.com/$Fork.git"
    $urlAmont = "https://github.com/$Amont.git"
    $remotes = @(& git -C $Root remote)
    $origin = if ($remotes -contains 'origin') { (& git -C $Root remote get-url origin) -replace '\.git$', '' } else { '' }
    if ($origin -eq ($urlAmont -replace '\.git$', '')) {
        & git -C $Root remote rename origin upstream
        $remotes = @(& git -C $Root remote)
        $origin = ''
    }
    if (-not $origin) { & git -C $Root remote add origin $urlFork; Ok "Remote origin : $urlFork" }
    if ($remotes -notcontains 'upstream') { & git -C $Root remote add upstream $urlAmont; Ok "Remote upstream : $urlAmont" }
    & git -C $Root fetch -q origin
    & git -C $Root branch -q --set-upstream-to=origin/release release 2>$null
}

function Invoke-SyncFork([string]$Root, [string[]]$arguments) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'perso\Sync-Upstream.ps1') @arguments 2>&1 |
        ForEach-Object { "      $_" } | Out-Host
    return ($LASTEXITCODE -eq 0)
}

# Mise à jour (à chaque lancement) : fusion du projet d'origine, migration, push sur le fork.
function Update-WinarchyKomorebi([string]$Root) {
    Write-Host '==> Mise à jour de Winarchy (projet d''origine -> ton fork)'
    if (-not (Test-Path (Join-Path $Root '.git'))) { Warn "$Root n'est pas un dépôt git : mise à jour sautée."; return }
    Set-RemotesWinarchy $Root
    if (Invoke-SyncFork $Root @()) { Ok 'Winarchy à jour' }
    else { Warn 'Mise à jour impossible (détails ci-dessus) : les réglages perso sont quand même appliqués.' }
}

# Réglages appliqués par ce script (user.ahk, rules.toml, modèles) : commit + push sur le fork.
function Save-ReglagesFork([string]$Root) {
    Write-Host '==> Sauvegarde des réglages sur ton fork'
    if (Invoke-SyncFork $Root @('-SauverSeulement')) { Ok "Poussé sur github.com/$Fork" }
    else { Warn 'Sauvegarde sur le fork impossible (détails ci-dessus).' }
}

# Winarchy absent : installation depuis le fork (boot.ps1), activée au démarrage de session.
function Install-WinarchyKomorebi {
    Write-Host "==> Winarchy introuvable : installation ($Fork)"
    $env:WINARCHY_ACTIVATE = '1'
    try {
        $boot = Invoke-RestMethod "https://raw.githubusercontent.com/$Fork/release/boot.ps1"
        & ([scriptblock]::Create($boot))
    } catch {
        Err "Installation de Winarchy échouée : $($_.Exception.Message)"
        exit 1
    }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    $root = Find-WinarchyKomorebi
    if (-not $root) { Err 'Winarchy installé mais introuvable (config\ahk\winarchy.ahk absent).'; exit 1 }
    Set-RemotesWinarchy $root
    if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
        Invoke-WinarchyCli $root @('reload') | Out-Null
        Start-Sleep -Seconds 3
    }
    Ok "Winarchy installé : $root"
}

# --- Déroulé ---------------------------------------------------------------------

Assert-PasAdmin
$Komorebi = Find-WinarchyKomorebi
if ($Desinstaller) {
    if (-not $Komorebi) { Warn 'Winarchy introuvable : rien à retirer.'; exit 0 }
    Write-Host '==> Réglages perso retirés des modèles de Winarchy'
    & git -C $Komorebi checkout upstream/release -- @($ModelesPatches | ForEach-Object { $_ -replace '\\', '/' }) 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok 'Modèles remis comme dans le projet d''origine' } else { Warn 'Modèles non remis d''origine (git checkout).' }
    Update-ThemeActif $Komorebi
    Install-Raccourcis $Komorebi
    exit 0
}

if ($Komorebi) {
    if (-not $SansMiseAJour) { Update-WinarchyKomorebi $Komorebi }
} else {
    Install-WinarchyKomorebi
    $Komorebi = Find-WinarchyKomorebi
}
Write-Host "==> Winarchy : $Komorebi"
Set-ReglagesWinarchy $Komorebi
Install-Raccourcis $Komorebi
Save-ReglagesFork $Komorebi

Write-Host ''
Write-Host '==> Terminé. À vérifier :' -ForegroundColor Cyan
Write-Host '   - Super seul ouvre le lanceur d''applis, Super+Espace le menu Démarrer'
Write-Host '   - Super+Q ouvre le menu Winarchy (Super+Alt+Espace aussi)'
Write-Host '   - Super+K liste tes raccourcis sous « Perso : … »'
Write-Host '   - Connexion, une fois par compte (réglages copiés sans jetons) :'
Write-Host '       Super+Backspace puis /login (Foxis), Super+Shift+Backspace puis /login (perso)'
Write-Host '       $env:GH_CONFIG_DIR="$HOME\.config\gh-foxis"; gh auth login   (idem avec gh-perso)'
