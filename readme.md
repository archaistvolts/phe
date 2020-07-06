# TODO
[x] - add short deck
  [x] - generate hashtable_sd5 and hashtable_sd7
  [x] - port tests from go version
    - tests are called: shortdeck, fuzz shortdeck5 and fuzz shortdeck7
  [] - perhaps evaluator_test.sdTest needs to more thoroughly validate straights?
[x] - get build.zig working for 
  [x] - building lib
  [x] - running tests
  [x] - building tables - move all tables into separate lib so they don't have to be rebuilt
[x] - compare against c version in tests
  [x] - just add c source for evaluator_omaha.  other evaluate fns can be cImported
