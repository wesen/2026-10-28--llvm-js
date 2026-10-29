// Runtime-side ABI. Tagged values stay inside the runtime/console library.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
void *shllvm_host_create(void);
int shllvm_host_execute(void *host, void *creator);
int shllvm_host_drain(void *host);
void shllvm_host_collect(void *host);
void shllvm_host_destroy(void *host);
#ifdef __cplusplus
}
#endif
