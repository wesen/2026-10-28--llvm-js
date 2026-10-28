// SHLLVM_TEST: {"kind":"compile-error","family":"async"}
async function invalid() { return await; }
