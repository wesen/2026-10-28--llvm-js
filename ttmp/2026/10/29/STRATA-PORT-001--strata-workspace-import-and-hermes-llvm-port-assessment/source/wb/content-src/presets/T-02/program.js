// A counter object whose getter has a side effect. The read in main is "unused".
let reads = 0;
const counter = {
  get next() {
    reads = reads + 1;
    return reads;
  },
};
const ignored = counter.next;
print("reads: " + reads);
