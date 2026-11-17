# PREZPH=/tmp/poker-hand-evaluator
# PREPHE=/tmp/phe
# mkdir $PREZPH $PREPHE

# sudo sysctl -w kernel.perf_event_paranoid=0
RELEASE=small
STRIP=true

runBench() {
    zig build --release=$RELEASE       -DbenchN=5 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-5-$RELEASE
    zig build --release=$RELEASE -Dphe -DbenchN=5 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-c-5-$RELEASE
    ~/Documents/Code/zig/poop/zig-out/bin/poop -d 2000 zig-out/bin/bench-c-5-$RELEASE zig-out/bin/bench-5-$RELEASE

    zig build --release=$RELEASE       -DbenchN=7 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-7-$RELEASE
    zig build --release=$RELEASE -Dphe -DbenchN=7 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-c-7-$RELEASE
    ~/Documents/Code/zig/poop/zig-out/bin/poop -d 2000 zig-out/bin/bench-c-7-$RELEASE zig-out/bin/bench-7-$RELEASE
}

runBench

RELEASE=fast
runBench
