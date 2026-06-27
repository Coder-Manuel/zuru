#!/bin/bash
MIN_COVERAGE=20

rm -rf test/.data/
flutter test --coverage
TEST_EXIT=$?
if [ $TEST_EXIT -ne 0 ]; then
  echo "❌ Tests Failed"
  exit 1
fi
genhtml coverage/lcov.info -o coverage/html
TOTAL_COVERAGE=$(awk -F ':' '
  $1=="LF" { total += $2 }
  $1=="LH" { covered += $2 }
  END { if (total > 0) printf "%.2f", (covered/total*100); else print 0 }
' coverage/lcov.info)

echo "Total coverage: $TOTAL_COVERAGE%"
if (( $(echo "$TOTAL_COVERAGE < $MIN_COVERAGE" | bc -l) )); then
  echo "❌ Coverage is below threshold ($MIN_COVERAGE%)"
  exit 1
else
  echo "✅ Coverage is above threshold"
fi
