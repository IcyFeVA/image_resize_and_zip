#!/bin/bash

# ------------------------------------------------------------------------
# use like this
# ./imgrsr.sh -l myimage.webp 300
# ------------------------------------------------------------------------


# Usage message
usage() {
    echo "Usage: $0 [-l|-p] <image-file> [DPI]"
    echo "-l: Resize image for landscape orientation"
    echo "-p: Resize image for portrait orientation"
    echo "Example: $0 -l image.jpg 300"
    exit 1
}

# Check if minimum number of arguments is provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Process flags
while getopts ":lp" opt; do
  case ${opt} in
    l )
      orientation="landscape"
      ;;
    p )
      orientation="portrait"
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Assign arguments after flag processing
input_image="$1"
dpi="${2:-300}" # Default DPI if not provided

# Validate image file format
if ! [[ $input_image =~ \.(jpg|jpeg|png|tif|tiff|webp)$ ]]; then
    echo "Unsupported image format. Please use JPG, JPEG, PNG, WEBP, TIF, or TIFF."
    exit 1
fi

# Define frame sizes based on DPI
sizes=("5x7" "8x10" "8x12" "9x12" "11x14" "16x20")
resized_images=() # Array to keep track of resized image filenames

for size in "${sizes[@]}"; do
    read width height <<< $(echo $size | tr 'x' ' ' | awk -v dpi="$dpi" '{printf "%d %d", $1*dpi, $2*dpi}')
    
    # Adjust for orientation
    if [ "$orientation" == "landscape" ]; then
        # Ensure width is greater than height
        [ $width -lt $height ] && { temp=$width; width=$height; height=$temp; }
    elif [ "$orientation" == "portrait" ]; then
        # Ensure height is greater than width
        [ $height -lt $width ] && { temp=$width; width=$height; height=$temp; }
    fi

    size_pixels="${width}x${height}"
    output_image="$(basename "$input_image" | cut -f 1 -d '.')_${size}_${orientation}.jpg"
    convert "$input_image" -resize "$size_pixels^" -gravity center -extent "$size_pixels" "$output_image"
    resized_images+=("$output_image") # Add the filename to the array
done

# Zip the resized images
zip_name="$(basename "$input_image" | cut -f 1 -d '.')"_"${orientation}_resized_images.zip"
zip "$zip_name" "${resized_images[@]}"

echo "Resizing complete. Images zipped in $zip_name."

# Optional: Remove the individual files after zipping if desired
for file in "${resized_images[@]}"; do
    rm "$file"
done
