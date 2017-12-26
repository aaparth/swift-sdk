#!/bin/bash

set -o pipefail
exitCode=0
DESTINATION="OS=11.2,name=iPhone 7"

function checkStatus {
    if [[ $exitCode == 0 && $1 != 0 ]]; then
        exitCode=$1
    fi
}

schemes=(
	"AlchemyDataNewsV1"
	"AlchemyLanguageV1"
	"AlchemyVisionV1"
	"ConversationV1"
	"DialogV1"
	"DiscoveryV1"
	"DocumentConversionV1"
	"LanguageTranslatorV2"
	"NaturalLanguageClassifierV1"
	"NaturalLanguageUnderstandingV1"
	"PersonalityInsightsV2"
	"PersonalityInsightsV3"
	"RelationshipExtractionV1Beta"
	"RetrieveAndRankV1"
	"SpeechToTextV1"
	"TextToSpeechV1"
	"ToneAnalyzerV3"
	"TradeoffAnalyticsV1"
	"VisualRecognitionV3"
)

BUILD_ROOT=$(xcodebuild -showBuildSettings | grep '\<BUILD_ROOT\>' | awk '{print $3}')
rm -rf $BUILD_ROOT/../ProfileData

COVERAGE_DIR=$BUILD_ROOT/../Coverage
rm -rf $COVERAGE_DIR
mkdir $COVERAGE_DIR

for scheme in ${schemes[@]}; do
    xcodebuild -quiet -scheme "$scheme" -destination "$DESTINATION" -enableCodeCoverage YES test
    PROF_DIR=$(dirname $(find $BUILD_ROOT/.. -name Coverage.profdata))
    cp $PROF_DIR/*.profraw $COVERAGE_DIR
    checkStatus $?
done

xcrun llvm-profdata merge -sparse $(ls $COVERAGE_DIR/*.profraw) -o $COVERAGE_DIR/Coverage.profdata

FRAMEWORKS=$(ls -d $BUILD_ROOT/Debug-iphonesimulator/*.framework)
BINARIES=$(echo $FRAMEWORKS | sed 's/\(\([A-Za-z0-9]*\).framework\)/\1\/\2/g' | sed 's/ / -object /g')

xcrun llvm-cov report -instr-profile $COVERAGE_DIR/Coverage.profdata $BINARIES

exit $exitCode
