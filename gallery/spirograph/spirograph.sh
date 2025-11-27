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

# Check dependencies
if ! command -v bc &> /dev/null; then
    tput rmcup # Restore screen to show error
    echo "Error: 'bc' is not installed. Please install 'bc' to run this screensaver." >&2
    echo "Press any key to exit..."
    read -n 1 -s -r
    exit 1
fi

# Constants
WIDTH=$(tput cols)
HEIGHT=$(tput lines)
HALF_WIDTH=$((WIDTH / 2))
if ((HALF_WIDTH < 1)); then HALF_WIDTH=1; fi

# Precompute LUT for Sin/Cos (0-360 degrees -> 0-3599 index)
# Precision: 0.1 degrees. Scale: 10000.
declare -a COS_LUT
declare -a SIN_LUT

echo "Calculating math..."
# Use bc to generate table
MATH_DATA_STR=$(bc -l <<EOF
for (i=0; i<3600; i++) {
    a = i * 3.1415926535 / 1800
    scale=20
    c_val = 10000 * c(a)
    s_val = 10000 * s(a)
    scale=0
    print c_val / 1; print "\n"
    print s_val / 1; print "\n"
}
EOF
)

# Parse into arrays
OLD_IFS=$IFS
IFS=$'\n'
MATH_DATA=($MATH_DATA_STR)
IFS=$OLD_IFS

for ((i=0; i<3600; i++)); do
    COS_LUT[i]=${MATH_DATA[$((i*2))]}
    SIN_LUT[i]=${MATH_DATA[$((i*2+1))]}
done

# Grid for additive color (stores brightness 0-23)
declare -a GRID

reset_grid() {
    GRID=()
    # Initialize with 0 is optional as unset=0 in arithmetic,
    # but explicit clear is good if array persists.
    # Actually, unsetting the array is faster.
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
        # R = Outer Radius, r = Inner Radius, d = Offset
        # We need these to produce integer screen coordinates.
        # Screen Center is (HALF_WIDTH/2, HEIGHT/2).
        # Max radius should fit roughly in min(HALF_WIDTH, HEIGHT)/2 * zoom.

        # Generate params using bc for convenience, then cast to integer
        PARAMS=$(bc -l <<EOF
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

print r_outer; print " "; print r_inner; print " "; print d_off; print " ";
print zoom; print " "; print ox; print " "; print oy; print " "; print step
EOF
)
        read -r R r d zoom ox oy step <<< "$PARAMS"

        # Scaling K for the second angle
        # theta2 = theta * (R-r)/r
        # We handle this by stepping two angles separately.
        # But for the loop to be tight, we need integer steps.
        # angle1_step = step
        # angle2_step = step * (R-r)/r
        # We can maintain angle2 as (val / r).
        # Or just compute:
        # phi1 += step
        # phi2 += step * (R-r)/r  <-- This might be fractional.

        # Improved Integer Math for Angles:
        # Track `t` (time).
        # angle1 = t % 3600
        # angle2 = (t * (R-r) / r) % 3600
        # To avoid division in loop, precalc ratio * 1000
        # ratio_scaled = (R-r) * 1000 / r
        # angle2 = (t * ratio_scaled / 1000) % 3600

        local ratio_scaled=$(( (R - r) * 1000 / r ))
        local t=0

        # Determine center
        local cx=$((HALF_WIDTH / 2 + ox))
        local cy=$((HEIGHT / 2 + oy))

        # Draw for a fixed duration or until a lot of cycles
        # 3000 steps * 0.01s = 30 seconds per shape
        # Or more? 6000 steps.
        for ((i=0; i<8000; i++)); do
             # Calculate angles (indices into 0-3599 LUT)
             local idx1=$(( t % 3600 ))
             local idx2=$(( (t * ratio_scaled / 1000) % 3600 ))
             # Handle negative modulo in case of overflow? t is increasing.
             if ((idx2 < 0)); then idx2=$((idx2 + 3600)); fi

             # Fetch Sin/Cos (scaled 10000)
             local cos1=${COS_LUT[idx1]}
             local sin1=${SIN_LUT[idx1]}
             local cos2=${COS_LUT[idx2]}
             local sin2=${SIN_LUT[idx2]}

             # Hypotrochoid Formula:
             # x = (R-r)*cos(t) + d*cos(...)
             # y = (R-r)*sin(t) - d*sin(...)

             local term1_coeff=$((R - r))

             # Calc raw coords (scaled by 10000)
             local raw_x=$(( term1_coeff * cos1 + d * cos2 ))
             local raw_y=$(( term1_coeff * sin1 - d * sin2 ))

             # Apply Zoom (zoom is scaled by 10)
             # And scale down the 10000 from LUT
             # Final pixels

             # We want roughly coordinate 1.0 to be 1 pixel?
             # R is ~50. 50 * 10000 = 500,000.
             # We need to divide by 10000.
             # zoom=10 (1.0).

             # local x = raw_x * zoom / 10 / 10000
             # Optimized: raw_x * zoom / 100000

             # Adjust aspect ratio? Terminal chars are roughly 2x1.
             # But we are using double-space pixels (approx square).
             # So x and y scaling should be equal.

             local x=$(( raw_x * zoom / 100000 + cx ))
             local y=$(( raw_y * zoom / 100000 + cy ))

             draw_pixel "$x" "$y"

             # Increment t
             t=$((t + step))

             # Delay
             # Check SCREENSAVER_DELAY or default
             # Use a very short sleep or sleep 0 for max speed?
             # User said "crea piano piano" (slowly).
             # But 8000 steps at 0.03s is 240s (4 mins).
             # That might be too slow. Let's try 0.01.
             # Or respect SCREENSAVER_DELAY if set, but maybe divide it?
             # Standard is 0.033 (30fps).
             sleep 0.01
        done

        # Pause before next shape
        sleep 3
    done
}

animate
