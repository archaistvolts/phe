using Libdl

lib = Libdl.dlopen("./zig-cache/lib/libphe.so")
ev5h = Libdl.dlsym(lib, :evaluate_5hand_w)
ev5 = Libdl.dlsym(lib, :evaluate_5cards_w)
ev7h = Libdl.dlsym(lib, :evaluate_7hand_w)
ev7 = Libdl.dlsym(lib, :evaluate_7cards_w)
hash_quinary5 = Libdl.dlsym(lib, :hash_quinary5_w)
cards_to_binary7_w = Libdl.dlsym(lib, :cards_to_binary7_w)
cards_to_binary5_w = Libdl.dlsym(lib, :cards_to_binary5_w)

hash_quinary(q, num_ranks, len) = ccall(hash_quinary5, Culong, (Ptr{UInt8}, UInt8, UInt8), pointer(q), num_ranks, len)

function hashcodes(hand, num_ranks, len)
    q = zeros(UInt8, num_ranks)
    for card in hand
        q[card >> 2 + 1] += 1
    end
    # println(q)
    return hash_quinary(q, num_ranks, len)
end

function hash_binary(q, len, k)
	sum = 0
	for i in 1:len # (i=0; i<len; i++)
		if q[i] != 0
            if len - i - 1 >= k
                # sum += choose[len-i-1][k];
                sum += tmp.choose[len - i][k]; 
            end
			k -= 1;
			if k == 0 break; end
        end
    end
	return sum + 1;
end


# rank = ccall(ev7, Cshort, (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8), 
#     combids[1], combids[2], combids[3], combids[4], combids[5], 
#     num_ranks)
# hand = "6s7s8s9sQhKhAh"
hand = "6s7s8s9sAh"
hand = "Ad7h8d6c9s"
# hand = "Ad6s7d8s9s9h9c"

bin, rank = if length(hand) == 10
    (ccall(cards_to_binary5_w, Cshort, (Ptr{UInt8},), pointer(hand)),
    ccall(ev5h, Cshort, (Ptr{UInt8}, UInt, UInt8), pointer(hand), length(hand), 13))
else
    @assert(length(hand) == 14)
    (ccall(cards_to_binary7_w, Cshort, (Ptr{UInt8},), pointer(hand)),
    ccall(ev7h, Cshort, (Ptr{UInt8}, UInt, UInt8), pointer(hand), length(hand), 13))
end

println("$(bitstring(bin)), $rank")