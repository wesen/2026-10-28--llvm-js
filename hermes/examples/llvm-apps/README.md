# Application qualification drafts

Exploratory sources for LLVM-APPS-001. These are not a completed application suite.
The persistent host and shared runner have not been implemented. Data and queue
sources have not yet received the designed qualification matrix.

The archive probe pins the unmodified fflate 0.8.2 browser ESM distribution.
Install with `pnpm --dir hermes/examples/llvm-apps install --frozen-lockfile --ignore-scripts`.
The ticket retains the small input and outputs: unoptimized frontend rejected
at the 1,024-slot frame bound; optimized frontend completed the round trips.
No compiler/runtime behavior was changed for this experiment.

See the ticket design for input contracts, comparison modes, milestones, and
acceptance criteria. The report describes completed engine/JIT work separately
from this proposed campaign.
