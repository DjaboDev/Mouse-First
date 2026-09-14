#!/usr/bin/env bash
# install.sh — Mouse First para Omarchy Quattro
# Cole e execute: bash install.sh

set -euo pipefail

PLUGIN_ID="io.github.mousefirst.controls"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Instalando Mouse First para Omarchy Quattro..."

# 1. Copia arquivos
mkdir -p "$PLUGIN_DIR/bin"
cp "$SCRIPT_DIR/manifest.json"         "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/BarWidget.qml"         "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/bin/"*                 "$PLUGIN_DIR/bin/"
chmod +x "$PLUGIN_DIR/bin/"*
echo "    Arquivos copiados para $PLUGIN_DIR"

# 2. Posição na barra superior (interativo se terminal interativo)
BAR_SECTION="left"
if [[ -t 0 ]]; then
    options=("Left (padrão)" "Center" "Right")
    sections=("left" "center" "right")
    selected=0

    # Oculta o cursor durante a seleção interativa
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null || true' EXIT INT TERM

    echo ""
    echo "==> Onde você deseja posicionar os ícones de aplicativos na barra do sistema?"
    echo "    (Use as setas ↑ / ↓ para navegar e Enter para confirmar)"
    echo ""

    render_menu() {
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf "    \e[1;36m> [●] %s\e[0m\n" "${options[$i]}"
            else
                printf "      [ ] %s\n" "${options[$i]}"
            fi
        done
    }

    render_menu

    while true; do
        IFS= read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 1 key2 || true
            case "$key2" in
                '[A') # Seta para cima
                    selected=$(( (selected - 1 + 3) % 3 ))
                    ;;
                '[B') # Seta para baixo
                    selected=$(( (selected + 1) % 3 ))
                    ;;
            esac
            printf "\e[3A"
            render_menu
        elif [[ "$key" == "" ]]; then
            # Enter
            break
        elif [[ "$key" == "1" ]]; then
            selected=0
            break
        elif [[ "$key" == "2" ]]; then
            selected=1
            break
        elif [[ "$key" == "3" ]]; then
            selected=2
            break
        fi
    done

    tput cnorm 2>/dev/null || true
    trap - EXIT INT TERM
    BAR_SECTION="${sections[$selected]}"
    echo ""
fi
echo "    Posição selecionada na barra: $BAR_SECTION"

# 3. Configuração padrão (preto, segue tema)
CFG="$HOME/.config/omarchy/mouse-first.json"
if [[ ! -f "$CFG" ]]; then
    cat > "$CFG" << CFGEOF
{
  "language": "en",
  "disableTiling": true,
  "alwaysVisible": true,
  "dragFullWidth": true,
  "showDragHandle": false,
  "ignoreDock": false,
  "disableSnapping": false,
  "enableMenuDrag": true,
  "rememberMenuPerWindow": false,
  "rememberMenuGlobal": false,
  "alwaysShowMenuDragZone": false,
  "minimizeToBar": true,
  "barSection": "$BAR_SECTION",
  "globalMenuOffsetX": 0,
  "globalMenuOffsetY": 0,
  "perWindowClassOffsets": {},
  "buttonOrder": ["float", "minimize", "maximize", "close"],
  "buttonVisible": {
    "float": false,
    "minimize": true,
    "maximize": true,
    "close": true
  },
  "colorMode": "theme",
  "customBg": "#0e0e14",
  "customFg": "#a9b1d6",
  "customAccent": "#7aa2f7",
  "customRed": "#f7768e"
}
CFGEOF
    echo "    Configuração padrão criada em $CFG"
else
    # Atualiza barSection se a configuração já existir
    if command -v jq &>/dev/null; then
        tmp_cfg="\$(mktemp)"
        jq --arg sec "$BAR_SECTION" '.barSection = \$sec' "$CFG" > "\$tmp_cfg" && mv "\$tmp_cfg" "$CFG"
    fi
    echo "    Configuração existente mantida em $CFG (posição: $BAR_SECTION)"
fi

# 4. looknfeel.lua — janelas flutuantes por padrão e redimensionamento por borda
LOOKNFEEL="$HOME/.config/hypr/looknfeel.lua"
if [[ ! -f "$LOOKNFEEL" ]]; then
    cat > "$LOOKNFEEL" << 'LUAEOF'
-- looknfeel.lua — gerado pelo Mouse First
hl.config({
  general = {
    resize_on_border = true,
    extend_border_grab_area = 15,
    hover_icon_on_border = true,
  },
})

-- Janelas flutuantes e centralizadas por padrão
o.window(".*", { float = true, center = true })
o.window({ tag = "chromium-based-browser" }, { float = true, center = true, size = { "(monitor_w*85/100)", "(monitor_h*80/100)" } })
o.window("^(brave-.+|chrome-.+|chromium-.+|google-chrome-.+)$", { float = true, center = true, size = { "(monitor_w*85/100)", "(monitor_h*80/100)" } })
LUAEOF
    echo "    looknfeel.lua criado (janelas flutuantes por padrão)"
else
    echo "    looknfeel.lua já existe — não modificado"
fi

# 5. Habilita o plugin no shell
if command -v omarchy &>/dev/null; then
    echo "==> Habilitando plugin na seção $BAR_SECTION..."
    omarchy plugin enable "$PLUGIN_ID" --section "$BAR_SECTION" 2>/dev/null || true
fi

# 6. Recarrega
echo "==> Recarregando..."
hyprctl reload 2>/dev/null && echo "    hyprctl reload OK" || echo "    rode 'hyprctl reload' manualmente"
omarchy restart shell 2>/dev/null && echo "    shell reiniciado OK" || \
    echo "    rode 'omarchy restart shell' manualmente"

echo ""
echo "✓ Mouse First instalado!"
echo ""
echo "  A barra flutuante aparece no canto superior direito de cada janela."
echo "  Botões: Minimizar | Maximizar | Fechar"
echo "  Clique direito na barra → abre configurações."
echo "  Drag: passe o mouse pelo topo da janela e arraste."
echo ""
echo "  Para remover:"
echo "  omarchy plugin remove $PLUGIN_ID --yes"
