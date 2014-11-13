#!/bin/sh

set -o pipefail && xcodebuild -target ContentfulModelGenerator 2>/dev/null | xcpretty -c

build/Release/ContentfulModelGenerator generate \
	--spaceKey=a3rsszoo7qqp --accessToken=57a1ef74e87e234bed4d3f932ec945a82dae641d6ea2b2435ea2837de94d6be5

rm -rf ContentfulModel.xcdatamodeld
