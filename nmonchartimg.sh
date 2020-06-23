#!/bin/bash
#Create NMON files chart images
#Requires ksh, nodejs, puppeteer-core, nmonchart

function usage(){
  echo "Usage:
  ${0##*/} [options] <chartID> <input> <output>

where <chartID> is the NMON CHART ID (see below how to get them for your nmon file)

<input> is the input file, which can be:
  - an NMON file (.nmon)
  - an NMONCHART file (.html)
and <output> is the output .jpg or .png file

Options are:
 -h | --help                   Display this help
 -C | --get-chart-ids          Display the chart IDs which can be used with this NMON file
 -s | --size <width>x<height>  Set height and width of the graph (default is ${GRAPH_WIDTH}x${GRAPH_HEIGHT})
 -aT | --area-top <unit>       Set the chart area top margin to <unit>% (default is $AREA_TOP%)
 -aL | --area-left <unit>      Set the chart area left margin to <unit>% (default is $AREA_LEFT%) 
 -aW | --area-width <unit>     Set the chart area width to <unit>% (default is $AREA_WIDTH%)
 -aH | --area-height <unit>    Set the chart area height to <unit>% (default is $AREA_HEIGHT%)
 -dHf <date_format>            Date format for the horizontal axis (apply only to charts with times)
"
  exit 1
}

function error(){
  echo "ERROR: $2"
  exit $1
}

GRAPH_WIDTH=800
GRAPH_HEIGHT=400
AREA_TOP=10
AREA_LEFT=5
AREA_WIDTH=80
AREA_HEIGHT=75
INPUT_FILE=
OUTPUT_FILE=
CHART_ID=
DATE_FORMAT_AXIS=
GET_CHART_IDS=false

#Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
   -h | --help) usage ;;
   -s | --size) GRAPH_WIDTH=${2%x*}; GRAPH_HEIGHT=${2#*x}; shift 2 ;;
   -aT | --area-top) AREA_TOP=$2; shift 2 ;;
   -aL | --area-left) AREA_LEFT=$2; shift 2 ;;
   -aW | --area-width) AREA_WIDTH=$2; shift 2 ;;
   -aH | --area-height) AREA_HEIGHT=$2; shift 2 ;;
   -dHf) DATE_FORMAT_AXIS="format: \"$2\","; shift 2 ;;
   -C | --get-chart-ids) GET_CHART_IDS=true; CHART_ID="none"; OUTPUT_FILE="temp"; shift 1 ;;
   -h | --help) usage ;;
   *) if [[ -z "$CHART_ID" ]]; then
        CHART_ID="$1"
      elif [[ -z "$INPUT_FILE" ]]; then
        INPUT_FILE="$1"
      elif [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$1"
      else
        error 11 "Too many input arguments"
      fi
      shift 1
    ;;
  esac
done

#Check arguments
[[ -z "$CHART_ID" ]] && usage
[[ -z "$INPUT_FILE" ]] && usage
INPUT_FILE="`readlink -f $INPUT_FILE`"
[[ -e "$INPUT_FILE" ]] || error 3 "Input file does not exists"
[[ -z "$OUTPUT_FILE" ]] && error 2 "Please specify an output JPEG or PNG file"
touch $OUTPUT_FILE &>/dev/null
[[ $? -ne 0 ]]  && error 4 "Failed to write output file. Check output directory"
OUTPUT_FILE="`readlink -f $OUTPUT_FILE`"
rm -f $OUTPUT_FILE

#Detect input file format
case "`head -c 4 < $INPUT_FILE`" in
 '<htm') INPUT_FILE_FORMAT='html';;
 'AAA,') INPUT_FILE_FORMAT='nmon';;
 *) echo "WARN: Cannot detect input file format. Supposing is nmon format"; 
    INPUT_FILE_FORMAT='nmon';;
esac

#If input format is NMON, convert to HTML first with NMONCHART, otherwise just use the HTML
if [[ "$INPUT_FILE_FORMAT" == "nmon" ]]; then
 NMONCHART=`command -v nmonchart 2>/dev/null`
 [[ -x "$NMONCHART" ]] || NMONCHART=
 [[ -z "$NMONCHART" && -x "./nmonchart" ]] && NMONCHART="./nmonchart"
 [[ -z "$NMONCHART" ]] && error 14 "NmonChart is required by this script. Please install it or download it from http://nmon.sourceforge.net and uncompress it in the script folder"
 [[ -z "`command -v ksh 2>/dev/null`" ]] && error 15 "ksh not found. This is needed to run nmonchart. Please install it." 
 echo "INFO: Converting NMON file to HTML"
 $NMONCHART $INPUT_FILE $OUTPUT_FILE.htm
else
  cp -f $INPUT_FILE $OUTPUT_FILE.htm
fi

if $GET_CHART_IDS; then
  #Get chart IDs to use in rendering
  echo "Possible chart IDs for $INPUT_FILE:"
  sed -n 's|^.*id="draw_\([^"]*\)".*<b>\([^<]*\)<.*$|\1,=> \2|p' $OUTPUT_FILE.htm | column -t -s,
  rm -f $OUTPUT_FILE.htm
  exit 1
fi

#Render HTML with puppeteer
echo "INFO: Rendering HTML..."
NODE=`command -v node 2>/dev/null`
[[ -x "$NODE" ]] || NODE=
[[ -z "$NODE" ]] && error 14 "Cannot find node installed. Please install it!"
[[ -d "/usr/lib/node_modules/puppeteer-core" ]] || error 15 "Cannot find puppeteer-core installed. Please install it as global node library!"
CHROME_EXEC=`command -v google-chrome-stable 2>/dev/null`
[[ -x "$CHROME_EXEC" ]] || CHROME_EXEC=
[[ -z "$CHROME_EXEC" ]] && error 16 "Cannot find node google-chrome-stable installed. Please install it!"
#Fix HTML layout
sed -i -e 's|chartArea: {left: "5%", width: "85%", top: "10%", height: "80%"}|"width": '"$GRAPH_WIDTH"',"height": '"$GRAPH_HEIGHT"',chartArea: {left: "'"$AREA_LEFT"'%", width: "'"$AREA_WIDTH"'%", top: "'"$AREA_TOP"'%", height: "'"$AREA_HEIGHT"'%"}|g' -e 's|nmon data file: <b>[^<]*</b>||g' -e 's|<br>||g' -e 's|<body |<body style="margin: 0;" |g' -e 's|<button |<button style="display:none;" |g' -e "s|hAxis: {|hAxis: { $DATE_FORMAT_AXIS|g" $OUTPUT_FILE.htm

#Render HTML
$NODE <<EOF
const puppeteer = require('/usr/lib/node_modules/puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({executablePath: '$CHROME_EXEC', args: ['--no-sandbox', '--disable-setuid-sandbox']});
  const page = await browser.newPage();
  await page.setViewport({
    width: $GRAPH_WIDTH,
    height: $GRAPH_HEIGHT,
    deviceScaleFactor: 1,
  });
  await page.goto('file://$OUTPUT_FILE.htm');
  await page.evaluate(() => {
    document.getElementById('draw_$CHART_ID').click();
  });
  await page.screenshot({path: '$OUTPUT_FILE'});
  await browser.close();
})();
EOF
rm -f $OUTPUT_FILE.htm
echo "INFO: Output image created in $OUTPUT_FILE..."

exit 0
