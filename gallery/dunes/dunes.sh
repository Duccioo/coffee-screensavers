#!/usr/bin/env bash

# Dunes Screensaver - Based on Perlin-ish Noise (Pixel Art)

_cleanup_and_exit() {
  tput cnorm; tput sgr0; echo; exit 0
}
trap _cleanup_and_exit EXIT INT TERM QUIT

GRID_W=16
GRID_H=12
declare -a NOISE_GRID

# Init
for ((i=0; i<GRID_W*GRID_H; i++)); do NOISE_GRID[i]=$((RANDOM % 256)); done

source gallery/dunes/config.sh

update_grid() {
    local time_offset=$1
    for ((y=0; y<GRID_H; y++)); do
        for ((x=0; x<GRID_W; x++)); do
            # Scale the coordinates to make the noise field appear larger and smoother
            local scaled_x=$((x * 8))
            local scaled_y=$((y * 8))
            local val=$(pnoise $scaled_x $scaled_y $time_offset)
            NOISE_GRID[y * GRID_W + x]=$val
        done
    done
}

# Simple integer-based Perlin noise
pnoise() {
    local x=$1 y=$2 z=$3
    local corners=(
        $(( (x/8) * 8 + (y/8) * 8 * GRID_W + (z/8) * 8 * GRID_W * GRID_H ))
        $(( (x/8+1) * 8 + (y/8) * 8 * GRID_W + (z/8) * 8 * GRID_W * GRID_H ))
        $(( (x/8) * 8 + (y/8+1) * 8 * GRID_W + (z/8) * 8 * GRID_W * GRID_H ))
        $(( (x/8+1) * 8 + (y/8+1) * 8 * GRID_W + (z/8) * 8 * GRID_W * GRID_H ))
        $(( (x/8) * 8 + (y/8) * 8 * GRID_W + (z/8+1) * 8 * GRID_W * GRID_H ))
        $(( (x/8+1) * 8 + (y/8) * 8 * GRID_W + (z/8+1) * 8 * GRID_W * GRID_H ))
        $(( (x/8) * 8 + (y/8+1) * 8 * GRID_W + (z/8+1) * 8 * GRID_W * GRID_H ))
        $(( (x/8+1) * 8 + (y/8+1) * 8 * GRID_W + (z/8+1) * 8 * GRID_W * GRID_H ))
    )

    local rand_corners=()
    for c in "${corners[@]}"; do
        RANDOM=$((c)); rand_corners+=($((RANDOM % 256))); RANDOM=$((c*c))
    done

    local dx=$(( (x % 8) * 32 ))
    local dy=$(( (y % 8) * 32 ))
    local dz=$(( (z % 8) * 32 ))

    local v1=$(( rand_corners[0] + (rand_corners[1] - rand_corners[0]) * dx / 256 ))
    local v2=$(( rand_corners[2] + (rand_corners[3] - rand_corners[2]) * dx / 256 ))
    local v3=$(( rand_corners[4] + (rand_corners[5] - rand_corners[4]) * dx / 256 ))
    local v4=$(( rand_corners[6] + (rand_corners[7] - rand_corners[6]) * dx / 256 ))

    local i1=$(( v1 + (v2 - v1) * dy / 256 ))
    local i2=$(( v3 + (v4 - v3) * dy / 256 ))

    local v=$(( i1 + (i2 - i1) * dz / 256 ))
    echo $v
}

animate() {
    tput civis
    local width=$(tput cols)
    local height=$(tput lines)
    local delay=${SCREENSAVER_DELAY:-0.033}
    local calc_width=$((width / 2))
    if ((calc_width < 1)); then calc_width=1; fi

    local gw_minus_1=$((GRID_W - 1))
    local gh_minus_1=$((GRID_H - 1))

    local seg_w=$(( calc_width / gw_minus_1 ))
    if ((seg_w < 1)); then seg_w=1; fi

    # Color Palette: Warm, sandy tones
    local palette=(230 229 228 222 221 220 215 214 209 208 203 202)

    local time=0
    clear

    while true; do
        update_grid $((time * speed / 2))
        local frame_buffer="\e[H"

        for ((y=0; y<height; y++)); do
            local y_scaled=$(( y * (GRID_H - 1) * 1000 / height ))
            local gy=$(( y_scaled / 1000 ))
            local ry=$(( y_scaled % 1000 ))

            local row_idx_1=$(( gy * GRID_W ))
            local row_idx_2=$(( (gy + 1) * GRID_W ))
            if ((row_idx_2 >= GRID_W * GRID_H)); then row_idx_2=$row_idx_1; fi

            local current_row_vals=()
            for ((gx=0; gx<GRID_W; gx++)); do
                local v1=${NOISE_GRID[row_idx_1 + gx]}
                local v2=${NOISE_GRID[row_idx_2 + gx]}
                local v=$(( v1 + (v2 - v1) * ry / 1000 ))
                current_row_vals+=("$v")
            done

            for ((x=0; x<width; x++)); do
                local x_scaled=$(( x * (GRID_W - 1) * 1000 / width ))
                local gx=$(( x_scaled / 1000 ))
                local rx=$(( x_scaled % 1000 ))

                local v_left=${current_row_vals[gx]}
                local v_right=${current_row_vals[gx+1]}
                if [ -z "$v_right" ]; then v_right=$v_left; fi

                local val=$(( v_left + (v_right - v_left) * rx / 1000 ))

                local p_idx=$(( val * ${#palette[@]} / 256 ))
                if ((p_idx >= ${#palette[@]})); then p_idx=$((${#palette[@]} - 1)); fi
                if ((p_idx < 0)); then p_idx=0; fi

                color=${palette[$p_idx]}
                frame_buffer+="\e[38;5;${color}m."
            done
            if ((y < height - 1)); then frame_buffer+="\n"; fi
        done

        printf '%b' "$frame_buffer"
        sleep "$delay"
        time=$((time + 1))
    done
}

animate
