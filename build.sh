#!/bin/bash
set -euo pipefail

declare -r BUILD_VERSION='0.2.1'

declare -r BASE_DIR=$(cd $(dirname $0); pwd)
declare -r SOURCE_DIR="$BASE_DIR/source"
declare -r BUILD_TMP_DIR="$BASE_DIR/build_tmp"
declare -r BUILD_DIR="$BASE_DIR/build"

declare -r FONTFORGE_COMMAND=$(which fontforge)
declare -r TTFAUTOHINT_COMMAND_REGULAR="ttfautohint -m $BASE_DIR/hinting_post_process/Regular-ctrl.txt -l 6 -r 45 -a qsq -D latn -W -X 6- -I"
declare -r TTFAUTOHINT_COMMAND_BOLD="ttfautohint -l 6 -r 45 -a qsq -D latn -W -X 6- -I"

declare -r FFSCRIPT_JP="$BUILD_TMP_DIR/modify_jp_fonts.pe"
declare -r FFSCRIPT_NUM="$BUILD_TMP_DIR/modify_num_fonts.pe"

declare -r EN_FONT_REGULAR="$SOURCE_DIR/Inter-3.19/Inter Hinted for Windows/Desktop/Inter-Regular.ttf"
declare -r EN_FONT_BOLD="$SOURCE_DIR/Inter-3.19/Inter Hinted for Windows/Desktop/Inter-Bold.ttf"
declare -r JP_FONT_REGULAR="$SOURCE_DIR/genshingothic-20150607/GenShinGothic-P-Regular.ttf"
declare -r JP_FONT_BOLD="$SOURCE_DIR/genshingothic-20150607/GenShinGothic-P-Bold.ttf"

declare -r OUTPUT_JP_FONT_REGULAR="$BUILD_TMP_DIR/jp_regular.ttf"
declare -r OUTPUT_JP_FONT_BOLD="$BUILD_TMP_DIR/jp_bold.ttf"
declare -r OUTPUT_JP_FONT_REGULAR_N="$BUILD_TMP_DIR/jp_regular_n.ttf"
declare -r OUTPUT_JP_FONT_BOLD_N="$BUILD_TMP_DIR/jp_bold_n.ttf"
declare -r OUTPUT_NUM_FONT_REGULAR="$BUILD_TMP_DIR/num_regular.ttf"
declare -r OUTPUT_NUM_FONT_BOLD="$BUILD_TMP_DIR/num_bold.ttf"

declare -r TTX_NAME_REGULAR='InGenUI-Regular.ttx'
declare -r TTX_NAME_BOLD='InGenUI-Bold.ttx'
declare -r TTX_NAME_REGULAR_N='InGenUIN-Regular.ttx'
declare -r TTX_NAME_BOLD_N='InGenUIN-Bold.ttx'

declare -r BUILD_REGULAR="$BUILD_TMP_DIR/${TTX_NAME_REGULAR%.ttx}.ttf"
declare -r BUILD_BOLD="$BUILD_TMP_DIR/${TTX_NAME_BOLD%.ttx}.ttf"
declare -r BUILD_REGULAR_N="$BUILD_TMP_DIR/${TTX_NAME_REGULAR_N%.ttx}.ttf"
declare -r BUILD_BOLD_N="$BUILD_TMP_DIR/${TTX_NAME_BOLD_N%.ttx}.ttf"

# 処理開始
rm -rf "$BUILD_TMP_DIR"
mkdir -p "$BUILD_TMP_DIR/build"
cd "$BUILD_TMP_DIR"

cat > "$FFSCRIPT_JP" << _EOT_
#!$FONTFORGE_COMMAND -script

Print("Generate modified jp fonts")

# Set parameters
input_list = [ \\
  "$JP_FONT_REGULAR", \\
  "$JP_FONT_BOLD" \\
]
output_list = [ \\
  "$OUTPUT_JP_FONT_REGULAR", \\
  "$OUTPUT_JP_FONT_BOLD" \\
]
output_list_n = [ \\
  "$OUTPUT_JP_FONT_REGULAR_N", \\
  "$OUTPUT_JP_FONT_BOLD_N" \\
]

i = 0
while (i < SizeOf(input_list))
  Open(input_list[i])

  em_x = 2252
  em_y = 564
  width = em_x + em_y
  move_bracket = width / 4

  ScaleToEm(em_x, em_y)

  Select(0uff01, 0uff5e)
  SelectFewer(0uff0c)
  SelectFewer(0uff0e)
  foreach
    glyph_width = GlyphInfo("Width")
    Move((width - glyph_width) / 2, 0)
  endloop
  SelectMore(0uff0c)
  SelectMore(0uff0e)
  SetWidth(width)
  Select(0uff08); CenterInWidth(); Move(move_bracket, 0); SetWidth(width)
  Select(0uff09); CenterInWidth(); Move(-move_bracket, 0); SetWidth(width)
  Select(0uff3b); CenterInWidth(); Move(move_bracket, 0); SetWidth(width)
  Select(0uff3d); CenterInWidth(); Move(-move_bracket, 0); SetWidth(width)
  Select(0uff5b); CenterInWidth(); Move(move_bracket, 0); SetWidth(width)
  Select(0uff5d); CenterInWidth(); Move(-move_bracket, 0); SetWidth(width)

  Generate(output_list[i])

  # Narrow版の生成
  SelectWorthOutputting()
  Scale(90, 100, 0, 0)
  Generate(output_list_n[i])

  i++
endloop

_EOT_

cat > "$FFSCRIPT_NUM" << _EOT_
#!$FONTFORGE_COMMAND -script

Print("Generate modified num fonts")

# Set parameters
input_list = [ \\
  "$EN_FONT_REGULAR", \\
  "$EN_FONT_BOLD" \\
]
output_list = [ \\
  "$OUTPUT_NUM_FONT_REGULAR", \\
  "$OUTPUT_NUM_FONT_BOLD" \\
]

i = 0
while (i < SizeOf(input_list))
  Open(input_list[i])
  
  Select(0ue071, 0ue07a); Copy()
  Select(0u0030, 0u0039)
  Paste()
  Scale(93, 100, 0, 0)
  RemovePosSub("'kern' Horizontal Kerning in Latin lookup 1 per glyph data 0")

  Generate(output_list[i])
  i++
endloop
_EOT_

fontforge -script "$FFSCRIPT_JP"
fontforge -script "$FFSCRIPT_NUM"

$TTFAUTOHINT_COMMAND_REGULAR "$OUTPUT_NUM_FONT_REGULAR" hinted_en_regular
$TTFAUTOHINT_COMMAND_BOLD "$OUTPUT_NUM_FONT_BOLD" hinted_en_bold

pyftsubset "$OUTPUT_JP_FONT_REGULAR" '*' --drop-tables+=vhea --drop-tables+=vmtx
pyftmerge hinted_en_regular "${OUTPUT_JP_FONT_REGULAR%.ttf}.subset.ttf"
sed -e "s/v0.0.1/v$BUILD_VERSION/g" "$SOURCE_DIR/$TTX_NAME_REGULAR" > "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR"
ttx -m merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR"
rm -f merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR"
ttx -t GSUB "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR%.ttx}.ttf"
sed -ri 's/.*Substitution in="(zero|one|two|three|four|five|six|seven|eight|nine)".*//g' "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR"
ttx -m "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR%.ttx}.ttf" "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR"
mv -f "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR%.ttx}#1.ttf" "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR%.ttx}.ttf"

pyftsubset "$OUTPUT_JP_FONT_BOLD" '*' --drop-tables+=vhea --drop-tables+=vmtx
pyftmerge hinted_en_bold "${OUTPUT_JP_FONT_BOLD%.ttf}.subset.ttf"
sed -e "s/v0.0.1/v$BUILD_VERSION/g" "$SOURCE_DIR/$TTX_NAME_BOLD" > "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD"
ttx -m merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD"
rm -f merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD"
ttx -t GSUB "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD%.ttx}.ttf"
sed -ri 's/.*Substitution in="(zero|one|two|three|four|five|six|seven|eight|nine)".*//g' "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD"
ttx -m "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD%.ttx}.ttf" "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD"
mv -f "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD%.ttx}#1.ttf" "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD%.ttx}.ttf"

pyftsubset "$OUTPUT_JP_FONT_REGULAR_N" '*' --drop-tables+=vhea --drop-tables+=vmtx
pyftmerge hinted_en_regular "${OUTPUT_JP_FONT_REGULAR_N%.ttf}.subset.ttf"
sed -e "s/v0.0.1/v$BUILD_VERSION/g" "$SOURCE_DIR/$TTX_NAME_REGULAR_N" > "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR_N"
ttx -m merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR_N"
rm -f merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR_N"
ttx -t GSUB "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR_N%.ttx}.ttf"
sed -ri 's/.*Substitution in="(zero|one|two|three|four|five|six|seven|eight|nine)".*//g' "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR_N"
ttx -m "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR_N%.ttx}.ttf" "$BUILD_TMP_DIR/build/$TTX_NAME_REGULAR_N"
mv -f "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR_N%.ttx}#1.ttf" "$BUILD_TMP_DIR/build/${TTX_NAME_REGULAR_N%.ttx}.ttf"

pyftsubset "$OUTPUT_JP_FONT_BOLD_N" '*' --drop-tables+=vhea --drop-tables+=vmtx
pyftmerge hinted_en_bold "${OUTPUT_JP_FONT_BOLD_N%.ttf}.subset.ttf"
sed -e "s/v0.0.1/v$BUILD_VERSION/g" "$SOURCE_DIR/$TTX_NAME_BOLD_N" > "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD_N"
ttx -m merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD_N"
rm -f merged.ttf "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD_N"
ttx -t GSUB "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD_N%.ttx}.ttf"
sed -ri 's/.*Substitution in="(zero|one|two|three|four|five|six|seven|eight|nine)".*//g' "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD_N"
ttx -m "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD_N%.ttx}.ttf" "$BUILD_TMP_DIR/build/$TTX_NAME_BOLD_N"
mv -f "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD_N%.ttx}#1.ttf" "$BUILD_TMP_DIR/build/${TTX_NAME_BOLD_N%.ttx}.ttf"

rm -f "$BUILD_TMP_DIR/build"/*.ttx
rm -rf "$BUILD_DIR"
mv "$BUILD_TMP_DIR/build" "$BUILD_DIR"
rm -rf "$BUILD_TMP_DIR"
