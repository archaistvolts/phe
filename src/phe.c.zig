pub const ev5 = @cImport({
    @cInclude("evaluator5.c");
    @cInclude("hash.c");
});
pub const ev7 = @cImport({
    @cInclude("evaluator7.c");
    // @cInclude("hash.c");
});

pub extern fn evaluate_omaha_cards(c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
