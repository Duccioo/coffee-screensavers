#!/usr/bin/env bash

# Grayscale Perlin-ish Noise Screensaver (Pixel Art)
# Optimized: Half-width resolution for speed + Posterized for style.

_cleanup_and_exit() {
  tput cnorm; tput sgr0; echo; exit 0
}
trap _cleanup_and_exit EXIT INT TERM QUIT

GRID_W=12
GRID_H=8
declare -a NOISE_GRID
declare -a TARGET_GRID

# Init
for ((i=0; i<GRID_W*GRID_H; i++)); do
    NOISE_GRID[i]=$((RANDOM % 256))
    TARGET_GRID[i]=$((RANDOM % 256))
done

update_grid() {
    for ((i=0; i<GRID_W*GRID_H; i++)); do
        local current=${NOISE_GRID[i]}
        local target=${TARGET_GRID[i]}

        # Calculate difference
        local diff=$((target - current))

        if (( diff == 0 )); then
            # Reached target, pick new one
            TARGET_GRID[i]=$((RANDOM % 256))
        else
            # Move towards target with easing
            local step=$(( diff / 16 ))

            # Ensure minimum movement of 1 to prevent stalling
            if (( step == 0 )); then
                if (( diff > 0 )); then step=1; else step=-1; fi
            fi

            NOISE_GRID[i]=$(( current + step ))
        fi
    done
}

animate() {
    tput civis
    local width=$(tput cols)
    local height=$(tput lines)
    local delay=${SCREENSAVER_DELAY:-0.033}

    # Speed Optimization: Render at half horizontal resolution
    # This doubles performance and creates "square" pixels
    local calc_width=$((width / 2))
    if ((calc_width < 1)); then calc_width=1; fi

    local gw_minus_1=$((GRID_W - 1))
    local gh_minus_1=$((GRID_H - 1))

    # Segment width in calc_pixels
    local seg_w=$(( calc_width / gw_minus_1 ))
    if ((seg_w < 1)); then seg_w=1; fi

    # Palette: 5 distinct shades for posterized "Generative Art" look
    # Creates distinct "contour lines"
    local palette=(232 237 242 247 252)

    clear # Clear screen initially to prevent ghosts

    while true; do
        update_grid
        local frame_buffer="\e[H"

        for ((y=0; y<height; y++)); do
            # Vertical interpolation
            local y_scaled=$(( y * gh_minus_1 * 1000 / height ))
            local gy=$(( y_scaled / 1000 ))
            local ry=$(( y_scaled % 1000 ))
            local row_idx_1=$(( gy * GRID_W ))
            local row_idx_2=$(( (gy + 1) * GRID_W ))

            local current_row_vals=()
            for ((gx=0; gx<GRID_W; gx++)); do
                local v1=${NOISE_GRID[row_idx_1 + gx]}
                local v2=${NOISE_GRID[row_idx_2 + gx]}
                local v=$(( v1 + (v2 - v1) * ry / 1000 ))
                current_row_vals+=("$v")
            done

            local current_x=0 # In calc pixels
            local color=232 # Default color

            for ((gx=0; gx<gw_minus_1; gx++)); do
                local v_left=${current_row_vals[gx]}
                local v_right=${current_row_vals[gx+1]}

                local val_scaled=$(( v_left * 1000 ))
                local step_scaled=$(( (v_right - v_left) * 1000 / seg_w ))

                for ((k=0; k<seg_w; k++)); do
                     if ((current_x >= calc_width)); then break; fi

                     local val=$(( val_scaled / 1000 ))
                     val_scaled=$(( val_scaled + step_scaled ))

                     # Quantize / Posterize
                     local p_idx=$(( val * 5 / 256 ))
                     if ((p_idx > 4)); then p_idx=4; fi
                     if ((p_idx < 0)); then p_idx=0; fi

                     color=${palette[$p_idx]}

                     # Render DOUBLE SPACE for 1 calc pixel
                     frame_buffer+="\e[48;5;${color}m  "
                     current_x=$((current_x + 1))
                done
            done

            # Fill remaining calc pixels (margin fix)
            while ((current_x < calc_width)); do
                 frame_buffer+="\e[48;5;${color}m  "
                 current_x=$((current_x + 1))
            done

            # Fill remaining real pixels (if width is odd)
            if (( width % 2 != 0 )); then
                 frame_buffer+="\e[48;5;${color}m "
            fi

            frame_buffer+="\e[0m"
            if ((y < height - 1)); then frame_buffer+="\n"; fi
        done

        printf '%b' "$frame_buffer"
        sleep "$delay"
    done
}

animate
