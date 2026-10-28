function* sequence() { yield 1; yield 2; }
print(sequence().next().value);
