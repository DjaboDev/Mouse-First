import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    property QtObject bar: null
    property string moduleName: ""
    property var settings: ({})

    readonly property bool vertical: bar ? bar.vertical : false
    readonly property int barSize: bar ? bar.barSize : 26

    implicitWidth: (root.shouldShowAppsInBar && root.barAppsList.length > 0)
        ? minAppsRow.implicitWidth
        : 0
    implicitHeight: root.barSize
    width: implicitWidth
    height: implicitHeight

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string binDir:
        homeDir + "/.config/omarchy/plugins/io.github.mousefirst.controls/bin"
    readonly property string cfgFile:
        homeDir + "/.config/omarchy/mouse-first.json"

    property string language:       "en"
    property bool   disableTiling:  true
    property bool   alwaysVisible:  true
    property bool   dragFullWidth:  true
    property bool   showDragHandle: false
    property bool   ignoreDock:     false
    property bool   disableSnapping: false
    property bool   minimizeToBar:  true

    readonly property string detectedSection: {
        try {
            if (root.parent && root.parent.parent && root.parent.parent.region) {
                var r = String(root.parent.parent.region).trim()
                if (r === "left" || r === "center" || r === "right") return r
            }
        } catch(e) {}
        return ""
    }

    property string barSection: (detectedSection !== "") ? detectedSection : "left"

    onDetectedSectionChanged: {
        if (detectedSection !== "") {
            barSection = detectedSection
        }
    }

    property bool   isDockPresent:  true
    readonly property bool shouldShowAppsInBar: root.minimizeToBar || !root.isDockPresent
    property var    barAppsList:    []

    property bool   enableMenuDrag:        true
    property bool   rememberMenuPerWindow: false
    property bool   rememberMenuGlobal:    false
    property bool   alwaysShowMenuDragZone: false
    property real   curMenuOffsetX:        0
    property real   curMenuOffsetY:        0
    property real   globalMenuOffsetX:     0
    property real   globalMenuOffsetY:     0
    property var    perWindowClassOffsets: ({})
    property var    sessionMenuOffsets:    ({})
    property string winClass:              ""
    property var    clampedWindows:        ({})

    property bool   isMenuDragging:        false
    property real   menuDragStartMouseX:   0
    property real   menuDragStartMouseY:   0
    property real   menuDragStartOffsetX:  0
    property real   menuDragStartOffsetY:  0
    property var    buttonOrder:    ["float", "minimize", "maximize", "close"]
    property var    buttonVisible:  ({ float: false, minimize: true, maximize: true, close: true })
    property string colorMode:      "theme"
    property string customBg:       "#0e0e14"
    property string customFg:       "#a9b1d6"
    property string customAccent:   "#7aa2f7"
    property string customRed:      "#f7768e"
    property var    minimizedWindows:   []
    property bool   showMinimizedPanel: false

    // Cores do tema
    property string themeBg:     "#1a1b26"
    property string themeFg:     "#a9b1d6"
    property string themeAccent: "#7aa2f7"
    property string themeRed:    "#f7768e"
    property string themeMuted:  "#414868"
    property string themeMode:   "dark"

    readonly property string effBg:
        colorMode === "theme" ? Qt.darker(themeBg, 1.4) : customBg
    readonly property string effFg:
        colorMode === "theme" ? themeFg : customFg
    readonly property string effAccent:
        colorMode === "theme" ? themeAccent : customAccent
    readonly property string effRed:
        colorMode === "theme" ? themeRed : customRed

    // Internationalization helper
    function t(key) {
        var isPt = root.language === "pt"
        var d = {
            minimize: isPt ? "Minimizar" : "Minimize",
            maximize: isPt ? "Maximizar" : "Maximize",
            restore:  isPt ? "Restaurar" : "Restore",
            close:    isPt ? "Fechar" : "Close",
            float:    isPt ? "Flutuar" : "Float",
            tile:     isPt ? "Tilar" : "Tile",
            floatTile: isPt ? "Float / Tile" : "Float / Tile",
            maxRestore: isPt ? "Maximizar / Restaurar" : "Maximize / Restore",
            untitled: isPt ? "Sem título" : "Untitled",
            settingsTitle: "Mouse First",
            settingsHint: isPt ? "Clique com botão direito na barra para abrir/fechar" : "Right-click the bar to toggle settings",
            systemBehavior: isPt ? "COMPORTAMENTO DO SISTEMA" : "SYSTEM BEHAVIOR",
            disableTiling: isPt ? "Desativar tiling (todas as janelas flutuantes)" : "Disable window tiling",
            disableTilingSub: isPt ? "Força todas as janelas a abrirem flutuando como no Windows" : "Open all windows as floating by default",
            minimizedSectionTitle: isPt ? "JANELAS E APLICATIVOS NA BARRA" : "SYSTEM BAR APPS & WINDOWS",
            minimizeToBar: isPt ? "Minimizar janelas para a barra do sistema" : "Minimize windows to system bar",
            minimizeToBarSub: isPt ? "Exibe ícones de aplicativos na barra do sistema. Se desativado, usa a dock se disponível." : "Show application icons on the system bar. When disabled, uses the dock if available.",
            minimizedAppsLocation: isPt ? "Posição dos aplicativos na barra" : "System bar apps position",
            minimizedAppsLocationSub: isPt ? "Escolha onde os ícones dos apps aparecem na barra do sistema" : "Choose where application icons appear on the system bar",
            locLeft: isPt ? "Esquerda" : "Left",
            locCenter: isPt ? "Centro" : "Center",
            locRight: isPt ? "Direita" : "Right",
            visibility: isPt ? "VISIBILIDADE" : "VISIBILITY",
            alwaysVisible: isPt ? "Barra sempre visível" : "Always show control bar",
            alwaysVisibleSub: isPt ? "Desativado: revela apenas ao passar o mouse no canto superior" : "When disabled, reveals on top-right hover",
            dragging: isPt ? "ARRASTO E SNAP DE JANELAS" : "WINDOW DRAGGING & SNAPPING",
            dragZone: isPt ? "Mostrar zona de arrasto no topo da janela" : "Show top window drag zone",
            dragZoneSub: isPt ? "Mostra uma faixa de arrasto ao passar o mouse na borda superior" : "Shows a draggable area when hovering over window top edge",
            dragHandle: isPt ? "Mostrar alça de arrasto na barra (⠿)" : "Show drag grip on control bar (⠿)",
            dragHandleSub: isPt ? "Ícone de arrasto à esquerda dos botões de controle" : "Draggable grip icon on the left side of the bar",
            ignoreDock: isPt ? "Ignorar dock no snap" : "Ignore dock when snapping",
            ignoreDockSub: isPt ? "Permite que o snap inferior se estenda sobre a área da dock" : "Allow snapped windows to extend over the dock area",
            disableSnapping: isPt ? "Desativar snap de janelas" : "Disable window snapping",
            disableSnappingSub: isPt ? "Desativa o snap nas bordas da tela e as sombras de preview" : "Turns off edge snapping and snap preview outlines",
            menuDragging: isPt ? "POSIÇÃO DA BARRA DE CONTROLES" : "CONTROL BAR POSITIONING",
            enableMenuDrag: isPt ? "Permitir reposicionar a barra de controles" : "Allow repositioning control bar",
            enableMenuDragSub: isPt ? "Arraste a borda inferior para mover. Clique duplo para resetar." : "Drag the thin bottom handle to freely move the bar. Double-click to reset.",
            rememberMenuPerWindow: isPt ? "Lembrar posição por aplicativo" : "Remember position per application",
            rememberMenuPerWindowSub: isPt ? "Mantém a posição personalizada para cada aplicativo mesmo após fechar" : "Saves custom position for each application across sessions",
            rememberMenuGlobal: isPt ? "Aplicar mesma posição a todas as janelas" : "Apply position to all windows",
            rememberMenuGlobalSub: isPt ? "Aplica a mesma posição personalizada globalmente a todas as janelas" : "Applies the same custom position globally to all windows",
            alwaysShowMenuDragZone: isPt ? "Sempre mostrar alça de arrasto da barra" : "Always show control bar drag handle",
            alwaysShowMenuDragZoneSub: isPt ? "Mantém a alça de arrasto inferior visível mesmo sem passar o mouse" : "Keep the bottom drag handle visible even when not hovering",
            buttonsTitle: isPt ? "BOTÕES — ORDEM E VISIBILIDADE" : "BUTTONS — ORDER & VISIBILITY",
            buttonsHint: isPt ? "↑ ↓ para reordenar. Toggle para mostrar/ocultar." : "↑ ↓ to reorder. Toggle to show or hide.",
            colorTitle: isPt ? "COR DA BARRA" : "BAR COLOR",
            themeFollow: isPt ? "Seguir tema do Omarchy" : "Follow Omarchy theme",
            themeFollowSub: isPt ? "Atualiza as cores automaticamente ao trocar de tema" : "Automatically updates colors when theme changes",
            closeSettings: isPt ? "Fechar configurações" : "Close settings"
        }
        return d[key] || key
    }

    // Estado da Janela Ativa
    property int    winX:      0
    property int    winY:      0
    property int    winW:      800
    property int    winH:      600
    property string winAddr:   ""
    property string winTitle:  ""
    property bool   winFloat:  true
    property bool   winMax:    false
    property bool   hasWindow: winAddr !== ""
    property string lastFloatedAddr: ""
    property var    savedWinSizes:   ({})
    property var    preSnapSizes:    ({})
    property int    savedFloatingW:  1000
    property int    savedFloatingH:  650

    // Estado do Arraste Suave e Estável
    property bool isDragging:        false
    property bool dragInitiated:     false
    property bool wasMaxOnPress:     false
    property bool wasSnappedOnPress: false
    property real pressCursorX:      0
    property real pressCursorY:      0
    property real dragStartWinX:     0
    property real dragStartWinY:     0
    property int  dragStartWinW:     800
    property int  dragStartWinH:     600
    property bool dragNeedsDispatch: false

    // Zonas de Snapping (Aero Snap / Light Tiling)
    property string snapZone:        ""
    property int    snapTargetX:     0
    property int    snapTargetY:     0
    property int    snapTargetW:     0
    property int    snapTargetH:     0

    // Reservas de tela do monitor (top bar e dock)
    property int reservedTop:    26
    property int reservedBottom: 69


    function cleanAddr(addr) {
        if (!addr) return ""
        var s = String(addr).trim()
        return /^0x[0-9a-fA-F]+$/.test(s) ? s : ""
    }

    function dispatchLua(lua) {
        if (!lua) return
        Hyprland.dispatch(lua)
    }

    function applyWindowGeometry(addr, x, y, w, h) {
        var a = cleanAddr(addr)
        if (!a) return
        Hyprland.dispatch('hl.dsp.window.resize({ x = ' + Math.round(w) + ', y = ' + Math.round(h) + ', window = "address:' + a + '" })')
        Hyprland.dispatch('hl.dsp.window.move({ x = ' + Math.round(x) + ', y = ' + Math.round(y) + ', relative = false, window = "address:' + a + '" })')
    }

    function unmaximizeAndRestore(addr, x, y, w, h) {
        var a = cleanAddr(addr)
        if (!a) return
        Hyprland.dispatch('hl.dsp.window.fullscreen({ mode = "maximized", window = "address:' + a + '" })')
        Hyprland.dispatch('hl.dsp.window.float({ action = "on", window = "address:' + a + '" })')
        Hyprland.dispatch('hl.dsp.window.resize({ x = ' + Math.round(w) + ', y = ' + Math.round(h) + ', window = "address:' + a + '" })')
        Hyprland.dispatch('hl.dsp.window.move({ x = ' + Math.round(x) + ', y = ' + Math.round(y) + ', relative = false, window = "address:' + a + '" })')
        Hyprland.dispatch('hl.dsp.window.bring_to_top({ window = "address:' + a + '" })')
    }

    function evalLua(lua) {
        if (!lua) return
        var re = /hl\.dispatch\((hl\.dsp\.[^;)]+\))\)/g
        var m
        var found = false
        while ((m = re.exec(lua)) !== null) {
            found = true
            Hyprland.dispatch(m[1])
        }
        if (!found) {
            Hyprland.dispatch(lua)
        }
    }

    function clampWinX(x, w) {
        var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
        var minX = 6
        var winW = (w > 0 ? w : root.winW)
        var maxX = Math.max(minX, sW - (winW > 0 ? winW : 800) - 6)
        return Math.round(Math.max(minX, Math.min(maxX, x)))
    }

    function clampWinY(y, h) {
        var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
        var minY = root.reservedTop + 6
        var winH = (h > 0 ? h : root.winH)
        var effectiveDock = root.ignoreDock ? 0 : root.reservedBottom
        var maxY = Math.max(minY, sH - effectiveDock - 6 - (winH > 0 ? winH : 600))
        return Math.round(Math.max(minY, Math.min(maxY, y)))
    }

    Process {
        id: monitorInfoProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var mons = JSON.parse(text)
                    if (mons && mons.length > 0) {
                        var m = mons.find(function(x) { return x.focused; }) || mons[0]
                        if (m && m.reserved) {
                            root.reservedTop = (m.reserved[1] !== undefined && m.reserved[1] > 0) ? m.reserved[1] : 26
                            root.reservedBottom = (m.reserved[3] !== undefined && m.reserved[3] > 0) ? m.reserved[3] : 0
                        }
                    }
                } catch(e) {}
            }
        }
    }

    // ── Detecção Universal de Dock ────────────────────────────
    Process {
        id: dockCheckProc
        command: [root.binDir + "/mf-dock-check"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isDockPresent = (text.trim() === "1")
                if (!root.isDockPresent) {
                    root.reservedBottom = 0
                }
            }
        }
    }

    // ── Sincronização da Seção na Barra do Sistema ─────────────
    Process {
        id: checkBarSectionProc
        command: ["bash", "-c", "cat ~/.config/omarchy/shell.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.detectedSection !== "") return
                try {
                    var s = JSON.parse(text)
                    if (s && s.bar && s.bar.layout) {
                        var l = s.bar.layout
                        var foundSec = ""
                        if (l.left && l.left.some(function(x) { return x.id === "io.github.mousefirst.controls"; })) {
                            foundSec = "left"
                        } else if (l.center && l.center.some(function(x) { return x.id === "io.github.mousefirst.controls"; })) {
                            foundSec = "center"
                        } else if (l.right && l.right.some(function(x) { return x.id === "io.github.mousefirst.controls"; })) {
                            foundSec = "right"
                        }
                        if (foundSec !== "") {
                            root.barSection = foundSec
                        }
                    }
                } catch(e) {}
            }
        }
    }

    function setBarSection(sec) {
        if (!sec || (sec !== "left" && sec !== "center" && sec !== "right")) return
        root.barSection = sec
        root.saveConfig()
        Quickshell.execDetached(["omarchy-shell", "shell", "moveBarWidget", "io.github.mousefirst.controls", JSON.stringify({ section: sec })])
    }

    Timer {
        id: monitorPollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (root.isDragging || root.dragInitiated) return
            if (!monitorInfoProc.running) monitorInfoProc.running = true
            if (!dockCheckProc.running) dockCheckProc.running = true
            if (!checkBarSectionProc.running) checkBarSectionProc.running = true
        }
    }

    Component.onCompleted: {
        if (root.detectedSection !== "") root.barSection = root.detectedSection
        cfgReadProc.running = true
        appsProc.running = true
        themeProc.running = true
        activeWinTimer.running = true
        themeTimer.running = true
        monitorInfoProc.running = true
        dockCheckProc.running = true
        checkBarSectionProc.running = true
    }

    // ── Eventos em Tempo Real do Hyprland ─────────────────────
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || !event.name) return
            if (root.isDragging || root.dragInitiated) return
            var n = event.name
            if (n === "activewindowv2" || n === "activewindow" ||
                n === "openwindow"     || n === "closewindow"  ||
                n === "movewindow"     || n === "changefloatingmode") {
                if (!activeWinProc.running) activeWinProc.running = true
            }
            if (n === "openwindow" || n === "closewindow") {
                if (!appsProc.running) appsProc.running = true
            }
            if (n === "closewindow") {
                var d = event.data ? event.data.trim() : ""
                var a1 = d.indexOf("0x") === 0 ? d : ("0x" + d)
                if (root.sessionMenuOffsets[a1] || root.sessionMenuOffsets[d]) {
                    var sMap = Object.assign({}, root.sessionMenuOffsets)
                    delete sMap[a1]
                    delete sMap[d]
                    root.sessionMenuOffsets = sMap
                }
                if (root.preSnapSizes[a1] || root.preSnapSizes[d]) {
                    var snapMapClose = Object.assign({}, root.preSnapSizes)
                    delete snapMapClose[a1]
                    delete snapMapClose[d]
                    root.preSnapSizes = snapMapClose
                }
            }
        }
    }

    // ── Timer de despacho suave ao Hyprland (60fps) ───────────
    Timer {
        id: dragMoveTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.isDragging) {
                running = false
                return
            }
            var addr = root.cleanAddr(root.winAddr)
            if (root.dragNeedsDispatch && addr !== "") {
                root.dragNeedsDispatch = false
                var cx = dragProxy.x
                var cy = dragProxy.y
                root.dispatchLua('hl.dsp.window.move({ x = ' + cx + ', y = ' + cy + ', relative = false, window = "address:' + addr + '" })')
            }
        }
    }

    // ── Polling de Janela Ativa para acompanhar Resize e Super-Drag ──
    Timer {
        id: activeWinTimer
        interval: 120
        repeat: true
        onTriggered: {
            if (!root.isDragging && !root.dragInitiated && !settleTimer.running && !activeWinProc.running) {
                activeWinProc.running = true
            }
        }
    }

    // ── Timer de estabilização pós-ação (evita ler coordenadas transitórias) ──
    Timer {
        id: settleTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.isDragging && !activeWinProc.running) {
                activeWinProc.running = true
            }
        }
    }

    Process {
        id: recoverFocusProc
        command: ["bash", "-c", "AW=$(hyprctl activeworkspace -j 2>/dev/null | python3 -c \"import sys,json\ntry:\n    d=json.load(sys.stdin)\n    print(d.get('lastwindow',''))\nexcept:\n    pass\" 2>/dev/null); if [ -n \"$AW\" ] && [ \"$AW\" != \"0x0\" ] && [ \"$AW\" != \"null\" ]; then hyprctl dispatch \"hl.dsp.focus({ window = 'address:$AW' })\" >/dev/null 2>&1 || true; fi"]
        onExited: {
            if (!activeWinProc.running) activeWinProc.running = true
        }
    }

    Process {
        id: activeWinProc
        command: ["hyprctl", "--batch", "j/activewindow ; cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var rawText = text
                    var jsonEnd = rawText.lastIndexOf("}")
                    if (jsonEnd === -1) return
                    var jsonStr = rawText.substring(0, jsonEnd + 1)
                    var w = JSON.parse(jsonStr)

                    var cursorMatch = rawText.match(/(\d+),\s*(\d+)\s*$/)
                    var curMouseX = cursorMatch ? parseInt(cursorMatch[1]) : -1
                    var curMouseY = cursorMatch ? parseInt(cursorMatch[2]) : -1

                    var isSpecial = !!(w && w.workspace && w.workspace.name && w.workspace.name.indexOf("special:") === 0)
                    if (!w || !w.address || w.mapped === false || w.hidden === true || w.visible === false || isSpecial) {
                        if (!root.isDragging && !root.dragInitiated) {
                            root.hasWindow = false
                            root.winAddr = ""
                        }
                        if (isSpecial) {
                            if (!recoverFocusProc.running) recoverFocusProc.running = true
                        }
                        return
                    }

                    if (root.isDragging || root.dragInitiated || settleTimer.running) {
                        return
                    }

                    var rawX = (Array.isArray(w.at) && w.at.length >= 2 && !isNaN(Number(w.at[0]))) ? Number(w.at[0]) : 0
                    var rawY = (Array.isArray(w.at) && w.at.length >= 2 && !isNaN(Number(w.at[1]))) ? Number(w.at[1]) : 0
                    var rawW = (Array.isArray(w.size) && w.size.length >= 2 && !isNaN(Number(w.size[0]))) ? Number(w.size[0]) : 800
                    var rawH = (Array.isArray(w.size) && w.size.length >= 2 && !isNaN(Number(w.size[1]))) ? Number(w.size[1]) : 600

                    if (rawW < 100 || rawH < 100) {
                        return
                    }

                    var isMax = (w.fullscreen === 1 || w.fullscreen === 2)
                    var isFloat = (w.floating || false)

                    // ── Limpeza de estado de Snap se a janela foi movida ou redimensionada fora do snap ──
                    if (w.address && !isMax && isFloat && !settleTimer.running) {
                        var snapInfo = root.preSnapSizes[w.address]
                        if (snapInfo && snapInfo.snapW > 0) {
                            var atSnapPos = (Math.abs(rawX - snapInfo.snapX) <= 12 && Math.abs(rawY - snapInfo.snapY) <= 12)
                            var atSnapSize = (Math.abs(rawW - snapInfo.snapW) <= 20 && Math.abs(rawH - snapInfo.snapH) <= 20)

                            if (!snapInfo.settled) {
                                if (atSnapPos && atSnapSize) {
                                    snapInfo.settled = true
                                }
                            } else {
                                var movedAway = (Math.hypot(rawX - snapInfo.snapX, rawY - snapInfo.snapY) > 25)
                                var sizeChanged = (!atSnapSize)
                                if (movedAway || sizeChanged) {
                                    var snapMapClean = Object.assign({}, root.preSnapSizes)
                                    delete snapMapClean[w.address]
                                    root.preSnapSizes = snapMapClean
                                }
                            }
                        }
                    }

                    if (!root.isDragging) {
                        root.snapZone = ""
                    }

                    root.winAddr  = w.address
                    root.winClass = w.class || w.initialClass || ""
                    root.winTitle = (w.title || root.winClass || "").substring(0, 60)
                    root.winFloat = isFloat
                    root.winMax   = isMax
                    root.winX     = Math.round(rawX)
                    root.winY     = Math.round(rawY)
                    root.winW     = Math.round(rawW)
                    root.winH     = Math.round(rawH)
                    root.hasWindow = true

                    // Proteção inteligente contra janelas e webapps que abrem maiores que a tela ou sob a barra do sistema
                    if (root.winFloat && !root.winMax && !root.preSnapSizes[w.address] && !root.isDragging && !root.dragInitiated && root.winW >= 200 && root.winH >= 200) {
                        if (!root.clampedWindows[w.address]) {
                            root.clampedWindows[w.address] = true
                            var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                            var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                            var topReserve = Math.max(30, root.reservedTop)
                            var bottomReserve = (root.isDockPresent && root.reservedBottom > 0) ? root.reservedBottom : 0
                            var maxUsableW = sW - 24
                            var maxUsableH = sH - topReserve - bottomReserve - 16

                            var curW = root.winW
                            var curH = root.winH
                            var curX = root.winX
                            var curY = root.winY

                            var needsClamp = false
                            var targetW = curW
                            var targetH = curH
                            var targetX = curX
                            var targetY = curY

                            if (curW > maxUsableW || curH > maxUsableH) {
                                needsClamp = true
                                targetW = Math.min(curW, Math.round(sW * 0.88))
                                targetH = Math.min(curH, Math.round((sH - topReserve - bottomReserve) * 0.84))
                                targetX = Math.round((sW - targetW) / 2)
                                targetY = Math.round(topReserve + Math.max(8, (sH - topReserve - bottomReserve - targetH) / 2))
                            } else if (curY < topReserve) {
                                needsClamp = true
                                targetY = topReserve + 8
                                if (targetY + curH > sH - bottomReserve) {
                                    targetH = Math.max(300, sH - targetY - bottomReserve - 8)
                                }
                            }

                            if (needsClamp && targetW >= 200 && targetH >= 200) {
                                root.winW = targetW
                                root.winH = targetH
                                root.winX = targetX
                                root.winY = targetY
                                dragProxy.x = targetX
                                dragProxy.y = targetY
                                dragProxy.width = targetW
                                var addr = root.cleanAddr(w.address)
                                if (addr) {
                                    root.applyWindowGeometry(addr, targetX, targetY, targetW, targetH)
                                }
                            }
                        }
                    }

                    if (!root.isMenuDragging) {
                        root.updateMenuOffsetForActiveWindow(w.address, root.winClass)
                    }

                    if (root.winFloat && !root.winMax && root.winW > 200 && root.winH > 200) {
                        var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                        var isLikelySnapped = (root.winW >= Math.floor(sW * 0.48))
                        var isWeb = /brave|chrome|chromium/i.test(w.class || w.initialClass || "")
                        if (!root.preSnapSizes[w.address]) {
                            if (!isLikelySnapped) {
                                root.savedFloatingW = root.winW
                                root.savedFloatingH = root.winH
                            }
                            if (!isLikelySnapped || isWeb) {
                                var sizes = Object.assign({}, root.savedWinSizes)
                                sizes[w.address] = { w: root.winW, h: root.winH }
                                root.savedWinSizes = sizes
                            }
                        }
                    }

                    // Desativação Global do Tiling
                    if (root.disableTiling && !root.winFloat && root.lastFloatedAddr !== root.winAddr) {
                        var addr = root.cleanAddr(root.winAddr)
                        if (addr) {
                            root.lastFloatedAddr = root.winAddr
                            root.dispatchLua('hl.dsp.window.float({ action = "toggle", window = "address:' + addr + '" })')
                            root.winFloat = true
                        }
                    }
                } catch(e) {
                    if (!root.isDragging) {
                        root.hasWindow = false
                        root.winAddr = ""
                    }
                }
            }
        }
    }

    // ── Polling de Aplicativos e Minimizadas ──────────────────
    Timer {
        id: appsTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (root.isDragging || root.dragInitiated) return
            if (!appsProc.running) appsProc.running = true
            if (!listProc.running) listProc.running = true
        }
    }

    Process {
        id: appsProc
        command: [root.binDir + "/mf-apps"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.barAppsList = JSON.parse(text) || [] }
                catch(e) { root.barAppsList = [] }
            }
        }
    }

    Process {
        id: listProc
        command: [root.binDir + "/mf-list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.minimizedWindows = JSON.parse(text) || [] }
                catch(e) { root.minimizedWindows = [] }
            }
        }
    }

    // ── Config ───────────────────────────────────────────────
    Process {
        id: cfgReadProc
        command: ["cat", root.cfgFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var c = JSON.parse(text)
                    if (c.language        !== undefined) root.language        = c.language
                    if (c.disableTiling   !== undefined) root.disableTiling   = c.disableTiling
                    if (c.alwaysVisible   !== undefined) root.alwaysVisible   = c.alwaysVisible
                    if (c.dragFullWidth   !== undefined) root.dragFullWidth   = c.dragFullWidth
                    if (c.showDragHandle  !== undefined) root.showDragHandle  = c.showDragHandle
                    if (c.ignoreDock            !== undefined) root.ignoreDock            = c.ignoreDock
                    if (c.disableSnapping       !== undefined) root.disableSnapping       = c.disableSnapping
                    if (c.enableMenuDrag        !== undefined) root.enableMenuDrag        = c.enableMenuDrag
                    if (c.rememberMenuPerWindow !== undefined) root.rememberMenuPerWindow = c.rememberMenuPerWindow
                    if (c.rememberMenuGlobal    !== undefined) root.rememberMenuGlobal    = c.rememberMenuGlobal
                    if (c.alwaysShowMenuDragZone !== undefined) root.alwaysShowMenuDragZone = c.alwaysShowMenuDragZone
                    if (c.minimizeToBar         !== undefined) root.minimizeToBar         = c.minimizeToBar
                    if (c.barSection            !== undefined && root.detectedSection === "") root.barSection = c.barSection
                    if (c.globalMenuOffsetX     !== undefined) root.globalMenuOffsetX     = c.globalMenuOffsetX
                    if (c.globalMenuOffsetY     !== undefined) root.globalMenuOffsetY     = c.globalMenuOffsetY
                    if (c.perWindowClassOffsets !== undefined) root.perWindowClassOffsets = c.perWindowClassOffsets
                    if (c.buttonOrder           !== undefined) root.buttonOrder           = c.buttonOrder
                    if (c.buttonVisible         !== undefined) root.buttonVisible         = c.buttonVisible
                    if (c.colorMode             !== undefined) root.colorMode             = c.colorMode
                    if (c.customBg              !== undefined) root.customBg              = c.customBg
                    if (c.customFg              !== undefined) root.customFg              = c.customFg
                    if (c.customAccent          !== undefined) root.customAccent          = c.customAccent
                    if (c.customRed             !== undefined) root.customRed             = c.customRed
                } catch(e) {}
            }
        }
    }

    function saveConfig() {
        var cfg = {
            language: root.language,
            disableTiling: root.disableTiling,
            alwaysVisible: root.alwaysVisible,
            dragFullWidth: root.dragFullWidth,
            showDragHandle: root.showDragHandle,
            ignoreDock: root.ignoreDock,
            disableSnapping: root.disableSnapping,
            enableMenuDrag: root.enableMenuDrag,
            rememberMenuPerWindow: root.rememberMenuPerWindow,
            rememberMenuGlobal: root.rememberMenuGlobal,
            alwaysShowMenuDragZone: root.alwaysShowMenuDragZone,
            minimizeToBar: root.minimizeToBar,
            barSection: root.barSection,
            globalMenuOffsetX: root.globalMenuOffsetX,
            globalMenuOffsetY: root.globalMenuOffsetY,
            perWindowClassOffsets: root.perWindowClassOffsets,
            buttonOrder: root.buttonOrder,
            buttonVisible: root.buttonVisible,
            colorMode: root.colorMode,
            customBg: root.customBg,
            customFg: root.customFg,
            customAccent: root.customAccent,
            customRed: root.customRed
        }
        var jsonStr = JSON.stringify(cfg, null, 2)
        Quickshell.execDetached(["bash", "-c", "cat << 'CFGEOF' > '" + root.cfgFile + "'\n" + jsonStr + "\nCFGEOF\n"])
    }

    // ── Tema ─────────────────────────────────────────────────
    Timer { id: themeTimer; interval: 5000; repeat: true; onTriggered: themeProc.running = true }

    Process {
        id: themeProc
        command: [root.binDir + "/mf-theme"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var t = JSON.parse(text)
                    root.themeBg     = t.background || "#1a1b26"
                    root.themeFg     = t.foreground || "#a9b1d6"
                    root.themeAccent = t.accent     || "#7aa2f7"
                    root.themeRed    = t.red        || "#f7768e"
                    root.themeMuted  = t.muted      || "#414868"
                    root.themeMode   = t.mode       || "dark"
                } catch(e) {}
            }
        }
    }

    // ── Processos auxiliares ──────────────────────────────────
    Process {
        id: minimizeProc
        property string addr: ""
        command: {
            var targetWs = (root.minimizeToBar && root.isDockPresent) ? "special:mf-minimized" : "special:minimized"
            return addr !== "" ? [root.binDir + "/mf-minimize", addr, targetWs] : [root.binDir + "/mf-minimize", "", targetWs]
        }
        onExited: {
            if (!activeWinProc.running) activeWinProc.running = true
            if (!listProc.running) listProc.running = true
            if (!appsProc.running) appsProc.running = true
        }
    }
    Process {
        id: restoreProc
        property string addr: ""
        command: addr !== "" ? [root.binDir + "/mf-restore", addr] : [root.binDir + "/mf-restore"]
        onExited: {
            if (!activeWinProc.running) activeWinProc.running = true
            if (!listProc.running) listProc.running = true
            if (!appsProc.running) appsProc.running = true
        }
    }

    function launchApp(appId) {
        if (!appId) return
        Quickshell.execDetached(["gtk-launch", appId])
        appsTimer.restart()
    }

    function focusWindow(addr) {
        var clean = root.cleanAddr(addr)
        if (!clean) return
        root.dispatchLua('hl.dsp.focus({ window = "address:' + clean + '" })')
        root.dispatchLua('hl.dsp.window.bring_to_top({ window = "address:' + clean + '" })')
        if (!activeWinProc.running) activeWinProc.running = true
        appsTimer.restart()
    }

    function minimizeWindow(addr) {
        root.hasWindow = false
        root.winAddr = ""
        minimizeProc.addr = addr || ""
        if (!minimizeProc.running) minimizeProc.running = true
    }

    function restoreWindow(addr) {
        restoreProc.addr = addr || ""
        if (!restoreProc.running) restoreProc.running = true
    }

    function closeWindow(addr) {
        var clean = root.cleanAddr(addr)
        if (!clean) return
        root.dispatchLua('hl.dsp.window.close({ window = "address:' + clean + '" })')
        if (!activeWinProc.running) activeWinProc.running = true
        appsTimer.restart()
    }

    // ── Helpers ───────────────────────────────────────────────
    function moveButton(i, dir) {
        var a = root.buttonOrder.slice()
        var t = i + dir
        if (t < 0 || t >= a.length) return
        var tmp = a[i]; a[i] = a[t]; a[t] = tmp
        root.buttonOrder = a
        root.saveConfig()
    }

    function btnTooltip(id) {
        if (id === "float")    return root.winFloat ? root.t("tile") : root.t("float")
        if (id === "minimize") return root.t("minimize")
        if (id === "maximize") return root.winMax ? root.t("restore") : root.t("maximize")
        if (id === "close")    return root.t("close")
        return ""
    }

    function btnLabel(id) {
        if (id === "float")    return root.t("floatTile")
        if (id === "minimize") return root.t("minimize")
        if (id === "maximize") return root.t("maxRestore")
        if (id === "close")    return root.t("close")
        return id
    }

    function updateMenuOffsetForActiveWindow(addr, wClass) {
        if (!root.enableMenuDrag) {
            root.curMenuOffsetX = 0
            root.curMenuOffsetY = 0
            return
        }
        if (root.rememberMenuGlobal) {
            root.curMenuOffsetX = root.globalMenuOffsetX
            root.curMenuOffsetY = root.globalMenuOffsetY
        } else if (root.rememberMenuPerWindow) {
            if (wClass && root.perWindowClassOffsets[wClass]) {
                root.curMenuOffsetX = root.perWindowClassOffsets[wClass].x || 0
                root.curMenuOffsetY = root.perWindowClassOffsets[wClass].y || 0
            } else {
                root.curMenuOffsetX = 0
                root.curMenuOffsetY = 0
            }
        } else {
            if (addr && root.sessionMenuOffsets[addr]) {
                root.curMenuOffsetX = root.sessionMenuOffsets[addr].x || 0
                root.curMenuOffsetY = root.sessionMenuOffsets[addr].y || 0
            } else {
                root.curMenuOffsetX = 0
                root.curMenuOffsetY = 0
            }
        }
    }

    function finishMenuDrag() {
        if (!root.isMenuDragging) return
        root.isMenuDragging = false

        if (root.rememberMenuGlobal) {
            root.globalMenuOffsetX = root.curMenuOffsetX
            root.globalMenuOffsetY = root.curMenuOffsetY
            root.saveConfig()
        } else if (root.rememberMenuPerWindow) {
            if (root.winClass !== "") {
                var map = Object.assign({}, root.perWindowClassOffsets)
                map[root.winClass] = { x: root.curMenuOffsetX, y: root.curMenuOffsetY }
                root.perWindowClassOffsets = map
                root.saveConfig()
            }
        } else {
            if (root.winAddr !== "") {
                var sMap = Object.assign({}, root.sessionMenuOffsets)
                sMap[root.winAddr] = { x: root.curMenuOffsetX, y: root.curMenuOffsetY }
                root.sessionMenuOffsets = sMap
            }
        }
    }

    function resetMenuOffset() {
        root.curMenuOffsetX = 0
        root.curMenuOffsetY = 0
        if (root.rememberMenuGlobal) {
            root.globalMenuOffsetX = 0
            root.globalMenuOffsetY = 0
            root.saveConfig()
        } else if (root.rememberMenuPerWindow) {
            if (root.winClass !== "" && root.perWindowClassOffsets[root.winClass]) {
                var map = Object.assign({}, root.perWindowClassOffsets)
                delete map[root.winClass]
                root.perWindowClassOffsets = map
                root.saveConfig()
            }
        } else {
            if (root.winAddr !== "" && root.sessionMenuOffsets[root.winAddr]) {
                var sMap = Object.assign({}, root.sessionMenuOffsets)
                delete sMap[root.winAddr]
                root.sessionMenuOffsets = sMap
            }
        }
    }

    function triggerBtn(id) {
        if (!root.hasWindow || !root.winAddr) return
        var addr = root.cleanAddr(root.winAddr)
        if (!addr) return

        if (id === "float") {
            root.dispatchLua('hl.dsp.window.float({ action = "toggle", window = "address:' + addr + '" })')
            root.winFloat = !root.winFloat
            settleTimer.restart()
            return
        }
        if (id === "minimize") {
            root.hasWindow = false
            root.winAddr = ""
            minimizeProc.addr = addr
            minimizeProc.running = true
            return
        }
        if (id === "maximize") {
            root.dispatchLua('hl.dsp.window.fullscreen({ mode = "maximized", window = "address:' + addr + '" })')
            root.winMax = !root.winMax
            settleTimer.restart()
            return
        }
        if (id === "close") {
            var closingAddr = root.winAddr
            root.hasWindow = false
            root.winAddr = ""
            root.curMenuOffsetX = 0
            root.curMenuOffsetY = 0
            if (closingAddr && root.sessionMenuOffsets[closingAddr]) {
                var sMap = Object.assign({}, root.sessionMenuOffsets)
                delete sMap[closingAddr]
                root.sessionMenuOffsets = sMap
            }
            root.dispatchLua('hl.dsp.window.close({ window = "address:' + addr + '" })')
            settleTimer.restart()
            return
        }
    }

    function updateSnapZone(cx, cy, rawWinX, rawWinY) {
        if (root.disableSnapping) {
            root.snapZone = ""
            return
        }

        var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
        var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)

        var topBarH = root.reservedTop
        var dockH   = root.ignoreDock ? 0 : root.reservedBottom
        var G = 6 // gap uniforme em todos os lados

        var usableX = G
        var usableY = topBarH + G
        var usableW = sW - (G * 2)
        var usableH = sH - topBarH - dockH - (G * 2)

        var halfW = Math.round((usableW - G) / 2)
        var halfH = Math.round((usableH - G) / 2)
        var remH  = usableH - halfH - G

        var winW = (root.winW > 100 ? root.winW : 800)
        var winH = (root.winH > 100 ? root.winH : 600)

        var minX = usableX
        var maxX = Math.max(minX, sW - winW - G)
        var minY = usableY
        var maxY = Math.max(minY, sH - dockH - G - winH)

        // Se rawWinX / rawWinY não foram passados (ex: fallback), usa as coordenadas do proxy
        var rX = (rawWinX !== undefined ? rawWinX : dragProxy.x)
        var rY = (rawWinY !== undefined ? rawWinY : dragProxy.y)

        // Detecção de ultrapassagem intencional ("pressionar demais" > 45px além da borda)
        // Permite transpor limites da tela (ex: multi-monitores ou esconder parte da janela)
        var breakMargin = 45
        var isBreaking = (rX < minX - breakMargin) || (rX > maxX + breakMargin) ||
                         (rY < minY - breakMargin) || (rY > maxY + breakMargin) ||
                         (cx < -10) || (cx > sW + 10) || (cy < -10) || (cy > sH + 10)

        if (isBreaking) {
            root.snapZone = ""
            return
        }

        // Margem de contato para ativação do snap ao encostar a janela na borda
        var touchMargin = 6
        var winPushLeft   = (rX <= minX + touchMargin)
        var winPushRight  = (rX >= maxX - touchMargin)
        var winPushTop    = (rY <= minY + touchMargin)
        var winPushBottom = (rY >= maxY - touchMargin)

        // Detecção por cursor arremessado na borda extrema
        var cursorPushLeft   = (cx <= 16)
        var cursorPushRight  = (cx >= sW - 16)
        var cursorPushTop    = (cy <= topBarH + 16)
        var cursorPushBottom = (cy >= sH - dockH - 16)

        var isPushLeft   = winPushLeft   || cursorPushLeft
        var isPushRight  = winPushRight  || cursorPushRight
        var isPushTop    = winPushTop    || cursorPushTop
        var isPushBottom = winPushBottom || cursorPushBottom

        if (!isPushLeft && !isPushRight && !isPushTop && !isPushBottom) {
            root.snapZone = ""
            return
        }

        // Quinas extremas para acionamento direto pelo cursor
        var cornerSize = 32
        var cursorInTopLeft     = (cx <= cornerSize && cy <= topBarH + cornerSize)
        var cursorInTopRight    = (cx >= sW - cornerSize && cy <= topBarH + cornerSize)
        var cursorInBottomLeft  = (cx <= cornerSize && cy >= sH - dockH - cornerSize)
        var cursorInBottomRight = (cx >= sW - cornerSize && cy >= sH - dockH - cornerSize)

        // 1. Cantos da tela (quartos de tela):
        // Aciona somente quando o canto da janela entra em contato físico com o canto da tela
        // (contato lateral E superior/inferior simultaneamente), ou o cursor está na quina extrema.
        var isTopLeft     = cursorInTopLeft     || (isPushLeft  && isPushTop)
        var isTopRight    = cursorInTopRight    || (isPushRight && isPushTop)
        var isBottomLeft  = cursorInBottomLeft  || (isPushLeft  && isPushBottom)
        var isBottomRight = cursorInBottomRight || (isPushRight && isPushBottom)

        var zone = ""
        var tx = 0, ty = 0, tw = 0, th = 0

        if (isTopLeft) {
            zone = "top-left"
            tx = usableX
            ty = usableY
            tw = halfW
            th = halfH
        } else if (isTopRight) {
            zone = "top-right"
            tx = usableX + halfW + G
            ty = usableY
            tw = halfW
            th = halfH
        } else if (isBottomLeft) {
            zone = "bottom-left"
            tx = usableX
            ty = usableY + halfH + G
            tw = halfW
            th = remH
        } else if (isBottomRight) {
            zone = "bottom-right"
            tx = usableX + halfW + G
            ty = usableY + halfH + G
            tw = halfW
            th = remH
        }
        // 2. Bordas laterais (metades verticais) — ampla área de contato na lateral
        else if (isPushLeft) {
            zone = "left"
            tx = usableX
            ty = usableY
            tw = halfW
            th = usableH
        } else if (isPushRight) {
            zone = "right"
            tx = usableX + halfW + G
            ty = usableY
            tw = halfW
            th = usableH
        }
        // 3. Bordas superior e inferior (metades horizontais)
        else if (isPushTop) {
            zone = "top"
            tx = usableX
            ty = usableY
            tw = usableW
            th = halfH
        } else if (isPushBottom) {
            zone = "bottom"
            tx = usableX
            ty = usableY + halfH + G
            tw = usableW
            th = remH
        }

        root.snapZone = zone
        if (zone !== "") {
            root.snapTargetX = tx
            root.snapTargetY = ty
            root.snapTargetW = tw
            root.snapTargetH = th
        }
    }

    function handlePress(cx, cy, isRightBtn) {
        if (isRightBtn) {
            settingsWin.visible = !settingsWin.visible
            return
        }
        if (!root.hasWindow || !root.winAddr) return
        if (!monitorInfoProc.running) monitorInfoProc.running = true
        root.pressCursorX = cx
        root.pressCursorY = cy
        root.dragStartWinX = dragProxy.x
        root.dragStartWinY = dragProxy.y
        root.dragStartWinW = root.winW
        root.dragStartWinH = root.winH
        root.wasMaxOnPress = root.winMax
        root.wasSnappedOnPress = !!(root.preSnapSizes[root.winAddr])
        root.dragInitiated = true
    }

    function handlePositionChanged(cx, cy) {
        if (!root.dragInitiated) return
        var dist = Math.hypot(cx - root.pressCursorX, cy - root.pressCursorY)

        if (!root.isDragging) {
            if (dist < 4) return
            root.isDragging = true

            if (root.wasMaxOnPress) {
                root.winMax = false

                var sz = root.savedWinSizes[root.winAddr]
                var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                var isWeb = /brave|chrome|chromium/i.test(root.winClass)
                var maxAllowedW = isWeb ? Math.floor(sW * 0.85) : Math.min(1050, Math.floor(sW * 0.55))
                var maxAllowedH = isWeb ? Math.floor(sH * 0.80) : Math.min(700, Math.floor(sH * 0.65))
                var defaultW = isWeb ? Math.floor(sW * 0.85) : Math.min(1000, Math.floor(sW * 0.55))
                var defaultH = isWeb ? Math.floor(sH * 0.80) : Math.min(650, Math.floor(sH * 0.65))

                var baseW = (sz && sz.w && sz.w <= maxAllowedW && sz.w >= 400) ? sz.w :
                            ((root.savedFloatingW && root.savedFloatingW <= maxAllowedW && root.savedFloatingW >= 400) ? root.savedFloatingW : defaultW)
                var baseH = (sz && sz.h && sz.h <= maxAllowedH && sz.h >= 300) ? sz.h :
                            ((root.savedFloatingH && root.savedFloatingH <= maxAllowedH && root.savedFloatingH >= 300) ? root.savedFloatingH : defaultH)

                var restoredW = Math.max(500, Math.min(baseW, maxAllowedW))
                var restoredH = Math.max(350, Math.min(baseH, maxAllowedH))

                var curProxyW = dragProxy.width > 0 ? dragProxy.width : sW
                var ratioX = Math.max(0.15, Math.min(0.85, (root.pressCursorX - dragProxy.x) / curProxyW))

                var rawX = Math.round(cx - restoredW * ratioX)
                var rawY = Math.round(cy - 14)
                var newWinX = root.clampWinX(rawX, restoredW)
                var newWinY = root.clampWinY(rawY, restoredH)

                root.winW = restoredW
                root.winH = restoredH
                root.winX = newWinX
                root.winY = newWinY

                dragProxy.width = restoredW
                dragProxy.x = newWinX
                dragProxy.y = newWinY

                root.dragStartWinX = newWinX
                root.dragStartWinY = newWinY
                root.pressCursorX = cx
                root.pressCursorY = cy

                var addr = root.cleanAddr(root.winAddr)
                if (addr) {
                    root.unmaximizeAndRestore(addr, newWinX, newWinY, restoredW, restoredH)
                }
            } else if (root.wasSnappedOnPress) {
                var pre = root.preSnapSizes[root.winAddr] || root.savedWinSizes[root.winAddr]
                var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                var isWeb = /brave|chrome|chromium/i.test(root.winClass)
                var maxAllowedW = isWeb ? Math.floor(sW * 0.85) : Math.min(1050, Math.floor(sW * 0.55))
                var maxAllowedH = isWeb ? Math.floor(sH * 0.80) : Math.min(700, Math.floor(sH * 0.65))
                var defaultW = isWeb ? Math.floor(sW * 0.85) : Math.min(1000, Math.floor(sW * 0.55))
                var defaultH = isWeb ? Math.floor(sH * 0.80) : Math.min(650, Math.floor(sH * 0.65))

                var baseW = (pre && pre.w && pre.w <= maxAllowedW && pre.w >= 400) ? pre.w :
                            ((root.savedFloatingW && root.savedFloatingW <= maxAllowedW && root.savedFloatingW >= 400) ? root.savedFloatingW : defaultW)
                var baseH = (pre && pre.h && pre.h <= maxAllowedH && pre.h >= 300) ? pre.h :
                            ((root.savedFloatingH && root.savedFloatingH <= maxAllowedH && root.savedFloatingH >= 300) ? root.savedFloatingH : defaultH)

                var restoredW = Math.max(500, Math.min(baseW, maxAllowedW))
                var restoredH = Math.max(350, Math.min(baseH, maxAllowedH))

                var snapMap = Object.assign({}, root.preSnapSizes)
                delete snapMap[root.winAddr]
                root.preSnapSizes = snapMap

                var curProxyW = dragProxy.width > 0 ? dragProxy.width : sW
                var ratioX = Math.max(0.15, Math.min(0.85, (root.pressCursorX - dragProxy.x) / curProxyW))

                var rawX = Math.round(cx - restoredW * ratioX)
                var rawY = Math.round(cy - 14)
                var newWinX = root.clampWinX(rawX, restoredW)
                var newWinY = root.clampWinY(rawY, restoredH)

                root.winW = restoredW
                root.winH = restoredH
                root.winX = newWinX
                root.winY = newWinY

                dragProxy.width = restoredW
                dragProxy.x = newWinX
                dragProxy.y = newWinY

                root.dragStartWinX = newWinX
                root.dragStartWinY = newWinY
                root.pressCursorX = cx
                root.pressCursorY = cy

                var addr = root.cleanAddr(root.winAddr)
                if (addr) {
                    root.applyWindowGeometry(addr, newWinX, newWinY, restoredW, restoredH)
                }
            }

            var addr = root.cleanAddr(root.winAddr)
            if (addr) {
                if (!root.winFloat) {
                    root.dispatchLua('hl.dsp.window.float({ action = "on", window = "address:' + addr + '" })')
                    root.winFloat = true
                }
                root.dispatchLua('hl.dsp.window.bring_to_top({ window = "address:' + addr + '" })')
            }
        }

        var dx = cx - root.pressCursorX
        var dy = cy - root.pressCursorY

        var rawWinX = root.dragStartWinX + dx
        var rawWinY = root.dragStartWinY + dy

        var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
        var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
        var winW = (root.winW > 100 ? root.winW : 800)
        var winH = (root.winH > 100 ? root.winH : 600)
        var effectiveDock = root.ignoreDock ? 0 : root.reservedBottom
        var minX = 6
        var maxX = Math.max(minX, sW - winW - 6)
        var minY = root.reservedTop + 6
        var maxY = Math.max(minY, sH - effectiveDock - 6 - winH)

        var breakMargin = 45
        var isBreaking = (rawWinX < minX - breakMargin) || (rawWinX > maxX + breakMargin) ||
                         (rawWinY < minY - breakMargin) || (rawWinY > maxY + breakMargin) ||
                         (cx < -10) || (cx > sW + 10) || (cy < -10) || (cy > sH + 10)

        var targetX = isBreaking ? rawWinX : root.clampWinX(rawWinX, root.winW)
        var targetY = isBreaking ? rawWinY : root.clampWinY(rawWinY, root.winH)

        dragProxy.x = targetX
        dragProxy.y = targetY
        root.winX = targetX
        root.winY = targetY

        root.dragNeedsDispatch = true
        if (!dragMoveTimer.running) dragMoveTimer.running = true

        root.updateSnapZone(cx, cy, rawWinX, rawWinY)
    }

    function handleRelease() {
        root.dragInitiated = false
        if (root.isDragging) {
            root.isDragging = false
            root.finishDrag()
        }
    }

    function finishDrag() {
        dragMoveTimer.running = false
        root.dragNeedsDispatch = false

        if (root.winAddr !== "") {
            if (root.snapZone !== "") {
                var origW = (root.preSnapSizes[root.winAddr] && root.preSnapSizes[root.winAddr].w) ? root.preSnapSizes[root.winAddr].w :
                            (root.savedWinSizes[root.winAddr] ? root.savedWinSizes[root.winAddr].w : root.dragStartWinW)
                var origH = (root.preSnapSizes[root.winAddr] && root.preSnapSizes[root.winAddr].h) ? root.preSnapSizes[root.winAddr].h :
                            (root.savedWinSizes[root.winAddr] ? root.savedWinSizes[root.winAddr].h : root.dragStartWinH)
                var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                var isWeb = /brave|chrome|chromium/i.test(root.winClass)
                var maxFloatingCapW = isWeb ? Math.floor(sW * 0.85) : Math.min(1000, Math.floor(sW * 0.55))
                var maxFloatingCapH = isWeb ? Math.floor(sH * 0.80) : Math.min(650, Math.floor(sH * 0.65))
                if (origW > maxFloatingCapW) origW = maxFloatingCapW
                if (origH > maxFloatingCapH) origH = maxFloatingCapH

                var targetX = root.snapTargetX
                var targetY = root.snapTargetY
                var targetW = root.snapTargetW
                var targetH = root.snapTargetH

                var snapMap = Object.assign({}, root.preSnapSizes)
                snapMap[root.winAddr] = {
                    w: origW,
                    h: origH,
                    snapX: targetX,
                    snapY: targetY,
                    snapW: targetW,
                    snapH: targetH,
                    settled: false
                }
                root.preSnapSizes = snapMap

                root.winX = targetX
                root.winY = targetY
                root.winW = targetW
                root.winH = targetH

                dragProxy.x = targetX
                dragProxy.y = targetY
                dragProxy.width = targetW

                root.snapZone = ""

                var addr = root.cleanAddr(root.winAddr)
                if (addr) {
                    root.applyWindowGeometry(addr, targetX, targetY, targetW, targetH)
                }
            } else {
                var finalX = root.clampWinX(dragProxy.x, root.winW)
                var finalY = root.clampWinY(dragProxy.y, root.winH)
                dragProxy.x = finalX
                dragProxy.y = finalY
                root.winX = finalX
                root.winY = finalY
                var addr = root.cleanAddr(root.winAddr)
                if (addr) {
                    root.dispatchLua('hl.dsp.window.move({ x = ' + finalX + ', y = ' + finalY + ', relative = false, window = "address:' + addr + '" })')
                }
            }
        }
        settleTimer.restart()
    }

    // ── Ícones de aplicativos e janelas na barra do sistema ───
    Row {
        id: minAppsRow
        spacing: 4
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: root.barSize
        visible: root.shouldShowAppsInBar && root.barAppsList.length > 0

        Repeater {
            model: root.barAppsList
            delegate: Rectangle {
                id: appTile
                required property var modelData
                required property int index

                implicitWidth: 26
                implicitHeight: 26
                width: 26
                height: 26
                radius: 6
                color: {
                    if (tileMouse.containsMouse) {
                        return modelData.state === "active" ? Qt.rgba(1, 1, 1, 0.22) :
                               modelData.state === "running" ? Qt.rgba(1, 1, 1, 0.16) :
                               modelData.state === "minimized" ? Qt.rgba(1, 1, 1, 0.14) :
                               Qt.rgba(1, 1, 1, 0.12)
                    }
                    return modelData.state === "active" ? Qt.rgba(1, 1, 1, 0.14) :
                           modelData.state === "running" ? Qt.rgba(1, 1, 1, 0.06) :
                           modelData.state === "minimized" ? Qt.rgba(1, 1, 1, 0.04) :
                           "transparent"
                }
                border.color: {
                    if (modelData.state === "active") return Qt.rgba(root.effAccent.r, root.effAccent.g, root.effAccent.b, 0.5)
                    if (tileMouse.containsMouse) return Qt.rgba(1, 1, 1, 0.22)
                    return "transparent"
                }
                border.width: 1
                Behavior on color { ColorAnimation { duration: 80 } }

                Image {
                    id: appIco
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize.width: 16
                    sourceSize.height: 16
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    opacity: (modelData.state === "minimized") ? 0.55 : ((modelData.state === "closed") ? 0.8 : 1.0)
                    source: {
                        var ico = modelData.icon || ""
                        if (!ico) return ""
                        if (ico.indexOf("file://") === 0) return ico
                        if (ico.charAt(0) === "/") return "file://" + ico
                        return ""
                    }
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !appIco.visible
                    text: (modelData.name || modelData.appId || "?").substring(0, 1).toUpperCase()
                    color: root.effAccent
                    font.pixelSize: 11
                    font.bold: true
                }

                // Indicador de estado (ativo, em execução, minimizado)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: modelData.state !== "closed"
                    width: (modelData.state === "active") ? 10 : 4
                    height: (modelData.state === "active") ? 2.5 : 2
                    radius: 1.25
                    color: (modelData.state === "minimized") ? root.themeMuted : root.effAccent
                    opacity: (modelData.state === "active") ? 1.0 : ((modelData.state === "running") ? 0.85 : 0.65)
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        var title = modelData.title ? (modelData.name + " — " + modelData.title) : (modelData.name || modelData.appId || root.t("untitled"))
                        try {
                            if (root.parent && root.parent.bar && root.parent.bar.showTooltip) {
                                root.parent.bar.showTooltip(appTile, title)
                            } else if (root.bar && root.bar.showTooltip) {
                                root.bar.showTooltip(appTile, title)
                            }
                        } catch(e) {}
                    }
                    onExited: {
                        try {
                            if (root.parent && root.parent.bar && root.parent.bar.hideTooltip) {
                                root.parent.bar.hideTooltip(appTile)
                            } else if (root.bar && root.bar.hideTooltip) {
                                root.bar.hideTooltip(appTile)
                            }
                        } catch(e) {}
                    }

                    onClicked: mouse => {
                        try {
                            if (root.parent && root.parent.bar && root.parent.bar.hideTooltip) {
                                root.parent.bar.hideTooltip(appTile)
                            } else if (root.bar && root.bar.hideTooltip) {
                                root.bar.hideTooltip(appTile)
                            }
                        } catch(e) {}

                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.state === "active") {
                                root.minimizeWindow(modelData.address)
                            } else if (modelData.state === "running") {
                                root.focusWindow(modelData.address)
                            } else if (modelData.state === "minimized") {
                                root.restoreWindow(modelData.address)
                            } else if (modelData.state === "closed") {
                                root.launchApp(modelData.appId)
                            }
                        } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                            if (modelData.state !== "closed" && modelData.address) {
                                root.closeWindow(modelData.address)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── PanelWindow — Overlay Flutuante Global ────────────────
    PanelWindow {
        id: fw

        WlrLayershell.namespace: "mouse-first-controls"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // Input mask: somente as áreas interativas recebem cliques (em drag, a tela toda recebe)
        mask: Region {
            Region { item: (root.isDragging || root.dragInitiated || root.isMenuDragging) ? overlayRoot : null }
            Region { item: settingsBackdrop.visible ? settingsBackdrop : null }
            Region { item: minDropBackdrop.visible ? minDropBackdrop : null }
            Region { item: settingsWin.visible ? settingsWin : null }
            Region { item: minDropPanel.visible ? minDropPanel : null }
            Region { item: (root.hasWindow && root.dragFullWidth) ? dragHandleZone : null }
            Region { item: controlPanel.visible ? controlPanel : null }
        }

        Item {
            id: overlayRoot
            anchors.fill: parent

            // ── Sombra de Preview de Snapping (Aero Snap / Light Tiling) ──
            Rectangle {
                id: snapPreview
                property bool active: root.isDragging && root.snapZone !== ""
                visible: opacity > 0.01
                opacity: active ? 1.0 : 0.0
                x: root.snapTargetX
                y: root.snapTargetY
                width: root.snapTargetW
                height: root.snapTargetH
                radius: 12
                color: Qt.rgba(0.48, 0.64, 0.97, 0.16)
                border.color: root.effAccent
                border.width: 2
                z: 2

                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }

            // ── Backdrop para fechar Settings ao clicar fora ───
            MouseArea {
                id: settingsBackdrop
                anchors.fill: parent
                visible: settingsWin.visible
                z: 90
                onClicked: settingsWin.visible = false
            }

            // ── Backdrop para fechar Dropdown de Minimizadas ────
            MouseArea {
                id: minDropBackdrop
                anchors.fill: parent
                visible: minDropPanel.visible
                z: 140
                onClicked: root.showMinimizedPanel = false
            }

            // ── Item de Drag Nativo (QtQuick C++ Drag Engine) ──
            Item {
                id: dragProxy
                visible: root.hasWindow
                x: root.winX
                y: root.winY
                width: root.winW
                height: 8

                Binding {
                    target: dragProxy
                    property: "x"
                    value: root.winX
                    when: !root.isDragging
                }
                Binding {
                    target: dragProxy
                    property: "y"
                    value: root.winY
                    when: !root.isDragging
                }
                Binding {
                    target: dragProxy
                    property: "width"
                    value: root.winW
                }

                onXChanged: {
                    if (root.isDragging) {
                        root.winX = dragProxy.x
                        root.dragNeedsDispatch = true
                        if (!dragMoveTimer.running) dragMoveTimer.running = true
                    }
                }
                onYChanged: {
                    if (root.isDragging) {
                        root.winY = dragProxy.y
                        root.dragNeedsDispatch = true
                        if (!dragMoveTimer.running) dragMoveTimer.running = true
                    }
                }

                // Linha visual elegante centralizada na janela
                Rectangle {
                    id: topDragIndicator
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(160, Math.min(parent.width - 160, Math.round(parent.width * 0.45)))
                    height: 3
                    radius: 1.5
                    color: root.effAccent
                    visible: root.dragFullWidth
                    opacity: (dragTopMouse.containsMouse || root.isDragging) ? 0.65 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                // Zona de arrasto ampla no cabeçalho (preserva botões na esquerda e controles na direita)
                Item {
                    id: dragHandleZone
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    // Deixa margem para botões de voltar/refresh em webapps quando flutuante normal;
                    // quando ancorada ou maximizada, cobre desde o canto esquerdo para un-snap imediato
                    anchors.leftMargin: (root.preSnapSizes[root.winAddr] || root.winMax) ? 6 : 72
                    anchors.rightMargin: Math.max(120, bubble.width + 12)
                    height: 8

                    MouseArea {
                        id: dragTopMouse
                        anchors.fill: parent
                        enabled: root.dragFullWidth
                        hoverEnabled: root.dragFullWidth
                        cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.triggerBtn("maximize")
                            }
                        }

                        onPressed: mouse => {
                            var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                            root.handlePress(pt.x, pt.y, mouse.button === Qt.RightButton)
                        }

                        onPositionChanged: mouse => {
                            var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                            root.handlePositionChanged(pt.x, pt.y)
                        }

                        onReleased: {
                            root.handleRelease()
                        }

                        onCanceled: {
                            root.handleRelease()
                        }
                    }
                }
            }

            // ── Barra Flutuante de Controles ──────────────────
            Item {
                id: controlPanel
                visible: root.hasWindow
                z: 50

                property bool isHovered: false

                Timer {
                    id: hideTimer
                    interval: 500
                    onTriggered: controlPanel.isHovered = false
                }

                // Posicionamento GLUADO diretamente no canto superior direito da janela com offset customizado
                x: {
                    var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                    var curX = (root.isDragging ? dragProxy.x : root.winX)
                    var curW = (root.isDragging ? dragProxy.width : root.winW)
                    return Math.max(0, Math.min(sW - bubble.width, curX + curW - bubble.width + root.curMenuOffsetX))
                }
                y: {
                    var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                    var curY = (root.isDragging ? dragProxy.y : root.winY)
                    return Math.max(root.reservedTop, Math.min(sH - bubble.height, curY + root.curMenuOffsetY))
                }
                width: bubble.width
                height: bubble.height

                opacity: {
                    if (root.alwaysVisible) return 1.0
                    return (controlPanel.isHovered || bubbleHover.containsMouse || settingsWin.visible) ? 1.0 : 0.0
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Zona de aproximação do hover
                MouseArea {
                    anchors.centerIn: parent
                    width: parent.width + 24
                    height: parent.height + 16
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        hideTimer.stop()
                        controlPanel.isHovered = true
                    }
                    onExited: {
                        hideTimer.restart()
                    }
                }

                Rectangle {
                    id: bubble
                    height: 34
                    radius: 10
                    color: root.effBg
                    border.color: Qt.rgba(1,1,1, root.themeMode === "dark" ? 0.20 : 0.30)
                    border.width: 1

                    implicitWidth: {
                        var n = root.buttonOrder.filter(b => root.buttonVisible[b] !== false).length
                        return 6 + (root.showDragHandle ? 24 : 0) + n * 28 + Math.max(0, n-1) * 4 + 6
                    }
                    width: implicitWidth

                    MouseArea {
                        id: bubbleHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                settingsWin.visible = !settingsWin.visible
                            }
                        }
                        onEntered: {
                            hideTimer.stop()
                            controlPanel.isHovered = true
                        }
                        onExited: {
                            hideTimer.restart()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 4

                        // Alça de Drag opcional
                        Item {
                            visible: root.showDragHandle
                            implicitWidth: 22
                            implicitHeight: 28
                            Column {
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: 3
                                    Row {
                                        spacing: 3
                                        Repeater {
                                            model: 2
                                            Rectangle {
                                                width: 3
                                                height: 3
                                                radius: 1.5
                                                color: root.effFg
                                                opacity: handleMouse.containsMouse ? 0.75 : 0.28
                                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                            }
                                        }
                                    }
                                }
                            }
                            MouseArea {
                                id: handleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.SizeAllCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onPressed: mouse => {
                                    var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                                    root.handlePress(pt.x, pt.y, mouse.button === Qt.RightButton)
                                }
                                onPositionChanged: mouse => {
                                    var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                                    root.handlePositionChanged(pt.x, pt.y)
                                }
                                onReleased: {
                                    root.handleRelease()
                                }
                                onCanceled: {
                                    root.handleRelease()
                                }
                            }
                        }

                        // Botões da Janela
                        Repeater {
                            model: root.buttonOrder
                            delegate: Rectangle {
                                required property string modelData
                                property string bid: modelData
                                visible: root.buttonVisible[bid] !== false
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 7
                                readonly property bool hov: bma.containsMouse
                                readonly property bool prs: bma.pressed
                                readonly property bool isClose:  bid === "close"
                                readonly property bool isAccent: bid === "float" && root.winFloat
                                readonly property color iconColor: (hov && isClose) ? "white" : (isAccent ? root.effAccent : Qt.rgba(1, 1, 1, 0.85))

                                color: {
                                    if (prs && isClose)  return Qt.rgba(0.85,0.15,0.15,0.9)
                                    if (hov && isClose)  return Qt.rgba(0.9,0.2,0.2,0.70)
                                    if (prs && isAccent) return Qt.rgba(0.47,0.64,0.97,0.35)
                                    if (hov && isAccent) return Qt.rgba(0.47,0.64,0.97,0.20)
                                    if (prs)             return Qt.rgba(1,1,1,0.15)
                                    if (hov)             return Qt.rgba(1,1,1,0.09)
                                    return "transparent"
                                }
                                Behavior on color { ColorAnimation { duration: 80 } }

                                // Desenho consistente e vetorial dos ícones
                                Item {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14

                                    // Minimizar: barra horizontal nítida de 10x2px
                                    Rectangle {
                                        visible: bid === "minimize"
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 2
                                        radius: 1
                                        color: iconColor
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }

                                    // Maximizar (quando não maximizada): quadrado vazado nítido de 10x10px
                                    Rectangle {
                                        visible: bid === "maximize" && !root.winMax
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 1.5
                                        color: "transparent"
                                        border.color: iconColor
                                        border.width: 1.5
                                        Behavior on border.color { ColorAnimation { duration: 80 } }
                                    }

                                    // Restaurar (quando maximizada): dois quadrados sobrepostos consistentes
                                    Item {
                                        visible: bid === "maximize" && root.winMax
                                        anchors.centerIn: parent
                                        width: 11
                                        height: 11
                                        Rectangle {
                                            x: 2; y: 0; width: 8; height: 8; radius: 1
                                            color: "transparent"
                                            border.color: iconColor
                                            border.width: 1.2
                                            Behavior on border.color { ColorAnimation { duration: 80 } }
                                        }
                                        Rectangle {
                                            x: 0; y: 3; width: 8; height: 8; radius: 1
                                            color: (hov && isClose) ? "white" : root.effBg
                                            border.color: iconColor
                                            border.width: 1.2
                                            Behavior on border.color { ColorAnimation { duration: 80 } }
                                        }
                                    }

                                    // Fechar: dois traços vetoriais cruzados nítidos e proporcionais
                                    Item {
                                        visible: bid === "close"
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 13.5
                                            height: 1.8
                                            radius: 0.9
                                            rotation: 45
                                            color: iconColor
                                            antialiasing: true
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 13.5
                                            height: 1.8
                                            radius: 0.9
                                            rotation: -45
                                            color: iconColor
                                            antialiasing: true
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                    }

                                    // Float/Tile
                                    Text {
                                        visible: bid === "float"
                                        anchors.centerIn: parent
                                        text: root.winFloat ? "⧉" : "⊡"
                                        color: iconColor
                                        font.pixelSize: 12
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }
                                }

                                Rectangle {
                                    visible: hov
                                    anchors.bottom: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 5
                                    width: ttxt.implicitWidth + 14
                                    height: ttxt.implicitHeight + 8
                                    radius: 5
                                    color: Qt.rgba(0,0,0,0.85)
                                    border.color: Qt.rgba(1,1,1,0.12)
                                    border.width: 1
                                    z: 200
                                    Text {
                                        id: ttxt
                                        anchors.centerIn: parent
                                        text: root.btnTooltip(bid)
                                        color: "white"
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: bma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            settingsWin.visible = !settingsWin.visible
                                        } else {
                                            root.triggerBtn(bid)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Indicador fino de arrasto na borda inferior do menu (aparece no hover/drag ou sempre se alwaysShowMenuDragZone)
                    Rectangle {
                        id: menuDragLine
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 2
                        width: Math.min(parent.width - 24, 34)
                        height: 2
                        radius: 1
                        color: root.effAccent
                        visible: root.enableMenuDrag
                        opacity: (root.alwaysShowMenuDragZone || menuDragArea.containsMouse || root.isMenuDragging) ? 0.85 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    MouseArea {
                        id: menuDragArea
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width - 16, 46)
                        height: 5
                        enabled: root.enableMenuDrag
                        hoverEnabled: root.enableMenuDrag
                        cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton
                        z: 20

                        onEntered: {
                            hideTimer.stop()
                            controlPanel.isHovered = true
                        }
                        onExited: {
                            if (!root.isMenuDragging) hideTimer.restart()
                        }

                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.resetMenuOffset()
                            }
                        }

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                                root.menuDragStartMouseX = pt.x
                                root.menuDragStartMouseY = pt.y
                                root.menuDragStartOffsetX = root.curMenuOffsetX
                                root.menuDragStartOffsetY = root.curMenuOffsetY
                                root.isMenuDragging = true
                            }
                        }

                        onPositionChanged: mouse => {
                            if (!root.isMenuDragging) return
                            var pt = mapToItem(overlayRoot, mouse.x, mouse.y)
                            var dx = pt.x - root.menuDragStartMouseX
                            var dy = pt.y - root.menuDragStartMouseY

                            var sW = (overlayRoot.width > 0 ? overlayRoot.width : Screen.width)
                            var sH = (overlayRoot.height > 0 ? overlayRoot.height : Screen.height)
                            var baseMenuX = dragProxy.x + dragProxy.width - bubble.width
                            var baseMenuY = dragProxy.y

                            var rawOffX = root.menuDragStartOffsetX + dx
                            var rawOffY = root.menuDragStartOffsetY + dy

                            var minOffX = -baseMenuX
                            var maxOffX = sW - bubble.width - baseMenuX
                            var minOffY = root.reservedTop - baseMenuY
                            var maxOffY = sH - bubble.height - baseMenuY

                            root.curMenuOffsetX = Math.round(Math.max(minOffX, Math.min(maxOffX, rawOffX)))
                            root.curMenuOffsetY = Math.round(Math.max(minOffY, Math.min(maxOffY, rawOffY)))
                        }

                        onReleased: {
                            root.finishMenuDrag()
                        }

                        onCanceled: {
                            root.finishMenuDrag()
                        }
                    }
                }
            }

            // ── Painel de Configurações ────────────────────────
            Rectangle {
                id: settingsWin
                visible: false
                onVisibleChanged: {
                    if (visible) {
                        if (root.detectedSection !== "") {
                            root.barSection = root.detectedSection
                        } else if (!checkBarSectionProc.running) {
                            checkBarSectionProc.running = true
                        }
                    }
                }
                z: 100
                x: Math.max(8, Math.min((fw.width > 0 ? fw.width : Screen.width) - width - 8, controlPanel.x + controlPanel.width - width))
                y: Math.max(40, Math.min((fw.height > 0 ? fw.height : Screen.height) - height - 8, controlPanel.y + controlPanel.height + 8))
                width: 390
                height: sCol.implicitHeight + 32
                radius: 12
                color: root.effBg
                border.color: Qt.rgba(1,1,1,0.12)
                border.width: 1

                MouseArea { anchors.fill: parent }

                Column {
                    id: sCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 12

                    Text { text: root.t("settingsTitle"); color: root.effFg; font.pixelSize: 14; font.bold: true; width: parent.width }
                    Text { text: root.t("settingsHint"); color: root.themeMuted; font.pixelSize: 10; width: parent.width }
                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                    // Comportamento Global de Tiling
                    Text { text: root.t("systemBehavior"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("disableTiling")
                        sublabel: root.t("disableTilingSub")
                        checked: root.disableTiling
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: {
                            root.disableTiling = !root.disableTiling
                            root.saveConfig()
                        }
                    }

                    // Janelas Minimizadas na Barra do Sistema
                    Text { text: root.t("minimizedSectionTitle"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("minimizeToBar")
                        sublabel: root.t("minimizeToBarSub")
                        checked: root.minimizeToBar
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: {
                            root.minimizeToBar = !root.minimizeToBar
                            root.saveConfig()
                        }
                    }

                    Column {
                        width: parent.width - 16
                        x: 16
                        spacing: 6
                        opacity: root.minimizeToBar ? 1.0 : 0.35
                        enabled: root.minimizeToBar
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            text: root.t("minimizedAppsLocation")
                            color: root.effFg
                            font.pixelSize: 12
                            width: parent.width
                            wrapMode: Text.Wrap
                        }
                        Text {
                            text: root.t("minimizedAppsLocationSub")
                            color: root.themeMuted
                            font.pixelSize: 10
                            width: parent.width
                            wrapMode: Text.Wrap
                        }

                        Row {
                            spacing: 24
                            topPadding: 4

                            Repeater {
                                model: [
                                    { id: "left", label: root.t("locLeft") },
                                    { id: "center", label: root.t("locCenter") },
                                    { id: "right", label: root.t("locRight") }
                                ]
                                delegate: Item {
                                    id: radioItem
                                    required property var modelData
                                    readonly property bool isSelected: root.barSection === (radioItem.modelData ? radioItem.modelData.id : "")
                                    width: radioRow.implicitWidth
                                    height: 24

                                    Row {
                                        id: radioRow
                                        spacing: 8
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: "transparent"
                                            border.color: radioItem.isSelected ? root.effAccent : Qt.rgba(1,1,1,0.25)
                                            border.width: 1.5
                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: root.effAccent
                                                visible: radioItem.isSelected
                                                opacity: radioItem.isSelected ? 1.0 : 0
                                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: radioItem.modelData ? radioItem.modelData.label : ""
                                            color: radioItem.isSelected ? root.effFg : root.themeMuted
                                            font.pixelSize: 11
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: root.minimizeToBar
                                        onClicked: {
                                            root.barSection = radioItem.modelData.id
                                            root.setBarSection(radioItem.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Visibilidade
                    Text { text: root.t("visibility"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("alwaysVisible")
                        sublabel: root.t("alwaysVisibleSub")
                        checked: root.alwaysVisible
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.alwaysVisible = !root.alwaysVisible; root.saveConfig() }
                    }

                    // Drag
                    Text { text: root.t("dragging"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("dragZone")
                        sublabel: root.t("dragZoneSub")
                        checked: root.dragFullWidth
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.dragFullWidth = !root.dragFullWidth; root.saveConfig() }
                    }
                    SettingsToggle {
                        label: root.t("dragHandle")
                        sublabel: root.t("dragHandleSub")
                        checked: root.showDragHandle
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.showDragHandle = !root.showDragHandle; root.saveConfig() }
                    }
                    SettingsToggle {
                        label: root.t("ignoreDock")
                        sublabel: root.t("ignoreDockSub")
                        checked: root.ignoreDock
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.ignoreDock = !root.ignoreDock; root.saveConfig() }
                    }
                    SettingsToggle {
                        label: root.t("disableSnapping")
                        sublabel: root.t("disableSnappingSub")
                        checked: root.disableSnapping
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.disableSnapping = !root.disableSnapping; root.saveConfig() }
                    }

                    // Reposicionamento dos Controles Flutuantes
                    Text { text: root.t("menuDragging"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("enableMenuDrag")
                        sublabel: root.t("enableMenuDragSub")
                        checked: root.enableMenuDrag
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: {
                            root.enableMenuDrag = !root.enableMenuDrag
                            if (!root.enableMenuDrag) {
                                root.curMenuOffsetX = 0
                                root.curMenuOffsetY = 0
                            } else {
                                root.updateMenuOffsetForActiveWindow(root.winAddr, root.winClass)
                            }
                            root.saveConfig()
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8
                        opacity: root.enableMenuDrag ? 1.0 : 0.35
                        enabled: root.enableMenuDrag
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        SettingsToggle {
                            width: parent.width - 16
                            x: 16
                            label: root.t("rememberMenuPerWindow")
                            sublabel: root.t("rememberMenuPerWindowSub")
                            checked: root.rememberMenuPerWindow
                            accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                            onToggled: {
                                root.rememberMenuPerWindow = !root.rememberMenuPerWindow
                                if (root.rememberMenuPerWindow) {
                                    root.rememberMenuGlobal = false
                                }
                                root.updateMenuOffsetForActiveWindow(root.winAddr, root.winClass)
                                root.saveConfig()
                            }
                        }

                        SettingsToggle {
                            width: parent.width - 16
                            x: 16
                            label: root.t("rememberMenuGlobal")
                            sublabel: root.t("rememberMenuGlobalSub")
                            checked: root.rememberMenuGlobal
                            accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                            onToggled: {
                                root.rememberMenuGlobal = !root.rememberMenuGlobal
                                if (root.rememberMenuGlobal) {
                                    root.rememberMenuPerWindow = false
                                }
                                root.updateMenuOffsetForActiveWindow(root.winAddr, root.winClass)
                                root.saveConfig()
                            }
                        }

                        SettingsToggle {
                            width: parent.width - 16
                            x: 16
                            label: root.t("alwaysShowMenuDragZone")
                            sublabel: root.t("alwaysShowMenuDragZoneSub")
                            checked: root.alwaysShowMenuDragZone
                            accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                            onToggled: {
                                root.alwaysShowMenuDragZone = !root.alwaysShowMenuDragZone
                                root.saveConfig()
                            }
                        }
                    }

                    // Botões
                    Text { text: root.t("buttonsTitle"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    Text { text: root.t("buttonsHint"); color: root.themeMuted; font.pixelSize: 10; width: parent.width; wrapMode: Text.Wrap }

                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.buttonOrder
                            delegate: Rectangle {
                                required property string modelData
                                required property int    index
                                property string bid: modelData
                                width: parent.width
                                height: 40
                                radius: 8
                                color: Qt.rgba(1,1,1,0.04)
                                border.color: Qt.rgba(1,1,1,0.07)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Rectangle {
                                        width: 26; height: 26; radius: 6
                                        color: Qt.rgba(1,1,1,0.07)
                                        Item {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            Rectangle {
                                                visible: bid === "minimize"
                                                anchors.centerIn: parent
                                                width: 10; height: 2; radius: 1; color: root.effFg
                                            }
                                            Rectangle {
                                                visible: bid === "maximize"
                                                anchors.centerIn: parent
                                                width: 10; height: 10; radius: 1.5; color: "transparent"; border.color: root.effFg; border.width: 1.5
                                            }
                                            Item {
                                                visible: bid === "close"
                                                anchors.centerIn: parent
                                                width: 12; height: 12
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 12; height: 2; radius: 1
                                                    rotation: 45; color: root.effRed; antialiasing: true
                                                }
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 12; height: 2; radius: 1
                                                    rotation: -45; color: root.effRed; antialiasing: true
                                                }
                                            }
                                            Text {
                                                visible: bid === "float"
                                                anchors.centerIn: parent
                                                text: "⧉"; color: root.effFg; font.pixelSize: 12
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.btnLabel(bid)
                                        color: root.effFg
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        spacing: 2
                                        Rectangle {
                                            width: 22; height: 22; radius: 5
                                            color: upMa.containsMouse && index > 0 ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.04)
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "↑"
                                                color: index > 0 ? root.effFg : root.themeMuted
                                                font.pixelSize: 13
                                                opacity: index > 0 ? 1.0 : 0.25
                                            }
                                            MouseArea { id: upMa; anchors.fill: parent; hoverEnabled: true; enabled: index > 0; onClicked: root.moveButton(index, -1) }
                                        }
                                        Rectangle {
                                            width: 22; height: 22; radius: 5
                                            color: dnMa.containsMouse && index < root.buttonOrder.length-1 ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.04)
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "↓"
                                                color: index < root.buttonOrder.length-1 ? root.effFg : root.themeMuted
                                                font.pixelSize: 13
                                                opacity: index < root.buttonOrder.length-1 ? 1.0 : 0.25
                                            }
                                            MouseArea { id: dnMa; anchors.fill: parent; hoverEnabled: true; enabled: index < root.buttonOrder.length-1; onClicked: root.moveButton(index, 1) }
                                        }
                                    }

                                    Rectangle {
                                        id: vp
                                        width: 36; height: 20; radius: 10
                                        property bool on: root.buttonVisible[bid] !== false
                                        color: on ? root.effAccent : Qt.rgba(1,1,1,0.12)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Rectangle {
                                            x: vp.on ? 18 : 2; y: 2; width: 16; height: 16; radius: 8; color: "white"
                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                var bv = Object.assign({}, root.buttonVisible)
                                                bv[bid] = !vp.on
                                                root.buttonVisible = bv
                                                root.saveConfig()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Cor
                    Text { text: root.t("colorTitle"); color: root.themeMuted; font.pixelSize: 9; font.bold: true; width: parent.width }
                    SettingsToggle {
                        label: root.t("themeFollow")
                        sublabel: root.t("themeFollowSub")
                        checked: root.colorMode === "theme"
                        accentColor: root.effAccent; fgColor: root.effFg; mutedColor: root.themeMuted
                        onToggled: { root.colorMode = root.colorMode === "theme" ? "custom" : "theme"; root.saveConfig() }
                    }

                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }
                    Rectangle {
                        width: parent.width; height: 32; radius: 6
                        color: csm.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: root.t("closeSettings"); color: root.themeMuted; font.pixelSize: 12 }
                        MouseArea { id: csm; anchors.fill: parent; hoverEnabled: true; onClicked: settingsWin.visible = false }
                    }
                    Item { height: 4 }
                }
            }

            // ── Dropdown minimizadas (unclipped no overlay) ────────
            Rectangle {
                id: minDropPanel
                visible: root.showMinimizedPanel && root.minimizedWindows.length > 0
                x: {
                    try {
                        var pt = root.mapToItem(null, 0, 0)
                        return Math.max(10, Math.min((fw.width > 0 ? fw.width : Screen.width) - width - 10, pt.x))
                    } catch(e) {
                        return 10
                    }
                }
                y: 36
                width: 280
                height: minCol.implicitHeight + 16
                radius: 8
                z: 150
                color: Qt.rgba(0.06, 0.07, 0.10, 0.95)
                border.color: Qt.rgba(1,1,1,0.10)
                border.width: 1

                Column {
                    id: minCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 8
                    spacing: 2

                    Repeater {
                        model: root.minimizedWindows
                        Rectangle {
                            width: minCol.width
                            height: 34
                            radius: 6
                            color: rMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Rectangle {
                                id: ico
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                radius: 5
                                color: Qt.rgba(0.47, 0.64, 0.97, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.class || "?").substring(0,1).toUpperCase()
                                    color: "#7aa2f7"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.left: ico.right
                                anchors.leftMargin: 8
                                anchors.right: xBtn.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title || modelData.class || root.t("untitled")
                                color: "white"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: xBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                radius: 10
                                visible: rMouse.containsMouse || xMouse.containsMouse
                                color: xMouse.containsMouse ? Qt.rgba(0.9,0.2,0.2,0.8) : Qt.rgba(1,1,1,0.08)
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 12; font.bold: true }
                                MouseArea {
                                    id: xMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var clean = root.cleanAddr(modelData.address)
                                        if (clean) root.dispatchLua('hl.dsp.window.close({ window = "address:' + clean + '" })')
                                        listProc.running = true
                                    }
                                }
                            }

                            MouseArea {
                                id: rMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.showMinimizedPanel = false
                                    restoreProc.addr = modelData.address
                                    restoreProc.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Componente reutilizável SettingsToggle ────────────────
    component SettingsToggle: Item {
        id: tog
        property string label:      ""
        property string sublabel:   ""
        property bool   checked:    false
        property string accentColor: "#7aa2f7"
        property string fgColor:    "#a9b1d6"
        property string mutedColor: "#414868"
        signal toggled()

        width: parent ? parent.width : 300
        height: Math.max(36, labelCol.implicitHeight + 10)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.right: togPill.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: tog.label
                color: tog.fgColor
                font.pixelSize: 12
                width: parent.width
                wrapMode: Text.Wrap
            }
            Text {
                visible: tog.sublabel !== ""
                text: tog.sublabel
                color: tog.mutedColor
                font.pixelSize: 10
                width: parent.width
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            id: togPill
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 20; radius: 10
            color: tog.checked ? tog.accentColor : Qt.rgba(1,1,1,0.12)
            Behavior on color { ColorAnimation { duration: 150 } }
            Rectangle {
                x: tog.checked ? 18 : 2; y: 2; width: 16; height: 16; radius: 8; color: "white"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: tog.toggled() }
    }
}
