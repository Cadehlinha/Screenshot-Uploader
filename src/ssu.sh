#!/bin/bash

check_dependency() {
  command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 is required but it's not installed. Aborting."; exit 1; }
}

calculate_new_dimensions() {
  local original_width=$1
  local original_height=$2
  local box_x=$3
  local box_width=$4
  local offset=$5
  local box_height=$6
  local border_radius=$7

  local new_width=$((original_width < (box_x + box_width + offset) ? (box_x + box_width + offset) : original_width))
  local new_height=$((original_height + box_height + border_radius + offset))

  if ((original_width < new_width)) || ((original_height < new_height)); then
    new_height=$((new_height + offset))
  fi

  echo "$new_width $new_height"
}

draw_rounded_rectangle_with_text() {
  local screenshot_file=$1
  local box_x=$2
  local box_y=$3
  local box_width=$4
  local box_height=$5
  local border_radius=$6
  local box_color=$7
  local font_color=$8
  local font_size=$9
  local ttf_path=${10}
  local text=${11}

  local text_height=$(convert -font "$ttf_path" -pointsize "$font_size" -debug annotate -annotate 0 "$text" null: 2>&1 | awk '/Metrics:/ {print $4}' | cut -d'+' -f1)
  local text_y=$((box_y + (box_height - text_height) / 2))
  local offset_x=$((box_x + 15))
  local offset_y=$((text_y + 12))

  convert "$screenshot_file" \
    -fill "$box_color" \
    -stroke black -strokewidth 3 \
    -draw "roundrectangle $box_x,$box_y $((box_x + box_width)),$((box_y + box_height + border_radius)) $border_radius,$border_radius" \
    -fill "$font_color" -pointsize "$font_size" -font "$ttf_path" -annotate +"$offset_x"+"$offset_y" "$text" \
    "$screenshot_file"
}

capture_screenshot() {
  local screenshot_file=$1
  scrot -s "$screenshot_file"
}

extend_canvas() {
  local screenshot_file=$1
  local new_width=$2
  local new_height=$3
  local offset=$4
  convert "$screenshot_file" -background none -extent "${new_width}x${new_height}" "$screenshot_file"
}

get_file_time() {
  date +"%m-%d-%H:%M:%S"
}

get_box_time() {
  date +"%d-%m-%Y - %H:%M:%S"
}

generate_screenshot_filename() {
  local file_prefix=$1
  local screen_dimension=$2
  local current_time=$3
  local file_extension=$4
  echo "/tmp/${file_prefix}_${screen_dimension}_${current_time}.${file_extension}"
}

load_image_dimensions() {
  local screenshot_file=$1
  local original_width=$(identify -format "%w" "$screenshot_file")
  local original_height=$(identify -format "%h" "$screenshot_file")
  echo "$original_width $original_height"
}


upload_screenshot() {
  local screenshot_file=$1
  local upload_url=$2
  local authorization_token=$3

  local response=$(curl -s -X POST -H "Authorization: $authorization_token" -F "file=@$screenshot_file" "$upload_url")
  local url=$(echo "$response" | jq -r '.url')

  echo "$url"
}

send_notification() {
  local urgency=$1
  local timeout=$2
  local appname=$3
  local icon=$4
  local summary=$5
  local description=$6
  notify-send -u "$urgency" -t "$timeout" -a "$appname" -i "$icon" "$summary" "$description"
}

main() {
  # Check if dependencies are installed
  check_dependency xdpyinfo
  check_dependency scrot
  check_dependency convert
  check_dependency jq
  check_dependency curl
  check_dependency xclip

  # Define the screenshot file name
  local file_prefix="Linux"
  local screen_dimension=$(xdpyinfo | awk '/dimensions/{print $2}')
  local current_time=$(get_file_time)
  local file_extension="png"
  local screenshot_file=$(generate_screenshot_filename "$file_prefix" "$screen_dimension" "$current_time" "$file_extension")

  # Capture a screenshot using scrot
  capture_screenshot "$screenshot_file"

  # Dimensions of the blue box
  local box_width=550
  local box_height=50
  local border_radius=10

  # Colors and position of the blue box
  local box_color="#0066cc"
  local box_x=10
  local offset=10

  # Load the original image dimensions
  local original_dimensions=$(load_image_dimensions "$screenshot_file")
  read -r original_width original_height <<< "$original_dimensions"

  # Calculate the new dimensions if the image is too small
  local new_dimensions=$(calculate_new_dimensions "$original_width" "$original_height" "$box_x" "$box_width" "$offset" "$box_height" "$border_radius")
  read -r new_width new_height <<< "$new_dimensions"

  # Extend the canvas if the image is too small
  if ((original_width < new_width)) || ((original_height < new_height)); then
    new_height=$((new_height + offset))
    extend_canvas "$screenshot_file" "$new_width" "$new_height" "$offset"
  fi

  # Text to be written insidethe blue box
  local current_time=$(get_box_time)
  local text="ScreenCap: | $current_time"
  local font_color="white"
  local font_size=24
  # this is a good fallback if you dont know what font to use
  #local ttf_path="/usr/share/fonts/TTF/DejaVuSans.ttf"
  local ttf_path="/usr/share/fonts/TTF/TerminessNerdFontMono-Regular.ttf"

  # Draw the rounded rectangle with text
  draw_rounded_rectangle_with_text "$screenshot_file" "$box_x" "$((original_height + offset))" "$box_width" "$box_height" "$border_radius" "$box_color" "$font_color" "$font_size" "$ttf_path" "$text"

  # Upload the screenshot
  local endpoint="https://alekeagle.me/api/upload"
  local token="TOKEN_HERE"
  local url=$(upload_screenshot "$screenshot_file" "$endpoint" "$token")
  send_notification "normal" "5000" "Scweenshot UplOwOder" "$screenshot_file" "Screenshot Uploaded!" "URL copied to clipboard"
  echo "$url" | xclip -selection clipboard

  rm $screenshot_file
}

# Execute the main function
main
