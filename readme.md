# TODO
- [x] add short deck
  - [x] generate hashtable_sd5 and hashtable_sd7
  - [x] port tests from go version
    - tests are called: shortdeck, fuzz shortdeck5 and fuzz shortdeck7
  - [] evaluator_test.sdTest could more thoroughly validate straights
  - [] why so slow?
- [x] get build.zig working for 
  - [x] building lib
  - [x] running tests
  - [x] building tables - move all tables into separate lib so they don't have to be rebuilt
- [x] compare against c version in tests
  - [x] just add c source for evaluator_omaha.  other evaluate fns can be cImported
- [x] razz
  - [x] generate 5 card lookup table 
  - [w] 5 card tests
  - [] why so slow?

- [x] dry up evaluator_tests. create benchmark_runner or something to make benchmarks more uniform. 