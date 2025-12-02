#!/usr/bin/env bash

# Rorschach Screensaver
# Generative symmetrical inkblot patterns
# Based on perlin-pixel with added symmetry logic

_cleanup_and_exit() {
  tput cnorm; tput sgr0; echo; exit 0
}
trap _cleanup_and_exit EXIT INT TERM QUIT

# Use a square grid to support diagonal symmetry
GRID_W=10
GRID_H=10
declare -a NOISE_GRID
declare -a TARGET_GRID

# Symmetry Mode
# 0 = Vertical (Rorschach Classic)
# 1 = Horizontal (Water Reflection)
# 2 = Diagonal (Cross)
# 3 = Quad (Vertical + Horizontal)
# 4 = Kaleidoscope (Vertical + Horizontal + Diagonal)
SYM_MODE=0

init_symmetry() {
    SYM_MODE=$((RANDOM % 5))
}

symmetrize_grid() {
    # Helper to copy Upper-Right Triangle to Lower-Left Triangle (Diagonal Mirror)
    if [[ $SYM_MODE -eq 2 || $SYM_MODE -eq 4 ]]; then
        for ((y=0; y<GRID_H; y++)); do
            for ((x=y+1; x<GRID_W; x++)); do
                local source_idx=$((y * GRID_W + x))
                local target_idx=$((x * GRID_W + y))
                NOISE_GRID[target_idx]=${NOISE_GRID[source_idx]}
                TARGET_GRID[target_idx]=${TARGET_GRID[source_idx]}
            done
        done
    fi

    # Helper to copy Left Half to Right Half (Vertical Mirror)
    if [[ $SYM_MODE -eq 0 || $SYM_MODE -eq 3 || $SYM_MODE -eq 4 ]]; then
        local half_w=$((GRID_W / 2))
        for ((y=0; y<GRID_H; y++)); do
            for ((x=0; x<half_w; x++)); do
                local source_idx=$((y * GRID_W + x))
                local target_idx=$((y * GRID_W + (GRID_W - 1 - x)))
                NOISE_GRID[target_idx]=${NOISE_GRID[source_idx]}
                TARGET_GRID[target_idx]=${TARGET_GRID[source_idx]}
            done
        done
    fi

    # Helper to copy Top Half to Bottom Half (Horizontal Mirror)
    if [[ $SYM_MODE -eq 1 || $SYM_MODE -eq 3 || $SYM_MODE -eq 4 ]]; then
        local half_h=$((GRID_H / 2))
        for ((y=0; y<half_h; y++)); do
            for ((x=0; x<GRID_W; x++)); do
                local source_idx=$((y * GRID_W + x))
                local target_idx=$(((GRID_H - 1 - y) * GRID_W + x))
                NOISE_GRID[target_idx]=${NOISE_GRID[source_idx]}
                TARGET_GRID[target_idx]=${TARGET_GRID[source_idx]}
            done
        done
    fi
}

# Init
init_symmetry
for ((i=0; i<GRID_W*GRID_H; i++)); do
    NOISE_GRID[i]=$((RANDOM % 256))
    TARGET_GRID[i]=$((RANDOM % 256))
done
symmetrize_grid

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
            # Faster speed: divide by 8 instead of 16
            local step=$(( diff / 8 ))

            # Ensure minimum movement of 1 to prevent stalling
            if (( step == 0 )); then
                if (( diff > 0 )); then step=1; else step=-1; fi
            fi

            NOISE_GRID[i]=$(( current + step ))
        fi
    done

    # Enforce symmetry after updates
    symmetrize_grid
}

animate() {
    tput civis
    local width=$(tput cols)
    local height=$(tput lines)
    local delay=${SCREENSAVER_DELAY:-0.033}

    # Speed Optimization: Render at half horizontal resolution
    local calc_width=$((width / 2))
    if ((calc_width < 1)); then calc_width=1; fi

    local gw_minus_1=$((GRID_W - 1))
    local gh_minus_1=$((GRID_H - 1))

    # Palette: 5 distinct shades for posterized look
    local palette=(232 237 242 247 252)

    clear # Clear screen initially

    while true; do
        update_grid
        local frame_buffer="\e[H"

        for ((y=0; y<height; y++)); do
            # Vertical interpolation logic (unchanged)
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

            local color=232 # Default color

            # Correct Horizontal Interpolation
            # Directly map screen x (current_x) to grid coordinates (gx)
            # This avoids the "margin fix" loop and ensures even coverage
            for ((current_x=0; current_x<calc_width; current_x++)); do
                 local x_scaled=$(( current_x * gw_minus_1 * 1000 / calc_width ))
                 local gx=$(( x_scaled / 1000 ))
                 local rx=$(( x_scaled % 1000 ))

                 local v_left=${current_row_vals[gx]}
                 local v_right=${current_row_vals[gx+1]}

                 # Interpolate
                 local val=$(( v_left + (v_right - v_left) * rx / 1000 ))

                 # Quantize / Posterize
                 local p_idx=$(( val * 5 / 256 ))
                 if ((p_idx > 4)); then p_idx=4; fi
                 if ((p_idx < 0)); then p_idx=0; fi

                 color=${palette[$p_idx]}

                 # Render DOUBLE SPACE for 1 calc pixel
                 frame_buffer+="\e[48;5;${color}m  "
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
