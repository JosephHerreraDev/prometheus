import QtQuick

QtObject {
  readonly property color background: "{{ background }}"
  readonly property color foreground: "{{ foreground }}"
  readonly property color accent: "{{ accent }}"
  readonly property color selectionForeground: "{{ selection_foreground }}"
  readonly property color selectionBackground: "{{ selection_background }}"
  readonly property color cursor: "{{ cursor }}"

  readonly property color color0: background
  readonly property color color1: "{{ color0 }}"
  readonly property color color2: "{{ color8 }}"
  readonly property color color3: selectionBackground
  readonly property color color4: foreground
  readonly property color color5: "{{ color7 }}"
  readonly property color color6: "{{ color15 }}"
  readonly property color color7: "{{ color14 }}"
  readonly property color color8: "{{ color6 }}"
  readonly property color color9: accent
  readonly property color color10: "{{ color12 }}"
  readonly property color color11: "{{ color1 }}"
  readonly property color color12: "{{ color9 }}"
  readonly property color color13: "{{ color3 }}"
  readonly property color color14: "{{ color2 }}"
  readonly property color color15: "{{ color5 }}"

  readonly property color terminalColor0: "{{ color0 }}"
  readonly property color terminalColor1: "{{ color1 }}"
  readonly property color terminalColor2: "{{ color2 }}"
  readonly property color terminalColor3: "{{ color3 }}"
  readonly property color terminalColor4: "{{ color4 }}"
  readonly property color terminalColor5: "{{ color5 }}"
  readonly property color terminalColor6: "{{ color6 }}"
  readonly property color terminalColor7: "{{ color7 }}"
  readonly property color terminalColor8: "{{ color8 }}"
  readonly property color terminalColor9: "{{ color9 }}"
  readonly property color terminalColor10: "{{ color10 }}"
  readonly property color terminalColor11: "{{ color11 }}"
  readonly property color terminalColor12: "{{ color12 }}"
  readonly property color terminalColor13: "{{ color13 }}"
  readonly property color terminalColor14: "{{ color14 }}"
  readonly property color terminalColor15: "{{ color15 }}"
}
