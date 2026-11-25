; Surcharges perso de Winarchy (non suivi par git, survit aux mises a jour).

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
#e::PersoLanceIci(() => Run('explorer.exe'))     ; Explorateur, sur l'écran de la souris
#b::PersoIci(), Run(DefaultBrowser())   ; Navigateur
#Enter::Wezterm('start --position ' PersoCoinSouris())   ; Terminal
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
    PersoKomorebic('resize-delta 50')
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
    Run('wt.exe --pos ' PersoCoinSouris() ' -d "' h '\Work" pwsh -NoExit -NoLogo -ExecutionPolicy Bypass -File "' h '\.winarchy-perso\claude.ps1" ' profil)
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
; Après la parade (Super tenu sur Ninja, focus prêté à une fenêtre invisible), Ninja a
; transmis à la session distante l'appui de Super (et d'Alt/Ctrl/Shift) mais pas leur
; relâchement : côté serveur, Super restait enfoncé et on ne pouvait plus écrire. Quand
; Ninja revient au premier plan, touches relâchées, on lui envoie ces relâchements.
; (L'ancienne réinstallation du crochet d'AHK ici est retirée : faite pendant que Super
; était tenu, AHK croyait Super coincé et le copier-coller ne marchait plus.)
PersoNinjaAReset := 0
SetTimer(PersoCrochetDevant, 200)
PersoCrochetDevant() {
    global PersoNinjaAReset
    if !PersoNinjaAReset
        return
    try hwnd := WinActive('ahk_exe ncplayer.exe')
    catch
        hwnd := 0
    if (!hwnd || hwnd != PersoNinjaAReset || GetKeyState('LWin', 'P') || GetKeyState('RWin', 'P'))
        return
    PersoNinjaAReset := 0
    haut := '{LWin up}{RWin up}'
    for k in ['Alt', 'Ctrl', 'Shift']
        if !GetKeyState(k, 'P')
            haut .= '{' k ' up}'
    SendEvent(haut)
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
; le relâchement arrive, et PersoToucheAvalee fait l'action (flèches, Super+W).
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
            SetTimer(PersoToucheAvalee.Bind(vk, GetKeyState('Alt', 'P'), GetKeyState('Ctrl', 'P'), GetKeyState('Shift', 'P')), -250)
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
; Appui avalé par Ninja (seul le relâchement est arrivé) : action faite directement, sans
; rejouer la touche (Ninja avale aussi les touches rejouées tant que Super est tenu).
PersoToucheAvalee(vk, alt, ctrl, maj) {
    global PersoNinja, PersoLeurre, PersoDernierRacc, PersoRaccourciFait
    ; Un raccourci est déjà parti pour cette touche (l'appui était passé jusqu'à AHK) : rien.
    if (A_TickCount - PersoDernierRacc < 600)
        return
    nom := GetKeyName(Format('vk{:02X}', vk))
    if (nom != '' && A_TimeSincePriorHotkey != '' && A_TimeSincePriorHotkey < 600
        && SubStr(A_PriorHotkey, -StrLen(nom)) = nom)
        return
    if !PersoNinja || !WinExist('ahk_id ' PersoNinja)
        return
    dir := (vk >= 0x25 && vk <= 0x28) ? ['left', 'up', 'right', 'down'][vk - 0x24] : ''
    if (dir = '' && !(vk = 0x57 && !alt && !ctrl && !maj))   ; seulement flèches et Super+W
        return
    ; Copie locale : Super relâché entre-temps remet PersoNinja à 0 (PersoRendNinja).
    h := PersoNinja
    PersoRaccourciFait := true, PersoDernierRacc := A_TickCount
    DllCall('SetForegroundWindow', 'Ptr', h)
    PersoLeurre.Hide()
    Sleep(30)
    if (vk = 0x57) {
        try PostMessage(0x0010, 0, 0, , 'ahk_id ' h)     ; Super+W : fermer Ninja
        return
    }
    if ctrl
        PersoVersEcran(dir)
    else if alt
        PersoPlace(dir)
    else if maj
        PersoKomorebic('move ' dir)
    else
        PersoKomorebic('focus ' dir)
    SetTimer(PersoRevole, -300)
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
    global PersoNinjaAReset := h                    ; relâchements à renvoyer à Ninja (PersoCrochetDevant)
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
    h := PersoNinja
    if (h && WinExist('ahk_id ' h)) {
        try PostMessage(0x0010, 0, 0, , 'ahk_id ' h)   ; WM_CLOSE
    }
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
