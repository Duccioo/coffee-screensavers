#!/usr/bin/env bash

# Spirograph Screensaver
# Generates Hypotrochoid patterns (Spirograph) with additive blending.
# "Pixel" style using double-width characters.

_cleanup_and_exit() {
  local code=$?
  tput cnorm; tput sgr0; clear
  exit $code
}
trap _cleanup_and_exit EXIT INT TERM QUIT

fail() {
    tput rmcup # Restore screen to show error
    echo "Error: $1" >&2
    if [[ -n "$2" ]]; then
        echo "Details:" >&2
        echo "$2" | head -n 10 >&2
    fi
    echo "Press Enter to exit..."
    read -r
    exit 1
}

# Check dependencies
if ! command -v bc &> /dev/null; then
    fail "'bc' is not installed. Please install 'bc' to run this screensaver."
fi

# Constants
WIDTH=$(tput cols)
HEIGHT=$(tput lines)

if [[ -z "$WIDTH" || -z "$HEIGHT" ]]; then
    fail "Could not determine terminal dimensions."
fi

HALF_WIDTH=$((WIDTH / 2))
if ((HALF_WIDTH < 1)); then HALF_WIDTH=1; fi

# Precompute LUT for Sin/Cos (0-360 degrees -> 0-3599 index)
# Precision: 0.1 degrees. Scale: 10000.
declare -a COS_LUT
declare -a SIN_LUT

echo "Calculating math..."
# Use bc to generate table
# Note: Output one value per line for POSIX bc compatibility (avoiding 'print')
# Capture stderr to debug failures
MATH_DATA_STR=$(bc -l <<EOF 2>&1
for (i=0; i<3600; i++) {
    a = i * 3.1415926535 / 1800
    scale=20
    c_val = 10000 * c(a)
    s_val = 10000 * s(a)
    scale=0
    c_val / 1
    s_val / 1
}
EOF
)

# Parse into arrays
OLD_IFS=$IFS
IFS=$'\n'
MATH_DATA=($MATH_DATA_STR)
IFS=$OLD_IFS

if [[ ${#MATH_DATA[@]} -lt 7200 ]]; then
    fail "Math generation failed (bc output incomplete)." "$MATH_DATA_STR"
fi

for ((i=0; i<3600; i++)); do
    COS_LUT[i]=${MATH_DATA[$((i*2))]}
    SIN_LUT[i]=${MATH_DATA[$((i*2+1))]}
done

# Grid for additive color (stores brightness 0-23)
declare -a GRID

reset_grid() {
    GRID=()
    unset GRID
    declare -a GRID
    tput sgr0
    clear
}

draw_pixel() {
    local x=$1
    local y=$2

    # Check bounds
    if ((x >= 0 && x < HALF_WIDTH && y >= 0 && y < HEIGHT)); then
         local idx=$((y * HALF_WIDTH + x))
         local val=${GRID[idx]:-0}

         if ((val < 23)); then
             val=$((val + 1))
             GRID[idx]=$val

             local color=$((232 + val))

             tput cup $y $((x * 2))
             tput setab $color
             echo -n "  "
         fi
    fi
}

animate() {
    tput civis

    while true; do
        reset_grid

        # --- Generative Parameters ---
        # Output one value per line for POSIX bc compatibility
        PARAMS_STR=$(bc -l <<EOF 2>&1
scale=0
# Random seeds
seed = $RANDOM
# R: 20 to 80
r_outer = (seed % 60) + 20
# r: 2 to (R-2)
r_inner = ((seed / 10) % (r_outer - 5)) + 5
# d: 5 to 100
d_off = ((seed / 100) % 95) + 5

# Zoom: 0.5 to 2.5 (scaled by 10) -> 5 to 25
zoom = ((seed / 7) % 20) + 5

# Offsets (Center shift): -20 to 20
ox = ((seed / 3) % 40) - 20
oy = ((seed / 11) % 40) - 20

# Rotation Step Speed (1 to 5)
step = (seed % 5) + 1

r_outer
r_inner
d_off
zoom
ox
oy
step
EOF
)
        # Parse params from newline-separated string
        PARAMS_ARR=($PARAMS_STR)

        if [[ ${#PARAMS_ARR[@]} -lt 7 ]]; then
             fail "Parameter generation failed." "$PARAMS_STR"
        fi

        local R=${PARAMS_ARR[0]}
        local r=${PARAMS_ARR[1]}
        local d=${PARAMS_ARR[2]}
        local zoom=${PARAMS_ARR[3]}
        local ox=${PARAMS_ARR[4]}
        local oy=${PARAMS_ARR[5]}
        local step=${PARAMS_ARR[6]}

        local ratio_scaled=$(( (R - r) * 1000 / r ))
        local t=0

        # Determine center
        local cx=$((HALF_WIDTH / 2 + ox))
        local cy=$((HEIGHT / 2 + oy))

        # Draw loop
        for ((i=0; i<8000; i++)); do
             # Calculate angles (indices into 0-3599 LUT)
             local idx1=$(( t % 3600 ))
             local idx2=$(( (t * ratio_scaled / 1000) % 3600 ))

             if ((idx2 < 0)); then idx2=$((idx2 + 3600)); fi

             local cos1=${COS_LUT[idx1]}
             local sin1=${SIN_LUT[idx1]}
             local cos2=${COS_LUT[idx2]}
             local sin2=${SIN_LUT[idx2]}

             local term1_coeff=$((R - r))

             local raw_x=$(( term1_coeff * cos1 + d * cos2 ))
             local raw_y=$(( term1_coeff * sin1 - d * sin2 ))

             local x=$(( raw_x * zoom / 100000 + cx ))
             local y=$(( raw_y * zoom / 100000 + cy ))

             draw_pixel "$x" "$y"

             t=$((t + step))
             sleep "${SCREENSAVER_DELAY:-0.033}"
        done

        sleep 3
    done
}

animate
