#!/bin/bash
#Create NMON files chart images
#Requires ksh, wkhtmltox, nmonchart

function usage(){
  echo "Usage:
  ${0##*/} [options] <chartID> <input> <output>

where <chartID> is the NMON CHART ID, which can be one of the following:
"
tr ' ' '\n' <<<$GRAPHS | column
echo "
<input> is the input file, which can be:
  - an NMON file (.nmon)
  - an NMONCHART file (.html)
and <output> is the output .jpg or .png file

Options are:
 -h | --help                   Display this help
 -s | --size <width>x<height>  Set height and width of the graph (default is ${GRAPH_WIDTH}x${GRAPH_HEIGHT})
 -aT | --area-top <unit>       Set the chart area top margin to <unit>% (default is $AREA_TOP%)
 -aL | --area-left <unit>      Set the chart area left margin to <unit>% (default is $AREA_LEFT%) 
 -aW | --area-width <unit>     Set the chart area width to <unit>% (default is $AREA_WIDTH%)
 -aH | --area-height <unit>    Set the chart area height to <unit>% (default is $AREA_HEIGHT%)
"
  exit 1
}

function error(){
  echo "ERROR: $2"
  exit $1
}

GRAPHS='PHYSICAL_CPU POOLIDLE CPU_UTIL REALMEM VIRTMEM FSCACHE MEMNEW RUNQ PSWITCH SYSCALL READWRITE FORKEXEC FILEIO PAGING SWAPIN CPU_USE TOPDISK NET NETPACKET NETSIZE ADAPT_KBS ADAPT_TPS DISKBUSY DISKBUSY DISKREAD DISKREAD DISKWRITE DISKWRITE DISKBSIZE DISKXFER JFS IPC TOPDISK PHYSICAL_CPU POOLIDLE CPU_UTIL CPU_USE RUNQ PSWITCH SYSCALL READWRITE FORKEXEC FILEIO REALMEM VIRTMEM FSCACHE MEMNEW PAGING SWAPIN NET NETPACKET NETSIZE ADAPT_KBS ADAPT_TPS DISKBUSY DISKBUSY DISKREAD DISKREAD DISKWRITE DISKWRITE DISKBSIZE DISKXFER'
GRAPH_WIDTH=800
GRAPH_HEIGHT=400
AREA_TOP=10
AREA_LEFT=5
AREA_WIDTH=80
AREA_HEIGHT=75
INPUT_FILE=
OUTPUT_FILE=
CHART_ID=

#Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
   -h | --help) usage ;;
   -s | --size) GRAPH_WIDTH=${2%x*}; GRAPH_HEIGHT=${2#*x}; shift 2 ;;
   -aT | --area-top) AREA_TOP=$2; shift 2 ;;
   -aL | --area-left) AREA_LEFT=$2; shift 2 ;;
   -aW | --area-width) AREA_WIDTH=$2; shift 2 ;;
   -aH | --area-height) AREA_HEIGHT=$2; shift 2 ;;   
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
tr ' ' '\n' <<<"$GRAPHS" | grep -q -E "^$CHART_ID\$" || error 3 "Invalid chart ID. Please check usage"
[[ -z "$INPUT_FILE" ]] && usage
[[ -z "$OUTPUT_FILE" ]] && error 2 "Please specify an output JPEG or PNG file"

#Detect input file format
case "`head -c 4 < $INPUT_FILE`" in
 '<htm') INPUT_FILE_FORMAT='html';;
 'AAA,') INPUT_FILE_FORMAT='nmon';;
 *) echo "WARN: Cannot detect input file format. Supposing is nmon format"; 
    INPUT_FILE_FORMAT='nmon';;
esac

#If input format is NMON, convert to HTML first with NMONCHART, otherwise just use the HTML
if [[ "$INPUT_FILE_FORMAT" == "nmon" ]]; then
 NMONCHART=`which nmonchart 2>/dev/null`
 [[ -z "$NMONCHART" && -x "./nmonchart" ]] && NMONCHART="./nmonchart"
 [[ -z "$NMONCHART" ]] && error 14 "NmonChart is required by this script. Please install it or download it from http://nmon.sourceforge.net and uncompress it in the script folder"
 [[ -z "`which ksh 2>/dev/null`" ]] && error 15 "ksh not found. This is needed to run nmonchart. Please install it." 
 echo "INFO: Converting NMON file to HTML"
 $NMONCHART $INPUT_FILE $OUTPUT_FILE.htm
else
  cp -f $INPUT_FILE $OUTPUT_FILE.htm
fi

#Render HTML with wkhtmltoimage
echo "INFO: Rendering HTML..."
HTMLTOIMAGE=`which wkhtmltoimage 2>/dev/null`
[[ -z "$HTMLTOIMAGE" && -x "./wkhtmltoimage" ]] && HTMLTOIMAGE="./wkhtmltoimage"
[[ -z "$HTMLTOIMAGE" ]] && error 14 "Cannot find wkhtmltopdf software. Please install it or download it from https://wkhtmltopdf.org/"
#Fix HTML layout
sed -i -e 's|chartArea: {left: "5%", width: "85%", top: "10%", height: "80%"}|"width": '"$GRAPH_WIDTH"',"height": '"$GRAPH_HEIGHT"',chartArea: {left: "'"$AREA_LEFT"'%", width: "'"$AREA_WIDTH"'%", top: "'"$AREA_TOP"'%", height: "'"$AREA_HEIGHT"'%"}|g' -e 's|nmon data file: <b>[^<]*</b>||g' -e 's|<br>||g' -e 's|<body |<body style="margin: 0;" |g' -e 's|<button |<button style="display:none;" |g' $OUTPUT_FILE.htm
#Render HTML
$HTMLTOIMAGE --height $GRAPH_HEIGHT --width $GRAPH_WIDTH --disable-smart-width  --debug-javascript --enable-javascript --run-script 'document.getElementById("draw_'"$CHART_ID"'").click();' $OUTPUT_FILE.htm $OUTPUT_FILE
rm -f $OUTPUT_FILE.htm
echo "INFO: Output image created in $OUTPUT_FILE..."

