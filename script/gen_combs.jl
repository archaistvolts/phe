using Combinatorics
println("pub const data = [_][5]u6{")
for comb in combinations(16:51, 5)
    print(".{")
    print(join(comb, ","))
    println("},")
end
println("};")