#!/usr/bin/env bash
# Launch PassionRide Web Server on port 3000
echo "=================================================="
echo " Starting PassionRide Web Dev Server on Port 3000"
echo " Open in browser: http://localhost:3000"
echo "=================================================="
/snap/bin/flutter run -d web-server --web-port=3000 --web-hostname=localhost "$@"
