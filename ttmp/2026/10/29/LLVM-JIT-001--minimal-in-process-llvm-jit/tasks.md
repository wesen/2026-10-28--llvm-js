# Tasks

## TODO
- [x] Build optional LLVM 18 LLJIT target and qualify coexistence with Hermes llvh and one runtime implementation. <!-- t:aafx -->
- [x] Implement owned IR parsing, target validation, LLVM verification, unique creator lookup, and symbol resolution. <!-- t:xocj -->
- [x] Execute multiple creator-only units in one runtime using guarded initialization. <!-- t:k0rp -->
- [x] Implement state/error handling and retain initialized code through runtime destruction, including throwing initializers. <!-- t:ckwp -->
- [x] Qualify cross-unit object and closure identity, forced GC, exceptions, jobs, and repeated engine teardown. <!-- t:3kpn -->
- [x] Extract reusable source-to-IR frontend options and diagnostics; remove frontend subprocess from source API. <!-- t:z1se -->
- [x] Add minimal host CLI and qualify source submissions plus existing bundled module examples. <!-- t:1qoq -->
- [x] Run relevant AOT/native regression gates, record latency and retained-memory measurements, and document limits. <!-- t:ib1q -->
