PREFIX1=/tmp/poker-hand-evaluator
PREFIX2=/tmp/phe
RELEASE=small
mkdir $PREFIX1 $PREFIX2

runBench() {
zig build --release=$RELEASE       -DbenchN=5 -DbenchR=13 --prefix $PREFIX1
zig build --release=$RELEASE -Dphe -DbenchN=5 -DbenchR=13 --prefix $PREFIX2
~/Documents/Code/zig/poop/zig-out/bin/poop $PREFIX2/bin/bench $PREFIX1/bin/bench

zig build --release=$RELEASE       -DbenchN=7 -DbenchR=13 --prefix $PREFIX1
zig build --release=$RELEASE -Dphe -DbenchN=7 -DbenchR=13 --prefix $PREFIX2
~/Documents/Code/zig/poop/zig-out/bin/poop $PREFIX2/bin/bench $PREFIX1/bin/bench
}

runBench
RELEASE="fast"
runBench
