#!/bin/bash
echo "test will run $1 seconds"

$1/test/stressapptest -s $2 --pause_delay 3600 --pause_duration 1 -W --stop_on_errors  -M 32 > $3 &

exit 0

