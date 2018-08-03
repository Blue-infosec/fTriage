#!/bin/bash

# Author:
# Matt May <mcmay.web@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a
# copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

if [ $# -ne 1 ] || [ ! -f $1 ]; then
    echo "ERROR - usage: $0 ftriage.conf"
    exit 1
else
    source $1
fi

# If foremost_slack OUTDIR does not exist, create it - else, continue 
build_outdir "$OUTDIR/carving/foremost_slack"

# If blkls.slack dump does not exist, create it - else, continue
if [ ! -f "$OUTDIR/carving/$HOSTNAME.blkls.slack" ]; then
    echo "Dumping slack space..."
    blkls -s $DISKPATH > $OUTDIR/carving/$HOSTNAME.blkls.slack
else
    echo "File $OUTDIR/carving/$HOSTNAME.blkls.slack already exists - moving on..."
fi    

# If $OUTDIR/foremost_slack is not empty, inform user and exit
if_not_empty_exit_else_continue "$OUTDIR/carving/foremost_slack"

echo "Carving files from slack space..."
foremost -q -o $OUTDIR/carving/foremost_slack -c $FOREMOST_CONF $OUTDIR/carving/$HOSTNAME.blkls.slack
#foremost -q -b 4096 -o $OUTDIR/carving/foremost_slack -c /usr/local/etc/foremost.conf $OUTDIR/carving/$HOSTNAME.blkls

if [ -f "$OUTDIR/carving/foremost_slack/audit.txt" ]; then
    echo ""
    egrep "(FILES EXTRACTED|:=)" $OUTDIR/carving/foremost_slack/audit.txt
else
    echo "File $OUTDIR/carving/foremost_slack/audit.txt does not exist..."
fi
