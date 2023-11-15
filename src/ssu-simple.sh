#!/bin/bash

check_dependency() {
  command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 is required but it's not installed. Aborting."; exit 1; }
}

capture_screenshot() {
  local screenshot_file=$1
  scrot -s "$screenshot_file"
}

get_file_time() {
  date +"%m-%d-%H:%M:%S"
}

generate_screenshot_filename() {
  local file_prefix=$1
  local screen_dimension=$2
  local current_time=$3
  local file_extension=$4
  echo "/tmp/${file_prefix}_${screen_dimension}_${current_time}.${file_extension}"
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
  check_dependency jq
  check_dependency curl
  check_dependency xclip

  # Define the screenshot file name
  local current_time=$(get_file_time)
  local screen_dimension=$(xdpyinfo | awk '/dimensions/{print $2}')
  local screenshot_file=$(generate_screenshot_filename "$file_prefix" "$screen_dimension" "$current_time" "$file_extension")

  # Capture a screenshot using scrot
  capture_screenshot "$screenshot_file"

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
