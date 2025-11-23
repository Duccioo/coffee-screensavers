#!/usr/bin/env bash

# Grayscale Perlin-ish Noise Screensaver (Pixel Art)
# Optimized for Bash performance using integer arithmetic and simple Value Noise.

_cleanup_and_exit() {
  tput cnorm # show cursor
  tput sgr0  # reset attributes
  echo
  exit 0
}
trap _cleanup_and_exit EXIT INT TERM QUIT

# Configuration
# Low res grid interpolated to screen res
GRID_W=12
GRID_H=8
declare -a NOISE_GRID

# Initialize Grid with random values
for ((i=0; i<GRID_W*GRID_H; i++)); do
    NOISE_GRID[i]=$((RANDOM % 256))
done

update_grid() {
    for ((i=0; i<GRID_W*GRID_H; i++)); do
        local r=$((RANDOM % 10))
        local val=${NOISE_GRID[i]}

        # Random walk with tendency to center to maintain contrast
        # 40% chance to decrease, 40% chance to increase, 20% stay
        if ((r < 4)); then val=$((val - 5));
        elif ((r < 8)); then val=$((val + 5)); fi

        # Soft clamp / pull to center to avoid getting stuck at extremes
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

    # Pre-calculate constants
    local gw_minus_1=$((GRID_W - 1))
    local gh_minus_1=$((GRID_H - 1))

    # Calculate segment width (approximate)
    local seg_w=$(( width / gw_minus_1 ))
    if ((seg_w < 1)); then seg_w=1; fi

    while true; do
        update_grid

        local frame_buffer="\e[H" # Home cursor

        for ((y=0; y<height; y++)); do
            # Map y to grid coordinates (vertical interpolation)
            # Fixed point math (scale 1000)
            local y_scaled=$(( y * gh_minus_1 * 1000 / height ))
            local gy=$(( y_scaled / 1000 ))
            local ry=$(( y_scaled % 1000 ))

            # Grid indices for this row
            local row_idx_1=$(( gy * GRID_W ))
            local row_idx_2=$(( (gy + 1) * GRID_W ))

            # Interpolate vertically to create a row of control points
            local current_row_vals=()
            for ((gx=0; gx<GRID_W; gx++)); do
                local v1=${NOISE_GRID[row_idx_1 + gx]}
                local v2=${NOISE_GRID[row_idx_2 + gx]}
                # Linear Interpolation: v1 + (v2-v1)*ry/1000
                local v=$(( v1 + (v2 - v1) * ry / 1000 ))
                current_row_vals+=("$v")
            done

            # Interpolate horizontally across the screen width
            local current_x=0
            for ((gx=0; gx<gw_minus_1; gx++)); do
                local v_left=${current_row_vals[gx]}
                local v_right=${current_row_vals[gx+1]}

                # Setup horizontal stepper
                local val_scaled=$(( v_left * 1000 ))
                local step_scaled=$(( (v_right - v_left) * 1000 / seg_w ))

                # Inner loop for this segment
                for ((k=0; k<seg_w; k++)); do
                     if ((current_x >= width)); then break; fi

                     local val=$(( val_scaled / 1000 ))
                     val_scaled=$(( val_scaled + step_scaled ))

                     # Map to grayscale 232-255
                     local color=$(( 232 + val * 24 / 256 ))
                     if ((color > 255)); then color=255; fi
                     if ((color < 232)); then color=232; fi

                     frame_buffer+="\e[48;5;${color}m "
                     current_x=$((current_x + 1))
                done
            done

            # Fill remaining pixels
            while ((current_x < width)); do
                 frame_buffer+=" "
                 current_x=$((current_x + 1))
            done

            frame_buffer+="\e[0m" # Reset color at end of line
            # Do not add newline if it's the last line to avoid scrolling
            if ((y < height - 1)); then
                frame_buffer+="\n"
            fi
        done

        printf '%b' "$frame_buffer"
        sleep "$delay"
    done
}

animate
