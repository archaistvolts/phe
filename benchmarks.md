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