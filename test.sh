#!/bin/sh

function lint() {
  xmllint --c14n "$1"|xmllint --format - 
}

set -o pipefail && xcodebuild -workspace ContentfulPlugin.xcworkspace \
	-scheme ContentfulModelGenerator 2>/dev/null | xcpretty -c

BUILD="`ls -d $HOME/Library/Developer/Xcode/DerivedData/ContentfulPlugin-*`"
$BUILD/Build/Products/Debug/ContentfulModelGenerator generate \
	--spaceKey=a3rsszoo7qqp \
	--accessToken=$CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN

lint Tests/a3rsszoo7qqp.xml >1.xml
lint ContentfulModel.xcdatamodeld/ContentfulModel.xcdatamodel/contents >2.xml
diff -w 1.xml 2.xml

rm -f 1.xml 2.xml
rm -rf ContentfulModel.xcdatamodeld
