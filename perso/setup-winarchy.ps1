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
        Barre YASB : sans compteur Codex ; CPU, RAM, disques et outils peu utilisés dans la bulle ▾ ; bureaux vides masqués
        Barre YASB : icônes de la zone de notification renvoyées à chaque redémarrage de YASB
        komorebi : tout est tilé (ShareX, Gestionnaire des tâches, Panneau de configuration, applis
          ignorées ou flottantes de la liste communautaire ASC, lanceurs de jeux) ; 4 écrans décrits
          (portable + 3 externes), 10 bureaux chacun ; relancé par sa tâche planifiée, en administrateur

  Raccourcis (ils passent devant ceux de Winarchy) :
        Super+Backspace            Claude Code (Foxis)
        Super+Shift+Backspace      Claude Desktop (ouvre / affiche / replie ; Super+Shift+A ne fait plus rien)
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
  Clic du milieu = coller (coller-clic-milieu.ahk, dossier Démarrage de la session).
  Règles komorebi perso (WorkSpaces, Teams, Citrix, RustDesk, installateurs…) : voir $voulues.
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
$ModelesPatches = @('templates\komorebi.json.tpl', 'templates\yasb-config.yaml.tpl', 'templates\yasb-styles.css.tpl', 'games.toml', 'vendor\asc\applications.json', 'module\Winarchy\Private\Util.ps1', 'module\Winarchy\Private\ThemeEngine.ps1')

# Corps de ~\.winarchy-perso\devant.ahk (voir Write-DevantScript).
$script:CorpsDevant = @'
; --- Fenêtres flottantes toujours devant -----------------------------------------
; Le focus au survol remonte les tuiles par-dessus tout ce que komorebi ne tuile pas.
; Règle par défaut : toute fenêtre que komorebi ne tuile pas passe au-dessus jusqu'à sa
; fermeture (notifications, popups, désinstalleurs…), sans voler le focus. Exclus :
; plein écran, maximisées, réduites, minuscules, jeux de games.toml, éléments système.
; Une fenêtre que komorebi finit par tuiler redevient normale.
; Cas particuliers, traités tout de suite :
;  - boîtes de dialogue #32770 RATTACHÉES à une autre, TOUTES celles de l'Explorateur et de YASB
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
                PersoVersSouris(hwnd)
                PersoDessus(hwnd)
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
                PersoDessus(hwnd)
        }
    }
}
; Met la fenêtre « toujours au-dessus », puis remonte la barre YASB par-dessus : sinon les
; fenêtres forcées devant la masquent (la barre doit rester visible).
PersoDessus(hwnd) {
    WinSetAlwaysOnTop(1, hwnd)
    for barre in WinGetList('ahk_exe yasb.exe')
        try DllCall('SetWindowPos', 'Ptr', barre, 'Ptr', -1, 'Int', 0, 'Int', 0, 'Int', 0, 'Int', 0, 'UInt', 0x13)   ; HWND_TOPMOST, NOMOVE|NOSIZE|NOACTIVATE
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
        PersoDessus(hwnd)
        return
    }
    installeur := PersoEstInstalleur(hwnd, classe)
    explorateur := (WinGetProcessName(hwnd) ~= 'i)^(explorer|yasb)\.exe$')   ; yasb : « Vider la corbeille » du widget
    if (installeur || (classe = '#32770' && (explorateur || DllCall('GetWindow', 'Ptr', hwnd, 'UInt', 4, 'Ptr')))) {
        PersoVues[hwnd] := 1
        titre := WinGetTitle(hwnd)
        if (explorateur && (InStr(titre, 'Propriétés') || InStr(titre, 'Properties')))
            PersoCentre(hwnd)
        PersoVersSouris(hwnd)
        PersoDessus(hwnd)
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
    ; Rattachée à une autre et sans barre de titre : menu clic droit ou liste déroulante
    ; (« Hôte contextuel » de l'Explorateur…). Les forcer devant les referme aussitôt.
    if (DllCall('GetWindow', 'Ptr', hwnd, 'UInt', 4, 'Ptr') && (WinGetStyle(hwnd) & 0xC00000) != 0xC00000)
        return false
    classe := WinGetClass(hwnd)
    if (InStr(classes, '|' classe '|') || InStr(classe, 'komoborder') || InStr(classe, 'PopupWindowSiteBridge'))
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
; Fenêtre flottante ouverte sur un autre écran que la souris (Gestionnaire des tâches,
; Programmes et fonctionnalités, installeurs…) : centrée sur l'écran de la souris. Pas
; les fenêtres rattachées à une autre : elles restent à côté de leur parente. En deux
; temps : Windows la redimensionne s'il change d'échelle (125 % / 100 %) en arrivant.
PersoVersSouris(hwnd) {
    if DllCall('GetWindow', 'Ptr', hwnd, 'UInt', 4, 'Ptr')
        return
    ctx := DllCall('SetThreadDpiAwarenessContext', 'Ptr', -4, 'Ptr')   ; coordonnées réelles
    try {
        CoordMode('Mouse', 'Screen')
        MouseGetPos(&mx, &my)
        WinGetPos(&x, &y, &l, &h, hwnd)
        cible := PersoEcran(mx, my, 0, 0)
        if (PersoEcran(x, y, l, h) != cible) {
            Loop 2 {
                MonitorGetWorkArea(cible, &g, &t, &d, &b)
                l := Min(l, d - g), h := Min(h, b - t)
                WinMove(g + (d - g - l) // 2, t + (b - t - h) // 2, l, h, hwnd)
                Sleep(150)
                WinGetPos(, , &l, &h, hwnd)
            }
        }
    }
    DllCall('SetThreadDpiAwarenessContext', 'Ptr', ctx, 'Ptr')
}
; Ctrl+Maj+Échap rappelle souvent la fenêtre déjà ouverte du Gestionnaire des tâches (pas
; une nouvelle) : on la ramène aussi sur l'écran de la souris. Ici (UI Access) parce
; qu'il tourne en administrateur.
~^+Esc::SetTimer(PersoTaskmgrIci, -600)
PersoTaskmgrIci() {
    if (hwnd := WinExist('ahk_class TaskManagerWindow ahk_exe Taskmgr.exe'))
        try PersoVersSouris(hwnd)
}
PersoCentre(hwnd) {
    WinGetPos(&x, &y, &l, &h, hwnd)
    MonitorGetWorkArea(PersoEcran(x, y, l, h), &g, &t, &d, &b)
    WinMove(g + (d - g - l) // 2, t + (b - t - h) // 2, , , hwnd)
}

; --- Barre des tâches Windows jamais visible ------------------------------------
; YASB la remplace. En masquage automatique, elle ressortait dès que la souris touchait
; le bas de l'écran : on la recache aussitôt (le menu Démarrer s'ouvre toujours).
; Super+Espace (menu Démarrer) l'affiche entière : elle reste visible tant que Démarrer, la
; recherche ou la barre elle-même ont le focus.
SetTimer(PersoCacheBarreWindows, 250)
PersoCacheBarreWindows() {
    try {
        exe := WinGetProcessName('A'), cl := WinGetClass('A')
        if (exe ~= 'i)^(StartMenuExperienceHost|SearchHost|ShellExperienceHost|ShellHost)\.exe$'
            || cl ~= '^(Shell_TrayWnd|Shell_SecondaryTrayWnd|TopLevelWindowForOverflowXamlIsland|NotifyIconOverflowWindow|XamlExplorerHostIslandWindow)$')
            return
    }
    ; Super+Espace vient d'afficher la barre (repère de moins de 1,5 s) : Démarrer n'a peut-être
    ; pas encore le focus, on ne recache rien.
    reprise := A_Temp '\winarchy-perso-komorebi-pause'
    if FileExist(reprise) && DateDiff(A_Now, FileGetTime(reprise, 'M'), 'Seconds') < 2
        return
    ; Fin de Super+Espace : focus au survol remis. Fait AVANT le test des barres visibles :
    ; en masquage auto, Windows recache souvent la barre lui-même et on sortait sans le remettre.
    if FileExist(reprise) {
        try FileDelete(reprise)
        DllCall('SystemParametersInfo', 'UInt', 0x1001, 'UInt', 0, 'Ptr', 1, 'UInt', 3)
    }
    visibles := []
    for classe in ['Shell_TrayWnd', 'Shell_SecondaryTrayWnd']
        for h in WinGetList('ahk_class ' classe)      ; seulement les visibles
            visibles.Push(h)
    if !visibles.Length
        return
    PersoMasquageAuto(true)                          ; remis après Super+Espace
    for h in visibles
        try WinHide(h)
}
; ABM_SETSTATE : ABS_AUTOHIDE (1) ou ABS_ALWAYSONTOP (2) pour toutes les barres des tâches.
PersoMasquageAuto(actif) {
    x64 := A_PtrSize = 8
    abd := Buffer(x64 ? 48 : 36, 0)
    NumPut('UInt', abd.Size, abd, 0)
    NumPut('Ptr', WinExist('ahk_class Shell_TrayWnd'), abd, x64 ? 8 : 4)
    NumPut('Ptr', actif ? 1 : 2, abd, x64 ? 40 : 32)
    DllCall('Shell32\SHAppBarMessage', 'UInt', 10, 'Ptr', abd)
}

; --- Demandes UAC en attente ----------------------------------------------------
; Une demande d'élévation lancée depuis l'arrière-plan n'ouvre pas le bureau sécurisé :
; Windows la range en bouton clignotant dans la barre des tâches, masquée par Winarchy,
; et on ne la voit jamais. Bandeau rouge en haut de l'écran tant qu'elle attend ; un
; clic l'affiche. (Quand le bureau sécurisé est ouvert, le bandeau est caché derrière.)
global PersoUacGui := 0
SetTimer(PersoUac, 700)
PersoUac() {
    global PersoUacGui
    static depuis := 0
    if !ProcessExist('consent.exe') {
        depuis := 0
        if PersoUacGui {
            PersoUacGui.Destroy()
            PersoUacGui := 0
        }
        return
    }
    if !depuis
        depuis := A_TickCount
    if (PersoUacGui || A_TickCount - depuis < 1500)
        return
    g := Gui('+AlwaysOnTop -Caption +ToolWindow +E0x08000000')   ; WS_EX_NOACTIVATE
    g.BackColor := 'C0392B'
    g.MarginY := 8
    g.SetFont('s11 cWhite bold', 'Segoe UI')
    t := g.AddText('Center w440', "Demande UAC en attente : clique ici pour l'afficher")
    t.OnEvent('Click', PersoUacAffiche)
    MonitorGetWorkArea(MonitorGetPrimary(), &gauche, &haut, &droite, &bas)
    g.Show('NoActivate x' (gauche + (droite - gauche - 460) // 2) ' y' (haut + 40) ' w460')
    PersoUacGui := g
}
PersoUacAffiche(*) {
    ; consent.exe tourne en SYSTEM : « ahk_exe » ne peut pas lire son nom. Sa fenêtre
    ; d'attente (classe ci-dessous) est RÉDUITE : l'activer ne fait rien, il faut lui
    ; envoyer WM_SYSCOMMAND/SC_RESTORE, comme un clic sur son bouton de barre des tâches.
    ; Marche parce que ce script tourne en UI Access (sinon UIPI bloque le message).
    dhw := DetectHiddenWindows(true)
    pid := ProcessExist('consent.exe')
    for crit in ['ahk_class $$$Secure UAP Dummy Window Class For Interim Dialog', pid ? 'ahk_pid ' pid : '']
        try if (crit && (h := WinExist(crit))) {
            PostMessage(0x0112, 0xF120, 0, , h)          ; WM_SYSCOMMAND, SC_RESTORE
            DllCall('SwitchToThisWindow', 'Ptr', h, 'Int', 1)
            DetectHiddenWindows(dhw)
            return
        }
    ; Sinon : la vraie barre des tâches (cachée par Winarchy), visible et active ; le bouton
    ; UAC y clignote. PersoCacheBarreWindows la recache dès qu'elle perd le focus.
    PersoMasquageAuto(false)
    for classe in ['Shell_TrayWnd', 'Shell_SecondaryTrayWnd']
        for h in WinGetList('ahk_class ' classe)
            try WinShow(h)
    try WinActivate('ahk_class Shell_TrayWnd')
    DetectHiddenWindows(dhw)
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
    # Version Microsoft Store : pas d'exe lançable, on passe par son identifiant d'application.
    $aumid = (Get-StartApps -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'Screenpresso' } | Select-Object -First 1).AppID
    Write-Utf8Bom $ahk (@'
#Requires AutoHotkey v2.0
#SingleInstance Force
; Lancé par le bouton capture de la barre YASB (setup-winarchy.ps1).
; Impr. écran doit appartenir à Screenpresso : ShareX ne la réserve plus (raccourci retiré).
exe := EnvGet('LOCALAPPDATA') '\Learnpulse\Screenpresso\Screenpresso.exe'
store := '__AUMID__'
if !ProcessExist('Screenpresso.exe') {
    if FileExist(exe)
        Run '"' exe '"'
    else if (store != '')
        Run 'explorer.exe shell:AppsFolder\' store
    else {
        MsgBox 'Screenpresso introuvable (ni ' exe ', ni version Store).', 'Capture', 'Icon!'
        ExitApp
    }
    if !ProcessWait('Screenpresso.exe', 10)
        ExitApp
    Sleep 2500   ; le temps qu'il enregistre son raccourci Impr. écran
}
Sleep 150        ; laisse le clic sur la barre se terminer
Send '{PrintScreen}'
'@).Replace('__AUMID__', [string]$aumid)
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

# Bulle « en plus » de la barre YASB (bouton ▾, comme le systray) : CPU, RAM, disques et outils
# peu utilisés, retirés de la barre faute de place. YASB ne sait pas faire déborder les widgets
# qui ne tiennent pas : la bulle a un contenu fixe. Données lues en direct par AHK (pas de PowerShell).
function Write-PlusBulle {
    $ahk = Join-Path $Perso 'plus-bulle.ahk'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
; Bulle « en plus » sous la barre YASB (bouton ▾) : écrit par setup-winarchy.ps1, ne pas modifier ici.
; CPU / RAM (rafraîchis toutes les 2 s), disques, outils. Reclic sur ▾ ou clic ailleurs = fermer.

Dossier := A_ScriptDir
Fond := "0c0a12", Texte := "eee2d8", Accent := "f25a00", Rouge := "e0435a", Gris := "9a8a94", Bouton := "2a1d26"
L := 300

if WinExist("PlusBulle ahk_class AutoHotkeyGUI") {
    WinClose
    ExitApp
}
if FermeeRecemment()
    ExitApp

CoordMode "Mouse", "Screen"
MouseGetPos &SourisX, &SourisY
PrecCpu := TempsCpu()

g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "PlusBulle")
g.BackColor := Fond
g.MarginX := 16, g.MarginY := 12
g.OnEvent("Close", (*) => ExitApp())
g.OnEvent("Escape", (*) => Fermer())

; --- Performances (clic = Gestionnaire des tâches) ---
Section("PERFORMANCES", "xm")
LCpu := Ligne("CPU", "…", () => Lancer("taskmgr.exe"))
BCpu := Barre()
LRam := Ligne("RAM", "…", () => Lancer("taskmgr.exe"))
BRam := Barre()

; --- Disques (clic = ouvrir le disque) ---
Section("DISQUES")
for genre in ["FIXED", "NETWORK"] {
    try lettres := DriveGetList(genre)
    catch
        continue
    Loop Parse lettres {
        d := A_LoopField ":\"
        try {
            if DriveGetStatus(d) != "Ready"
                continue
            total := DriveGetCapacity(d), libre := DriveGetSpaceFree(d)
            if total <= 0
                continue
            nom := DriveGetLabel(d)
        } catch
            continue
        pct := Round((total - libre) * 100 / total)
        Ligne(A_LoopField ":  " (nom != "" ? nom : genre = "NETWORK" ? "Réseau" : "Local"),
            pct " %  ·  " Go(libre) " libres", OuvrirDisque.Bind(d), pct >= 90)
        Barre(pct, genre = "NETWORK" ? "56b6c2" : "")
    }
}

; --- Outils ---
Section("OUTILS")
w := (L - 8) // 2
Outils := [
    ["Texte de l'écran (OCR)", "winarchy screenshot ocr"],
    ["Lire un QR code", "winarchy screenshot qr"],
    ["Pipette", "winarchy screenshot color"],
    ["Corbeille", "explorer.exe shell:RecycleBinFolder"],
    ["Plan d'alimentation", "control.exe powercfg.cpl"],
    ["Ce PC", "explorer.exe shell:MyComputerFolder"],
]
for i, o in Outils
    AjouterBouton((Mod(i, 2) ? "xm y+8" : "x+8 yp") " w" w, o[1], Lancer.Bind(o[2]))
g.AddText("xm y+4 w1 h1")   ; marge du bas

MajPerf()
Afficher()
SetTimer(MajPerf, 2000)
SetTimer(ClicDehors, 50)

Section(titre, pos := "xm y+16") {
    g.SetFont("s8 bold c" Gris, "Segoe UI")
    g.AddText(pos " w" L, titre)
}

; Nom à gauche, valeur à droite (rouge si alerte) ; toute la ligne est cliquable.
Ligne(nom, valeur, action, alerte := false) {
    g.SetFont("s10 norm c" Texte, "Segoe UI")
    n := g.AddText("xm y+6 w110", nom)
    g.SetFont("s10 " (alerte ? "bold" : "norm") " c" (alerte ? Rouge : Accent))
    v := g.AddText("x+0 yp w" (L - 110) " Right", valeur)
    n.OnEvent("Click", (*) => action())
    v.OnEvent("Click", (*) => action())
    return v
}

Barre(pct := 0, couleur := "") {
    return g.AddProgress("xm y+3 w" L " h4 c" (couleur != "" ? couleur : pct >= 90 ? Rouge : Accent) " Background" Bouton, pct)
}

AjouterBouton(opts, libelle, action) {
    g.SetFont("s9 norm c" Texte, "Segoe UI")
    b := g.AddText(opts " h28 Center 0x200 Background" Bouton, libelle)   ; 0x200 = centré verticalement
    b.OnEvent("Click", (*) => action())
}

MajPerf() {
    global PrecCpu
    t := TempsCpu()
    total := (t.noyau - PrecCpu.noyau) + (t.user - PrecCpu.user)
    cpu := total > 0 ? Round((total - (t.idle - PrecCpu.idle)) * 100 / total) : 0
    PrecCpu := t
    mem := Buffer(64, 0)
    NumPut("UInt", 64, mem)
    DllCall("GlobalMemoryStatusEx", "Ptr", mem)
    ram := NumGet(mem, 4, "UInt"), tot := NumGet(mem, 8, "UInt64"), dispo := NumGet(mem, 16, "UInt64")
    LCpu.Text := cpu " %"
    BCpu.Value := cpu
    LRam.Text := ram " %  ·  " Go(tot - dispo) " / " Go(tot)
    BRam.Value := ram
}

TempsCpu() {
    DllCall("GetSystemTimes", "Int64*", &idle := 0, "Int64*", &noyau := 0, "Int64*", &user := 0)
    return {idle: idle, noyau: noyau, user: user}
}

; Mo (DriveGet*) ou octets (mémoire) -> « 12,3 Go » / « 1,2 To ».
Go(v) {
    go := v > 1e7 ? v / 1073741824 : v / 1024
    return go >= 1000 ? StrReplace(Format("{:.1f}", go / 1024), ".", ",") " To" : StrReplace(Format("{:.1f}", go), ".", ",") " Go"
}

OuvrirDisque(d) => Lancer('explorer.exe "' d '"')

Lancer(cmd) {
    g.Hide()
    ; winarchy est un .cmd : passé par cmd.exe (fenêtre cachée) ; le reste s'ouvre normalement.
    try {
        if SubStr(cmd, 1, 9) = "winarchy "
            Run(A_ComSpec " /c " cmd, , "Hide")
        else
            Run(cmd)
    }
    ExitApp
}

ClicDehors() {
    static avant := true   ; bouton déjà enfoncé à l'ouverture : le clic qui a ouvert la bulle
    bas := GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
    if bas && !avant {
        MouseGetPos , , &sous
        if sous != g.Hwnd
            Fermer()
    }
    avant := bas
}

Fermer() {
    f := Dossier "\plus-bulle.ferme"
    try FileDelete(f)
    try FileAppend(DllCall("GetTickCount64", "Int64"), f)
    ExitApp
}

FermeeRecemment() {
    try return DllCall("GetTickCount64", "Int64") - Integer(FileRead(Dossier "\plus-bulle.ferme")) < 1500
    return false
}

; Sous la barre, bord droit aligné sur la souris (comme le popup du systray), dans l'écran.
Afficher() {
    n := MonitorGetPrimary()
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if SourisX >= l && SourisX < r && SourisY >= t && SourisY < b
            n := A_Index
    }
    MonitorGetWorkArea(n, &l, &t, &r, &b)
    g.Show("Hide AutoSize")
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 34, "UInt*", Bgr("55404c"), "UInt", 4)
    g.GetPos(, , &w)
    x := Max(l + 6, Min(SourisX + 20 - w, r - w - 6))
    g.Show("x" x " y" (t + 6))
}

Bgr(hex) {
    v := Integer("0x" hex)
    return ((v & 0xFF) << 16) | (v & 0xFF00) | ((v >> 16) & 0xFF)
}
'@
    Ok "Bulle « en plus » de la barre : $ahk"
}

# Clic du milieu = coller (Ctrl+V), lancé à chaque ouverture de session (dossier Démarrage).
# Hors du bloc user.ahk : script indépendant, comme sur le poste d'origine.
function Install-ColleClicMilieu([bool]$actif) {
    $demarrage = [Environment]::GetFolderPath('Startup')
    $ahk = Join-Path $demarrage 'coller-clic-milieu.ahk'
    if (-not $actif) {
        Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*coller-clic-milieu.ahk*' } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        if (Test-Path $ahk) { Remove-Item $ahk -Force; Ok 'Clic du milieu = coller : retiré' }
        return
    }
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Force

; Clic du milieu = coller (Ctrl+V). Écrit par setup-winarchy.ps1.
; - Windows Terminal : toujours (y compris dans Claude Code).
; - Ailleurs (navigateurs, VS Code, Bloc-notes, Word...) : seulement si le
;   pointeur est un curseur texte (barre "I"). Un clic gauche place d'abord le
;   curseur à l'endroit visé, puis colle.
;   Sur un lien, un onglet ou une zone sans texte, le clic du milieu reste normal.

#HotIf WinActive("ahk_exe WindowsTerminal.exe")
MButton::Send "^v"
#HotIf

#HotIf !WinActive("ahk_exe WindowsTerminal.exe") && A_Cursor = "IBeam"
MButton:: {
    Click
    Send "^v"
}
#HotIf
'@
    $exe = Find-AhkV2
    if ($exe) { Start-Process $exe -ArgumentList "`"$ahk`"" }   # #SingleInstance Force : remplace l'instance en cours
    Ok "Clic du milieu = coller : $ahk"
}

# Logo Windows de la barre YASB -> lanceur d'applis Flow (comme Super seul) : raccourci natif
# de Flow (Alt+Espace), ou démarrage de Flow s'il ne tourne pas encore.
function Write-LanceurAppsLauncher {
    $ahk = Join-Path $Perso 'lanceur.ahk'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Force
; Lancé par le logo Windows de la barre YASB (setup-winarchy.ps1).
flow := EnvGet('LOCALAPPDATA') '\FlowLauncher\Flow.Launcher.exe'
Sleep 150        ; laisse le clic sur la barre se terminer
if ProcessExist('Flow.Launcher.exe')
    Send '!{Space}'
else if FileExist(flow)
    Run '"' flow '"'
'@
    Ok "Lanceur d'applis (logo Windows de la barre) : $ahk"
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

# Widget « rdv » de la barre YASB : prochain rendez-vous Outlook (lu par COM, même Outlook fermé).
# rdv-bulle.ahk : bulle sous la barre, RDV de la semaine en cours au clic droit, alerte clignotante sur
# tous les écrans 5 min avant chaque RDV (Rappel 5 min / Outlook / OK), ouverte par rdv.ps1.
function Write-RdvScript {
    $ps1 = Join-Path $Perso 'rdv.ps1'
    New-Item -ItemType Directory -Force $Perso | Out-Null
    Write-Utf8Bom $ps1 @'
# Lancé chaque minute par le widget « rdv » de la barre YASB (setup-winarchy.ps1), en arrière-plan.
# Lit le calendrier d'Outlook classique par COM : s'il est fermé, Outlook démarre sans fenêtre le
# temps de la lecture puis se referme. Résultat gardé dans rdv.json et relu entre deux lectures
# (toutes les 2 min si Outlook tourne, toutes les 10 min sinon).
# Sortie JSON : barre, alt (avec le lieu), detail (bulle d'aide au survol : détail du prochain RDV).
# Écrit rdv-bulle.txt (RDV de la semaine en cours, lu par rdv-bulle.ahk : clic droit) et ouvre la bulle d'alerte $bulle minutes
# avant chaque RDV. La bulle répond dans rdv-actions.txt (« ok » ou « snooze » jusqu'à une heure).
#   -Actualiser : relit Outlook tout de suite.
param([switch]$Actualiser)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$avance = 15        # minutes : le widget passe en « dans N min »
$bulle = 5          # minutes : la bulle d'alerte s'ouvre
$dossier = Split-Path $MyInvocation.MyCommand.Path
$fCache = Join-Path $dossier 'rdv.json'
$fEtat = Join-Path $dossier 'rdv-etat.json'
$fBulle = Join-Path $dossier 'rdv-bulle.txt'
$fActions = Join-Path $dossier 'rdv-actions.txt'
$ahk = Join-Path $dossier 'rdv-bulle.ahk'
$utf8 = New-Object Text.UTF8Encoding $false
$icCal = [char]::ConvertFromUtf32(0xF00F0)      # nf-md-calendar_clock
$icVide = [char]::ConvertFromUtf32(0xF00ED)     # nf-md-calendar
$icAlerte = [char]::ConvertFromUtf32(0xF009E)   # nf-md-bell_ring
$maintenant = Get-Date
$lundi = $maintenant.Date.AddDays(-(([int]$maintenant.DayOfWeek + 6) % 7))

function Read-JsonFichier([string]$f) {
    try { if (Test-Path $f) { return ([IO.File]::ReadAllText($f) | ConvertFrom-Json) } } catch {}
    $null
}
function Get-Court([string]$s, [int]$n = 28) { if ($s.Length -gt $n) { $s.Substring(0, $n - 1) + '…' } else { $s } }
function Get-Propre([string]$s) { ($s -replace '[\t\r\n]+', ' ').Trim() }

function Read-CalendrierOutlook {
    $ol = New-Object -ComObject Outlook.Application
    try {
        $items = $ol.GetNamespace('MAPI').GetDefaultFolder(9).Items   # 9 = olFolderCalendar
        $items.IncludeRecurrences = $true
        $items.Sort('[Start]')
        # Semaine en cours (lundi -> dimanche) pour la bulle du clic droit, et au moins jusqu'à demain soir
        # pour le prochain RDV du widget (le dimanche, la semaine suivante n'est pas encore lue).
        $de = $lundi.ToString('g'); $a = (@($lundi.AddDays(7), $maintenant.Date.AddDays(2)) | Measure-Object -Maximum).Maximum.ToString('g')
        foreach ($i in $items.Restrict("[Start] < '$a' AND [End] > '$de'")) {
            # Refusés (4) et annulés (5, 7) : ignorés.
            if ($i.ResponseStatus -eq 4 -or $i.MeetingStatus -in 5, 7) { continue }
            [pscustomobject]@{
                debut = $i.Start.ToString('s'); fin = $i.End.ToString('s')
                sujet = [string]$i.Subject; lieu = [string]$i.Location; journee = [bool]$i.AllDayEvent
                organisateur = [string]$i.Organizer
            }
        }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($ol) }
}

# Clic du milieu sur le widget (exec_custom : relance immédiate du widget) : la souris est alors au
# centre d'une barre YASB -> lecture forcée d'Outlook. Survol prolongé : même effet, sans gravité.
if (-not $Actualiser) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $pos = [Windows.Forms.Cursor]::Position; $ecr = [Windows.Forms.Screen]::FromPoint($pos).Bounds
        if ($pos.Y - $ecr.Top -lt 50 -and [math]::Abs($pos.X - ($ecr.Left + $ecr.Width / 2)) -lt 400) { $Actualiser = $true }
    } catch {}
}

# --- Lecture d'Outlook (si le cache est trop vieux), une seule à la fois ---
$cache = Read-JsonFichier $fCache
$outlook = @(Get-Process OUTLOOK -ErrorAction SilentlyContinue)
$age = if ($cache) { ($maintenant - [datetime]$cache.lu).TotalMinutes } else { [double]::MaxValue }
$erreur = $null
if ($Actualiser -or $age -ge $(if ($outlook) { 2 } else { 10 })) {
    $mutex = New-Object Threading.Mutex($false, 'Local\winarchy-rdv')
    $libre = try { $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $true }
    if ($libre) {
        try {
            $rdv = @(Read-CalendrierOutlook)
            $cache = [pscustomobject]@{ lu = $maintenant.ToString('s'); rdv = $rdv }
            [IO.File]::WriteAllText($fCache, (ConvertTo-Json $cache -Depth 4 -Compress), $utf8)
        } catch { $erreur = $_.Exception.Message }
        finally { $mutex.ReleaseMutex() }
    }
}

# --- Rendez-vous de la journée et à venir ---
$tous = @(foreach ($r in @($cache.rdv)) {
    if (-not $r) { continue }
    [pscustomobject]@{ debut = [datetime]$r.debut; fin = [datetime]$r.fin; sujet = Get-Propre $r.sujet; lieu = Get-Propre $r.lieu
        organisateur = Get-Propre $r.organisateur; journee = [bool]$r.journee; cle = "$($r.debut)|$(Get-Propre $r.sujet)" }
}) | Where-Object { $_.fin -gt $lundi } | Sort-Object debut
$evts = @($tous | Where-Object { $_.fin -gt $maintenant })
$horaires = @($evts | Where-Object { -not $_.journee })

# Données de la bulle (depuis lundi) : clé, début, fin, journée, sujet, lieu, séparés par des tabulations.
$lignes = foreach ($e in $tous) { ($e.cle, $e.debut.ToString('yyyyMMddHHmmss'), $e.fin.ToString('yyyyMMddHHmmss'), [int]$e.journee, $e.sujet, $e.lieu) -join "`t" }
# Écrit seulement si changé, et remplacé d'un coup : la bulle ne lit jamais un fichier à moitié écrit.
$texteBulle = @($lignes) -join "`n"
if (-not (Test-Path $fBulle) -or [IO.File]::ReadAllText($fBulle) -cne $texteBulle) {
    $tmp = "$fBulle.$PID.tmp"
    [IO.File]::WriteAllText($tmp, $texteBulle, $utf8)
    try { if (Test-Path $fBulle) { [IO.File]::Replace($tmp, $fBulle, $null) } else { [IO.File]::Move($tmp, $fBulle) } }
    catch { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

# --- État : bulles déjà ouvertes, « OK » et rappels de la bulle (purgé après 2 jours) ---
# Une barre par écran lance ce script : verrou pour n'ouvrir qu'une seule bulle.
$verrou = New-Object Threading.Mutex($false, 'Local\winarchy-rdv-etat')
try { [void]$verrou.WaitOne(10000) } catch [Threading.AbandonedMutexException] {}
try {
$etat = Read-JsonFichier $fEtat
$recent = { param($c) try { [datetime]($c.Split('|')[0]) -gt $maintenant.AddDays(-2) } catch { $false } }
$ok = [Collections.Generic.List[string]]@(@($etat.ok) | Where-Object { $_ -and (& $recent $_) })
$montres = [Collections.Generic.List[string]]@(@($etat.montres) | Where-Object { $_ -and (& $recent $_) })
$snooze = @{}
if ($etat.snooze) { foreach ($p in $etat.snooze.PSObject.Properties) { if (& $recent $p.Name) { $snooze[$p.Name] = [string]$p.Value } } }
if (Test-Path $fActions) {
    foreach ($l in [IO.File]::ReadAllLines($fActions)) {
        $c = $l.TrimStart([char]0xFEFF).Split("`t")
        if ($c[0] -eq 'ok' -and $c.Count -ge 2) { $ok.Add($c[1]); $snooze.Remove($c[1]) }
        elseif ($c[0] -eq 'snooze' -and $c.Count -ge 3) { $snooze[$c[1]] = $c[2] }
    }
    Remove-Item $fActions -Force
}

# Bulle d'alerte : $bulle min avant (jusqu'à 15 min après le début), puis à chaque fin de rappel.
foreach ($e in $horaires) {
    if ($e.cle -in $ok -or $maintenant -lt $e.debut.AddMinutes(-$bulle) -or $maintenant -gt $e.debut.AddMinutes(15)) { continue }
    if ($e.cle -in $montres) {
        if (-not $snooze.ContainsKey($e.cle)) { continue }   # bulle encore ouverte, ou fermée sans réponse
        $jusqua = [datetime]::ParseExact($snooze[$e.cle], 'yyyyMMddHHmmss', $null)
        if ($maintenant -lt $jusqua) { continue }
        $snooze.Remove($e.cle)
    }
    if ($e.cle -notin $montres) { $montres.Add($e.cle) }
    try { Start-Process -FilePath $ahk -ArgumentList 'alerte', "`"$($e.cle)`"" } catch {}
    break
}
[IO.File]::WriteAllText($fEtat, (ConvertTo-Json @{ ok = @($ok); montres = @($montres); snooze = $snooze } -Compress), $utf8)
} finally { try { $verrou.ReleaseMutex() } catch {} }

# --- Sortie du widget ---
function Get-Jour([datetime]$d) {
    if ($d.Date -eq $maintenant.Date) { '' } elseif ($d.Date -eq $maintenant.Date.AddDays(1)) { 'demain ' } else { $d.ToString('ddd ') }
}
$suivant = $horaires | Where-Object { $_.debut -gt $maintenant.AddMinutes(-5) } | Select-Object -First 1
if ($suivant -and ($suivant.debut - $maintenant).TotalMinutes -le $avance) {
    $m = [math]::Ceiling(($suivant.debut - $maintenant).TotalMinutes)
    $barre = "$icAlerte $(if ($m -gt 0) { "dans $m min" } else { 'maintenant' }) · $(Get-Court $suivant.sujet 18)"
    $alt = $barre + $(if ($suivant.lieu) { " · $(Get-Court $suivant.lieu 30)" })
} elseif ($suivant) {
    $barre = "$icCal $(Get-Jour $suivant.debut)$($suivant.debut.ToString('HH:mm')) $(Get-Court $suivant.sujet 18)"
    $alt = $barre + $(if ($suivant.lieu) { " · $(Get-Court $suivant.lieu 30)" })
} else { $barre = $icVide; $alt = "$icVide rien à venir" }

# Bulle d'aide (survol) : détail du prochain RDV.
function Get-Duree([timespan]$t) {
    $m = [int][math]::Ceiling($t.TotalMinutes)
    if ($m -ge 60) { '{0} h {1:00}' -f [math]::Floor($m / 60), ($m % 60) } else { "$m min" }
}
$detail = @()
if ($suivant) {
    $jour = if ($suivant.debut.Date -eq $maintenant.Date) { "Aujourd'hui" } elseif ($suivant.debut.Date -eq $maintenant.Date.AddDays(1)) { 'Demain' } else { $suivant.debut.ToString('dddd d MMMM') }
    $ecart = $suivant.debut - $maintenant
    $quand = if ($ecart.TotalMinutes -gt 0) { "dans $(Get-Duree $ecart)" } else { "commencé depuis $(Get-Duree (-$ecart))" }
    $detail += $suivant.sujet
    $detail += "$jour $($suivant.debut.ToString('HH:mm'))–$($suivant.fin.ToString('HH:mm')) ($(Get-Duree ($suivant.fin - $suivant.debut)))  ·  $quand"
    if ($suivant.lieu) { $detail += "Lieu : $($suivant.lieu)" }
    if ($suivant.organisateur) { $detail += "Organisateur : $($suivant.organisateur)" }
} else { $detail += "Aucun rendez-vous à venir" }
# Seulement le RDV à venir ; une ligne de plus uniquement si Outlook n'a pas pu être lu.
if ($erreur) { $detail += ''; $detail += "Outlook injoignable : $erreur" }

[pscustomobject]@{ barre = $barre; alt = $alt; detail = $detail -join "`n" } | ConvertTo-Json -Compress
'@
    $ahk = Join-Path $Perso 'rdv-bulle.ahk'
    Write-Utf8Bom $ahk @'
#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
; Bulle des rendez-vous Outlook sous la barre YASB : écrit par setup-winarchy.ps1, ne pas modifier ici.
;   rdv-bulle.ahk             RDV de la semaine en cours (clic droit sur le widget rdv ; reclic = fermer)
;   rdv-bulle.ahk alerte CLE  alerte avant un RDV, sur tous les écrans (lancée par rdv.ps1) :
;                             Rappel 5 min / Outlook / OK ; un clic sur l'une ferme toutes les bulles
; Données : rdv-bulle.txt (écrit par rdv.ps1). Réponses : rdv-actions.txt (relu par rdv.ps1).

Dossier := A_ScriptDir
Mode := A_Args.Length ? A_Args[1] : "agenda"
Cle := A_Args.Length > 1 ? A_Args[2] : ""
Fond := "0c0a12", Texte := "eee2d8", Accent := "f25a00", Rouge := "e0435a", Gris := "9a8a94", Bouton := "2a1d26"
L := 340
Bulles := [], Bandes := [], Titres := []

if Mode = "agenda" {
    ; Reclic sur le widget : la bulle vient de se fermer (clic dehors) ou est encore ouverte.
    if WinExist("RdvBulle agenda ahk_class AutoHotkeyGUI") {
        WinClose
        ExitApp
    }
    if FermeeRecemment()
        ExitApp
} else {
    while WinExist("RdvBulle alerte ahk_class AutoHotkeyGUI") {
        WinClose
        Sleep 100
    }
}

Evts := []
try {
    Loop Parse FileRead(Dossier "\rdv-bulle.txt", "UTF-8"), "`n", "`r" {
        c := StrSplit(A_LoopField, "`t")
        if c.Length >= 6
            Evts.Push({cle: c[1], debut: c[2], fin: c[3], journee: c[4] = "1", sujet: c[5], lieu: c[6]})
    }
}

if Mode = "alerte" {
    E := ""
    for x in Evts
        if x.cle = Cle
            E := x
    if !IsObject(E)
        ExitApp
    Loop MonitorGetCount()
        BulleAlerte(A_Index)
    Clignements := 0
    SetTimer(Clignoter, 600)
    SetTimer(MajTitres, 10000)
    SoundPlay "*48"
} else {
    BulleAgenda(EcranSouris())
    SetTimer(ClicDehors, 50)   ; fermée dès qu'on clique ailleurs (la bulle n'a pas toujours le focus)
}

NouvelleBulle() {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "RdvBulle " Mode)
    g.BackColor := Fond
    g.MarginX := 16, g.MarginY := 12
    g.OnEvent("Close", (*) => ExitApp())
    g.OnEvent("Escape", (*) => Mode = "alerte" ? Repondre("ok") : Fermer())
    Bulles.Push(g)
    return g
}

BulleAlerte(n) {
    g := NouvelleBulle()
    bande := g.AddText("x0 y0 w" (L + 32) " h6 Background" Rouge)
    Bandes.Push(bande)
    g.SetFont("s10 bold c" Rouge, "Segoe UI")
    Titres.Push(g.AddText("xm y18 w" L, TexteTitre()))
    g.SetFont("s14 bold c" Texte)
    g.AddText("xm y+6 w" L, E.sujet)
    g.SetFont("s10 norm c" Gris)
    g.AddText("xm y+2 w" L, Heures(E) (E.lieu != "" ? "   ·   " E.lieu : ""))
    w := (L - 16) // 3
    AjouterBouton(g, "xm y+16 w" w, "Rappel 5 min", Bouton, () => Repondre("snooze"))
    AjouterBouton(g, "x+8 yp w" w, "Outlook", Bouton, () => Repondre("outlook"))
    AjouterBouton(g, "x+8 yp w" w, "OK", Rouge, () => Repondre("ok"))
    Afficher(g, n, false, bande)
}

; Tous les RDV de la semaine en cours, lundi -> dimanche (passés en gris). Jours sans RDV omis, sauf aujourd'hui.
BulleAgenda(n) {
    g := NouvelleBulle()
    lundi := DateAdd(A_Now, -Mod(A_WDay + 5, 7), "Days")   ; A_WDay : 1 = dimanche, 2 = lundi
    g.SetFont("s11 bold c" Accent, "Segoe UI")
    g.AddText("xm w" L, "Semaine du " FormatTime(lundi, "d MMMM") " au " FormatTime(DateAdd(lundi, 6, "Days"), "d MMMM"))
    Loop 7 {
        jour := DateAdd(lundi, A_Index - 1, "Days"), cle := FormatTime(jour, "yyyyMMdd")
        rel := DateDiff(cle, FormatTime(A_Now, "yyyyMMdd"), "Days")
        du := []
        for e in Evts
            ; (un RDV qui finit à minuit pile n'appartient pas au jour où il finit)
            if SubStr(e.debut, 1, 8) <= cle && SubStr(e.fin, 1, 8) >= cle && !(SubStr(e.fin, 1, 8) = cle && SubStr(e.fin, 9) = "000000" && SubStr(e.debut, 1, 8) != cle)
                du.Push(e)
        if !du.Length && rel != 0
            continue
        nom := rel = 0 ? "Aujourd'hui · " : rel = 1 ? "Demain · " : ""
        g.SetFont("s8 bold c" (rel = 0 ? Accent : Gris))
        g.AddText("xm y+14 w" L, StrUpper(nom FormatTime(jour, "dddd d MMMM")))
        for e in du
            LigneRdv(g, e)
        if !du.Length {
            g.SetFont("s10 norm c" Gris)
            g.AddText("xm y+6 w" L, "Aucun rendez-vous")
        }
    }
    g.AddText("xm y+4 w1 h1")   ; marge du bas
    Afficher(g, n, true)
}

; Une ligne : heures (orange ; rouge si en cours ou dans 15 min ; gris si passé), sujet, lieu.
LigneRdv(g, e) {
    passe := e.fin <= A_Now
    proche := !passe && !e.journee && Minutes(e) <= 15
    g.SetFont("s10 " (proche ? "bold" : "norm") " c" (passe ? Gris : proche ? Rouge : Accent))
    g.AddText("xm y+6 w92", Heures(e))
    g.SetFont("s10 " (proche ? "bold" : "norm") " c" (passe ? Gris : Texte))
    g.AddText("x+4 yp w" (L - 96), e.sujet)
    if e.lieu != "" && !passe {   ; lieu masqué pour les RDV passés (bulle moins haute)
        g.SetFont("s9 norm c" Gris)
        g.AddText("xp y+1 w" (L - 96), e.lieu)
    }
}

Minutes(e) => Ceil(DateDiff(e.debut, A_Now, "Seconds") / 60)
Heures(e) => e.journee ? "Journée" : FormatTime(e.debut, "HH:mm") "–" FormatTime(e.fin, "HH:mm")

TexteTitre() {
    m := Minutes(E)
    q := m > 0 ? "DANS " m " MIN" : m = 0 ? "MAINTENANT" : "COMMENCÉ DEPUIS " (-m) " MIN"
    return "⚠  RENDEZ-VOUS " q
}

MajTitres() {
    for t in Titres
        t.Text := TexteTitre()
}

Jour(d) {
    if SubStr(d, 1, 8) = FormatTime(A_Now, "yyyyMMdd")
        return "AUJOURD'HUI"
    if SubStr(d, 1, 8) = FormatTime(DateAdd(A_Now, 1, "Days"), "yyyyMMdd")
        return "DEMAIN"
    return StrUpper(FormatTime(d, "dddd d MMMM"))
}

AjouterBouton(g, opts, libelle, couleur, action) {
    g.SetFont("s10 bold c" Texte)
    b := g.AddText(opts " h30 Center 0x200 Background" couleur, libelle)   ; 0x200 = centré verticalement
    b.OnEvent("Click", (*) => action())
}

; Bandeau et titre qui clignotent jusqu'à la réponse.
Clignoter() {
    global Clignements
    Clignements += 1
    allume := Mod(Clignements, 2)
    for b in Bandes {
        b.Opt("Background" (allume ? Fond : Rouge))
        b.Redraw()
    }
    for t in Titres
        t.SetFont("c" (allume ? Texte : Rouge))
}

Repondre(quoi) {
    ligne := quoi = "snooze" ? "snooze`t" Cle "`t" DateAdd(A_Now, 5, "Minutes") : "ok`t" Cle
    FileAppend(ligne "`n", Dossier "\rdv-actions.txt", "UTF-8-RAW")
    if quoi = "outlook"
        OuvrirOutlook()
    ExitApp
}

OuvrirOutlook() {
    try Run("outlook.exe /select outlook:calendar")
}

ClicDehors() {
    static avant := true   ; bouton déjà enfoncé à l'ouverture : le clic qui a ouvert la bulle
    bas := GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
    if bas && !avant {
        CoordMode "Mouse", "Screen"
        MouseGetPos , , &sous
        if sous != Bulles[1].Hwnd
            Fermer()
    }
    avant := bas
}

Fermer() {
    if Mode = "agenda" {
        f := Dossier "\rdv-bulle.ferme"
        try FileDelete(f)
        try FileAppend(DllCall("GetTickCount64", "Int64"), f)
    }
    ExitApp
}

FermeeRecemment() {
    try return DllCall("GetTickCount64", "Int64") - Integer(FileRead(Dossier "\rdv-bulle.ferme")) < 1500
    return false
}

EcranSouris() {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if mx >= l && mx < r && my >= t && my < b
            return A_Index
    }
    return MonitorGetPrimary()
}

; Sous la barre, centrée sur l'écran n (zone de travail = sous l'AppBar YASB).
Afficher(g, n, activer, bande := "") {
    MonitorGetWorkArea(n, &l, &t, &r, &b)
    g.Show("Hide AutoSize")
    if bande {   ; bandeau rouge sur toute la largeur réelle
        g.GetClientPos(, , &cw)
        bande.Move(0, 0, cw)
    }
    ; Windows 11 : coins arrondis et bordure couleur (rouge pour l'alerte).
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 34, "UInt*", Bgr(Mode = "alerte" ? Rouge : "55404c"), "UInt", 4)
    g.GetPos(, , &w)
    g.Show("x" (l + (r - l - w) // 2) " y" (t + 6) (activer ? "" : " NoActivate"))
}

Bgr(hex) {
    v := Integer("0x" hex)
    return ((v & 0xFF) << 16) | (v & 0xFF00) | ((v >> 16) & 0xFF)
}
'@
    # Restes de l'ancienne version (widget d'alerte séparé).
    Remove-Item (Join-Path $Perso 'rdv-alerte.txt') -Force -ErrorAction SilentlyContinue
    Ok "Rendez-vous Outlook (barre YASB) : $ps1, $ahk"
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
    $racine = Find-WinarchyKomorebi
    $cfgKomorebi = if ($racine) { Join-Path $racine 'config\komorebi' } else { 'C:\winarchy\config\komorebi' }
    Write-Utf8Bom $ps1 (@'
# Lancé par le widget « wifi » de la barre YASB (setup-winarchy.ps1), en arrière-plan.
# Sortie JSON : icone (barre, écrite par le watcher Start-NetIcon.ps1 de Winarchy), detail (bulle).
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
# Repli si YASB a été lancé sans KOMOREBI_CONFIG_HOME (sinon Join-Path plante et la barre affiche « None »).
$cfg = if ($env:KOMOREBI_CONFIG_HOME) { $env:KOMOREBI_CONFIG_HOME } else { '__KOMOREBI_CONFIG__' }
$flag = Join-Path $cfg '..\..\state\net-icon.flag'
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
'@).Replace('__KOMOREBI_CONFIG__', $cfgKomorebi)
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

# Raccourcis Super de Windows : seuls ceux de Winarchy restent. Les combinaisons Super+lettre
# ou chiffre que Winarchy ne prend pas n'ouvrent plus rien (DisabledHotkeys, sauf T, que
# devant.ahk envoie pour les demandes UAC ; Super+Tab reste pour l'Exposé). « Actions par
# clic » (Super+clic, l'IA qui s'ouvrait à la place de Flow) et Copilot sont coupés par
# stratégie. Super+L (verrouiller) reste géré par Windows.
function Set-RaccourcisWindows([bool]$desactives) {
    $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $strategies = @(
        @{ Cle = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI'; Nom = 'DisableClickToDo' },
        @{ Cle = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Nom = 'TurnOffWindowsCopilot' }
    )
    if ($desactives) {
        $touches = (@([char[]]'ABCDEFGHIJKLMNOPQRSUVWXYZ0123456789') -join '')
        Set-ItemProperty $adv -Name DisabledHotkeys -Value $touches -Type String
        Ok 'Raccourcis Super de Windows désactivés (hors Winarchy, Super+Tab, Super+T, Super+L)'
        try {
            foreach ($s in $strategies) {
                New-Item $s.Cle -Force -ErrorAction Stop | Out-Null
                Set-ItemProperty $s.Cle -Name $s.Nom -Value 1 -Type DWord -ErrorAction Stop
            }
            Ok 'Actions par clic (Super+clic) et Copilot désactivés'
        } catch {
            Write-Warning 'Actions par clic / Copilot : relance le setup en administrateur pour les désactiver'
        }
    } else {
        Remove-ItemProperty $adv -Name DisabledHotkeys -ErrorAction SilentlyContinue
        foreach ($s in $strategies) { Remove-ItemProperty $s.Cle -Name $s.Nom -ErrorAction SilentlyContinue }
        Ok 'Raccourcis Super de Windows rétablis'
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
        Info 'Fenêtre UAC : accepte-la pour régler komorebi (fenêtres admin tilées).'
        Info '   Pas de fenêtre ? Clique sur le bandeau rouge « Demande UAC en attente » en haut de l''écran.'
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
        Set-RaccourcisWindows $false
        Set-KomorebiAdmin $false
        if (Test-Path $Perso) { Remove-Item $Perso -Recurse -Force; Ok "Supprimé : $Perso" }
        return
    }

    Write-Host '==> Installation des raccourcis perso'
    Copy-Profils
    Write-ClaudeLauncher
    Write-ScreenpressoLauncher
    Write-PressePapiersLauncher
    Write-PlusBulle
    Write-LanceurAppsLauncher
    Write-DisquesScript
    Write-RdvScript
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
#HotIf PersoAvantRaccourci()   ; toujours vrai (passe devant winarchy.ahk) ; rend le focus à Ninja si besoin
; --- Perso : applis -----------------------------------------------------------
#Backspace::PersoIci(), PersoClaude('foxis')                  ; Claude Code (Foxis)
#+Backspace::PersoIci(), PersoClaudeBascule()                 ; Claude Desktop : ouvre / affiche / replie
#+a::return                                       ; Supprimé (webapp claude.ai de Winarchy)
#^!+Enter::PersoIci(), PersoClaudePerso()                     ; Claude Desktop perso (2e instance, compte perso)
#a::PersoExpose()                                 ; Exposé (Vue des tâches)
#!Tab::PersoExpose()                              ; Exposé (Vue des tâches)
#o::PersoIci(), PersoOutlook()                                ; Outlook (remplace Obsidian de Winarchy)
#+o::return                                       ; Supprimé (Outlook est passé sur Super+O)
#m::PersoLanceIci(PersoDeezer)                                ; Deezer, sur l'écran de la souris (remplace la musique de Winarchy)
#y::return                                        ; Supprimés : applis web de Winarchy
#x::return                                        ;   (YouTube, X, Google Calendar, WhatsApp)
#c::return
#g::return
#n::GetKeyState('LWin','P') || GetKeyState('RWin','P') ? PersoLanceIci(() => Run('notepad.exe')) : Send('#n')   ; Bloc-notes (Super+N) ; Win+N simulé (cloche YASB) → centre de notifications
#+n::Send('{Blind}{Shift up}n')                   ; Centre de notifications : Windows reçoit Win+N
#r::PersoIci(), Run('explorer.exe shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}')   ; Exécuter
#i::PersoIci(), Run('ms-settings:')               ; Paramètres Windows
; Raccourcis de Winarchy repris pour s'ouvrir sur l'écran de la souris (PersoIci).
#Enter::Wezterm('start --position ' PersoCoinSouris())   ; Terminal
#b::PersoIci(), Run(DefaultBrowser())   ; Navigateur
#e::PersoLanceIci(() => Run('explorer.exe'))     ; Explorateur, sur l'écran de la souris
#Space::PersoDemarrer()                           ; Menu Démarrer + barre des tâches Windows entière
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
#^Left::PersoVersEcran('left')                    ; Fenêtre vers l'écran voisin (Super+Ctrl+flèche, remplace le changement de bureau virtuel)
#^Up::PersoVersEcran('up')
#^Right::PersoVersEcran('right')
#^Down::PersoVersEcran('down')
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
#+s::PersoRameneTout()                            ; Ramener toutes les fenêtres réduites
#p::Run('ms-settings-displays-topology:projection')   ; Projeter (menu Windows)
#+w::PersoScreenpresso()                          ; Capture Screenpresso (remplace ShareX fenêtre active)
#+p::PersoScreenpresso()                          ; Capture Screenpresso (remplace ShareX plein écran)
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
        if !depuis {
            depuis := A_TickCount
            PersoSuivreSouris()
        }
        return
    }
    Send('{Blind}{vkE8}{LWin up}')
    seul := (A_PriorKey = 'LWin' && A_TickCount - depuis < 500)
    depuis := 0
    if seul
        PersoIci(), PersoFlowDereduit(), ToggleFlow()
}

; Flow réduit (Super+S, Win+D…) : Alt+Espace ne l'affichait plus qu'en petite barre en bas
; à gauche. On le restaure et on le recache avant de l'ouvrir.
PersoFlowDereduit() {
    DetectHiddenWindows(true)
    try {
        h := WinExist('Flow.Launcher ahk_exe Flow.Launcher.exe')
        if h && WinGetMinMax(h) = -1 {
            WinRestore(h)
            WinHide(h)
        }
    }
    DetectHiddenWindows(false)
}

; Nouvelle fenêtre sur l'écran de la souris : komorebi range une fenêtre qui s'ouvre sur
; l'écran qu'il a en focus, qui n'est pas celui de la souris quand elle est sur un écran
; vide, la barre ou le bureau. On lui donne l'écran du curseur avant de lancer. Les
; fenêtres flottantes (Gestionnaire des tâches…) sont ramenées par devant.ahk.
PersoIci() {
    try PersoKomorebic('focus-monitor-at-cursor')
}

; Écran (HMONITOR) sous le curseur.
PersoEcranSouris() {
    CoordMode('Mouse', 'Screen')
    MouseGetPos(&x, &y)
    return DllCall('user32\MonitorFromPoint', 'Int64', (y << 32) | (x & 0xFFFFFFFF), 'UInt', 2, 'Ptr')
}

; « x,y » près du coin haut-gauche de la zone de travail de l'écran de la souris. Pour les
; terminaux qui acceptent une position au lancement (WezTerm --position, Windows Terminal
; --pos) : ils s'ouvrent directement sur cet écran. Les autres applis rouvrent à la place de
; leur dernière fenêtre, sans option équivalente.
PersoCoinSouris() {
    mi := Buffer(40, 0), NumPut('UInt', 40, mi, 0)
    DllCall('user32\GetMonitorInfoW', 'Ptr', PersoEcranSouris(), 'Ptr', mi)
    return (NumGet(mi, 20, 'Int') + 60) ',' (NumGet(mi, 24, 'Int') + 60)
}

; Super appuyé : si la souris est sur un autre écran que la fenêtre active, komorebi passe
; sur l'écran de la souris avant la touche suivante. Tous les raccourcis Super (tiling,
; bureaux, applis, y compris ceux de winarchy.ahk) agissent alors sur cet écran.
PersoSuivreSouris() {
    global KomorebicExe
    souris := PersoEcranSouris()
    actif := WinExist('A')
    if actif && DllCall('user32\MonitorFromWindow', 'Ptr', actif, 'UInt', 2, 'Ptr') = souris
        return
    try Run('"' KomorebicExe '" focus-monitor-at-cursor', , 'Hide')
}

; Super+E (Explorateur) et Super+N (Bloc-notes) : ces applis rouvrent là où était leur
; dernière fenêtre, et komorebi les range sur cet écran-là (en < 20 ms, bordure comprise).
; Pendant 20 s après le raccourci, un crochet Windows guette les nouvelles fenêtres (dès la
; première traitée, seulement celles du même programme) :
; - création (pas encore affichée) : la fenêtre est rendue invisible. komorebi ignore les
;   fenêtres transparentes (« layered ») : il ne la range donc pas à l'affichage ;
; - affichage : invisible, elle est posée sur l'écran de la souris (même position relative),
;   cachée, rendue opaque puis réaffichée : komorebi la range là, normalement.
; Testé : rien de visible sur le mauvais écran. Pas pour Outlook (il gère lui-même la
; transparence de sa fenêtre) ni les terminaux (option de position, voir PersoCoinSouris).
PersoLanceIci(lancer) {
    ecran := PersoEcranSouris()                    ; (le focus komorebi suit déjà : PersoSuivreSouris)
    PersoGuette(ecran, 20000)
    lancer()
}

PersoGuette(ecran, duree) {
    global PersoGuet
    static cb := CallbackCreate(PersoGuetEvt, 'F', 7)
    PersoGuetFin()
    avant := Map()
    dhw := DetectHiddenWindows(true)
    for h in WinGetList()
        avant[h] := true
    DetectHiddenWindows(dhw)
    ; EVENT_OBJECT_CREATE (0x8000) .. EVENT_OBJECT_SHOW (0x8002), hors contexte
    hook := DllCall('SetWinEventHook', 'UInt', 0x8000, 'UInt', 0x8002, 'Ptr', 0, 'Ptr', cb
        , 'UInt', 0, 'UInt', 0, 'UInt', 0, 'Ptr')
    PersoGuet := {ecran: ecran, avant: avant, hook: hook, caches: Map(), exe: ''}
    SetTimer(PersoGuetFin, -duree)
}

; Fin du guet : crochet retiré ; les fenêtres masquées à la création mais jamais affichées
; retrouvent leur opacité.
PersoGuetFin(*) {
    global PersoGuet
    SetTimer(PersoGuetFin, 0)
    if !IsSet(PersoGuet) || !PersoGuet
        return
    g := PersoGuet, PersoGuet := 0
    if g.hook
        DllCall('UnhookWinEvent', 'Ptr', g.hook)
    for h in g.caches
        try WinSetTransparent('Off', h)
}

; Fenêtre principale ou boîte de dialogue d'une appli : ni enfant, ni outil, ni déjà
; « layered » (on ne touche pas à son alpha), avec un cadre ; pas komorebi ni la barre.
PersoGuetCandidate(hwnd) {
    if DllCall('user32\GetAncestor', 'Ptr', hwnd, 'UInt', 2, 'Ptr') != hwnd
        return false
    st := WinGetStyle(hwnd), ex := WinGetExStyle(hwnd)
    if (st & 0x40000000) || (ex & 0x80) || (ex & 0x80000) || !(st & 0xC40000)
        return false
    return !PersoIgnoree(hwnd) && WinGetProcessName(hwnd) != 'komorebi.exe'
}

PersoGuetEvt(hHook, evt, hwnd, idObj, idChild, thread, temps) {
    global PersoGuet
    if (idObj != 0 || !IsSet(PersoGuet) || !PersoGuet)
        return
    g := PersoGuet
    dhw := DetectHiddenWindows(true)               ; à la création, la fenêtre est encore cachée
    try {
        if g.avant.Has(hwnd)
            return
        if (g.exe != '') && (evt != 0x8001) && (WinGetProcessName(hwnd) != g.exe)
            return                                 ; autre programme que celui lancé
        if (evt = 0x8000) {                        ; création
            if PersoGuetCandidate(hwnd) {
                ; noté AVANT de masquer : WinSetTransparent peut laisser passer l'évènement
                ; d'affichage pendant qu'on est encore ici (rappel réentrant).
                g.caches[hwnd] := true
                WinSetTransparent(0, hwnd)
            }
            return
        }
        if (evt = 0x8001) {                        ; destruction
            g.caches.Delete(hwnd)
            return
        }
        masquee := g.caches.Has(hwnd)              ; affichage
        if !masquee && !PersoGuetCandidate(hwnd)
            return
    } catch {
        return
    } finally {
        DetectHiddenWindows(dhw)
    }
    ; traitée une seule fois (PersoGuetPose la réaffiche : nouvel évènement d'affichage)
    g.avant[hwnd] := true, g.caches.Delete(hwnd)
    if (g.exe = '')
        try g.exe := WinGetProcessName(hwnd)
    bon := DllCall('user32\MonitorFromWindow', 'Ptr', hwnd, 'UInt', 2, 'Ptr') = g.ecran
    ; (traitements lancés par minuteur : hors du rappel du crochet)
    if bon {
        if masquee                                 ; bon écran : réaffichée pour que komorebi la range
            SetTimer(PersoGuetPose.Bind(hwnd, g.ecran, true), -1)
        return                                     ; non masquée : rien à faire (navigateur…)
    }
    if !masquee
        try WinSetTransparent(0, hwnd)
    ; mauvais écran : si komorebi l'a déjà rangée (le masquage a traîné), c'est lui qui la
    ; déplace ; sinon elle est posée à la main (PersoGuetPose).
    SetTimer(PersoGuetDeplace.Bind(hwnd, g.ecran), -1)
}

; Zone de travail d'un écran (HMONITOR).
PersoZone(hmon) {
    mi := Buffer(40, 0), NumPut('UInt', 40, mi, 0)
    DllCall('user32\GetMonitorInfoW', 'Ptr', hmon, 'Ptr', mi)
    return {l: NumGet(mi, 20, 'Int'), t: NumGet(mi, 24, 'Int'), r: NumGet(mi, 28, 'Int'), b: NumGet(mi, 32, 'Int')}
}

; Fenêtre masquée que komorebi n'a pas rangée (il ignore les fenêtres transparentes) :
; posée sur l'écran voulu (même position relative), cachée, rendue opaque puis réaffichée.
; Ce nouvel affichage, opaque et déjà sur le bon écran, komorebi le traite normalement
; (rangée en tuile ou laissée flottante selon ses règles).
PersoGuetPose(hwnd, ecran, bon) {
    SetWinDelay(-1)
    try {
        if !bon {
            zs := PersoZone(DllCall('user32\MonitorFromWindow', 'Ptr', hwnd, 'UInt', 2, 'Ptr')), zd := PersoZone(ecran)
            WinGetPos(&x, &y, &w, &h, hwnd)
            w := Min(w, zd.r - zd.l), h := Min(h, zd.b - zd.t)
            x := Max(zd.l, Min(zd.l + x - zs.l, zd.r - w)), y := Max(zd.t, Min(zd.t + y - zs.t, zd.b - h))
            WinMove(x, y, w, h, hwnd)
        }
        DllCall('user32\ShowWindow', 'Ptr', hwnd, 'Int', 0)    ; SW_HIDE
        WinSetTransparent('Off', hwnd)
        DllCall('user32\ShowWindow', 'Ptr', hwnd, 'Int', 5)    ; SW_SHOW
    }
    try WinSetTransparent('Off', hwnd)
    try WinActivate(hwnd)
}

; Fenêtre masquée sur le mauvais écran. Rangée par komorebi (masquage arrivé trop tard) :
; komorebi la déplace (move-to-monitor) ; sinon : PersoGuetPose.
PersoGuetDeplace(hwnd, ecran) {
    global KomorebicExe
    SetWinDelay(-1)
    idx := PersoIdxKomorebi(ecran)
    try {
        tmp := A_Temp '\winarchy-perso-guet.json'
        RunWait(A_ComSpec ' /c ""' KomorebicExe '" state > "' tmp '""', , 'Hide')
        etat := FileRead(tmp)
        if (idx >= 0) && (InStr(etat, '"hwnd": ' hwnd ',') || InStr(etat, '"hwnd":' hwnd ',')) {
            WinActivate(hwnd)
            Sleep(40)                              ; komorebi enregistre le focus
            PersoKomorebic('move-to-monitor ' idx)
            fin := A_TickCount + 500
            while (DllCall('user32\MonitorFromWindow', 'Ptr', hwnd, 'UInt', 2, 'Ptr') != ecran && A_TickCount < fin)
                Sleep(15)
            Sleep(60)                              ; fin de l'animation de komorebi
            WinSetTransparent('Off', hwnd)
            return
        }
    }
    PersoGuetPose(hwnd, ecran, false)              ; komorebi ne la gère pas : à la main
}

; Index komorebi d'un écran (HMONITOR), gardé en cache : relire l'état complet de komorebi
; prend plusieurs centaines de ms. Le cache est vidé quand la configuration des écrans change.
PersoIdxKomorebi(hmon) {
    static cache := Map()
    static ecoute := OnMessage(0x7E, Vider)       ; WM_DISPLAYCHANGE
    Vider(*) {
        cache.Clear()
    }
    nom := PersoNomEcran(hmon)                     ; « \\.\DISPLAY2 » ; komorebi dit « DISPLAY2 »
    if !cache.Has(nom) {
        cache.Clear()
        try {
            els := PersoEtat().monitors.elements
            Loop els.length {
                i := A_Index - 1
                cache['\\.\' els.%i%.name] := i
            }
        }
    }
    return cache.Has(nom) ? cache[nom] : -1
}

; Envoie la fenêtre sur l'écran hmon s'il n'y est pas (move-to-monitor : la fenêtre et
; le focus suivent).
PersoEnvoieSurEcran(hwnd, ecran) {
    if !WinExist(hwnd) || (DllCall('user32\MonitorFromWindow', 'Ptr', hwnd, 'UInt', 2, 'Ptr') = ecran)
        return
    idx := PersoIdxKomorebi(ecran)
    if (idx < 0)
        return
    try WinActivate(hwnd)
    PersoKomorebic('move-to-monitor ' idx)
}

; La barre des tâches est cachée par devant.ahk : on la réaffiche, puis Démarrer. Elle reste
; visible tant que Démarrer ou la barre ont le focus (devant.ahk).
PersoDemarrer() {
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    ; Repère dans %TEMP% : devant.ahk ne recache pas la barre pendant l'ouverture, et le
    ; gardien ne remet pas le focus au survol ; devant.ahk l'efface quand Démarrer se ferme.
    reprise := A_Temp '\winarchy-perso-komorebi-pause'
    if !FileExist(reprise) {
        try FileAppend('', reprise)
    } else {
        try FileSetTime(, reprise, 'M')
    }
    ; Focus au survol coupé aussi : la fenêtre sous la souris reprendrait le focus et
    ; refermerait Démarrer. devant.ahk le remet avec komorebi.
    DllCall('SystemParametersInfo', 'UInt', 0x1001, 'UInt', 0, 'Ptr', 0, 'UInt', 0)   ; SET ACTIVEWINDOWTRACKING
    barres := []
    for classe in ['Shell_TrayWnd', 'Shell_SecondaryTrayWnd']
        for h in WinGetList('ahk_class ' classe)
            barres.Push(h), WinShow(h)
    ; Masquage automatique GARDÉ : le couper réserve la place de la barre, la zone de travail
    ; change et komorebi redimensionne toutes les fenêtres (deux fois, à l'aller et au
    ; retour), ce qui volait aussi le focus à Démarrer. En masquage auto, Windows sort la
    ; barre par-dessus les fenêtres à l'ouverture de Démarrer.
    PersoMasquageAuto(true)
    Send('^{Esc}')
    ; devant.ahk recache la barre tous les 250 ms tant que Démarrer n'a pas le focus : s'il
    ; passe juste avant l'ouverture, on la réaffiche.
    Loop 20 {
        Sleep(50)
        for h in barres
            if !DllCall('IsWindowVisible', 'Ptr', h)
                try WinShow(h)
    }
    DetectHiddenWindows(dhw)
}
; ABM_SETSTATE : ABS_AUTOHIDE (1) ou ABS_ALWAYSONTOP (2) pour toutes les barres des tâches.
PersoMasquageAuto(actif) {
    x64 := A_PtrSize = 8
    abd := Buffer(x64 ? 48 : 36, 0)
    NumPut('UInt', abd.Size, abd, 0)
    NumPut('Ptr', WinExist('ahk_class Shell_TrayWnd'), abd, x64 ? 8 : 4)
    NumPut('Ptr', actif ? 1 : 2, abd, x64 ? 40 : 32)
    DllCall('Shell32\SHAppBarMessage', 'UInt', 10, 'Ptr', abd)
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

; Barres, bureau, YASB et Flow : jamais déplacés ni réduits.
PersoIgnoree(h) {
    return WinGetClass('ahk_id ' h) ~= '^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$'
        || WinGetProcessName('ahk_id ' h) ~= 'i)^(yasb|Flow\.Launcher)\.exe$'
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
; Super+Shift+S ramène toutes les fenêtres réduites, quelle que soit la façon.
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

; Capture via Screenpresso (même lanceur que le bouton de la barre). On attend que Win et Maj
; soient relâchées : sinon Impr. écran partirait en Win+Impr. écran (capture Windows).
PersoScreenpresso() {
    KeyWait('LWin'), KeyWait('RWin'), KeyWait('Shift')
    Run('"' A_AhkPath '" "' EnvGet('USERPROFILE') '\.winarchy-perso\screenpresso-capture.ahk"')
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

; Ramène TOUTES les fenêtres réduites (Super+S, bouton réduire, barre des tâches…).
; La dernière réduite par Super+S reprend le focus, sinon la dernière ramenée.
PersoRameneTout() {
    liste := PersoCachees()
    PersoNettoie(liste)
    dernier := liste.Length ? liste[liste.Length] : 0
    DetectHiddenWindows(false)
    ramenee := 0
    for h in WinGetList() {
        try {
            if WinGetMinMax('ahk_id ' h) != -1 || PersoIgnoree(h) || WinGetTitle('ahk_id ' h) = ''
                continue
            if WinGetExStyle('ahk_id ' h) & 0x80          ; WS_EX_TOOLWINDOW : pas une vraie fenêtre
                continue
            WinRestore('ahk_id ' h)
            ramenee := h
        }
    }
    liste.Length := 0
    if (dernier || ramenee)
        try WinActivate('ahk_id ' (dernier ? dernier : ramenee))
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
    Run('wt.exe --pos ' PersoCoinSouris() ' -d "' h '\Work" __SHELL__ -NoExit -NoLogo -ExecutionPolicy Bypass -File "' h '\.winarchy-perso\claude.ps1" ' profil)
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

; Super+Shift+Backspace : instance pro (l'instance perso est ignorée).
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
    ; Appli « Deezer Music » du Microsoft Store, sinon l'ancienne version de bureau, sinon le site.
    store := 'Deezer.62021768415AF_q7m17pa7q8kj0'
    exe := EnvGet('LOCALAPPDATA') '\Programs\deezer-desktop\Deezer.exe'
    if DirExist(EnvGet('LOCALAPPDATA') '\Packages\' store)
        Run('explorer.exe shell:AppsFolder\' store '!Deezer.Music')
    else if FileExist(exe)
        Run('"' exe '"')
    else
        Run('https://www.deezer.com/')
}

; --- Icônes de la zone de notification dans YASB --------------------------------
; Quand YASB (re)démarre (thème, mise à jour, plantage), les applis déjà lancées ne lui
; renvoient pas toujours leur icône (Ditto, Discord, OpenVPN, iCloud...). À chaque
; nouveau processus yasb.exe, on rediffuse « TaskbarCreated » : chaque appli recrée
; alors son icône, comme après un redémarrage de l'Explorateur.
; Screenpresso 2.2.9 (version couverte par la licence) propose sans cesse la 2.4.x, sans
; bouton « ignorer » et malgré CheckForUpdate=false : on masque la fenêtre dès qu'elle apparaît (la fermer quitte Screenpresso).
SetTimer(PersoMasqueMajScreenpresso, 2000)
PersoMasqueMajScreenpresso() {
    if WinExist('Nouvelle version de Screenpresso ahk_exe Screenpresso.exe')
        WinHide()
}
; Rappels Outlook (« N rappel(s) », toujours au premier plan) : Outlook la rouvre collée
; en haut de l'écran, par-dessus la barre YASB. À chaque nouvelle fenêtre on la centre dans
; la zone de travail de son écran, puis on la redescend si elle remonte sous la barre.
SetTimer(PersoPlaceRappels, 500)
PersoPlaceRappels() {
    static vues := Map()
    for h in WinGetList('rappel(s) ahk_class #32770 ahk_exe OUTLOOK.EXE') {
        try {
            WinGetPos(&x, &y, &w, &hh, h)
            hmon := DllCall('user32\MonitorFromWindow', 'Ptr', h, 'UInt', 2, 'Ptr')
            mi := Buffer(40, 0), NumPut('UInt', 40, mi, 0)
            DllCall('user32\GetMonitorInfoW', 'Ptr', hmon, 'Ptr', mi)
            l := NumGet(mi, 20, 'Int'), t := NumGet(mi, 24, 'Int'), r := NumGet(mi, 28, 'Int'), b := NumGet(mi, 32, 'Int')
            if !vues.Has(h)
                WinMove(l + (r - l - w) // 2, t + (b - t - hh) // 2, , , h)
            else if (y < t && !GetKeyState('LButton', 'P'))
                WinMove(, t, , , h)
            vues[h] := A_TickCount
        }
    }
    for h, tick in vues.Clone()
        if !WinExist(h)
            vues.Delete(h)
}
SetTimer(PersoSurveilleYasb, 3000)
PersoSurveilleYasb() {
    static dernier := 0
    pid := ProcessExist('yasb.exe')
    if (pid && pid != dernier)
        SetTimer(PersoRediffuseTray, -8000)       ; laisse YASB monter son systray
    dernier := pid
}
PersoRediffuseTray() {
    ; Fenêtre par fenêtre, sauf YASB : sur « TaskbarCreated », YASB croit l'Explorateur
    ; redémarré et réenregistre ses AppBars, ce qui fait perdre la réservation du haut
    ; de l'écran (komorebi tuilait alors sous la barre).
    msg := DllCall('RegisterWindowMessage', 'Str', 'TaskbarCreated', 'UInt')
    yasb := ProcessExist('yasb.exe')
    dhw := DetectHiddenWindows(true)
    for h in WinGetList() {
        pid := 0
        try pid := WinGetPID(h)
        if (pid && pid = yasb)
            continue
        DllCall('SendNotifyMessage', 'Ptr', h, 'UInt', msg, 'Ptr', 0, 'Ptr', 0)
    }
    DetectHiddenWindows(dhw)
}

; --- Super+glisser vers un autre écran ------------------------------------------
; Le WindowDrag de Winarchy ne sait qu'échanger avec la tuile visée (un seul « move »
; gauche/droite) et remet la fenêtre en place si on la lâche sur un écran vide : on ne
; pouvait pas changer d'écran à la souris. Après son glisser, si le curseur est sur un
; autre écran que la fenêtre, on l'y envoie (move-to-monitor : la fenêtre et le focus
; suivent).
Hotkey('#LButton', PersoGlisserFenetre)
PersoGlisserFenetre(*) {
    CoordMode('Mouse', 'Screen')
    MouseGetPos(, , &sous)
    hwnd := DllCall('user32\GetAncestor', 'Ptr', sous, 'UInt', 2, 'Ptr')
    WindowDrag(true)
    if !hwnd || !WinExist(hwnd)
        return
    MouseGetPos(&x, &y)
    ecran := DllCall('user32\MonitorFromPoint', 'Int64', (y << 32) | (x & 0xFFFFFFFF), 'UInt', 2, 'Ptr')
    Sleep(150)                                   ; laisse komorebi finir un éventuel « move »
    PersoEnvoieSurEcran(hwnd, ecran)
}
PersoNomEcran(hmon) {
    mi := Buffer(104, 0)                         ; MONITORINFOEXW
    NumPut('UInt', 104, mi, 0)
    DllCall('user32\GetMonitorInfoW', 'Ptr', hmon, 'Ptr', mi)
    return StrGet(mi.Ptr + 40, 32, 'UTF-16')
}

; --- Focus qui suit la souris : gardien ----------------------------------------
; Un redémarrage de komorebi (ou autre) peut couper le réglage Windows « activer une
; fenêtre en la survolant ». Toutes les 2 s, on vérifie et on le remet si besoin.
SetTimer(PersoSurveilleSurvol, 2000)
PersoSurveilleSurvol() {
    if FileExist(A_Temp '\winarchy-perso-komorebi-pause')     ; Super+Espace en cours (devant.ahk le remet)
        return
    actif := 0
    DllCall('SystemParametersInfo', 'UInt', 0x1000, 'UInt', 0, 'Int*', &actif, 'UInt', 0)  ; GET ACTIVEWINDOWTRACKING
    if actif
        return
    DllCall('SystemParametersInfo', 'UInt', 0x1001, 'UInt', 0, 'Ptr', 1, 'UInt', 3)    ; SET ACTIVEWINDOWTRACKING
    DllCall('SystemParametersInfo', 'UInt', 0x100D, 'UInt', 0, 'Ptr', 1, 'UInt', 3)    ; premier plan au survol
    DllCall('SystemParametersInfo', 'UInt', 0x2003, 'UInt', 0, 'Ptr', 150, 'UInt', 3)  ; après 150 ms
}

; --- Contrôle à distance : garder les raccourcis Super --------------------------
; NinjaRemote (ncplayer.exe) pose son propre crochet clavier quand il prend le focus :
; installé après celui d'AHK, il passe en premier et avale les touches (Super+Shift+2
; n'arrivait jamais). Dès qu'une de ces fenêtres devient active, on réinstalle le
; crochet d'AHK pour repasser devant (Windows appelle le dernier installé en premier).
SetTimer(PersoCrochetDevant, 200)
PersoCrochetDevant() {
    static dernier := 0
    try hwnd := WinActive('ahk_exe ncplayer.exe')
    catch
        hwnd := 0
    ; Ninja repose son crochet plus tard (clic dans la session, reconnexion) : tant qu'il est
    ; au premier plan, on repasse devant toutes les secondes (et tout de suite au focus).
    static compte := 0
    if hwnd {
        compte := (hwnd != dernier) ? 0 : compte + 1
        if (hwnd != dernier || Mod(compte, 5) = 0)
            InstallKeybdHook(true, true)
    }
    dernier := hwnd
}

; Ninja avale les touches ordinaires (journal : Super et Shift arrivent, les autres
; jamais, pas même en Raw Input). Parade : on suit Super en Raw Input ; dès qu'il est
; tenu sur Ninja, on lui retire le focus au profit d'une fenêtre invisible d'AHK, et la
; touche suivante arrive aux raccourcis. Juste avant qu'un raccourci perso s'exécute
; (#HotIf PersoAvantRaccourci, évalué avant l'action), Ninja reprend le premier plan :
; les raccourcis qui visent la fenêtre active (caler, vers l'écran, réduire…) agissent
; sur elle. Super toujours tenu : on revole le focus pour la touche suivante. Super
; relâché : Ninja reprend le focus si rien d'autre ne l'a pris (Super seul : Flow).
; Touches ordinaires (lettres, flèches…) : Ninja avale l'appui même sans le focus ; seul
; le relâchement arrive, et PersoRejoue rejoue alors la touche pour que le raccourci parte.
PersoRawInit()
PersoRawInit() {
    global PersoLeurre := Gui('-Caption +ToolWindow +AlwaysOnTop')
    global PersoNinja := 0, PersoWinTenu := false, PersoAutreTouche := false, PersoSuperDepuis := 0, PersoRaccourciFait := false, PersoDernierRacc := 0
    PersoLeurre.BackColor := '000000'
    PersoLeurre.Show('x0 y0 w1 h1 NoActivate Hide')
    rid := Buffer(8 + A_PtrSize, 0)                 ; RAWINPUTDEVICE
    NumPut('UShort', 1, 'UShort', 6, 'UInt', 0x100, 'Ptr', PersoLeurre.Hwnd, rid)   ; clavier, INPUTSINK
    DllCall('RegisterRawInputDevices', 'Ptr', rid, 'UInt', 1, 'UInt', rid.Size)
    OnMessage(0x00FF, PersoRawClavier)              ; WM_INPUT
}
PersoRawClavier(wParam, lParam, *) {
    global PersoNinja, PersoWinTenu, PersoAutreTouche, PersoSuperDepuis, PersoRaccourciFait
    static vus := Map()
    hdr := 8 + 2 * A_PtrSize                        ; RAWINPUTHEADER
    taille := 0
    DllCall('GetRawInputData', 'Ptr', lParam, 'UInt', 0x10000003, 'Ptr', 0, 'UInt*', &taille, 'UInt', hdr)
    if !taille
        return
    buf := Buffer(taille, 0)
    if (DllCall('GetRawInputData', 'Ptr', lParam, 'UInt', 0x10000003, 'Ptr', buf, 'UInt*', &taille, 'UInt', hdr) <= 0)
        return
    if (NumGet(buf, 0, 'UInt') != 1)                ; RIM_TYPEKEYBOARD
        return
    vk := NumGet(buf, hdr + 6, 'UShort')
    if !(vk = 0x5B || vk = 0x5C) {
        haut := NumGet(buf, hdr + 2, 'UShort') & 1
        ; Relâchement de Super manqué : on se recale sur l'état réel.
        if (PersoWinTenu && !GetKeyState('LWin', 'P') && !GetKeyState('RWin', 'P'))
            PersoWinTenu := false
        switch vk {
            case 0x12, 0xA4, 0xA5, 0x11, 0xA2, 0xA3, 0x10, 0xA0, 0xA1, 0xE8, 0xFF:
                return                              ; modificateurs (passent) et touches techniques
        }
        if !haut {
            vus[vk] := true
            if PersoWinTenu
                PersoAutreTouche := true            ; Super n'est plus « seul »
            return
        }
        ; Ninja avale l'APPUI des touches ordinaires (lettres, flèches…) même sans le focus ;
        ; seul le relâchement arrive. Relâchement sans appui vu, Super tenu sur Ninja : on
        ; rejoue la touche (Ninja laisse passer les touches simulées) pour que le raccourci
        ; normal parte.
        if (PersoNinja && PersoWinTenu && !vus.Has(vk)) {
            PersoAutreTouche := true
            SetTimer(PersoRejoue.Bind(vk), -60)
        }
        if vus.Has(vk)
            vus.Delete(vk)
        return
    }
    PersoWinTenu := !(NumGet(buf, hdr + 2, 'UShort') & 1)    ; RI_KEY_BREAK
    if (PersoWinTenu && !PersoNinja) {
        PersoAutreTouche := false, PersoSuperDepuis := A_TickCount, PersoRaccourciFait := false
        try PersoNinja := WinActive('ahk_exe ncplayer.exe')
        if PersoNinja
            PersoVole()
    } else if (!PersoWinTenu && PersoNinja) {
        SetTimer(PersoRendNinja, -200)              ; laisse le raccourci (ou Démarrer) agir
    }
}
PersoVole() {
    global PersoLeurre
    PersoLeurre.Show('x0 y0 w1 h1')
    if !DllCall('SetForegroundWindow', 'Ptr', PersoLeurre.Hwnd) || !WinActive('ahk_id ' PersoLeurre.Hwnd)
        try WinActivate(PersoLeurre.Hwnd)
}
; Évalué par AHK avant chaque raccourci perso : rend le premier plan à Ninja.
PersoAvantRaccourci() {
    global PersoLeurre, PersoNinja, PersoDernierRacc
    if !(A_ThisHotkey ~= 'i)LWin')
        PersoDernierRacc := A_TickCount             ; un raccourci est passé : pas de doublon
    if (PersoNinja && !(A_ThisHotkey ~= 'i)LWin') && WinActive('ahk_id ' PersoLeurre.Hwnd)) {
        global PersoRaccourciFait := true, PersoDernierRacc := A_TickCount
        DllCall('SetForegroundWindow', 'Ptr', PersoNinja)
        PersoLeurre.Hide()
        SetTimer(PersoRevole, -300)
    }
    return true
}
PersoRejoue(vk) {
    global PersoNinja, PersoDernierRacc, PersoRaccourciFait
    nom := GetKeyName(Format('vk{:02X}', vk))
    if (nom = '')
        return
    ; Un raccourci est déjà parti pour cette touche (l'appui était passé jusqu'à AHK) : rien.
    if (A_TickCount - PersoDernierRacc < 500)
        return
    if (A_TimeSincePriorHotkey != '' && A_TimeSincePriorHotkey < 500
        && SubStr(A_PriorHotkey, -StrLen(nom)) = nom)
        return
    if !PersoNinja || !WinExist('ahk_id ' PersoNinja)
        return
    PersoRaccourciFait := true
    SendLevel(1)                                    ; pour déclencher nos propres raccourcis
    Send('{Blind}{' nom '}')
    SendLevel(0)
}
PersoRevole() {
    global PersoNinja, PersoWinTenu
    if (PersoWinTenu && PersoNinja && WinActive('ahk_id ' PersoNinja))
        PersoVole()                                 ; Super toujours tenu : prêt pour la touche suivante
}
PersoRendNinja() {
    global PersoLeurre, PersoNinja, PersoWinTenu
    if (PersoWinTenu || !PersoNinja)
        return
    h := PersoNinja
    encore := WinActive('ahk_id ' PersoLeurre.Hwnd)
    PersoNinja := 0
    PersoLeurre.Hide()
    ; Super seul (court, sans autre touche) : le « LWin up » de winarchy ne part pas pendant
    ; la parade, on ouvre Flow nous-mêmes comme PersoSuper.
    global PersoAutreTouche, PersoSuperDepuis, PersoRaccourciFait
    if (encore && !PersoAutreTouche && !PersoRaccourciFait && A_TickCount - PersoSuperDepuis < 700) {
        PersoIci(), PersoFlowDereduit(), ToggleFlow()
        return
    }
    if encore                                       ; personne n'a pris le focus : retour à Ninja
        try WinActivate(h)
}
#HotIf PersoAvantRaccourci()
; Super+W pendant la parade : fermer Ninja explicitement (WinExist('A') peut encore
; désigner la fenêtre invisible au moment où le raccourci s'exécute).
#w:: {
    global PersoNinja
    if (PersoNinja && WinExist('ahk_id ' PersoNinja))
        PostMessage(0x0010, 0, 0, , 'ahk_id ' PersoNinja)   ; WM_CLOSE
    else
        CloseWindow()
}
#HotIf
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
    Set-RaccourcisWindows $true
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

# Barre YASB : Winarchy installe sa barre native par défaut (et pas YASB) ; les réglages et
# widgets perso de ce script visent YASB. « winarchy bar use yasb » l'installe (version
# épinglée) au besoin, bascule l'autostart et arrête la barre native.
function Set-BarreYasb([string]$Root) {
    $f = Join-Path $Root 'state\bar'
    $barre = if (Test-Path $f) { ([IO.File]::ReadAllText($f)).Trim() } else { '' }
    if ($barre -eq 'yasb') { Info 'Barre YASB déjà active'; return }
    if (Invoke-WinarchyCli $Root @('bar', 'use', 'yasb')) { Ok 'Barre YASB activée (à la place de la barre native)' }
    else { Warn '« winarchy bar use yasb » a échoué : barre native conservée.' }
}

# Polices de la barre YASB : styles.css utilise « JetBrainsMono NFP » et « JetBrainsMonoNL NFP »
# (variantes Propo) ; Winarchy n'installe que « JetBrainsMono NF ». Installées pour
# l'utilisateur (sans admin) depuis la release officielle Nerd Fonts, puis YASB relancé.
function Install-PolicesBarre([string]$Root) {
    $dest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $cle = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    $voulues = 'JetBrainsMonoNerdFontPropo-Regular.ttf', 'JetBrainsMonoNLNerdFontPropo-Regular.ttf'
    if (-not ($voulues | Where-Object { -not (Test-Path (Join-Path $dest $_)) })) { Info 'Polices de la barre (JetBrainsMono NFP / NL NFP) déjà installées'; return }
    $tmp = Join-Path $env:TEMP "winarchy-polices-$PID"
    New-Item -ItemType Directory -Force $tmp, $dest | Out-Null
    try {
        $zip = Join-Path $tmp 'JetBrainsMono.zip'
        Invoke-WebRequest 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive $zip (Join-Path $tmp 'x') -Force
        if (-not ('PersoWinarchy.Polices' -as [type])) {
            Add-Type -Namespace PersoWinarchy -Name Polices -MemberDefinition '[DllImport("gdi32.dll", CharSet = CharSet.Unicode)] public static extern int AddFontResource(string f);'
        }
        $n = 0
        foreach ($f in Get-ChildItem (Join-Path $tmp 'x') -Filter '*NerdFontPropo-*.ttf') {
            $cible = Join-Path $dest $f.Name
            if (-not (Test-Path $cible)) { Copy-Item $f.FullName $cible }
            New-ItemProperty -Path $cle -Name "$($f.BaseName) (TrueType)" -Value $cible -PropertyType String -Force | Out-Null
            [void][PersoWinarchy.Polices]::AddFontResource($cible)
            $n++
        }
        Ok "Polices de la barre installées : $n fichiers (JetBrainsMono NFP / NL NFP)"
        if (Invoke-WinarchyCli $Root @('reload')) { Ok 'Barre relancée avec les nouvelles polices' }
    } catch { Warn "Polices de la barre non installées : $($_.Exception.Message)" }
    finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

# Surveillance de la zone réservée par YASB (perso\Watch-YasbZone.ps1) : YASB perd parfois
# son AppBar sur un écran après un changement de géométrie ; la tâche relance YASB et retile.
function Set-SurveillanceBarre([string]$Root, [bool]$active) {
    $nom = 'yasb-zone'; $dossier = '\Winarchy\'
    if (-not $active) {
        if (Get-ScheduledTask -TaskName $nom -TaskPath $dossier -ErrorAction SilentlyContinue) {
            Stop-ScheduledTask -TaskName $nom -TaskPath $dossier -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $nom -TaskPath $dossier -Confirm:$false
            Ok 'Surveillance de la zone de la barre YASB retirée'
        }
        return
    }
    $script = Join-Path $Root 'perso\Watch-YasbZone.ps1'
    if (-not (Test-Path $script)) { Warn "Surveillance de la barre non installée : $script introuvable"; return }
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $trigger.Delay = 'PT30S'
    $reglages = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $nom -TaskPath $dossier -Action $action -Trigger $trigger -Settings $reglages -Principal $principal -Force | Out-Null
    Start-ScheduledTask -TaskName $nom -TaskPath $dossier
    Ok 'Surveillance de la zone de la barre YASB active (tâche \Winarchy\yasb-zone)'
}

# Surveillance des écrans (perso\Watch-Ecrans.ps1) : au retrait d'un écran, ramène et
# dé-réduit les fenêtres ; au branchement, répartit le surplus sur les nouveaux écrans.
function Set-SurveillanceEcrans([string]$Root, [bool]$active) {
    $nom = 'ecrans'; $dossier = '\Winarchy\'
    if (-not $active) {
        if (Get-ScheduledTask -TaskName $nom -TaskPath $dossier -ErrorAction SilentlyContinue) {
            Stop-ScheduledTask -TaskName $nom -TaskPath $dossier -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $nom -TaskPath $dossier -Confirm:$false
            Ok 'Surveillance des écrans retirée'
        }
        return
    }
    $script = Join-Path $Root 'perso\Watch-Ecrans.ps1'
    if (-not (Test-Path $script)) { Warn "Surveillance des écrans non installée : $script introuvable"; return }
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $trigger.Delay = 'PT30S'
    $reglages = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $nom -TaskPath $dossier -Action $action -Trigger $trigger -Settings $reglages -Principal $principal -Force | Out-Null
    Start-ScheduledTask -TaskName $nom -TaskPath $dossier
    Ok 'Surveillance des écrans active (tâche \Winarchy\ecrans)'
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
    # Le haut de l'écran est réservé par l'AppBar de YASB (Edit-ModeleYasb), qui décale aussi
    # les icônes du bureau : komorebi n'ajoute aucun décalage (sinon double marge). Valeurs
    # d'origine de Winarchy (top 0, bottom 2 pour la barre des tâches masquée).
    $t = [regex]::Replace($t, '("global_work_area_offset":\s*\{\s*"left":\s*\d+,\s*"top":\s*)\d+(,\s*"right":\s*\d+,\s*"bottom":\s*)\d+', '${1}0${2}2')
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
# Windows Terminal cherche les polices par leur nom DirectWrite : « JetBrainsMono NF » (nom
# GDI, celui de la barre YASB) y est introuvable et il affichait un avertissement à chaque
# ouverture. Winarchy recopie la police de la barre dans le terminal à chaque thème : on
# traduit le nom à cet endroit.
function Edit-ThemeEngine([string]$t) {
    if ($t.Contains('perso: nom DirectWrite')) { return $t }
    $ligne = "`$settings['profiles']['defaults']['font']['face'] = `$FontFamily"
    if (-not $t.Contains($ligne)) { throw 'ancre police Windows Terminal absente' }
    $t.Replace($ligne, "`$settings['profiles']['defaults']['font']['face'] = (`$FontFamily -replace '^JetBrainsMono NF$', 'JetBrainsMono Nerd Font')   # perso: nom DirectWrite (Windows Terminal)")
}

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
# Le traitement tourne toujours dans PowerShell 7 : -AsHashtable n'existe pas dans Windows
# PowerShell 5.1 (lancement documenté « powershell -File ») et son ConvertTo-Json ne formate
# pas pareil (le fichier changerait à chaque lancement).
$script:CodeAsc = @'
param([string]$Entree, [string]$Sortie, [string]$SansIgnore)
$sans = $SansIgnore -split '\|'
$asc = [IO.File]::ReadAllText($Entree) | ConvertFrom-Json -AsHashtable
if (-not $asc.Contains('Zoom')) { throw 'format ASC inattendu' }
foreach ($app in @($asc.Keys)) {
    if ($app.StartsWith('$')) { continue }
    $cats = @('floating') + @(if ($app -in $sans) { 'ignore' })
    foreach ($c in $cats) { if ($asc[$app].Contains($c)) { $asc[$app].Remove($c) } }
}
# Explorateur : on garde ses autres ignore (progression de copie…), pas celui du Panneau de configuration.
$ex = $asc['Windows Explorer']
if ($ex -and $ex.Contains('ignore')) { $ex['ignore'] = @($ex['ignore'] | Where-Object { $_.id -ne 'Control Panel' }) }
[IO.File]::WriteAllText($Sortie, (($asc | ConvertTo-Json -Depth 20) + "`n"), [Text.UTF8Encoding]::new($false))
'@
function Edit-AscPerso([string]$t) {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { throw 'PowerShell 7 (pwsh) introuvable' }
    $dir = Join-Path $env:TEMP "winarchy-asc-$PID"
    New-Item -ItemType Directory -Force $dir | Out-Null
    try {
        $ps1 = Join-Path $dir 'asc.ps1'; $in = Join-Path $dir 'in.json'; $out = Join-Path $dir 'out.json'
        [IO.File]::WriteAllText($ps1, $script:CodeAsc, (New-Object Text.UTF8Encoding $true))
        [IO.File]::WriteAllText($in, $t, (New-Object Text.UTF8Encoding $false))
        $sortiePwsh = & $pwsh -NoProfile -ExecutionPolicy Bypass -File $ps1 -Entree $in -Sortie $out -SansIgnore ($script:AscSansIgnore -join '|') 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { throw "pwsh : $($sortiePwsh.Trim())" }
        [IO.File]::ReadAllText($out)
    } finally { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

# Barre YASB : groupes toujours dépliés, et pas de compteur Codex.
function Edit-ModeleYasb([string]$t) {
    $t = [regex]::Replace($t, '(collapse_options:\s*\r?\n\s*enabled:\s*)true', '${1}false')
    # Systray replié par défaut : déplié, il ne tenait pas dans la barre complète du BenQ
    # (1920 px) et les icônes s'écrasaient. Clic sur ▸ pour les voir, Alt+clic pour épingler.
    $t = $t.Replace('show_unpinned: true', 'show_unpinned: false')
    # Icônes non épinglées dans un popup sous ▸ : dépliées dans la barre, elles poussaient
    # et écrasaient les autres widgets.
    if ($t -notmatch 'show_in_popup:') {
        if ($t -notmatch '(?m)^      show_unpinned: false\r?$') { throw 'ancre systray popup absente' }
        $nlP = if ($t -match "`r`n") { "`r`n" } else { "`n" }
        $bloc = (@'
      show_in_popup: true
      icons_per_row: 6
      popup:
        alignment: "right"
        direction: "down"
        offset_top: 6
        offset_left: 0

'@) -replace '\r?\n', $nlP
        $t = [regex]::Replace($t, '(?m)^(      show_unpinned: false\r?\n)', '${1}' + $bloc.Replace('$', '$$'), 1)
    }
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
    # (ancre : "plus" si la bulle « en plus », plus bas, a déjà remplacé system + disques)
    if ($t -notmatch '"(system|plus)", ' -or $t -notmatch '(?m)^  memory:') { throw 'ancre disques absente' }
    $t = $t.Replace('"system", ', '"system", "disques", ')
    # Barre complète trop chargée pour 1920 px : sans titre de fenêtre active ni météo
    # (disques réseau non plus, voir juste au-dessus ; le widget reste défini).
    $t = $t.Replace('"taskbar", "active_window", ', '"taskbar", ').Replace('right: ["weather", ', 'right: [')
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
    # Perf CPU / RAM : widgets natifs YASB (mesure en interne via psutil, sans lancer de process).
    # L'ancienne version (CustomWidget + perf.ps1 toutes les 4 s, ~2 s de WMI par passage, × 2 écrans)
    # faisait tourner le CPU et les ventilateurs en continu. Pas de bulle au survol avec les natifs.
    # GPU retiré : le widget natif ne gère que NVIDIA (nvidia-smi), ici Radeon intégrée.
    # Clic = Gestionnaire des tâches, droit/milieu = libellé alternatif. Remplacés sur place.
    $nlY = if ($t -match "`r`n") { "`r`n" } else { "`n" }
    $icCpu = [char]::ConvertFromUtf32(0xF4BC); $icRam = [char]::ConvertFromUtf32(0xF035B)
    $natifs = @{
        cpu = @'
  cpu:
    # Perf (perso, setup-winarchy.ps1) : widget natif, clic = Gestionnaire des tâches.
    type: "yasb.cpu.CpuWidget"
    options:
      label: "<span>ICCPU</span> {info[percent][total]}%"
      label_alt: "<span>ICCPU</span> {info[freq][current]} MHz"
      update_interval: 3000
      callbacks:
        on_left: "exec taskmgr.exe"
        on_middle: "toggle_label"
        on_right: "toggle_label"

'@
        memory = @'
  memory:
    # Perf (perso, setup-winarchy.ps1) : widget natif, clic = Gestionnaire des tâches.
    type: "yasb.memory.MemoryWidget"
    options:
      label: "<span>ICRAM</span> {virtual_mem_percent}%"
      label_alt: "<span>ICRAM</span> {virtual_mem_free} libres"
      update_interval: 5000
      callbacks:
        on_left: "exec taskmgr.exe"
        on_middle: "toggle_label"
        on_right: "toggle_label"

'@
    }
    foreach ($cle in 'cpu', 'memory') {
        $rx = "(?m)^  ${cle}:\r?\n(?:(?:    [^\r\n]*)?\r?\n)*"
        if ($t -notmatch $rx) { throw "ancre perf $cle absente" }
        $b = $natifs[$cle].Replace('ICCPU', $icCpu).Replace('ICRAM', $icRam) -replace '\r?\n', $nlY
        $t = [regex]::Replace($t, $rx, $b.Replace('$', '$$'), 1)
    }
    $t = [regex]::Replace($t, '(?m)^  gpu:\r?\n(?:(?:    [^\r\n]*)?\r?\n)*', '')
    $t = $t.Replace('"gpu", ', '')
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
    # Barre toujours visible : au-dessus des fenêtres, y compris celles que devant.ahk met
    # « toujours au-dessus » (devant.ahk la remonte ensuite par-dessus elles).
    $t = [regex]::Replace($t, '(window_flags:\s*\r?\n\s*always_on_top:\s*)false', '${1}true')
    # Un seul mécanisme réserve le haut de l'écran : komorebi (global_work_area_offset, voir
    # Edit-ModeleKomorebi). L'AppBar de YASB se réenregistrait par moments et s'ajoutait au
    # décalage de komorebi (fenêtres à ~90 px du haut au lieu de 48).
    # Revu : c'est l'AppBar de YASB qui réserve le haut (Windows décale aussi les icônes du
    # bureau, que le décalage komorebi seul laissait sous la barre) ; komorebi n'ajoute rien.
    $t = $t.Replace('windows_app_bar: false', 'windows_app_bar: true')
    # Chemins absolus au lieu de %KOMOREBI_CONFIG_HOME% : la tâche YASB ne définit pas cette
    # variable, et le Planificateur ne voit les variables utilisateur qu'après un redémarrage.
    # Sans elle, logo Windows et menu ☰ (show-menu.flag) et indicateurs ne marchaient pas.
    $etat = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'state'
    $t = $t.Replace('%KOMOREBI_CONFIG_HOME%\\..\\..\\state', $etat.Replace('\', '\\')).Replace('%KOMOREBI_CONFIG_HOME%\..\..\state', $etat)
    # Logo Windows (widget home) -> lanceur d'applis Flow ; le ☰ de droite garde le menu Winarchy.
    $t = [regex]::Replace($t, '(?s)(\n  home:\r?\n.*?on_left: )"[^"\r\n]*"', '${1}"exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\lanceur.ahk"', 1)
    # Batterie : pourcentage toujours affiché (clic = icône seule).
    $t = [regex]::Replace($t, '(BatteryWidget"\s*\r?\n\s*options:\s*\r?\n\s*label: )"<span>\{icon\}</span>"(\s*\r?\n\s*label_alt: )"<span>\{icon\}</span> \{percent\}%"', '${1}"<span>{icon}</span> {percent}%"${2}"<span>{icon}</span>"')
    # Zone de notification : repliée par défaut (clic sur ▸ pour voir les icônes non épinglées).
    # Écran du laptop (1536 px de large à 125 %) : trop étroit pour tous les widgets de
    # droite, la barre était coupée. Barre compacte à part ; un écran visé par une barre
    # est retiré de la barre « * ». YASB nomme l'écran interne « \\.\DISPLAY1 » (pas de modèle).
    if ($t -notmatch '(?m)^  laptop-bar:') {
        if ($t -notmatch '(?m)^widgets:') { throw 'ancre laptop-bar absente' }
        $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
        $bloc = (@'
  # Écran du laptop (perso, setup-winarchy.ps1) : barre compacte, la barre complète y était coupée.
  laptop-bar:
    enabled: true
    screens: ["\\\\.\\DISPLAY1"]
    class_name: "yasb-bar"
    alignment:
      position: "{{computed.bar_position}}"
      align: "center"
    blur_effect:
      enabled: false
    window_flags:
      always_on_top: true
      windows_app_bar: true
    dimensions:
      width: "100%"
      height: {{bar.height}}
    padding:
      top: 0
      left: 0
      bottom: 0
      right: 0
    widgets:
      left: ["home", "komorebi_workspaces", "taskbar"]
      center: ["clock"]
      right: ["ai", "plus", "connections", "volume", "battery", "notifications", "systray", "winarchy_menu"]
    layouts:
      left:
        alignment: "left"
        stretch: true
      center:
        alignment: "center"
        stretch: false
      right:
        alignment: "right"
        stretch: true

'@) -replace '\r?\n', $nl
        $t = [regex]::Replace($t, '(?m)^(?=widgets:)', $bloc.Replace('$', '$$'), 1)
    }
    # Widgets de droite de la barre laptop (tenus à jour même si le bloc existe déjà) :
    # tokens Claude, perf (CPU/GPU/RAM), disques, puis l'essentiel.
    $t = [regex]::Replace($t, '(?s)(  laptop-bar:.*?\r?\n      right: )\[[^\]]*\]', '${1}["ai", "plus", "connections", "volume", "battery", "notifications", "systray", "winarchy_menu"]', 1)
    # Rendez-vous Outlook à droite de l'horloge, sur les deux barres. Bloc reconstruit à chaque passage.
    if ($t -notmatch '(?m)^  clock:') { throw 'ancre rdv absente' }
    $t = [regex]::Replace($t, '(?ms)^  # Rendez-vous Outlook \(perso.*?(?=^  clock:)', '')
    # (L'ancien widget rdv_alerte est retiré : hide_empty de YASB 2.0.7 le masquait pour de bon.)
    $t = $t.Replace('"rdv", "rdv_alerte"', '"rdv"').Replace('center: ["clock"]', 'center: ["clock", "rdv"]')
    $bloc = (@'
  # Rendez-vous Outlook (perso, setup-winarchy.ps1) : prochain RDV d'aujourd'hui/demain.
  # Lu par COM dans Outlook classique (démarré sans fenêtre s'il est fermé), voir rdv.ps1.
  # Survol = détail du prochain RDV, clic = calendrier Outlook, droit = bulle des RDV de la
  # semaine en cours (rdv-bulle.ahk), milieu = relecture forcée d'Outlook (exec_custom relance le widget, rdv.ps1
  # force la lecture quand la souris est au centre de la barre). 5 min avant un RDV, rdv.ps1 ouvre la
  # bulle d'alerte sur tous les écrans.
  rdv:
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "rdv-widget"
      label: "{data[barre]}"
      label_alt: "{data[barre]}"
      label_placeholder: ""
      tooltip: true
      tooltip_label: "{data[detail]}"
      exec_options:
        run_cmd: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\.winarchy-perso\rdv.ps1'
        run_interval: 60000
        return_format: "json"
        use_shell: true
        encoding: "utf-8"
      callbacks:
        on_left: "exec cmd.exe /c start outlook.exe /select outlook:calendar"
        on_middle: "exec_custom"
        on_right: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\rdv-bulle.ahk"

'@) -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
    $t = [regex]::Replace($t, '(?m)^(?=  clock:)', $bloc.Replace('$', '$$'), 1)
    # Bureaux komorebi : seulement ceux qui ont des fenêtres (+ celui affiché, même vide).
    if ($t -notmatch 'hide_empty_workspaces: (true|false)') { throw 'ancre bureaux vides absente' }
    $t = $t.Replace('hide_empty_workspaces: false', 'hide_empty_workspaces: true')
    # Barre moins chargée (2026-11-25) : CPU, RAM, disques et outils peu utilisés (OCR, QR,
    # pipette, plan d'alimentation) passent dans la bulle « en plus » (bouton ▾, plus-bulle.ahk),
    # sur les deux barres. YASB ne sait pas faire déborder ce qui ne tient pas, et ses groupes
    # repliables cassent l'affichage des widgets cachés au démarrage (CPU/RAM « { ⁝ : »).
    $t = [regex]::Replace($t, '(?m)^[ \t]*exclude_widgets: [^\n]*\n', '')   # restes du repli
    $t = $t.Replace('widgets: ["cpu", "memory", "disques"]', 'widgets: ["cpu", "memory"]')
    $t = $t.Replace('"system", "disques", ', '"plus", ').Replace('"system", ', '"plus", ')
    $t = $t.Replace('"tool_ocr", "tool_qr", "tool_color", ', '').Replace(', "power_plan"]', ']')
    if ($t -notmatch '"plus", ') { throw 'ancre bouton en plus absente' }
    $t = [regex]::Replace($t, '(?ms)^  # Bulle « en plus » \(perso.*?(?=^  clock:)', '')
    $bloc = (@'
  # Bulle « en plus » (perso, setup-winarchy.ps1) : CPU, RAM, disques et outils peu utilisés,
  # dans une bulle AutoHotkey (plus-bulle.ahk) ouverte par ▾, comme le systray.
  plus:
    type: "yasb.custom.CustomWidget"
    options:
      label: "▾"
      class_name: "plus-widget"
      tooltip: true
      tooltip_label: "CPU, RAM, disques et outils"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\plus-bulle.ahk"
        on_middle: "do_nothing"
        on_right: "do_nothing"

'@) -replace '\r?\n', $(if ($t -match "`r`n") { "`r`n" } else { "`n" })
    $t = [regex]::Replace($t, '(?m)^(?=  clock:)', $bloc.Replace('$', '$$'), 1)
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
/* Icône wifi : texte brut (un <span> casse {data[...]}) ; police proportionnelle et largeur
   minimale comme les autres icônes, sinon le glyphe est rogné. */
.wifi-widget .label { font-family: 'JetBrainsMono NFP'; font-size: 15px; min-width: 20px; padding: 0 5px; }
.gpu-widget .label.alt,
.cpu-widget .label.alt,
.memory-widget .label.alt { color: {{ui.system}}; }
.extras-grouper .widget,
.ai-grouper .widget,
.system-grouper .widget,
.connections-grouper .widget { padding: 0 6px; }
/* Icônes du systray à taille fixe : sinon Qt les compresse et elles se chevauchent. */
.systray .button { min-width: 20px; max-width: 20px; min-height: 20px; }
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
    # Rendez-vous Outlook (l'alerte est une bulle AutoHotkey, voir rdv-bulle.ahk). Bloc reconstruit.
    $t = [regex]::Replace($t, '(?ms)\r?\n\r?\n/\* Rendez-vous Outlook \(perso, setup-winarchy\.ps1\).*?(?=\r?\n\r?\n|\s*\z)', '')
    $t = ($t.TrimEnd() + "`n`n" + @'
/* Rendez-vous Outlook (perso, setup-winarchy.ps1) */
.rdv-widget .label { color: {{colors.foreground}}; padding: 0 6px; }
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
    $patchs = @{ 'templates\komorebi.json.tpl' = ${function:Edit-ModeleKomorebi}; 'templates\yasb-config.yaml.tpl' = ${function:Edit-ModeleYasb}; 'templates\yasb-styles.css.tpl' = ${function:Edit-ModeleYasbStyles}; 'games.toml' = ${function:Edit-JeuxLanceurs}; 'vendor\asc\applications.json' = ${function:Edit-AscPerso}; 'module\Winarchy\Private\Util.ps1' = ${function:Edit-UtilKomorebi}; 'module\Winarchy\Private\ThemeEngine.ps1' = ${function:Edit-ThemeEngine} }
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
            if ($rel -notmatch 'yasb|Util\.ps1|ThemeEngine\.ps1') { $script:RedemarrerKomorebi = $true }
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
        # Lanceur DCS World (classe « ED Launcher Window ») : popup sans WS_CAPTION, ignoré sans ça.
        @('manage', 'title', 'DCS Launcher', 'Equals'),
        # Fenêtre principale ESET (classe « ESET Main Frame ») : popup sans WS_CAPTION, topmost, ignorée sans ça.
        @('manage', 'class', 'ESET Main Frame'),
        # Anciens panneaux qui gèrent mal le passage 125 % -> 100 % : tuilés, ils débordaient
        # sur l'écran voisin. Flottants (devant.ahk les met devant, sur l'écran de la souris).
        @('floating', 'title', 'fonctionnalit', 'Contains'),
        @('floating', 'exe', 'Taskmgr.exe'),
        @('ignore', 'class', 'MSCTFIME UI'),
        @('ignore', 'class', 'IME'),
        # Accès à distance et clients Citrix / VMware : fenêtres de session tuilées.
        @('manage', 'exe', 'rustdesk.exe'),
        @('manage', 'exe', 'SelfService.exe'),
        @('manage', 'exe', 'CDViewer.exe'),
        @('manage', 'exe', 'wfica32.exe'),
        @('manage', 'exe', 'workspaces.exe'),
        # Screenpresso : vit dans la zone de notification ; sa fenêtre « Screenpresso » (calque de
        # capture) ne doit pas être tuilée.
        @('tray_and_multi_window', 'exe', 'Screenpresso.exe'),
        @('ignore', 'title', 'Screenpresso', 'Equals'),
        # Installateurs : toujours flottants, sinon leurs fenêtres passent derrière les tuiles.
        @('floating', 'exe', 'msiexec.exe'),
        @('floating', 'exe', 'CWAInstaller.exe'),
        @('floating', 'exe', 'WspUsbDriverInstaller.exe'),
        # Amazon WorkSpaces : seulement la fenêtre de session (titre = nom du WorkSpace). Avec
        # exe =, komorebi gérait aussi « ToolbarWindow », un calque transparent plein écran posé
        # sur la session : écran coupé en deux puis clics bloqués (manage passe avant ignore).
        @('manage', 'title', 'Swissmarine'),
        @('ignore', 'title', 'ToolbarWindow', 'Equals'),
        # Rappels Outlook (#32770 « N rappel(s) ») : flottante, komorebi la garde au-dessus.
        @('floating', 'title', 'rappel(s)', 'EndsWith'),
        # Teams (ms-teams.exe) : jamais pris en charge tout seul. Par le titre de la fenêtre
        # principale (« … | Microsoft Teams ») pour ne pas tuiler les toasts et fenêtres annexes.
        @('manage', 'title', '| Microsoft Teams', 'EndsWith')
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
    Set-SurveillanceBarre $Komorebi $false
    Set-SurveillanceEcrans $Komorebi $false
    Install-ColleClicMilieu $false
    exit 0
}

if ($Komorebi) {
    if (-not $SansMiseAJour) { Update-WinarchyKomorebi $Komorebi }
} else {
    Install-WinarchyKomorebi
    $Komorebi = Find-WinarchyKomorebi
}
Write-Host "==> Winarchy : $Komorebi"
Set-BarreYasb $Komorebi
Install-PolicesBarre $Komorebi
Set-SurveillanceBarre $Komorebi $true
Set-SurveillanceEcrans $Komorebi $true
Set-ReglagesWinarchy $Komorebi
Install-Raccourcis $Komorebi
Install-ColleClicMilieu $true
Save-ReglagesFork $Komorebi

Write-Host ''
Write-Host '==> Terminé. À vérifier :' -ForegroundColor Cyan
Write-Host '   - Super seul ouvre le lanceur d''applis, Super+Espace le menu Démarrer'
Write-Host '   - Super+Q ouvre le menu Winarchy (Super+Alt+Espace aussi)'
Write-Host '   - Super+K liste tes raccourcis sous « Perso : … »'
Write-Host '   - Connexion, une fois par compte (réglages copiés sans jetons) :'
Write-Host '       Super+Backspace puis /login (Foxis), Super+Shift+Backspace puis /login (perso)'
Write-Host '       $env:GH_CONFIG_DIR="$HOME\.config\gh-foxis"; gh auth login   (idem avec gh-perso)'
