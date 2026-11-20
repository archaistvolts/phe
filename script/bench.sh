# sudo sysctl -w kernel.perf_event_paranoid=0

RELEASE="${RELEASE:-small}"
STRIP="${STRIP:-true}"

runBench() {
    zig build --release=$RELEASE -DbenchN=5 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-5-$RELEASE
    zig build --release=$RELEASE -DbenchN=5 -DbenchR=13 -Dstrip=$STRIP -Dbench-target=phe_c
    cp zig-out/bin/bench zig-out/bin/bench-c-5-$RELEASE
    ~/Documents/Code/zig/poop/zig-out/bin/poop -d 1000 zig-out/bin/bench-c-5-$RELEASE zig-out/bin/bench-5-$RELEASE

    zig build --release=$RELEASE -DbenchN=7 -DbenchR=13 -Dstrip=$STRIP
    cp zig-out/bin/bench zig-out/bin/bench-7-$RELEASE
    zig build --release=$RELEASE -DbenchN=7 -DbenchR=13 -Dstrip=$STRIP -Dbench-target=phe_c
    cp zig-out/bin/bench zig-out/bin/bench-c-7-$RELEASE
    ~/Documents/Code/zig/poop/zig-out/bin/poop -d 1000 zig-out/bin/bench-c-7-$RELEASE zig-out/bin/bench-7-$RELEASE
}

runBench2() {
    echo "5-phe-c-$RELEASE"
    time zig-out/bin/bench-c-5-$RELEASE
    # zig build bench -Dverbose -DbenchN=5 --release=$RELEASE -Dstrip=$STRIP -Dbench-target=phe_c

    # echo "5-phe-z-$RELEASE"
    # zig build bench -Dverbose -DbenchN=5 -Dbench-target=phe_z --release=$RELEASE -Dstrip=$STRIP

    echo "5-$RELEASE"
    zig build bench -Dverbose -DbenchN=5 --release=$RELEASE -Dstrip=$STRIP

    echo "7-phe-c-$RELEASE"
    time zig-out/bin/bench-c-7-$RELEASE
    # zig build bench -Dverbose -DbenchN=7 --release=$RELEASE -Dstrip=$STRIP -Dbench-target=phe_c

    # echo "7-phe-z-$RELEASE"
    # zig build bench -Dverbose -DbenchN=7 -Dbench-target=phe_z --release=$RELEASE -Dstrip=$STRIP

    echo "7-$RELEASE"
    zig build bench -Dverbose -DbenchN=7 --release=$RELEASE -Dstrip=$STRIP
}

BENCH="${BENCH:-1}"
if [ "$BENCH" = "1" ]; then
	runBench
else
    runBench2
fi
