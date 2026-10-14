#!/usr/bin/env python3
"""Build the detailed Accord station; preserves legacy GLB for comparisons."""
import sys
from build_stations import main
if __name__=='__main__':
    sys.argv[1:]=['--faction','accord']
    main()
