#!/usr/bin/env bash

# ASCII Perlin-ish Noise Screensaver
# Optimized for Bash performance using integer arithmetic and simple Value Noise.

_cleanup_and_exit() {
  tput cnorm # show cursor
  tput sgr0  # reset attributes
  echo
  exit 0
}
trap _cleanup_and_exit EXIT INT TERM QUIT

# Configuration
GRID_W=12
GRID_H=8
declare -a NOISE_GRID

# ASCII Ramp (Low to High intensity)
CHARS=' .:-=+*#%@'
CHARS_LEN=${#CHARS}

# Initialize Grid
for ((i=0; i<GRID_W*GRID_H; i++)); do
    NOISE_GRID[i]=$((RANDOM % 256))
done

update_grid() {
    for ((i=0; i<GRID_W*GRID_H; i++)); do
        local r=$((RANDOM % 10))
        local val=${NOISE_GRID[i]}

        # Random walk
        if ((r < 4)); then val=$((val - 5));
        elif ((r < 8)); then val=$((val + 5)); fi

        # Soft clamp
        if ((val < 20)); then val=$((val + 2)); fi
        if ((val > 235)); then val=$((val - 2)); fi

        NOISE_GRID[i]=$val
    done
}

animate() {
    tput civis # Hide cursor

    local width=$(tput cols)
    local height=$(tput lines)
    local delay=${SCREENSAVER_DELAY:-0.033}

    local gw_minus_1=$((GRID_W - 1))
    local gh_minus_1=$((GRID_H - 1))

    local seg_w=$(( width / gw_minus_1 ))
    if ((seg_w < 1)); then seg_w=1; fi

    while true; do
        update_grid

        local frame_buffer="\e[H"

        for ((y=0; y<height; y++)); do
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

            local current_x=0
            for ((gx=0; gx<gw_minus_1; gx++)); do
                local v_left=${current_row_vals[gx]}
                local v_right=${current_row_vals[gx+1]}

                local val_scaled=$(( v_left * 1000 ))
                local step_scaled=$(( (v_right - v_left) * 1000 / seg_w ))

                for ((k=0; k<seg_w; k++)); do
                     if ((current_x >= width)); then break; fi

                     local val=$(( val_scaled / 1000 ))
                     val_scaled=$(( val_scaled + step_scaled ))

                     if ((val < 0)); then val=0; fi
                     if ((val > 255)); then val=255; fi

                     local idx=$(( val * CHARS_LEN / 256 ))
                     if ((idx >= CHARS_LEN)); then idx=$((CHARS_LEN - 1)); fi

                     local char="${CHARS:$idx:1}"
                     frame_buffer+="$char"
                     current_x=$((current_x + 1))
                done
            done

            while ((current_x < width)); do
                 frame_buffer+=" "
                 current_x=$((current_x + 1))
            done

            if ((y < height - 1)); then
                frame_buffer+="\n"
            fi
        done

        printf '%b' "$frame_buffer"
        sleep "$delay"
    done
}

animate
