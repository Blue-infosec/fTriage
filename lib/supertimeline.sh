#!/bin/bash

if [ $# -ne 1 ] || [ ! -f $1 ]; then
    echo "ERROR - usage: $0 ftriage.conf"
    exit 1
else
    source $1
fi

# If supertimeline OUTDIR does not exist, create it - else, continue 
if [ ! -d "$OUTDIR/supertimeline" ]; then
    echo "$OUTDIR/supertimeline/ does not exist - creating it now..."
    mkdir -p $OUTDIR/supertimeline
else
    echo "Directory $OUTDIR/supertimeline/ already exists - moving on..."
fi

# If fls bodyfile does not exist, create it - else, continue
if [ ! -f "$OUTDIR/timeline/fls.bodyfile" ] && [ -f "$DISKPATH" ]; then
    echo "Creating fls bodyfile..."
    fls -r -m C: $DISKPATH > $OUTDIR/timeline/fls.bodyfile
else
    echo "File $OUTDIR/timeline/fls.bodyfile already exists, or DISKPATH variable does not exist - moving on..."
fi    

# If volatility timeliner bodyfile does not exist, create it - else, continue
if [ ! -f "$OUTDIR/timeline/vol-timeliner.bodyfile" ] && [ -f "$MEMPATH" ]; then
    echo "Creating volatility timeliner bodyfile..."
    vol.py -f $MEMPATH --profile=$PROFILE timeliner --output=body --output-file=$OUTDIR/timeline/vol-timeliner.bodyfile
else
    echo "File $OUTDIR/timeline/vol-timeliner.bodyfile already exists, or MEMPATH variable does not exist - moving on..."
fi    

# Combine fls.bodyfile and vol-timeliner.bodyfile
if [ -f "$OUTDIR/timeline/fls.bodyfile" ] && [ -f "$OUTDIR/timeline/vol-timeliner.bodyfile" ]; then
    echo "Files fls.bodyfile and vol-timeliner.bodyfile both detected - combining now..."
    cp $OUTDIR/timeline/fls.bodyfile $OUTDIR/timeline/fls-vol-timeliner.bodyfile
    cat $OUTDIR/timeline/vol-timeliner.bodyfile >> $OUTDIR/timeline/fls-vol-timeliner.bodyfile
    BODYFILE="$OUTDIR/timeline/fls-vol-timeliner.bodyfile"
elif [ -f "$OUTDIR/timeline/fls.bodyfile" ] && [ ! -f "$OUTDIR/timeline/vol-timeliner.bodyfile" ]; then
    echo "File fls.bodyfile detected, but vol-timeliner.bodyfile was not - moving on..."
    BODYFILE="$OUTDIR/timeline/fls.bodyfile"
elif [ ! -f "$OUTDIR/timeline/fls.bodyfile" ] && [ -f "$OUTDIR/timeline/vol-timeliner.bodyfile" ]; then
    echo "File vol-timeliner.bodyfile detected, but fls.bodyfile was not - moving on..."
    BODYFILE="$OUTDIR/timeline/vol-timeliner.bodyfile"
elif [ ! -f "$OUTDIR/timeline/fls.bodyfile" ] && [ ! -f "$OUTDIR/timeline/vol-timeliner.bodyfile" ]; then
    echo "Neither body files detected - exiting..."
    exit 1
fi

if [[ $TIMELINE_START =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ $TIMELINE_END =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "Date $TIMELINE_START and $TIMELINE_END are both in the correct format (YYYY-MM-DD) - moving on..."
else
    echo "Date $TIMELINE_START or $TIMELINE_END is invalid format (YYYY-MM-DD) - exiting..."
    exit 1
fi

# If unfiltered mactime timeline file does not exist, create it - else, continue
if [ ! -f "$OUTDIR/supertimeline/supertimeline.csv" ]; then
    echo "Creating supertimeline.csv..."
    mactime -z UTC -y -d -b $BODYFILE $TIMELINE_START..$TIMELINE_END > $OUTDIR/supertimeline/supertimeline.csv
else
    echo "File supertimeline.csv already exists - exiting now..."
    #echo "File supertimeline.csv already exists - replacing now..."
    #mactime -z UTC -y -d -b $BODYFILE $TIMELINE_START..$TIMELINE_END > $OUTDIR/supertimeline/supertimeline.csv
fi    

if [ -f "$OUTDIR/supertimeline/supertimeline.csv" ] && [ -f $TIMELINE_REDUCE ]; then
    echo "Creating supertimeline-filtered.csv..."
    grep -v -i -f $TIMELINE_REDUCE $OUTDIR/supertimeline/supertimeline.csv > $OUTDIR/supertimeline/supertimeline-filtered.csv
else   
    echo "File supertimeline.csv does not exist, or $TIMELINE_REDUCE does not exist - exiting..."
    exit 1
fi