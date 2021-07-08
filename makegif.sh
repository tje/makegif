#!/usr/bin/env bash

INPUT=""
OUTPUT=""
WIDTH=""
HEIGHT=""
FFMPEG_PRE_OPTS="-hide_banner -loglevel error -stats"

HELP_TEXT=$(cat <<'HEREDOC'
Transcode a video file to an animated gif.

usage: makegif [options] <input> [output]

Options
  -w --width <number>       Width of the output file
  -h --height <number>      Height of the output file
  -f --force                Skip confirmation prompt for overwriting existing file

Examples
  Create a gif from input.mov, output defaults to same base name ("input.gif"):
    makegif input.mov

  Create a gif from input.mov with a width of 300, preserving aspect ratio:
    makegif -w 300 input.mov output.gif

  Create a gif that is half the size of the input file:
    makegif -w /2 input.mp4
HEREDOC
)

while (( "$#" )); do
  case "$1" in
    --width=*)
      WIDTH="${1#*=}"
      shift
      ;;
    -w|--width)
      WIDTH="$2"
      shift
      shift
      ;;
    --height=*)
      HEIGHT="${1#*=}"
      shift
      ;;
    -h|--height)
      HEIGHT="$2"
      shift
      shift
      ;;
    -y|-f|--force)
      FFMPEG_PRE_OPTS="$FFMPEG_PRE_OPTS -y"
      shift
      ;;
    -i|--input)
      INPUT="$2"
      shift
      shift
      ;;
    --input=*)
      INPUT="${1#*=}"
      shift
      ;;
    -o|--output)
      OUTPUT="$2"
      shift
      shift
      ;;
    --output=*)
      OUTPUT="${1#*=}"
      shift
      ;;
    --help)
      echo "$HELP_TEXT"
      exit 0
      ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      elif [[ -z "$OUTPUT" ]]; then
        OUTPUT="$1"
      fi
      shift
      ;;
  esac
done

if [ ! "$INPUT" ]; then
  echo "Error: No input file provided."
  echo ""
  echo "$HELP_TEXT"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "Error: Input file $INPUT does not exist."
  echo ""
  echo "$HELP_TEXT"
  exit 1
fi

DIR="$(dirname "$INPUT")"

if [ -z "$OUTPUT" ]; then
  o="$(basename "$INPUT")"
  o=${o##*/}
  OUTPUT="${o%.*}.gif"
fi

rx_num='^[0-9]+([.][0-9]+)?$'

if [[ $WIDTH =~ ^/[0-9]+$ ]]; then
  WIDTH="in_w$WIDTH"
elif ! [[ $WIDTH =~ $rx_num ]]; then
  WIDTH="-1"
fi

if [[ $HEIGHT =~ ^/[0-9]+$ ]]; then
  HEIGHT="in_h$HEIGHT"
elif ! [[ $HEIGHT =~ $rx_num ]]; then
  HEIGHT="-1"
fi

if [[ $WIDTH -eq "-1" ]] && [[ $HEIGHT -eq "-1" ]]; then
  WIDTH="in_w"
fi

FILTERS="fps=30,paletteuse"
if [[ "$WIDTH" =~ $rx_num ]] && [[ "$HEIGHT" =~ $rx_num ]]; then
  FILTERS="scale=$WIDTH:$HEIGHT:force_original_aspect_ratio=increase,crop=$WIDTH:$HEIGHT,$FILTERS"
else
  FILTERS="scale=$WIDTH:$HEIGHT,$FILTERS"
fi

PALETTE=`mktemp`

ffmpeg $FFMPEG_PRE_OPTS -y -i "$INPUT" -vf palettegen -f image2 "$PALETTE"
ffmpeg $FFMPEG_PRE_OPTS -i "$INPUT" -i "$PALETTE" -filter_complex "$FILTERS" "$OUTPUT"

OK="$?"

echo "Removing temp file(s):"
rm -v "$PALETTE"

[[ "$OK" == "0" ]] && echo "Created gif: $OUTPUT"

exit $OK
