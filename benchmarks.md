## 7/25/20
- Test [1/15] test "evAll5"...evaluateCards-5 cards 27052.1 Khands/s
- Test [2/15] test "evAll7"...evaluateCards-7 cards 25724.3 Khands/s
- Test [9/15] test "fuzz shortdeck5"...evaluateShortdeck-5 cards 17800.6 Khands/s
- Test [10/15] test "fuzz shortdeck7"...evaluateShortdeck-7 cards 13032.9 Khands/s
- Test [12/15] test "fuzz razz 5"...evaluateCardsRazz-5 cards 19723.2 Khands/s

## hashQuinary unroll loop
- Test [1/15] test "evAll5"...evaluateCards-5 cards 29665.6 Khands/s
- Test [2/15] test "evAll7"...evaluateCards-7 cards 27409.3 Khands/s
- Test [9/15] test "fuzz shortdeck5"...evaluateShortdeck-5 cards 15600.3 Khands/s
- Test [10/15] test "fuzz shortdeck7"...evaluateShortdeck-7 cards 12887.2 Khands/s
- Test [12/15] test "fuzz razz 5"...evaluateCardsRazz-5 cards 14787.9 Khands/s

## use util.combNCb rather than util.combN
- Test [1/15] test "evAll5"...evaluateCards-7 cards 29981.5 Khands/s
- Test [2/15] test "evAll7"...evaluateCards-7 cards 28131.9 Khands/s
- Test [9/15] test "fuzz shortdeck5"...evaluateShortdeck-5 cards 23670.8 Khands/s
- Test [10/15] test "fuzz shortdeck7"...evaluateShortdeck-7 cards 25307.5 Khands/s
- Test [12/15] test "fuzz razz 5"...evaluateCardsRazz-5 cards 23787.4 Khands/s

I have no idea why using the async channel comb functions would slow down the benchmarks. 

## with Card.id as u6
Test [1/10] test "benchmark 5"...evaluate5Cards-5 cards 54806.2 Khands/s
Test [2/10] test "benchmark 5 c"...evaluate5CardsC-5 cards 68130.1 Khands/s
Test [3/10] test "benchmark 7"...evaluate7Cards-7 cards 47714.7 Khands/s
Test [4/10] test "benchmark 7 c"...evaluate7CardsC-7 cards 64467.9 Khands/s
Test [5/10] test "benchmark omaha"...evaluateOmahaCards-9 cards 17181.3 Khands/s
Test [6/10] test "benchmark omaha c"...evaluateOmahaCards-9 cards 18783.2 Khands/s
Test [7/10] test "benchmark shortdeck 5"...evaluateShortdeck5-5 cards 63859.3 Khands/s
Test [8/10] test "benchmark shortdeck 7"...evaluateShortdeck7-7 cards 60067.6 Khands/s
Test [9/10] test "benchmark razz 5"...evaluateRazz5Vec-5 cards 47005.5 Khands/s
Test [10/10] test "benchmark razz 7"...evaluateRazz7Vec-7 cards 43166.2 Khands/s

## with Card.id as u8
Test [1/10] test "benchmark 5"...evaluate5Cards-5 cards 62611.3 Khands/s
Test [2/10] test "benchmark 5 c"...evaluate5CardsC-5 cards 69649.6 Khands/s
Test [3/10] test "benchmark 7"...evaluate7Cards-7 cards 49789.4 Khands/s
Test [4/10] test "benchmark 7 c"...evaluate7CardsC-7 cards 64953.6 Khands/s
Test [5/10] test "benchmark omaha"...evaluateOmahaCards-9 cards 19508.0 Khands/s
Test [6/10] test "benchmark omaha c"...evaluateOmahaCards-9 cards 19617.4 Khands/s
Test [7/10] test "benchmark shortdeck 5"...evaluateShortdeck5-5 cards 71851.5 Khands/s
Test [8/10] test "benchmark shortdeck 7"...evaluateShortdeck7-7 cards 70843.5 Khands/s
Test [9/10] test "benchmark razz 5"...evaluateRazz5Vec-5 cards 43473.7 Khands/s
Test [10/10] test "benchmark razz 7"...evaluateRazz7Vec-7 cards 43798.1 Khands/s

- ev5 14% faster, still 11% slower than c version