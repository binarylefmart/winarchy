; Surcharges perso de Winarchy (non suivi par git, survit aux mises a jour).

ToggleClaudeDesktop() {
    if WinActive('ahk_exe Claude.exe')
        WinClose('ahk_exe Claude.exe')            ; se replie dans la zone de notification
    else if WinExist('ahk_exe Claude.exe')
        WinActivate('ahk_exe Claude.exe')
    else
        Run('explorer.exe shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude')
}

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
#^!Left::PersoKomorebic('cycle-move-to-monitor previous')   ; Fenêtre vers l'écran voisin
#^!Up::PersoKomorebic('cycle-move-to-monitor previous')
#^!Right::PersoKomorebic('cycle-move-to-monitor next')
#^!Down::PersoKomorebic('cycle-move-to-monitor next')
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

; Super+F : une seule fenêtre en tuile -> bascule centrée / pleine largeur (bureau actif) ;
; plusieurs -> monocle. Si le monocle est déjà actif, Super+F le quitte.
PersoPlein() {
    global KomorebicExe
    static coupe := Map()   ; bureaux dont Super+F a coupé le centrage pour le monocle
    tmp := A_Temp '\winarchy-perso-state.json'
    try {
        RunWait(A_ComSpec ' /c ""' KomorebicExe '" state > "' tmp '""', , 'Hide')
        doc := ComObject('htmlfile')
        doc.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
        state := doc.parentWindow.JSON.parse(FileRead(tmp))
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
    global KomorebicExe
    actif := WinExist('A')
    tmp := A_Temp '\winarchy-perso-state.json'
    try {
        RunWait(A_ComSpec ' /c ""' KomorebicExe '" state > "' tmp '""', , 'Hide')
        doc := ComObject('htmlfile')
        doc.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
        state := doc.parentWindow.JSON.parse(FileRead(tmp))
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
    global KomorebicExe
    static pos := Map()   ; hwnd -> [col, ligne, x, y, l, h] ; col/ligne : 0 début, 1 plein, 2 fin
    h := WinExist('A')
    if !h
        return
    if WinGetClass('ahk_id ' h) ~= '^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$'
        || WinGetProcessName('ahk_id ' h) = 'yasb.exe'
        return
    tmp := A_Temp '\winarchy-perso-state.json'
    try {
        RunWait(A_ComSpec ' /c ""' KomorebicExe '" state > "' tmp '""', , 'Hide')
        doc := ComObject('htmlfile')
        doc.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
        state := doc.parentWindow.JSON.parse(FileRead(tmp))
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
    PersoKomorebic('resize-delta 50')
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
    if !h
        return
    if WinGetClass('ahk_id ' h) ~= '^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$'
        || WinGetProcessName('ahk_id ' h) = 'yasb.exe'
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
    Run('wt.exe -d "' h '\Work" pwsh -NoExit -NoLogo -ExecutionPolicy Bypass -File "' h '\.winarchy-perso\claude.ps1" ' profil)
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

; Super+Ctrl+Alt+Shift+Entrée. Ouvre / affiche / replie, comme Super+Ctrl+Shift+Backspace pour la pro. Fenêtre repliée
; dans la zone de notification : relancer la commande la fait réapparaître.
PersoClaudePerso() {
    hwnd := PersoClaudeFenetre(true)
    if (hwnd && WinActive(hwnd))
        WinClose(hwnd)
    else if hwnd
        WinActivate(hwnd)
    else
        Run('"' EnvGet('LOCALAPPDATA') '\Microsoft\WindowsApps\claude-desktop.exe" --user-data-dir="' EnvGet('APPDATA') '\Claude-perso"')
}

; Outlook classique (OUTLOOK.EXE), pas le nouvel Outlook (olk.exe).
PersoOutlook() {
    if WinExist('ahk_exe OUTLOOK.EXE ahk_class rctrl_renwnd32')
        return WinActivate()
    try Run('outlook.exe')                        ; App Paths -> Office16\OUTLOOK.EXE
    catch
        Run('https://outlook.office.com/mail/')
}

PersoClaudeBascule() {                            ; instance pro (l'instance perso est ignorée)
    hwnd := PersoClaudeFenetre(false)
    if (hwnd && WinActive(hwnd))
        WinClose(hwnd)                            ; se replie dans la zone de notification
    else if hwnd
        WinActivate(hwnd)
    else
        Run('explorer.exe shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude')
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
; <<< raccourcis-perso <<<
