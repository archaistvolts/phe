
### short deck
(s): 4 (suits)
(ranks): 9
(str8 flush): 6c1*(s) = 6*4 = 24 (6 distinct)
(4 kind): (ranks)*(ranks-1)*(s) = 9*8*4 = 288 (288 / 4 = 72 distinct)
(full house): 9c2*2*4c3*4c2 = 36*2*4*6 =  1728 (1728 / 12 = 72 distinct)
(flush): (s)*(9c5 - (str8 flush)) = 4*126-24 = 504-24 = 480 (480 / 4 = 120 distinct)
(str8): 6c1*((s)^5) - (str8 flush) = 6*1024-24 = 6120 (6120 / 4^5 = 6 distinct)
(3 kind): 9c1*4c3*8c2*(s)*(s) = 9*4*28*4*4 = 16128 (16128 / (4*4*4) = 252 distinct)
(2 pr): 9c2*4c2*4c2*7c1*(s) = 36*6*6*7*4 = 36288 (36288 / (4*6*6) = 252 distinct)
(pr): 9c1*4c2*8c3*(4^3) = 9*6*56*64 = 193536 (193536 / (64 * 6) =  504 distinct)
(hi card): 9c5*(4^5) - ((str8 flush) + (flush) + (str8)) = 
  126*1024- (24+480+6120) = 122400 (126 - 6 =  120 distinct)
(all): 36c5 = 376992 = 24+288+480+1728+16128+6120+36288+193536+122400
  (distinct): 6+72+72+120+6+252+252+504+120 = 1404
(distinct flushes): 126
(distinct nonflushes): 1404-126 = 1278

### long deck
(s): 4 (suits)
(ranks): 13
(str8 flush): 10c1*(s) = 10*4 = 40 (10 distinct)
(4 kind): (ranks)*(ranks-1)*(s) = 13*12*4 = 624 (624 / 4 = 156 distinct)
(full house): 13c1*4c3*12c1*4c2 = 13*4*12*6 =  3744 (3744 / 24 = 156 distinct)
(flush): (s)*(13c5 - (str8 flush)) = 4*1287-40 = 5108 (5108 / 4 = 1277 distinct)
(str8): 10c1*((s)^5) - (str8 flush) = 10*1024-40 = 10200 (10200 / 4^5 = 10 distinct)
(3 kind): 13c1*4c3*12c2*(s)*(s) = 13*4*66*4*4 = 54912 (54912 / (4*4*4) = 858 distinct)
(2 pr): 13c2*4c2*4c2*11c1*(s) = 78*6*6*11*4 =  123552 (123552 / (4*6*6) = 858 distinct)
(pr): 13c1*4c2*12c3*(4^3) = 13*6*220*64 = 1098240 (1098240 / (64 * 6) =  2860 distinct)
(hi card): 13c5*(4^5) - ((str8 flush) + (flush) + (str8)) = 
  1287*1024- (40+5108+10200) = 1302540 (1287 - 10 =  1277 distinct)
(all): 52c5 = 2598960 = 
  (distinct): 10+156+156+1277+10+858+858+2860+1277 = 7462
(distinct flushes): 1287
(distinct nonflushes): 7462 - 1287 = 6175

### short deck table generation

as discussed in https://github.com/HenryRLee/PokerHandEvaluator/issues/23

The strategy is to 'reuse' the long deck rank values for short deck by adjusting flush and full house ranks by -156 and +1277 respecively.  a56789 straights and a56789 straight flushes are special cases mapped to known values 1609 and 10.  There are 5 card and 7 card tables gen routines.  5 card gen maps directly from known ranks 747 => 10 and 6610 => 1610.  7 card gen uses the hand binary to detect a56789 straights.  

### short deck performance
Expected to be around the same as standard evaluation

evaluateCards-5 cards 26600.8 Khands/s
evaluateCards-7 cards 25127.8 Khands/s
evaluateShortdeck-5 cards 15172.3 Khands/s
evaluateShortdeck-7 cards 15872.2 Khands/s
