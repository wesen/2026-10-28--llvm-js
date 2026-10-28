#include "hermes/VM/static_h.h"
SHLegacyValue native_return_probe(SHRuntime *shr) { return shr->global_; }
SHLegacyValue native_call_probe(SHRuntime *shr, SHLegacyValue (*p)(SHRuntime *)) { return p(shr); }
