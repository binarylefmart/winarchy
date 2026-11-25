# managed by winarchy — generado desde templates/yasb-config.yaml.tpl + themes/{{computed.theme_dir}}/theme.toml.
# NO editar a mano: se regenera con `winarchy theme set`.
# Los colores viven en styles.css (mismo theme engine); acá va la geometría de la barra.
# NOTA: verificar nombres de widgets contra la wiki de YASB v2.x en el smoke test (tarea 9.1).
# watch_* en false a propósito: el hot-reload de YASB re-suscribe el widget de komorebi
# al named pipe sin cerrar la suscripción previa; con >1 reactor vivo las barras pelean
# el foco (mandan FocusWorkspaceNumber(0)) y te saltan al workspace 1 al minimizar/abrir
# un juego. Winarchy recarga YASB con un reinicio limpio (kill+start) desde `winarchy
# theme set` / `winarchy reload`, así que no hace falta el watcher. (Investigación 2026-06-28)
watch_stylesheet: false
watch_config: false
# Identidad unificada: YASB no muestra tray propio (el tray del stack lo hostea AHK)
# ni corre su update checker (los updates los maneja `winarchy update`). El widget
# `systray` de la barra (más abajo) NO se ve afectado: sigue mostrando iconos de terceros.
show_systray: false
update_check: false

komorebi:
  start_command: "komorebic start"
  stop_command: "komorebic stop"
  reload_command: "komorebic reload-configuration"

bars:
  status-bar:
    enabled: true
    screens: ["*"]
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
    # padding = offset del bar window respecto a los bordes de pantalla; 0 = pegada
    padding:
      top: 0
      left: 0
      bottom: 0
      right: 0
    widgets:
      left: ["home", "komorebi_workspaces", "komorebi_active_layout", "taskbar", "extras"]
      center: ["clock", "rdv"]
      right: ["game_mode", "stay_awake", "media", "ai", "plus", "connections", "volume", "battery", "winarchy_update", "notifications", "systray", "winarchy_menu"]
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

  # Écrans étroits (perso, setup-winarchy.ps1) : barre compacte ; écrans choisis par Watch-YasbZone.ps1.
  laptop-bar:
    enabled: true
    screens: ["aucun"]
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
      center: ["clock", "rdv"]
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
  # Écrans larges (perso, setup-winarchy.ps1) : tout dans la barre ; écrans choisis par Watch-YasbZone.ps1.
  wide-bar:
    enabled: true
    screens: ["aucun"]
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
      left: ["home", "komorebi_workspaces", "komorebi_active_layout", "taskbar", "extras_large"]
      center: ["clock", "rdv"]
      right: ["game_mode", "stay_awake", "media", "ai", "system", "disques", "disques_reseau", "connections", "volume", "battery", "winarchy_update", "notifications", "systray_large", "winarchy_menu"]
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
widgets:
  # Logo arriba-izquierda: abre el mismo menú principal de winarchy.ahk
  # (Apps/Themes/System/...) que SUPER+Alt+Space y el botón ☰ de la derecha.
  # Toca el flag show-menu.flag que AHK levanta con su watcher (YASB no puede
  # llamar funciones de AHK directo).
  home:
    type: "yasb.custom.CustomWidget"
    options:
      label: ""   # logo Windows (nerd font)
      class_name: "home-widget"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\lanceur.ahk"
        # sin esto, el right/middle-click por defecto hace toggle_label → label_alt
        # (no definido) y el logo desaparece hasta volver a togglear.
        on_middle: "do_nothing"
        on_right: "do_nothing"

  # Indicador de game-mode manual: muestra GAME si existe state\game-mode.flag.
  # (la suspensión automática por juego la maneja AHK; esto refleja el toggle manual)
  game_mode:
    type: "yasb.custom.CustomWidget"
    options:
      label: "{data}"
      label_alt: "{data}"
      class_name: "game-mode-widget"
      exec_options:
        hide_empty: true
        # cmd, NO powershell: esto corre en loop para siempre y cada powershell.exe
        # cuesta ~435 ms de arranque. `if exist` hace lo mismo por ~25 ms.
        # use_shell expande %KOMOREBI_CONFIG_HOME%.
        # Rutas sin comillas: YASB las escapa y el comando falla en silencio.
        run_cmd: 'cmd.exe /c if exist C:\winarchy\state\game-mode.flag echo GAME'
        run_interval: 3000
        return_format: "string"
        use_shell: true

  # Lee el flag que levanta ToggleStayAwake (AHK), que es donde vive el estado.
  stay_awake:
    type: "yasb.custom.CustomWidget"
    options:
      label: "{data}"
      label_alt: "{data}"
      class_name: "stay-awake-widget"
      exec_options:
        hide_empty: true
        run_cmd: 'cmd.exe /c if exist C:\winarchy\state\stay-awake.flag echo AWAKE'
        run_interval: 3000
        return_format: "string"
        use_shell: true

  # Lee el flag que escribe Write-WinarchyUpdateNotice cuando hay release nueva.
  winarchy_update:
    type: "yasb.custom.CustomWidget"
    options:
      label: "{data}"
      label_alt: "{data}"
      class_name: "winarchy-update-widget"
      exec_options:
        hide_empty: true
        run_cmd: 'cmd.exe /c if exist C:\winarchy\state\update-available.flag echo UPDATE'
        run_interval: 60000
        return_format: "string"
        use_shell: true
      callbacks:
        on_left: "exec winarchy update --self"
        on_middle: "do_nothing"
        on_right: "do_nothing"

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
  komorebi_workspaces:
    type: "komorebi.workspaces.WorkspaceWidget"
    options:
      label_offline: "komorebi offline"
      label_workspace_btn: "{name}"
      label_default_name: "{index}"
      hide_empty_workspaces: true

  komorebi_active_layout:
    type: "komorebi.active_layout.ActiveLayoutWidget"
    options:
      hide_if_offline: true
      label: "{icon}"
      # Sin esto YASB usa sus defaults, que son ASCII ("[\]", "[M]", "><>"): el unico
      # elemento no nerd-font de toda la barra. Se mapean los nueve layouts porque
      # SUPER+Shift+L cicla entre todos.
      layout_icons:
        bsp: "󰕰"
        columns: "󰕱"
        rows: "󰙀"
        grid: "󰝘"
        scrolling: "󰡍"
        vertical_stack: "󰓡"
        horizontal_stack: "󰓢"
        ultrawide_vertical_stack: "󰤼"
        right_main_vertical_stack: "󰤻"
        monocle: "󰊓"
        maximized: "󰊔"
        floating: "󰖯"
        paused: "󰏤"

  active_window:
    type: "yasb.active_window.ActiveWindowWidget"
    options:
      label: "{win[title]}"
      label_alt: "[class_name='{win[class_name]}' exe='{win[process][name]}']"
      label_no_window: ""
      max_length: 56
      max_length_ellipsis: "…"
      monitor_exclusive: true

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
  # Bulle « en plus » (perso, setup-winarchy.ps1) : CPU, RAM, disques et outils peu utilisés,
  # dans une bulle AutoHotkey (plus-bulle.ahk). Flèche comme le systray : ▸ fermée, ▾ ouverte
  # (plus-bulle.etat, écrit par la bulle). Surtout pas « encoding » : avec return_format string, YASB 2.0.7
  # appelle .decode() sur du texte, le thread plante et la flèche ne change jamais.
  plus:
    type: "yasb.custom.CustomWidget"
    options:
      label: "{data}"
      label_alt: "{data}"
      label_placeholder: "▸"
      class_name: "plus-widget"
      exec_options:
        run_cmd: 'type %USERPROFILE%\.winarchy-perso\plus-bulle.etat'
        run_interval: 500
        return_format: "string"
        use_shell: true
      tooltip: true
      tooltip_label: "CPU, RAM, disques et outils"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\plus-bulle.ahk"
        on_middle: "do_nothing"
        on_right: "do_nothing"
  clock:
    type: "yasb.clock.ClockWidget"
    options:
      label: "{%a %d %b · %H:%M}"
      label_alt: "{%A %d %B %Y · %H:%M:%S}"
      locale: "fr_FR"
      timezones: []
      callbacks:
        on_left: "toggle_calendar"
        on_middle: "next_timezone"
        on_right: "toggle_label"

  # Qué está sonando (Spotify, navegador, etc). Click: play/pausa.
  media:
    type: "yasb.media.MediaWidget"
    options:
      label: "<span></span> {title}"
      label_alt: "<span></span> {artist}{s}{title}"
      hide_empty: true
      show_thumbnail: false
      controls_hide: true
      max_field_size:
        label: 24
        label_alt: 44
      callbacks:
        on_left: "toggle_play_pause"
        on_middle: "open_media_source"
        on_right: "toggle_label"

  cpu:
    # Perf (perso, setup-winarchy.ps1) : widget natif, clic = Gestionnaire des tâches.
    type: "yasb.cpu.CpuWidget"
    options:
      label: "<span></span> {info[percent][total]}%"
      label_alt: "<span></span> {info[freq][current]} MHz"
      update_interval: 3000
      callbacks:
        on_left: "exec taskmgr.exe"
        on_middle: "toggle_label"
        on_right: "toggle_label"
  # Disques locaux (perso, setup-winarchy.ps1) : % utilisé, survol = détail de tous les disques,
  # clic = Ce PC, droit/milieu = espace libre. {data[...]} hors <span> (sinon pas substitué).
  disques:
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "disques-widget"
      label: "{data[local]}"
      label_alt: "{data[local_libre]}"
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
  # Disques réseau (perso, setup-winarchy.ps1) : % utilisé, survol = détail de tous les disques,
  # clic = Ce PC, droit/milieu = espace libre. {data[...]} hors <span> (sinon pas substitué).
  disques_reseau:
    type: "yasb.custom.CustomWidget"
    options:
      class_name: "disques-reseau-widget"
      label: "{data[reseau]}"
      label_alt: "{data[reseau_libre]}"
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
  memory:
    # Perf (perso, setup-winarchy.ps1) : widget natif, clic = Gestionnaire des tâches.
    type: "yasb.memory.MemoryWidget"
    options:
      label: "<span>󰍛</span> {virtual_mem_percent}%"
      label_alt: "<span>󰍛</span> {virtual_mem_free} libres"
      update_interval: 5000
      callbacks:
        on_left: "exec taskmgr.exe"
        on_middle: "toggle_label"
        on_right: "toggle_label"
  # Indicador de red propio (CustomWidget). El yasb.wifi.WifiWidget nativo deja
  # el placeholder {wifi_icon} literal mientras su WiFiWorker (winrt) no puede
  # leer el adaptador —red abajo en el arranque, o radio WiFi off— y no expone
  # un icono inicial (verificado en YASB 2.0.6, 2026-08-23: con ethernet_icon +
  # hide_if_ethernet:false el widget nativo igual pinta "{wifi_icon}" crudo sobre
  # Ethernet, asi que este workaround sigue haciendo falta).
  # config\yasb\net-icon.ps1 decide el glifo de forma sincrónica con fallback a
  # "desconectado", así la barra nunca muestra la plantilla cruda y se comporta
  # como el resto de los iconos. Lo mantiene actualizado scripts\Start-NetIcon.ps1
  # (watcher residente, ver ese script para el porqué). Tradeoff: sin selector de
  # redes en la barra; el click abre la config de red de Windows.
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
  # Click: Configuración de bluetooth de Windows.
  bluetooth:
    type: "yasb.bluetooth.BluetoothWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {device_name}"
      callbacks:
        on_left: "toggle_menu"
        on_middle: "exec cmd.exe /c start ms-settings:bluetooth"
        on_right: "toggle_label"

  # Click: mute mic. Click derecho: menú de micrófonos.
  microphone:
    type: "yasb.microphone.MicrophoneWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {level}%"
      callbacks:
        on_left: "toggle_mute"
        on_middle: "toggle_label"
        on_right: "toggle_mic_menu"

  volume:
    type: "yasb.volume.VolumeWidget"
    options:
      label: "<span>{icon}</span> {level}"
      label_alt: "<span>{icon}</span> {volume}"
      callbacks:
        on_left: "toggle_volume_menu"
        on_middle: "toggle_label"
        on_right: "toggle_mute"

  # Focus Assist de Windows. Click: on/off. Click derecho: cicla prioridad/alarmas.
  dnd:
    type: "yasb.dnd.DndWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {status}"
      callbacks:
        on_left: "toggle_status"
        on_middle: "toggle_label"
        on_right: "cycle_status"

  # Historique du presse-papiers (perso, setup-winarchy.ps1) -> Win+V.
  tool_clipboard:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Presse-papiers (Win+V)"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\presse-papiers.ahk"
        on_middle: "do_nothing"
        on_right: "do_nothing"
  # Corbeille (perso, setup-winarchy.ps1) : clic = ouvrir, milieu = nombre/taille, droit = vider.
  recycle_bin:
    type: "yasb.recycle_bin.RecycleBinWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {items_count} ({items_size})"
      class_name: "tool-widget"
      icons:
        bin_empty: ""
        bin_filled: ""
      tooltip: true
      show_confirmation: true
      callbacks:
        on_left: "open_bin"
        on_middle: "toggle_label"
        on_right: "empty_bin"
  tool_region:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Capture (Screenpresso)"
      callbacks:
        on_left: "exec cmd.exe /c %USERPROFILE%\\.winarchy-perso\\screenpresso-capture.ahk"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  tool_record:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Screen recording"
      callbacks:
        on_left: "exec winarchy screenshot record"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  tool_stop:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Stop recording"
      callbacks:
        on_left: "exec winarchy screenshot stop"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  tool_ocr:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Text from screen (OCR)"
      callbacks:
        on_left: "exec winarchy screenshot ocr"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  tool_qr:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Scan a QR on screen"
      callbacks:
        on_left: "exec winarchy screenshot qr"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  tool_color:
    type: "yasb.custom.CustomWidget"
    options:
      label: "<span></span>"
      class_name: "tool-widget"
      tooltip: true
      tooltip_label: "Colour picker"
      callbacks:
        on_left: "exec winarchy screenshot color"
        on_middle: "do_nothing"
        on_right: "do_nothing"

  extras:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "extras-grouper"
      widgets: ["tool_region", "tool_clipboard", "recycle_bin", "dnd", "brightness"]
      hide_empty: false
      collapse_options:
        enabled: false
        label_position: "left"
        collapsed_label: "▸"
        expanded_label: "◂"

  ai:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "ai-grouper"
      widgets: ["claude_usage"]
      hide_empty: false
      collapse_options:
        enabled: false
        label_position: "left"
        collapsed_label: "󰚩"
        expanded_label: "◂"

  system:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "system-grouper"
      widgets: ["cpu", "memory"]
      hide_empty: false
      collapse_options:
        enabled: false
        label_position: "left"
        collapsed_label: "▸"
        expanded_label: "◂"

  connections:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "connections-grouper"
      widgets: ["wifi", "bluetooth", "microphone"]
      hide_empty: false
      collapse_options:
        enabled: false
        label_position: "left"
        collapsed_label: "󰖩"
        expanded_label: "◂"

  # La ubicacion se elige en el popup y YASB la guarda en %LOCALAPPDATA%.
  weather:
    type: "yasb.open_meteo.OpenMeteoWidget"
    options:
      label: "<span>{icon}</span> {temp}"
      label_alt: "<span>{icon}</span> {temp} {location}"
      hide_decimal: true
      units: "metric"
      update_interval: 1800
      callbacks:
        on_left: "toggle_card"
        on_middle: "do_nothing"
        on_right: "toggle_label"

  # Brillo del monitor enfocado. En externos va por DDC/CI.
  brightness:
    type: "yasb.brightness.BrightnessWidget"
    options:
      label: "<span>{icon}</span>"
      label_alt: "<span>{icon}</span> {percent}%"
      scroll_step: 5
      callbacks:
        on_left: "toggle_brightness_menu"
        on_middle: "toggle_label"
        on_right: "toggle_label"

  power_plan:
    type: "yasb.power_plan.PowerPlanWidget"
    options:
      label: "<span>󰓅</span>"
      label_alt: "<span>󰓅</span> {active_plan}"
      callbacks:
        on_left: "toggle_menu"
        on_middle: "do_nothing"
        on_right: "toggle_label"

  # hide_unsupported deja el widget invisible en una maquina sin bateria,
  # asi el mismo config sirve para desktop y portatil.
  battery:
    type: "yasb.battery.BatteryWidget"
    options:
      label: "<span>{icon}</span> {percent}%"
      label_alt: "<span>{icon}</span>"
      hide_unsupported: true
      update_interval: 10000
      callbacks:
        on_left: "toggle_label"
        on_right: "toggle_label"

  # Uso de la suscripcion de Claude Code (ventanas de 5 horas y 7 dias).
  # cache_ttl alto a proposito: el endpoint esta rate-limiteado.
  claude_usage:
    type: "yasb.claude_usage.ClaudeUsageWidget"
    options:
      label: "<span>󰧑</span> {five_hour}%"
      label_alt: "<span>󰧑</span> {seven_day}%"
      update_interval: 300
      cache_ttl: 300
      token_history:
        enabled: true
        default_period: "today"
        show_graph: false
        show_models: true
      callbacks:
        on_left: "toggle_menu"
        on_middle: "refresh"
        on_right: "toggle_label"
      menu:
        blur: false
        round_corners: true
        alignment: "right"
        direction: "down"
        offset_top: 6

  codex_usage:
    type: "yasb.codex_usage.CodexUsageWidget"
    options:
      label: "<span>󰆍</span> {primary_used}%"
      label_alt: "<span>󰆍</span> {secondary_used}%"
      update_interval: 300
      cache_ttl: 300
      show_token_usage: true
      callbacks:
        on_left: "toggle_menu"
        on_middle: "refresh"
        on_right: "toggle_label"
      menu:
        blur: false
        round_corners: true
        alignment: "right"
        direction: "down"
        offset_top: 6
        show_overview: true
        show_models: true
        show_activity: true
        show_details: true

  # Click: centro de notificaciones de Windows. Click derecho: limpiar.
  notifications:
    type: "yasb.notifications.NotificationsWidget"
    options:
      label: "<span>{icon}</span> {count}"
      label_alt: "<span>{icon}</span> {count} unread"
      hide_empty: false
      callbacks:
        on_left: "toggle_notification"
        on_right: "clear_notifications"

  # Solo iconos pinneados a la vista; el resto detrás del botón.
  # Pinnear/despinnear: alt+click sobre el icono.
  # Barre large (perso, setup-winarchy.ps1) : outils peu utilisés dans la barre, systray déplié.
  extras_large:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "extras-grouper"
      widgets: ["tool_region", "tool_clipboard", "tool_ocr", "tool_qr", "tool_color", "recycle_bin", "dnd", "brightness", "power_plan"]
      hide_empty: false
      collapse_options:
        enabled: false
        label_position: "left"
        collapsed_label: "▸"
        expanded_label: "◂"
  systray_large:
    type: "yasb.systray.SystrayWidget"
    options:
      label_collapsed: "▸"
      label_expanded: "▾"
      pin_click_modifier: "alt"
      show_unpinned: true
      hide_icons: ["ShareX"]
  systray:
    type: "yasb.systray.SystrayWidget"
    options:
      # Triangulos unicode (no glifos nerd-font F053/F054): la fuente del bar
      # los dejaba como tofu --el "cuadrado invisible"--; estos caen al fallback
      # de Segoe UI y siempre renderizan. (colapsado = click para expandir).
      label_collapsed: "▸"
      label_expanded: "▾"
      pin_click_modifier: "alt"
      show_unpinned: false
      show_in_popup: true
      icons_per_row: 6
      popup:
        alignment: "right"
        direction: "down"
        offset_top: 6
        offset_left: 0
      # Tray propio de ShareX, oculto en la barra.
      hide_icons: ["ShareX"]

  # Esquina derecha, estilo Omarchy: abre el menu principal de winarchy.ahk
  # (Apps/Themes/System/...), el mismo que SUPER+Alt+Space y el right-click del
  # tray. YASB es un proceso separado y no puede llamar funciones de AHK
  # directo: el click toca un flag (mismo patron que game_mode) que AHK levanta
  # con su propio watcher.
  winarchy_menu:
    type: "yasb.custom.CustomWidget"
    options:
      label: "☰"
      class_name: "winarchy-menu-widget"
      callbacks:
        on_left: "exec cmd.exe /c copy /y nul C:\\winarchy\\state\\show-menu.flag"
        on_middle: "do_nothing"
        on_right: "do_nothing"
