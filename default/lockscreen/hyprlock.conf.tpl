# Generated from the shared Prometheus style by render.py.
general {
    hide_cursor = true
}

background {
    monitor =
    path = /usr/share/sddm/themes/prometheus/background.jpg
    color = @BACKGROUND_COLOR@
    blur_passes = 3
    blur_size = 8
}

label {
    monitor =
    text = <b>$TIME</b>
    color = @COLOR@
    font_family = @FONT@
    font_size = @CLOCK_SIZE@
    position = 0, -50
    halign = center
    valign = top
}

label {
    monitor =
    text = cmd[update:1000] date +"%A, %B %d, %Y"
    color = @COLOR@
    font_family = @FONT@
    font_size = @DATE_SIZE@
    position = 0, -160
    halign = center
    valign = top
}

label {
    monitor =
    text = <b>$USER</b>
    color = @COLOR@
    font_family = @FONT@
    font_size = @USER_SIZE@
    position = 0, 40
    halign = center
    valign = center
}

input-field {
    monitor =
    size = @INPUT_WIDTH@, @INPUT_HEIGHT@
    outline_thickness = 0
    rounding = @RADIUS@
    inner_color = @INPUT_COLOR@
    font_color = @COLOR@
    font_family = @FONT@
    placeholder_text = Password
    fail_text = <i>$PAMFAIL</i>
    fade_on_empty = false
    dots_size = 0.25
    dots_spacing = 0.3
    position = 0, -10
    halign = center
    valign = center
}

label {
    monitor =
    text = Type your password and press Enter
    color = @COLOR@
    font_family = @FONT@
    font_size = 12
    position = 0, 50
    halign = center
    valign = bottom
}
