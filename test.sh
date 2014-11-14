#!/bin/sh

function lint() {
  xmllint --c14n "$1"|xmllint --format - 
}

set -o pipefail && xcodebuild -target ContentfulModelGenerator 2>/dev/null | xcpretty -c

build/Release/ContentfulModelGenerator generate \
	--spaceKey=a3rsszoo7qqp --accessToken=57a1ef74e87e234bed4d3f932ec945a82dae641d6ea2b2435ea2837de94d6be5

lint Tests/a3rsszoo7qqp.xml >1.xml
lint ContentfulModel.xcdatamodeld/ContentfulModel.xcdatamodel/contents >2.xml
diff -w 1.xml 2.xml

rm -f 1.xml 2.xml
rm -rf ContentfulModel.xcdatamodeld
