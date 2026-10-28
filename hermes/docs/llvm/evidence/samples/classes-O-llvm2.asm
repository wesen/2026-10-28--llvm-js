0000000000106ca0 <shllvm_f0>:
  106ca0:      	pushq	%rbp
  106ca1:      	movq	%rsp, %rbp
  106ca4:      	pushq	%r15
  106ca6:      	pushq	%r14
  106ca8:      	pushq	%r13
  106caa:      	pushq	%r12
  106cac:      	pushq	%rbx
  106cad:      	subq	$0x1c8, %rsp            # imm = 0x1C8
  106cb4:      	movq	%rdi, %rbx
  106cb7:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  106cbc:      	movl	$0x47, %edi
  106cc1:      	callq	0x108530 <shllvm_frame_size>
  106cc6:      	movq	%rsp, %r14
  106cc9:      	addq	$0xf, %rax
  106ccd:      	andq	$-0x10, %rax
  106cd1:      	subq	%rax, %r14
  106cd4:      	movq	%r14, %rsp
  106cd7:      	movl	0x9945c2(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  106cde:      	movq	%rbx, %rdi
  106ce1:      	movq	%r14, %rsi
  106ce4:      	movl	$0x47, %edx
  106ce9:      	movl	$0x6, %ecx
  106cee:      	movl	%r13d, %r8d
  106cf1:      	callq	0x1085c0 <shllvm_enter>
  106cf6:      	movq	%rax, %r15
  106cf9:      	movq	%rax, -0x38(%rbp)
  106cfd:      	movq	%r14, -0xb0(%rbp)
  106d04:      	movq	%r14, %rdi
  106d07:      	callq	0x108970 <shllvm_roots>
  106d0c:      	movq	%rax, %r12
  106d0f:      	movq	%rax, -0xa8(%rbp)
  106d16:      	movq	%rbx, %rdi
  106d19:      	movl	%r13d, %esi
  106d1c:      	callq	0x108540 <shllvm_get_unit>
  106d21:      	movq	%rax, %r13
  106d24:      	movq	%rax, -0x48(%rbp)
  106d28:      	leaq	0x10(%r12), %rax
  106d2d:      	movq	%rax, -0x40(%rbp)
  106d31:      	leaq	0xe8(%r12), %rax
  106d39:      	movq	%rax, -0x98(%rbp)
  106d40:      	leaq	0x1c8(%r12), %r14
  106d48:      	leaq	0x1d0(%r12), %rax
  106d50:      	movq	%rax, -0xf0(%rbp)
  106d57:      	leaq	0x1d8(%r12), %rax
  106d5f:      	movq	%rax, -0xf8(%rbp)
  106d66:      	leaq	0x1e0(%r12), %rax
  106d6e:      	movq	%rax, -0x108(%rbp)
  106d75:      	leaq	0x1e8(%r12), %rax
  106d7d:      	movq	%rax, -0x110(%rbp)
  106d84:      	leaq	0x1f0(%r12), %rax
  106d8c:      	movq	%rax, -0x118(%rbp)
  106d93:      	leaq	0x1f8(%r12), %rax
  106d9b:      	movq	%rax, -0x120(%rbp)
  106da2:      	leaq	0x200(%r12), %rax
  106daa:      	movq	%rax, -0x130(%rbp)
  106db1:      	leaq	0x208(%r12), %rax
  106db9:      	movq	%rax, -0x140(%rbp)
  106dc0:      	leaq	0x210(%r12), %rax
  106dc8:      	movq	%rax, -0x148(%rbp)
  106dcf:      	leaq	0x218(%r12), %rax
  106dd7:      	movq	%rax, -0x158(%rbp)
  106dde:      	leaq	0x220(%r12), %rax
  106de6:      	movq	%rax, -0x160(%rbp)
  106ded:      	leaq	0x228(%r12), %rax
  106df5:      	movq	%rax, -0x170(%rbp)
  106dfc:      	movq	%rbx, %rdi
  106dff:      	movq	%r15, %rsi
  106e02:      	xorl	%edx, %edx
  106e04:      	callq	0x10a890 <shllvm_check_invocation>
  106e09:      	xorl	%eax, %eax
  106e0b:      	movl	%eax, %r15d
  106e0e:      	movq	%r14, %rdi
  106e11:      	xorl	%esi, %esi
  106e13:      	movq	%r15, %rdx
  106e16:      	callq	0x108400 <shllvm_constant>
  106e1b:      	movq	-0xf0(%rbp), %rdi
  106e22:      	movq	%rbx, %rsi
  106e25:      	movq	%r13, %rdx
  106e28:      	movl	$0x2, %ecx
  106e2d:      	callq	0x108ae0 <shllvm_symbol>
  106e32:      	movq	-0xf8(%rbp), %rdi
  106e39:      	movl	$0x2, %esi
  106e3e:      	movq	%r15, %rdx
  106e41:      	callq	0x108400 <shllvm_constant>
  106e46:      	movq	-0x108(%rbp), %rdi
  106e4d:      	movq	%rbx, %rsi
  106e50:      	movq	%r13, %rdx
  106e53:      	movl	$0x8, %ecx
  106e58:      	callq	0x108ae0 <shllvm_symbol>
  106e5d:      	movq	-0x110(%rbp), %rdi
  106e64:      	movq	%rbx, %rsi
  106e67:      	movq	%r13, %rdx
  106e6a:      	movl	$0x4, %ecx
  106e6f:      	callq	0x108ae0 <shllvm_symbol>
  106e74:      	movq	-0x118(%rbp), %rdi
  106e7b:      	movq	%rbx, %rsi
  106e7e:      	movq	%r13, %rdx
  106e81:      	movl	$0x6, %ecx
  106e86:      	callq	0x108ae0 <shllvm_symbol>
  106e8b:      	movabsq	$0x4014000000000000, %rdx # imm = 0x4014000000000000
  106e95:      	movq	-0x120(%rbp), %rdi
  106e9c:      	movl	$0x3, %esi
  106ea1:      	callq	0x108400 <shllvm_constant>
  106ea6:      	movabsq	$0x403e000000000000, %rdx # imm = 0x403E000000000000
  106eb0:      	movq	-0x130(%rbp), %rdi
  106eb7:      	movl	$0x3, %esi
  106ebc:      	callq	0x108400 <shllvm_constant>
  106ec1:      	movl	$0x1, %edx
  106ec6:      	movq	-0x140(%rbp), %rdi
  106ecd:      	movl	$0x2, %esi
  106ed2:      	callq	0x108400 <shllvm_constant>
  106ed7:      	movq	-0x148(%rbp), %rdi
  106ede:      	movq	%rbx, %rsi
  106ee1:      	movq	%r13, %rdx
  106ee4:      	movl	$0x9, %ecx
  106ee9:      	callq	0x108ae0 <shllvm_symbol>
  106eee:      	movabsq	$0x401c000000000000, %rdx # imm = 0x401C000000000000
  106ef8:      	movq	-0x158(%rbp), %rdi
  106eff:      	movl	$0x3, %esi
  106f04:      	callq	0x108400 <shllvm_constant>
  106f09:      	movq	-0x160(%rbp), %rdi
  106f10:      	movq	%rbx, %rsi
  106f13:      	movq	%r13, %rdx
  106f16:      	movl	$0xa, %ecx
  106f1b:      	callq	0x108ae0 <shllvm_symbol>
  106f20:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  106f2a:      	movq	-0x170(%rbp), %rdi
  106f31:      	movl	$0x3, %esi
  106f36:      	callq	0x108400 <shllvm_constant>
  106f3b:      	callq	0x10ac90 <shllvm_try_size>
  106f40:      	movq	%rsp, %rcx
  106f43:      	addq	$0xf, %rax
  106f47:      	andq	$-0x10, %rax
  106f4b:      	movq	%rcx, %rsi
  106f4e:      	subq	%rax, %rsi
  106f51:      	movq	%rsi, %rsp
  106f54:      	movl	$0x0, -0x2c(%rbp)
  106f5b:      	movq	%rbx, %rdi
  106f5e:      	movq	%rsi, -0xa0(%rbp)
  106f65:      	callq	0x10aca0 <shllvm_try_begin>
  106f6a:      	movq	%rax, %rdi
  106f6d:      	callq	0x2d5b0 <_setjmp@plt>
  106f72:      	testl	%eax, %eax
  106f74:      	je	0x10706a <shllvm_f0+0x3ca>
  106f7a:      	movq	-0x48(%rbp), %r13
  106f7e:      	movl	-0x2c(%rbp), %r14d
  106f82:      	movq	%rbx, %rdi
  106f85:      	movq	-0xb0(%rbp), %rsi
  106f8c:      	movq	-0x38(%rbp), %rdx
  106f90:      	movl	$0x6, %ecx
  106f95:      	callq	0x10ad30 <shllvm_catch_prepare>
  106f9a:      	cmpl	$0x1, %r14d
  106f9e:      	jne	0x10776e <shllvm_f0+0xace>
  106fa4:      	leaq	0x168(%r12), %r14
  106fac:      	leaq	0x170(%r12), %r15
  106fb4:      	leaq	0x178(%r12), %rax
  106fbc:      	movq	%rax, -0xe8(%rbp)
  106fc3:      	addq	$0x180, %r12            # imm = 0x180
  106fca:      	movl	$0x0, -0x2c(%rbp)
  106fd1:      	movq	%r14, %rdi
  106fd4:      	movq	%rbx, %rsi
  106fd7:      	callq	0x10ad40 <shllvm_catch_value>
  106fdc:      	movq	%r15, %rdi
  106fdf:      	movq	%rbx, %rsi
  106fe2:      	movq	%r13, %rdx
  106fe5:      	movq	-0x98(%rbp), %rcx
  106fec:      	movl	$0x9, %r8d
  106ff2:      	movl	$0x1, %r9d
  106ff8:      	callq	0x1099c0 <shllvm_get_id>
  106ffd:      	movq	-0xe8(%rbp), %rdi
  107004:      	movq	%rbx, %rsi
  107007:      	movq	%r13, %rdx
  10700a:      	movq	%r14, %rcx
  10700d:      	movl	$0xa, %r8d
  107013:      	xorl	%r9d, %r9d
  107016:      	callq	0x1099c0 <shllvm_get_id>
  10701b:      	movq	-0xa8(%rbp), %r14
  107022:      	movq	0x178(%r14), %rax
  107029:      	movq	%rax, -0xe0(%rbp)
  107030:      	leaq	-0xe0(%rbp), %rax
  107037:      	movq	%r12, %rdi
  10703a:      	movq	%rbx, %rsi
  10703d:      	movq	-0x38(%rbp), %r13
  107041:      	movq	%r13, %rdx
  107044:      	movq	%r15, %rcx
  107047:      	movq	-0x40(%rbp), %r8
  10704b:      	movq	%r8, %r9
  10704e:      	pushq	%rax
  10704f:      	pushq	$0x1
  107051:      	callq	0x109090 <shllvm_call>
  107056:      	addq	$0x10, %rsp
  10705a:      	movq	0x180(%r14), %rax
  107061:      	movq	%rax, 0x8(%r14)
  107065:      	jmp	0x107729 <shllvm_f0+0xa89>
  10706a:      	leaq	0x1b0(%r12), %rax
  107072:      	movq	%rax, -0x1e8(%rbp)
  107079:      	leaq	0x150(%r12), %rax
  107081:      	movq	%rax, -0x1e0(%rbp)
  107088:      	leaq	0x148(%r12), %rax
  107090:      	movq	%rax, -0x1d8(%rbp)
  107097:      	leaq	0x140(%r12), %rax
  10709f:      	movq	%rax, -0x1d0(%rbp)
  1070a6:      	leaq	0x138(%r12), %rax
  1070ae:      	movq	%rax, -0x1c8(%rbp)
  1070b5:      	leaq	0x130(%r12), %rax
  1070bd:      	movq	%rax, -0x1c0(%rbp)
  1070c4:      	leaq	0x128(%r12), %rax
  1070cc:      	movq	%rax, -0x1b8(%rbp)
  1070d3:      	leaq	0x118(%r12), %rax
  1070db:      	movq	%rax, -0x88(%rbp)
  1070e2:      	leaq	0x110(%r12), %rax
  1070ea:      	movq	%rax, -0x1b0(%rbp)
  1070f1:      	leaq	0x108(%r12), %rax
  1070f9:      	movq	%rax, -0x1a8(%rbp)
  107100:      	leaq	0x100(%r12), %rax
  107108:      	movq	%rax, -0x1a0(%rbp)
  10710f:      	leaq	0xf8(%r12), %rax
  107117:      	movq	%rax, -0x198(%rbp)
  10711e:      	leaq	0xf0(%r12), %rax
  107126:      	movq	%rax, -0x90(%rbp)
  10712d:      	leaq	0xe0(%r12), %rax
  107135:      	movq	%rax, -0x80(%rbp)
  107139:      	leaq	0xb0(%r12), %rax
  107141:      	movq	%rax, -0x188(%rbp)
  107148:      	leaq	0xa8(%r12), %rax
  107150:      	movq	%rax, -0x190(%rbp)
  107157:      	leaq	0x98(%r12), %rax
  10715f:      	movq	%rax, -0x78(%rbp)
  107163:      	leaq	0x90(%r12), %rax
  10716b:      	movq	%rax, -0x180(%rbp)
  107172:      	leaq	0x88(%r12), %rax
  10717a:      	movq	%rax, -0x50(%rbp)
  10717e:      	leaq	0x80(%r12), %rax
  107186:      	movq	%rax, -0x178(%rbp)
  10718d:      	leaq	0x70(%r12), %rax
  107192:      	movq	%rax, -0x150(%rbp)
  107199:      	leaq	0x68(%r12), %rax
  10719e:      	movq	%rax, -0x168(%rbp)
  1071a5:      	leaq	0x58(%r12), %rax
  1071aa:      	movq	%rax, -0x128(%rbp)
  1071b1:      	leaq	0x50(%r12), %rax
  1071b6:      	movq	%rax, -0x138(%rbp)
  1071bd:      	leaq	0x40(%r12), %rax
  1071c2:      	movq	%rax, -0x100(%rbp)
  1071c9:      	leaq	0x38(%r12), %rax
  1071ce:      	movq	%rax, -0x70(%rbp)
  1071d2:      	leaq	0x30(%r12), %rax
  1071d7:      	movq	%rax, -0x60(%rbp)
  1071db:      	leaq	0x28(%r12), %r15
  1071e0:      	movq	%r15, -0x58(%rbp)
  1071e4:      	movq	%r12, %r13
  1071e7:      	addq	$0x20, %r13
  1071eb:      	xorl	%eax, %eax
  1071ed:      	movl	%eax, %r12d
  1071f0:      	movq	-0xa8(%rbp), %r14
  1071f7:      	movq	%r14, %rdi
  1071fa:      	movq	%rbx, %rsi
  1071fd:      	movq	%r12, %rdx
  107200:      	movl	$0x2, %ecx
  107205:      	callq	0x108cc0 <shllvm_env_create>
  10720a:      	movq	0x1c8(%r14), %rax
  107211:      	movq	%rax, 0x10(%r14)
  107215:      	movq	0x10(%r14), %rax
  107219:      	movq	%rax, 0x8(%r14)
  10721d:      	leaq	0x56c(%rip), %r8        # 0x107790 <shllvm_f1>
  107224:      	movq	%r15, %rdi
  107227:      	movq	%rbx, %rsi
  10722a:      	movq	%r12, %rdx
  10722d:      	movq	-0x48(%rbp), %rcx
  107231:      	movl	$0x1, %r9d
  107237:      	pushq	$0x0
  107239:      	pushq	%r13
  10723b:      	callq	0x10aa80 <shllvm_class>
  107240:      	addq	$0x10, %rsp
  107244:      	movq	0x20(%r14), %rax
  107248:      	movq	%rax, 0x30(%r14)
  10724c:      	movq	0x1d0(%r14), %rax
  107253:      	movq	%rax, 0x38(%r14)
  107257:      	leaq	0x6b2(%rip), %r8        # 0x107910 <shllvm_f2>
  10725e:      	movq	-0x100(%rbp), %r13
  107265:      	movq	%r13, %rdi
  107268:      	movq	%rbx, %rsi
  10726b:      	movq	%r12, %r15
  10726e:      	movq	%r12, -0x68(%rbp)
  107272:      	movq	%r12, %rdx
  107275:      	movq	-0x48(%rbp), %r12
  107279:      	movq	%r12, %rcx
  10727c:      	movl	$0x2, %r9d
  107282:      	callq	0x108f60 <shllvm_closure>
  107287:      	movq	%rbx, %rdi
  10728a:      	movq	-0x60(%rbp), %rsi
  10728e:      	movq	-0x70(%rbp), %rdx
  107292:      	movq	%r13, %rcx
  107295:      	xorl	%r8d, %r8d
  107298:      	callq	0x109c90 <shllvm_define>
  10729d:      	movq	0x1e0(%r14), %rax
  1072a4:      	movq	%rax, 0x50(%r14)
  1072a8:      	leaq	0x761(%rip), %r8        # 0x107a10 <shllvm_f3>
  1072af:      	movq	-0x128(%rbp), %r13
  1072b6:      	movq	%r13, %rdi
  1072b9:      	movq	%rbx, %rsi
  1072bc:      	movq	%r15, %rdx
  1072bf:      	movq	%r12, %rcx
  1072c2:      	movl	$0x3, %r9d
  1072c8:      	callq	0x108f60 <shllvm_closure>
  1072cd:      	movq	%rbx, %rdi
  1072d0:      	movq	-0x60(%rbp), %rsi
  1072d4:      	movq	-0x138(%rbp), %rdx
  1072db:      	movq	%r13, %rcx
  1072de:      	movq	-0x40(%rbp), %r8
  1072e2:      	xorl	%r9d, %r9d
  1072e5:      	callq	0x109cc0 <shllvm_define_accessor>
  1072ea:      	movq	0x1e8(%r14), %rax
  1072f1:      	movq	%rax, 0x68(%r14)
  1072f5:      	leaq	0x814(%rip), %r8        # 0x107b10 <shllvm_f4>
  1072fc:      	movq	-0x150(%rbp), %r15
  107303:      	movq	%r15, %rdi
  107306:      	movq	%rbx, %rsi
  107309:      	movq	-0x68(%rbp), %rdx
  10730d:      	movq	%r12, %rcx
  107310:      	movl	$0x4, %r9d
  107316:      	callq	0x108f60 <shllvm_closure>
  10731b:      	movq	%rbx, %rdi
  10731e:      	movq	-0x58(%rbp), %r13
  107322:      	movq	%r13, %rsi
  107325:      	movq	-0x168(%rbp), %rdx
  10732c:      	movq	%r15, %rcx
  10732f:      	xorl	%r8d, %r8d
  107332:      	callq	0x109c90 <shllvm_define>
  107337:      	leaq	0x8a2(%rip), %r8        # 0x107be0 <shllvm_f5>
  10733e:      	movq	-0x50(%rbp), %rdi
  107342:      	movq	%rbx, %rsi
  107345:      	movq	%r14, %rdx
  107348:      	movq	%r12, %rcx
  10734b:      	movl	$0x5, %r9d
  107351:      	pushq	%r13
  107353:      	pushq	-0x178(%rbp)
  107359:      	callq	0x10aa80 <shllvm_class>
  10735e:      	addq	$0x10, %rsp
  107362:      	movq	0x80(%r14), %rax
  107369:      	movq	%rax, 0x90(%r14)
  107370:      	leaq	0xac9(%rip), %r8        # 0x107e40 <shllvm_f6>
  107377:      	movq	-0x78(%rbp), %rdi
  10737b:      	movq	%rbx, %rsi
  10737e:      	movq	%r14, %rdx
  107381:      	movq	%r12, %rcx
  107384:      	movl	$0x6, %r9d
  10738a:      	callq	0x108f60 <shllvm_closure>
  10738f:      	movq	%rbx, %rdi
  107392:      	movq	-0x180(%rbp), %r13
  107399:      	movq	%r13, %rsi
  10739c:      	movq	-0x70(%rbp), %rdx
  1073a0:      	movq	-0x78(%rbp), %rcx
  1073a4:      	xorl	%r8d, %r8d
  1073a7:      	callq	0x109c90 <shllvm_define>
  1073ac:      	movq	0x1f0(%r14), %rax
  1073b3:      	movq	%rax, 0xa8(%r14)
  1073ba:      	leaq	0xcbf(%rip), %r8        # 0x108080 <shllvm_f7>
  1073c1:      	movq	-0x188(%rbp), %r15
  1073c8:      	movq	%r15, %rdi
  1073cb:      	movq	%rbx, %rsi
  1073ce:      	movq	-0x68(%rbp), %rdx
  1073d2:      	movq	%r12, %rcx
  1073d5:      	movl	$0x7, %r9d
  1073db:      	callq	0x108f60 <shllvm_closure>
  1073e0:      	movq	%rbx, %rdi
  1073e3:      	movq	%r13, %rsi
  1073e6:      	movq	-0x190(%rbp), %rdx
  1073ed:      	movq	%r15, %rcx
  1073f0:      	xorl	%r8d, %r8d
  1073f3:      	callq	0x109c90 <shllvm_define>
  1073f8:      	movq	%rbx, %rdi
  1073fb:      	movq	%r14, %rsi
  1073fe:      	movq	-0x50(%rbp), %r15
  107402:      	movq	%r15, %rdx
  107405:      	movl	$0x1, %ecx
  10740a:      	callq	0x108f20 <shllvm_env_store>
  10740f:      	movq	%rbx, %rdi
  107412:      	movq	%r14, %rsi
  107415:      	movq	%r13, %rdx
  107418:      	xorl	%ecx, %ecx
  10741a:      	callq	0x108f20 <shllvm_env_store>
  10741f:      	movq	0x1f8(%r14), %rax
  107426:      	movq	%rax, 0xd0(%r14)
  10742d:      	movq	0x200(%r14), %rax
  107434:      	movq	%rax, 0xd8(%r14)
  10743b:      	movq	0xd8(%r14), %rax
  107442:      	movq	%rax, -0xe0(%rbp)
  107449:      	movq	0xd0(%r14), %rax
  107450:      	movq	%rax, -0xd8(%rbp)
  107457:      	leaq	-0xe0(%rbp), %rax
  10745e:      	movq	-0x80(%rbp), %rdi
  107462:      	movq	%rbx, %rsi
  107465:      	movq	-0x38(%rbp), %rdx
  107469:      	movq	%r15, %rcx
  10746c:      	movq	-0x40(%rbp), %r8
  107470:      	movq	%r15, %r9
  107473:      	pushq	%rax
  107474:      	pushq	$0x2
  107476:      	callq	0x109090 <shllvm_call>
  10747b:      	addq	$0x10, %rsp
  10747f:      	movq	-0x98(%rbp), %r13
  107486:      	movq	%r13, %rdi
  107489:      	movq	%rbx, %rsi
  10748c:      	callq	0x108aa0 <shllvm_global>
  107491:      	movq	-0x90(%rbp), %rdi
  107498:      	movq	%rbx, %rsi
  10749b:      	movq	%r12, %rdx
  10749e:      	movq	%r13, %rcx
  1074a1:      	movl	$0x9, %r8d
  1074a7:      	movl	$0x1, %r9d
  1074ad:      	callq	0x1099c0 <shllvm_get_id>
  1074b2:      	movq	-0x198(%rbp), %r15
  1074b9:      	movq	%r15, %rdi
  1074bc:      	movq	%rbx, %rsi
  1074bf:      	movq	%r12, %rdx
  1074c2:      	movq	-0x80(%rbp), %r13
  1074c6:      	movq	%r13, %rcx
  1074c9:      	movl	$0x2, %r8d
  1074cf:      	xorl	%r9d, %r9d
  1074d2:      	callq	0x1099c0 <shllvm_get_id>
  1074d7:      	movq	-0x1a0(%rbp), %rdi
  1074de:      	movq	%rbx, %rsi
  1074e1:      	movq	-0x38(%rbp), %rdx
  1074e5:      	movq	%r15, %rcx
  1074e8:      	movq	%r13, %r8
  1074eb:      	movq	-0x40(%rbp), %r9
  1074ef:      	leaq	-0xe0(%rbp), %rax
  1074f6:      	pushq	%rax
  1074f7:      	pushq	$0x0
  1074f9:      	callq	0x109090 <shllvm_call>
  1074fe:      	addq	$0x10, %rsp
  107502:      	movq	-0x1a8(%rbp), %rdi
  107509:      	movq	%rbx, %rsi
  10750c:      	movq	%r12, %r15
  10750f:      	movq	%r12, %rdx
  107512:      	movq	%r13, %rcx
  107515:      	movl	$0x8, %r8d
  10751b:      	xorl	%r9d, %r9d
  10751e:      	callq	0x1099c0 <shllvm_get_id>
  107523:      	movq	-0x1b0(%rbp), %r12
  10752a:      	movq	%r12, %rdi
  10752d:      	movq	%rbx, %rsi
  107530:      	movq	%r15, %rdx
  107533:      	movq	%r13, %rcx
  107536:      	movl	$0x6, %r8d
  10753c:      	xorl	%r9d, %r9d
  10753f:      	callq	0x1099c0 <shllvm_get_id>
  107544:      	movq	-0x88(%rbp), %rdi
  10754b:      	movq	%rbx, %rsi
  10754e:      	movq	-0x38(%rbp), %r15
  107552:      	movq	%r15, %rdx
  107555:      	movq	%r12, %rcx
  107558:      	movq	%r13, %r8
  10755b:      	movq	-0x40(%rbp), %r12
  10755f:      	movq	%r12, %r9
  107562:      	leaq	-0xe0(%rbp), %rax
  107569:      	pushq	%rax
  10756a:      	pushq	$0x0
  10756c:      	callq	0x109090 <shllvm_call>
  107571:      	addq	$0x10, %rsp
  107575:      	movq	0x218(%r14), %rax
  10757c:      	movq	%rax, 0x120(%r14)
  107583:      	movq	0x120(%r14), %rax
  10758a:      	movq	%rax, -0xe0(%rbp)
  107591:      	movq	-0x1b8(%rbp), %rdi
  107598:      	movq	%rbx, %rsi
  10759b:      	movq	%r15, %rdx
  10759e:      	movq	-0x88(%rbp), %rcx
  1075a5:      	movq	%r12, %r8
  1075a8:      	movq	%r12, %r9
  1075ab:      	movq	%r12, %r15
  1075ae:      	leaq	-0xe0(%rbp), %rax
  1075b5:      	pushq	%rax
  1075b6:      	pushq	$0x1
  1075b8:      	callq	0x109090 <shllvm_call>
  1075bd:      	addq	$0x10, %rsp
  1075c1:      	movq	-0x1c0(%rbp), %rdi
  1075c8:      	movq	%rbx, %rsi
  1075cb:      	movl	$0x14, %edx
  1075d0:      	movq	%r13, %rcx
  1075d3:      	movq	-0x50(%rbp), %r12
  1075d7:      	movq	%r12, %r8
  1075da:      	callq	0x109360 <shllvm_binary>
  1075df:      	movq	-0x1c8(%rbp), %rdi
  1075e6:      	movq	%rbx, %rsi
  1075e9:      	movl	$0x14, %edx
  1075ee:      	movq	%r13, %rcx
  1075f1:      	movq	-0x58(%rbp), %r8
  1075f5:      	callq	0x109360 <shllvm_binary>
  1075fa:      	movq	-0x1d0(%rbp), %r13
  107601:      	movq	%r13, %rdi
  107604:      	movq	%rbx, %rsi
  107607:      	movq	-0x48(%rbp), %rdx
  10760b:      	movq	%r12, %rcx
  10760e:      	movl	$0x4, %r8d
  107614:      	xorl	%r9d, %r9d
  107617:      	callq	0x1099c0 <shllvm_get_id>
  10761c:      	movq	-0x1d8(%rbp), %rdi
  107623:      	movq	%rbx, %rsi
  107626:      	movq	-0x38(%rbp), %rdx
  10762a:      	movq	%r13, %rcx
  10762d:      	movq	%rdx, %r13
  107630:      	movq	%r12, %r8
  107633:      	movq	%r15, %r9
  107636:      	leaq	-0xe0(%rbp), %r12
  10763d:      	pushq	%r12
  10763f:      	pushq	$0x0
  107641:      	callq	0x109090 <shllvm_call>
  107646:      	addq	$0x10, %rsp
  10764a:      	movq	0x100(%r14), %rax
  107651:      	movq	%rax, -0xe0(%rbp)
  107658:      	movq	0x108(%r14), %rax
  10765f:      	movq	%rax, -0xd8(%rbp)
  107666:      	movq	0x128(%r14), %rax
  10766d:      	movq	%rax, -0xd0(%rbp)
  107674:      	movq	0x130(%r14), %rax
  10767b:      	movq	%rax, -0xc8(%rbp)
  107682:      	movq	0x138(%r14), %rax
  107689:      	movq	%rax, -0xc0(%rbp)
  107690:      	movq	0x148(%r14), %rax
  107697:      	movq	%rax, -0xb8(%rbp)
  10769e:      	movq	-0x1e0(%rbp), %rdi
  1076a5:      	movq	%rbx, %rsi
  1076a8:      	movq	%r13, %rdx
  1076ab:      	movq	-0x90(%rbp), %rcx
  1076b2:      	movq	%r15, %r8
  1076b5:      	movq	%r15, %r9
  1076b8:      	pushq	%r12
  1076ba:      	pushq	$0x6
  1076bc:      	callq	0x109090 <shllvm_call>
  1076c1:      	addq	$0x10, %rsp
  1076c5:      	movq	0x150(%r14), %rax
  1076cc:      	movq	%rax, 0x8(%r14)
  1076d0:      	movl	$0x1, -0x2c(%rbp)
  1076d7:      	movq	0x228(%r14), %rax
  1076de:      	movq	%rax, 0x1a8(%r14)
  1076e5:      	movq	0x1a8(%r14), %rax
  1076ec:      	movq	%rax, -0xe0(%rbp)
  1076f3:      	movq	-0x1e8(%rbp), %rdi
  1076fa:      	movq	%rbx, %rsi
  1076fd:      	movq	%r13, %rdx
  107700:      	movq	-0x58(%rbp), %rcx
  107704:      	movq	%r15, %r8
  107707:      	movq	%r15, %r9
  10770a:      	pushq	%r12
  10770c:      	pushq	$0x1
  10770e:      	callq	0x109090 <shllvm_call>
  107713:      	addq	$0x10, %rsp
  107717:      	movq	0x1b0(%r14), %rax
  10771e:      	movq	%rax, 0x8(%r14)
  107722:      	movl	$0x0, -0x2c(%rbp)
  107729:      	movq	0x8(%r14), %rax
  10772d:      	movq	%rax, 0x198(%r14)
  107734:      	movq	0x198(%r14), %r14
  10773b:      	movq	%rbx, %rdi
  10773e:      	movq	-0xa0(%rbp), %rsi
  107745:      	callq	0x10acf0 <shllvm_try_end>
  10774a:      	movq	%rbx, %rdi
  10774d:      	movq	-0xb0(%rbp), %rsi
  107754:      	movq	%r13, %rdx
  107757:      	callq	0x108980 <shllvm_leave>
  10775c:      	movq	%r14, %rax
  10775f:      	leaq	-0x28(%rbp), %rsp
  107763:      	popq	%rbx
  107764:      	popq	%r12
  107766:      	popq	%r13
  107768:      	popq	%r14
  10776a:      	popq	%r15
  10776c:      	popq	%rbp
  10776d:      	retq
  10776e:      	movq	%rbx, %rdi
  107771:      	movq	-0xa0(%rbp), %rsi
  107778:      	callq	0x10acf0 <shllvm_try_end>
  10777d:      	movq	%rbx, %rdi
  107780:      	callq	0x10ad80 <shllvm_rethrow>
  107785:      	nopw	%cs:(%rax,%rax)

0000000000107790 <shllvm_f1>:
  107790:      	pushq	%rbp
  107791:      	movq	%rsp, %rbp
  107794:      	pushq	%r15
  107796:      	pushq	%r14
  107798:      	pushq	%r13
  10779a:      	pushq	%r12
  10779c:      	pushq	%rbx
  10779d:      	subq	$0x38, %rsp
  1077a1:      	movq	%rdi, %rbx
  1077a4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  1077a9:      	movl	$0x9, %edi
  1077ae:      	callq	0x108530 <shllvm_frame_size>
  1077b3:      	movq	%rsp, %r14
  1077b6:      	addq	$0xf, %rax
  1077ba:      	andq	$-0x10, %rax
  1077be:      	subq	%rax, %r14
  1077c1:      	movq	%r14, %rsp
  1077c4:      	movl	0x993ad5(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  1077cb:      	movq	%rbx, %rdi
  1077ce:      	movq	%r14, %rsi
  1077d1:      	movq	%r14, -0x58(%rbp)
  1077d5:      	movl	$0x9, %edx
  1077da:      	xorl	%ecx, %ecx
  1077dc:      	movl	%r13d, %r8d
  1077df:      	callq	0x1085c0 <shllvm_enter>
  1077e4:      	movq	%rax, %r15
  1077e7:      	movq	%r14, %rdi
  1077ea:      	callq	0x108970 <shllvm_roots>
  1077ef:      	movq	%rax, %r12
  1077f2:      	movq	%rbx, %rdi
  1077f5:      	movl	%r13d, %esi
  1077f8:      	callq	0x108540 <shllvm_get_unit>
  1077fd:      	movq	%rax, %r13
  107800:      	leaq	0x8(%r12), %r14
  107805:      	leaq	0x10(%r12), %rax
  10780a:      	movq	%rax, -0x48(%rbp)
  10780e:      	leaq	0x18(%r12), %rax
  107813:      	movq	%rax, -0x50(%rbp)
  107817:      	leaq	0x30(%r12), %rax
  10781c:      	movq	%rax, -0x38(%rbp)
  107820:      	leaq	0x38(%r12), %rax
  107825:      	movq	%rax, -0x40(%rbp)
  107829:      	movq	%rbx, %rdi
  10782c:      	movq	%r15, -0x30(%rbp)
  107830:      	movq	%r15, %rsi
  107833:      	movl	$0x2, %edx
  107838:      	callq	0x10a890 <shllvm_check_invocation>
  10783d:      	movq	-0x38(%rbp), %rdi
  107841:      	movq	%rbx, %rsi
  107844:      	movq	%r13, %rdx
  107847:      	movl	$0xb, %ecx
  10784c:      	callq	0x108ae0 <shllvm_symbol>
  107851:      	movq	-0x40(%rbp), %rdi
  107855:      	movq	%rbx, %rsi
  107858:      	movq	%r13, %rdx
  10785b:      	movl	$0xc, %ecx
  107860:      	callq	0x108ae0 <shllvm_symbol>
  107865:      	movq	%r12, %rdi
  107868:      	movq	%r15, %rsi
  10786b:      	callq	0x109ed0 <shllvm_new_target>
  107870:      	movq	%r14, %r15
  107873:      	movq	%r14, %rdi
  107876:      	movq	%rbx, %rsi
  107879:      	movq	%r13, %rdx
  10787c:      	movq	%r12, %rcx
  10787f:      	movl	$0xb, %r8d
  107885:      	xorl	%r9d, %r9d
  107888:      	callq	0x1099c0 <shllvm_get_id>
  10788d:      	movq	-0x48(%rbp), %r14
  107891:      	movq	%r14, %rdi
  107894:      	movq	%rbx, %rsi
  107897:      	movq	%r13, %rdx
  10789a:      	movq	%r15, %rcx
  10789d:      	callq	0x109900 <shllvm_object_parent>
  1078a2:      	movq	-0x50(%rbp), %r15
  1078a6:      	movq	%r15, %rdi
  1078a9:      	movq	-0x30(%rbp), %rsi
  1078ad:      	movl	$0x1, %edx
  1078b2:      	callq	0x108a20 <shllvm_param>
  1078b7:      	subq	$0x8, %rsp
  1078bb:      	movq	%rbx, %rdi
  1078be:      	movq	%r13, %rsi
  1078c1:      	movq	%r14, %rdx
  1078c4:      	movl	$0xc, %ecx
  1078c9:      	movq	%r15, %r8
  1078cc:      	movl	$0x1, %r9d
  1078d2:      	pushq	$0x0
  1078d4:      	callq	0x109b30 <shllvm_set_id>
  1078d9:      	addq	$0x10, %rsp
  1078dd:      	movq	0x10(%r12), %r15
  1078e2:      	movq	%rbx, %rdi
  1078e5:      	movq	-0x58(%rbp), %rsi
  1078e9:      	movq	-0x30(%rbp), %rdx
  1078ed:      	callq	0x108980 <shllvm_leave>
  1078f2:      	movq	%r15, %rax
  1078f5:      	leaq	-0x28(%rbp), %rsp
  1078f9:      	popq	%rbx
  1078fa:      	popq	%r12
  1078fc:      	popq	%r13
  1078fe:      	popq	%r14
  107900:      	popq	%r15
  107902:      	popq	%rbp
  107903:      	retq
  107904:      	nopw	%cs:(%rax,%rax)

0000000000107910 <shllvm_f2>:
  107910:      	pushq	%rbp
  107911:      	movq	%rsp, %rbp
  107914:      	pushq	%r15
  107916:      	pushq	%r14
  107918:      	pushq	%r13
  10791a:      	pushq	%r12
  10791c:      	pushq	%rbx
  10791d:      	subq	$0x18, %rsp
  107921:      	movq	%rdi, %rbx
  107924:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107929:      	movl	$0x5, %edi
  10792e:      	callq	0x108530 <shllvm_frame_size>
  107933:      	movq	%rsp, %r14
  107936:      	addq	$0xf, %rax
  10793a:      	andq	$-0x10, %rax
  10793e:      	subq	%rax, %r14
  107941:      	movq	%r14, %rsp
  107944:      	movl	0x993955(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  10794b:      	movq	%rbx, %rdi
  10794e:      	movq	%r14, %rsi
  107951:      	movl	$0x5, %edx
  107956:      	xorl	%ecx, %ecx
  107958:      	movl	%r13d, %r8d
  10795b:      	callq	0x1085c0 <shllvm_enter>
  107960:      	movq	%rax, -0x38(%rbp)
  107964:      	movq	%r14, %rdi
  107967:      	callq	0x108970 <shllvm_roots>
  10796c:      	movq	%rax, %r12
  10796f:      	movq	%rbx, %rdi
  107972:      	movl	%r13d, %esi
  107975:      	callq	0x108540 <shllvm_get_unit>
  10797a:      	movq	%rax, %r15
  10797d:      	leaq	0x8(%r12), %rax
  107982:      	movq	%rax, -0x40(%rbp)
  107986:      	leaq	0x18(%r12), %rax
  10798b:      	movq	%rax, -0x30(%rbp)
  10798f:      	movq	%rbx, %rdi
  107992:      	movq	-0x38(%rbp), %r13
  107996:      	movq	%r13, %rsi
  107999:      	movl	$0x1, %edx
  10799e:      	callq	0x10a890 <shllvm_check_invocation>
  1079a3:      	movq	-0x30(%rbp), %rdi
  1079a7:      	movq	%rbx, %rsi
  1079aa:      	movq	%r15, %rdx
  1079ad:      	movl	$0xc, %ecx
  1079b2:      	callq	0x108ae0 <shllvm_symbol>
  1079b7:      	movq	%r12, %rdi
  1079ba:      	movq	%r13, %rsi
  1079bd:      	xorl	%edx, %edx
  1079bf:      	callq	0x108a20 <shllvm_param>
  1079c4:      	movq	-0x40(%rbp), %rdi
  1079c8:      	movq	%rbx, %rsi
  1079cb:      	movq	%r15, %rdx
  1079ce:      	movq	%r12, %rcx
  1079d1:      	movl	$0xc, %r8d
  1079d7:      	xorl	%r9d, %r9d
  1079da:      	callq	0x1099c0 <shllvm_get_id>
  1079df:      	movq	0x8(%r12), %r15
  1079e4:      	movq	%rbx, %rdi
  1079e7:      	movq	%r14, %rsi
  1079ea:      	movq	%r13, %rdx
  1079ed:      	callq	0x108980 <shllvm_leave>
  1079f2:      	movq	%r15, %rax
  1079f5:      	leaq	-0x28(%rbp), %rsp
  1079f9:      	popq	%rbx
  1079fa:      	popq	%r12
  1079fc:      	popq	%r13
  1079fe:      	popq	%r14
  107a00:      	popq	%r15
  107a02:      	popq	%rbp
  107a03:      	retq
  107a04:      	nopw	%cs:(%rax,%rax)

0000000000107a10 <shllvm_f3>:
  107a10:      	pushq	%rbp
  107a11:      	movq	%rsp, %rbp
  107a14:      	pushq	%r15
  107a16:      	pushq	%r14
  107a18:      	pushq	%r13
  107a1a:      	pushq	%r12
  107a1c:      	pushq	%rbx
  107a1d:      	subq	$0x18, %rsp
  107a21:      	movq	%rdi, %rbx
  107a24:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107a29:      	movl	$0x5, %edi
  107a2e:      	callq	0x108530 <shllvm_frame_size>
  107a33:      	movq	%rsp, %r14
  107a36:      	addq	$0xf, %rax
  107a3a:      	andq	$-0x10, %rax
  107a3e:      	subq	%rax, %r14
  107a41:      	movq	%r14, %rsp
  107a44:      	movl	0x993855(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107a4b:      	movq	%rbx, %rdi
  107a4e:      	movq	%r14, %rsi
  107a51:      	movl	$0x5, %edx
  107a56:      	xorl	%ecx, %ecx
  107a58:      	movl	%r13d, %r8d
  107a5b:      	callq	0x1085c0 <shllvm_enter>
  107a60:      	movq	%rax, -0x38(%rbp)
  107a64:      	movq	%r14, %rdi
  107a67:      	callq	0x108970 <shllvm_roots>
  107a6c:      	movq	%rax, %r12
  107a6f:      	movq	%rbx, %rdi
  107a72:      	movl	%r13d, %esi
  107a75:      	callq	0x108540 <shllvm_get_unit>
  107a7a:      	movq	%rax, %r15
  107a7d:      	leaq	0x8(%r12), %rax
  107a82:      	movq	%rax, -0x40(%rbp)
  107a86:      	leaq	0x18(%r12), %rax
  107a8b:      	movq	%rax, -0x30(%rbp)
  107a8f:      	movq	%rbx, %rdi
  107a92:      	movq	-0x38(%rbp), %r13
  107a96:      	movq	%r13, %rsi
  107a99:      	movl	$0x1, %edx
  107a9e:      	callq	0x10a890 <shllvm_check_invocation>
  107aa3:      	movq	-0x30(%rbp), %rdi
  107aa7:      	movq	%rbx, %rsi
  107aaa:      	movq	%r15, %rdx
  107aad:      	movl	$0xc, %ecx
  107ab2:      	callq	0x108ae0 <shllvm_symbol>
  107ab7:      	movq	%r12, %rdi
  107aba:      	movq	%r13, %rsi
  107abd:      	xorl	%edx, %edx
  107abf:      	callq	0x108a20 <shllvm_param>
  107ac4:      	movq	-0x40(%rbp), %rdi
  107ac8:      	movq	%rbx, %rsi
  107acb:      	movq	%r15, %rdx
  107ace:      	movq	%r12, %rcx
  107ad1:      	movl	$0xc, %r8d
  107ad7:      	xorl	%r9d, %r9d
  107ada:      	callq	0x1099c0 <shllvm_get_id>
  107adf:      	movq	0x8(%r12), %r15
  107ae4:      	movq	%rbx, %rdi
  107ae7:      	movq	%r14, %rsi
  107aea:      	movq	%r13, %rdx
  107aed:      	callq	0x108980 <shllvm_leave>
  107af2:      	movq	%r15, %rax
  107af5:      	leaq	-0x28(%rbp), %rsp
  107af9:      	popq	%rbx
  107afa:      	popq	%r12
  107afc:      	popq	%r13
  107afe:      	popq	%r14
  107b00:      	popq	%r15
  107b02:      	popq	%rbp
  107b03:      	retq
  107b04:      	nopw	%cs:(%rax,%rax)

0000000000107b10 <shllvm_f4>:
  107b10:      	pushq	%rbp
  107b11:      	movq	%rsp, %rbp
  107b14:      	pushq	%r15
  107b16:      	pushq	%r14
  107b18:      	pushq	%r13
  107b1a:      	pushq	%r12
  107b1c:      	pushq	%rbx
  107b1d:      	subq	$0x18, %rsp
  107b21:      	movq	%rdi, %rbx
  107b24:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107b29:      	movl	$0x4, %edi
  107b2e:      	callq	0x108530 <shllvm_frame_size>
  107b33:      	movq	%rsp, %r14
  107b36:      	addq	$0xf, %rax
  107b3a:      	andq	$-0x10, %rax
  107b3e:      	subq	%rax, %r14
  107b41:      	movq	%r14, %rsp
  107b44:      	movl	0x993755(%rip), %r12d   # 0xa9b2a0 <shllvm_unit_index>
  107b4b:      	movq	%rbx, %rdi
  107b4e:      	movq	%r14, %rsi
  107b51:      	movl	$0x4, %edx
  107b56:      	xorl	%ecx, %ecx
  107b58:      	movl	%r12d, %r8d
  107b5b:      	callq	0x1085c0 <shllvm_enter>
  107b60:      	movq	%rax, -0x38(%rbp)
  107b64:      	movq	%r14, %rdi
  107b67:      	callq	0x108970 <shllvm_roots>
  107b6c:      	movq	%rax, %r13
  107b6f:      	movq	%rbx, %rdi
  107b72:      	movl	%r12d, %esi
  107b75:      	callq	0x108540 <shllvm_get_unit>
  107b7a:      	movq	%rax, -0x30(%rbp)
  107b7e:      	leaq	0x10(%r13), %r15
  107b82:      	movq	%rbx, %rdi
  107b85:      	movq	-0x38(%rbp), %r12
  107b89:      	movq	%r12, %rsi
  107b8c:      	movl	$0x1, %edx
  107b91:      	callq	0x10a890 <shllvm_check_invocation>
  107b96:      	movq	%r15, %rdi
  107b99:      	movq	%rbx, %rsi
  107b9c:      	movq	-0x30(%rbp), %rdx
  107ba0:      	movl	$0xd, %ecx
  107ba5:      	callq	0x108ae0 <shllvm_symbol>
  107baa:      	movq	0x10(%r13), %r15
  107bae:      	movq	%r15, (%r13)
  107bb2:      	movq	%rbx, %rdi
  107bb5:      	movq	%r14, %rsi
  107bb8:      	movq	%r12, %rdx
  107bbb:      	callq	0x108980 <shllvm_leave>
  107bc0:      	movq	%r15, %rax
  107bc3:      	leaq	-0x28(%rbp), %rsp
  107bc7:      	popq	%rbx
  107bc8:      	popq	%r12
  107bca:      	popq	%r13
  107bcc:      	popq	%r14
  107bce:      	popq	%r15
  107bd0:      	popq	%rbp
  107bd1:      	retq
  107bd2:      	nopw	%cs:(%rax,%rax)

0000000000107be0 <shllvm_f5>:
  107be0:      	pushq	%rbp
  107be1:      	movq	%rsp, %rbp
  107be4:      	pushq	%r15
  107be6:      	pushq	%r14
  107be8:      	pushq	%r13
  107bea:      	pushq	%r12
  107bec:      	pushq	%rbx
  107bed:      	subq	$0x78, %rsp
  107bf1:      	movq	%rdi, %rbx
  107bf4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107bf9:      	movl	$0x11, %edi
  107bfe:      	callq	0x108530 <shllvm_frame_size>
  107c03:      	movq	%rsp, %r14
  107c06:      	addq	$0xf, %rax
  107c0a:      	andq	$-0x10, %rax
  107c0e:      	subq	%rax, %r14
  107c11:      	movq	%r14, %rsp
  107c14:      	movl	0x993685(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107c1b:      	movq	%rbx, %rdi
  107c1e:      	movq	%r14, %rsi
  107c21:      	movq	%r14, -0x90(%rbp)
  107c28:      	movl	$0x11, %edx
  107c2d:      	movl	$0x1, %ecx
  107c32:      	movl	%r13d, %r8d
  107c35:      	callq	0x1085c0 <shllvm_enter>
  107c3a:      	movq	%rax, %r15
  107c3d:      	movq	%rax, -0x30(%rbp)
  107c41:      	movq	%r14, %rdi
  107c44:      	callq	0x108970 <shllvm_roots>
  107c49:      	movq	%rax, %r12
  107c4c:      	movq	%rbx, %rdi
  107c4f:      	movl	%r13d, %esi
  107c52:      	callq	0x108540 <shllvm_get_unit>
  107c57:      	movq	%rax, -0x40(%rbp)
  107c5b:      	leaq	0x8(%r12), %rax
  107c60:      	movq	%rax, -0x50(%rbp)
  107c64:      	leaq	0x10(%r12), %rax
  107c69:      	movq	%rax, -0x58(%rbp)
  107c6d:      	leaq	0x18(%r12), %rax
  107c72:      	movq	%rax, -0x38(%rbp)
  107c76:      	leaq	0x20(%r12), %rax
  107c7b:      	movq	%rax, -0x60(%rbp)
  107c7f:      	leaq	0x28(%r12), %rax
  107c84:      	movq	%rax, -0x68(%rbp)
  107c88:      	leaq	0x30(%r12), %rax
  107c8d:      	movq	%rax, -0x70(%rbp)
  107c91:      	leaq	0x38(%r12), %rax
  107c96:      	movq	%rax, -0x78(%rbp)
  107c9a:      	leaq	0x40(%r12), %rax
  107c9f:      	movq	%rax, -0x80(%rbp)
  107ca3:      	leaq	0x50(%r12), %rax
  107ca8:      	movq	%rax, -0x88(%rbp)
  107caf:      	leaq	0x68(%r12), %r13
  107cb4:      	leaq	0x70(%r12), %r14
  107cb9:      	leaq	0x78(%r12), %rax
  107cbe:      	movq	%rax, -0x48(%rbp)
  107cc2:      	movq	%rbx, %rdi
  107cc5:      	movq	%r15, %rsi
  107cc8:      	movl	$0x2, %edx
  107ccd:      	callq	0x10a890 <shllvm_check_invocation>
  107cd2:      	movq	%r13, %rdi
  107cd5:      	movl	$0x2, %esi
  107cda:      	xorl	%edx, %edx
  107cdc:      	callq	0x108400 <shllvm_constant>
  107ce1:      	movq	%r14, %rdi
  107ce4:      	movl	$0x4, %esi
  107ce9:      	xorl	%edx, %edx
  107ceb:      	callq	0x108400 <shllvm_constant>
  107cf0:      	movq	-0x48(%rbp), %rdi
  107cf4:      	movq	%rbx, %rsi
  107cf7:      	movq	-0x40(%rbp), %rdx
  107cfb:      	movl	$0xe, %ecx
  107d00:      	callq	0x108ae0 <shllvm_symbol>
  107d05:      	movq	%r12, %rdi
  107d08:      	movq	%r15, %rsi
  107d0b:      	callq	0x109ed0 <shllvm_new_target>
  107d10:      	movq	-0x50(%rbp), %r13
  107d14:      	movq	%r13, %rdi
  107d17:      	movq	%rbx, %rsi
  107d1a:      	movq	%r15, %rdx
  107d1d:      	callq	0x108dc0 <shllvm_env_from_frame>
  107d22:      	movq	-0x58(%rbp), %r14
  107d26:      	movq	%r14, %rdi
  107d29:      	movq	%r13, %rsi
  107d2c:      	movl	$0x1, %edx
  107d31:      	callq	0x108eb0 <shllvm_env_load>
  107d36:      	movq	-0x38(%rbp), %r15
  107d3a:      	movq	%r15, %rdi
  107d3d:      	movq	%rbx, %rsi
  107d40:      	movq	%r14, %rdx
  107d43:      	callq	0x109e30 <shllvm_get_parent>
  107d48:      	movq	-0x60(%rbp), %r14
  107d4c:      	movq	%r14, %rdi
  107d4f:      	movq	%rbx, %rsi
  107d52:      	movq	%r15, %rdx
  107d55:      	movq	%r12, %rcx
  107d58:      	callq	0x109d90 <shllvm_create_this>
  107d5d:      	movq	-0x68(%rbp), %rdi
  107d61:      	movq	-0x30(%rbp), %r13
  107d65:      	movq	%r13, %rsi
  107d68:      	movl	$0x1, %edx
  107d6d:      	callq	0x108a20 <shllvm_param>
  107d72:      	movq	0x28(%r12), %rax
  107d77:      	movq	%rax, -0x98(%rbp)
  107d7e:      	leaq	-0x98(%rbp), %rax
  107d85:      	movq	-0x70(%rbp), %r15
  107d89:      	movq	%r15, %rdi
  107d8c:      	movq	%rbx, %rsi
  107d8f:      	movq	%r13, %rdx
  107d92:      	movq	-0x38(%rbp), %rcx
  107d96:      	movq	%r14, %r8
  107d99:      	movq	%r12, %r9
  107d9c:      	pushq	%rax
  107d9d:      	pushq	$0x1
  107d9f:      	callq	0x109090 <shllvm_call>
  107da4:      	addq	$0x10, %rsp
  107da8:      	movq	-0x78(%rbp), %r13
  107dac:      	movq	%r13, %rdi
  107daf:      	movq	%r14, %rsi
  107db2:      	movq	%r15, %rdx
  107db5:      	callq	0x109dd0 <shllvm_constructed_object>
  107dba:      	movq	0x70(%r12), %rax
  107dbf:      	movq	%rax, 0x40(%r12)
  107dc4:      	movq	%rbx, %rdi
  107dc7:      	movq	-0x80(%rbp), %rsi
  107dcb:      	callq	0x10ac40 <shllvm_check_this_initialized>
  107dd0:      	movq	-0x88(%rbp), %r14
  107dd7:      	movq	%r14, %rdi
  107dda:      	movq	-0x30(%rbp), %r15
  107dde:      	movq	%r15, %rsi
  107de1:      	movl	$0x2, %edx
  107de6:      	callq	0x108a20 <shllvm_param>
  107deb:      	subq	$0x8, %rsp
  107def:      	movq	%rbx, %rdi
  107df2:      	movq	-0x40(%rbp), %rsi
  107df6:      	movq	%r13, %rdx
  107df9:      	movl	$0xe, %ecx
  107dfe:      	movq	%r14, %r8
  107e01:      	movl	$0x1, %r9d
  107e07:      	pushq	$0x0
  107e09:      	callq	0x109b30 <shllvm_set_id>
  107e0e:      	addq	$0x10, %rsp
  107e12:      	movq	0x38(%r12), %r14
  107e17:      	movq	%rbx, %rdi
  107e1a:      	movq	-0x90(%rbp), %rsi
  107e21:      	movq	%r15, %rdx
  107e24:      	callq	0x108980 <shllvm_leave>
  107e29:      	movq	%r14, %rax
  107e2c:      	leaq	-0x28(%rbp), %rsp
  107e30:      	popq	%rbx
  107e31:      	popq	%r12
  107e33:      	popq	%r13
  107e35:      	popq	%r14
  107e37:      	popq	%r15
  107e39:      	popq	%rbp
  107e3a:      	retq
  107e3b:      	nopl	(%rax,%rax)

0000000000107e40 <shllvm_f6>:
  107e40:      	pushq	%rbp
  107e41:      	movq	%rsp, %rbp
  107e44:      	pushq	%r15
  107e46:      	pushq	%r14
  107e48:      	pushq	%r13
  107e4a:      	pushq	%r12
  107e4c:      	pushq	%rbx
  107e4d:      	subq	$0x88, %rsp
  107e54:      	movq	%rdi, %rbx
  107e57:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107e5c:      	movl	$0xf, %edi
  107e61:      	callq	0x108530 <shllvm_frame_size>
  107e66:      	movq	%rsp, %r14
  107e69:      	addq	$0xf, %rax
  107e6d:      	andq	$-0x10, %rax
  107e71:      	subq	%rax, %r14
  107e74:      	movq	%r14, -0x78(%rbp)
  107e78:      	movq	%r14, %rsp
  107e7b:      	movl	0x99341e(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107e82:      	movq	%rbx, %rdi
  107e85:      	movq	%r14, %rsi
  107e88:      	movl	$0xf, %edx
  107e8d:      	xorl	%ecx, %ecx
  107e8f:      	movl	%r13d, %r8d
  107e92:      	callq	0x1085c0 <shllvm_enter>
  107e97:      	movq	%rax, -0x30(%rbp)
  107e9b:      	movq	%r14, %rdi
  107e9e:      	callq	0x108970 <shllvm_roots>
  107ea3:      	movq	%rax, %r12
  107ea6:      	movq	%rbx, %rdi
  107ea9:      	movl	%r13d, %esi
  107eac:      	callq	0x108540 <shllvm_get_unit>
  107eb1:      	movq	%rax, %r15
  107eb4:      	leaq	0x8(%r12), %rax
  107eb9:      	movq	%rax, -0x50(%rbp)
  107ebd:      	leaq	0x10(%r12), %rax
  107ec2:      	movq	%rax, -0x68(%rbp)
  107ec6:      	leaq	0x18(%r12), %rax
  107ecb:      	movq	%rax, -0x70(%rbp)
  107ecf:      	leaq	0x20(%r12), %rax
  107ed4:      	movq	%rax, -0x80(%rbp)
  107ed8:      	leaq	0x28(%r12), %rax
  107edd:      	movq	%rax, -0x90(%rbp)
  107ee4:      	leaq	0x30(%r12), %rax
  107ee9:      	movq	%rax, -0x88(%rbp)
  107ef0:      	leaq	0x38(%r12), %rax
  107ef5:      	movq	%rax, -0x98(%rbp)
  107efc:      	leaq	0x40(%r12), %rax
  107f01:      	movq	%rax, -0xa0(%rbp)
  107f08:      	leaq	0x50(%r12), %r14
  107f0d:      	movq	%r14, -0x60(%rbp)
  107f11:      	leaq	0x58(%r12), %rax
  107f16:      	movq	%rax, -0x38(%rbp)
  107f1a:      	leaq	0x60(%r12), %rax
  107f1f:      	movq	%rax, -0x40(%rbp)
  107f23:      	leaq	0x68(%r12), %rax
  107f28:      	movq	%rax, -0x48(%rbp)
  107f2c:      	movq	%rbx, %rdi
  107f2f:      	movq	-0x30(%rbp), %r13
  107f33:      	movq	%r13, %rsi
  107f36:      	movl	$0x1, %edx
  107f3b:      	callq	0x10a890 <shllvm_check_invocation>
  107f40:      	movq	%r14, %rdi
  107f43:      	movq	%rbx, %rsi
  107f46:      	movq	%r15, %rdx
  107f49:      	movq	%r15, -0x58(%rbp)
  107f4d:      	movl	$0x2, %ecx
  107f52:      	callq	0x108ae0 <shllvm_symbol>
  107f57:      	movq	-0x38(%rbp), %rdi
  107f5b:      	xorl	%esi, %esi
  107f5d:      	xorl	%edx, %edx
  107f5f:      	callq	0x108400 <shllvm_constant>
  107f64:      	movq	-0x40(%rbp), %rdi
  107f68:      	movl	$0x2, %esi
  107f6d:      	xorl	%edx, %edx
  107f6f:      	callq	0x108400 <shllvm_constant>
  107f74:      	movq	-0x48(%rbp), %rdi
  107f78:      	movq	%rbx, %rsi
  107f7b:      	movq	%r15, %rdx
  107f7e:      	movl	$0xe, %ecx
  107f83:      	callq	0x108ae0 <shllvm_symbol>
  107f88:      	movq	%r12, %rdi
  107f8b:      	movq	%r13, %rsi
  107f8e:      	xorl	%edx, %edx
  107f90:      	callq	0x108a20 <shllvm_param>
  107f95:      	movq	-0x50(%rbp), %r14
  107f99:      	movq	%r14, %rdi
  107f9c:      	movq	%rbx, %rsi
  107f9f:      	movq	%r13, %rdx
  107fa2:      	callq	0x108dc0 <shllvm_env_from_frame>
  107fa7:      	movq	-0x68(%rbp), %r13
  107fab:      	movq	%r13, %rdi
  107fae:      	movq	%r14, %rsi
  107fb1:      	xorl	%edx, %edx
  107fb3:      	callq	0x108eb0 <shllvm_env_load>
  107fb8:      	movq	-0x70(%rbp), %r15
  107fbc:      	movq	%r15, %rdi
  107fbf:      	movq	%rbx, %rsi
  107fc2:      	movq	%r13, %rdx
  107fc5:      	callq	0x109e30 <shllvm_get_parent>
  107fca:      	movq	-0x80(%rbp), %r13
  107fce:      	movq	%r13, %rdi
  107fd1:      	movq	%rbx, %rsi
  107fd4:      	movq	%r15, %rdx
  107fd7:      	movq	-0x60(%rbp), %rcx
  107fdb:      	movq	%r12, %r8
  107fde:      	callq	0x10a970 <shllvm_get_receiver>
  107fe3:      	movq	0x58(%r12), %rax
  107fe8:      	movq	%rax, 0x28(%r12)
  107fed:      	leaq	-0xa8(%rbp), %rax
  107ff4:      	movq	-0x88(%rbp), %r15
  107ffb:      	movq	%r15, %rdi
  107ffe:      	movq	%rbx, %rsi
  108001:      	movq	-0x30(%rbp), %r14
  108005:      	movq	%r14, %rdx
  108008:      	movq	%r13, %rcx
  10800b:      	movq	%r12, %r8
  10800e:      	movq	-0x90(%rbp), %r9
  108015:      	pushq	%rax
  108016:      	pushq	$0x0
  108018:      	callq	0x109090 <shllvm_call>
  10801d:      	addq	$0x10, %rsp
  108021:      	movq	-0x98(%rbp), %r13
  108028:      	movq	%r13, %rdi
  10802b:      	movq	%rbx, %rsi
  10802e:      	movq	-0x58(%rbp), %rdx
  108032:      	movq	%r12, %rcx
  108035:      	movl	$0xe, %r8d
  10803b:      	xorl	%r9d, %r9d
  10803e:      	callq	0x1099c0 <shllvm_get_id>
  108043:      	movq	-0xa0(%rbp), %rdi
  10804a:      	movq	%rbx, %rsi
  10804d:      	xorl	%edx, %edx
  10804f:      	movq	%r15, %rcx
  108052:      	movq	%r13, %r8
  108055:      	callq	0x109360 <shllvm_binary>
  10805a:      	movq	0x40(%r12), %r15
  10805f:      	movq	%rbx, %rdi
  108062:      	movq	-0x78(%rbp), %rsi
  108066:      	movq	%r14, %rdx
  108069:      	callq	0x108980 <shllvm_leave>
  10806e:      	movq	%r15, %rax
  108071:      	leaq	-0x28(%rbp), %rsp
  108075:      	popq	%rbx
  108076:      	popq	%r12
  108078:      	popq	%r13
  10807a:      	popq	%r14
  10807c:      	popq	%r15
  10807e:      	popq	%rbp
  10807f:      	retq

0000000000108080 <shllvm_f7>:
  108080:      	pushq	%rbp
  108081:      	movq	%rsp, %rbp
  108084:      	pushq	%r15
  108086:      	pushq	%r14
  108088:      	pushq	%r13
  10808a:      	pushq	%r12
  10808c:      	pushq	%rbx
  10808d:      	subq	$0x18, %rsp
  108091:      	movq	%rdi, %rbx
  108094:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  108099:      	movl	$0x6, %edi
  10809e:      	callq	0x108530 <shllvm_frame_size>
  1080a3:      	movq	%rsp, %r14
  1080a6:      	addq	$0xf, %rax
  1080aa:      	andq	$-0x10, %rax
  1080ae:      	subq	%rax, %r14
  1080b1:      	movq	%r14, %rsp
  1080b4:      	movl	0x9931e5(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  1080bb:      	movq	%rbx, %rdi
  1080be:      	movq	%r14, %rsi
  1080c1:      	movl	$0x6, %edx
  1080c6:      	xorl	%ecx, %ecx
  1080c8:      	movl	%r13d, %r8d
  1080cb:      	callq	0x1085c0 <shllvm_enter>
  1080d0:      	movq	%rax, %r15
  1080d3:      	movq	%r14, %rdi
  1080d6:      	callq	0x108970 <shllvm_roots>
  1080db:      	movq	%rax, %r12
  1080de:      	movq	%rbx, %rdi
  1080e1:      	movl	%r13d, %esi
  1080e4:      	callq	0x108540 <shllvm_get_unit>
  1080e9:      	movq	%rax, -0x38(%rbp)
  1080ed:      	leaq	0x8(%r12), %r13
  1080f2:      	leaq	0x18(%r12), %rax
  1080f7:      	movq	%rax, -0x30(%rbp)
  1080fb:      	movq	%rbx, %rdi
  1080fe:      	movq	%r15, %rsi
  108101:      	movl	$0x1, %edx
  108106:      	callq	0x10a890 <shllvm_check_invocation>
  10810b:      	movq	%r12, %rdi
  10810e:      	movq	%rbx, %rsi
  108111:      	xorl	%edx, %edx
  108113:      	movl	$0x1, %ecx
  108118:      	callq	0x108cc0 <shllvm_env_create>
  10811d:      	movq	%r13, %rdi
  108120:      	movq	%r15, %rsi
  108123:      	xorl	%edx, %edx
  108125:      	callq	0x108a20 <shllvm_param>
  10812a:      	movq	%rbx, %rdi
  10812d:      	movq	%r12, %rsi
  108130:      	movq	%r13, %rdx
  108133:      	xorl	%ecx, %ecx
  108135:      	callq	0x108f20 <shllvm_env_store>
  10813a:      	leaq	0x3f(%rip), %r8         # 0x108180 <shllvm_f8>
  108141:      	movq	-0x30(%rbp), %rdi
  108145:      	movq	%rbx, %rsi
  108148:      	movq	%r12, %rdx
  10814b:      	movq	-0x38(%rbp), %rcx
  10814f:      	movl	$0x8, %r9d
  108155:      	callq	0x108f60 <shllvm_closure>
  10815a:      	movq	0x18(%r12), %r12
  10815f:      	movq	%rbx, %rdi
  108162:      	movq	%r14, %rsi
  108165:      	movq	%r15, %rdx
  108168:      	callq	0x108980 <shllvm_leave>
  10816d:      	movq	%r12, %rax
  108170:      	leaq	-0x28(%rbp), %rsp
  108174:      	popq	%rbx
  108175:      	popq	%r12
  108177:      	popq	%r13
  108179:      	popq	%r14
  10817b:      	popq	%r15
  10817d:      	popq	%rbp
  10817e:      	retq
  10817f:      	nop

0000000000108180 <shllvm_f8>:
  108180:      	pushq	%rbp
  108181:      	movq	%rsp, %rbp
  108184:      	pushq	%r15
  108186:      	pushq	%r14
  108188:      	pushq	%r13
  10818a:      	pushq	%r12
  10818c:      	pushq	%rbx
  10818d:      	subq	$0x58, %rsp
  108191:      	movq	%rdi, %rbx
  108194:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  108199:      	movl	$0xc, %edi
  10819e:      	callq	0x108530 <shllvm_frame_size>
  1081a3:      	movq	%rsp, %r15
  1081a6:      	addq	$0xf, %rax
  1081aa:      	andq	$-0x10, %rax
  1081ae:      	subq	%rax, %r15
  1081b1:      	movq	%r15, -0x78(%rbp)
  1081b5:      	movq	%r15, %rsp
  1081b8:      	movl	0x9930e1(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  1081bf:      	movq	%rbx, %rdi
  1081c2:      	movq	%r15, %rsi
  1081c5:      	movl	$0xc, %edx
  1081ca:      	xorl	%ecx, %ecx
  1081cc:      	movl	%r13d, %r8d
  1081cf:      	callq	0x1085c0 <shllvm_enter>
  1081d4:      	movq	%rax, %r14
  1081d7:      	movq	%r15, %rdi
  1081da:      	callq	0x108970 <shllvm_roots>
  1081df:      	movq	%rax, %r12
  1081e2:      	movq	%rbx, %rdi
  1081e5:      	movl	%r13d, %esi
  1081e8:      	callq	0x108540 <shllvm_get_unit>
  1081ed:      	movq	%rax, %r15
  1081f0:      	movq	%rax, -0x48(%rbp)
  1081f4:      	leaq	0x8(%r12), %rax
  1081f9:      	movq	%rax, -0x30(%rbp)
  1081fd:      	leaq	0x10(%r12), %rax
  108202:      	movq	%rax, -0x50(%rbp)
  108206:      	leaq	0x18(%r12), %rax
  10820b:      	movq	%rax, -0x60(%rbp)
  10820f:      	leaq	0x20(%r12), %rax
  108214:      	movq	%rax, -0x58(%rbp)
  108218:      	leaq	0x28(%r12), %rax
  10821d:      	movq	%rax, -0x68(%rbp)
  108221:      	leaq	0x30(%r12), %rax
  108226:      	movq	%rax, -0x70(%rbp)
  10822a:      	leaq	0x40(%r12), %r13
  10822f:      	leaq	0x48(%r12), %rax
  108234:      	movq	%rax, -0x38(%rbp)
  108238:      	leaq	0x50(%r12), %rax
  10823d:      	movq	%rax, -0x40(%rbp)
  108241:      	movq	%rbx, %rdi
  108244:      	movq	%r14, %rsi
  108247:      	movl	$0x1, %edx
  10824c:      	callq	0x10a890 <shllvm_check_invocation>
  108251:      	movq	%r13, %rdi
  108254:      	movq	%rbx, %rsi
  108257:      	movq	%r15, %rdx
  10825a:      	movl	$0x2, %ecx
  10825f:      	callq	0x108ae0 <shllvm_symbol>
  108264:      	movq	-0x38(%rbp), %rdi
  108268:      	xorl	%esi, %esi
  10826a:      	xorl	%edx, %edx
  10826c:      	callq	0x108400 <shllvm_constant>
  108271:      	movq	-0x40(%rbp), %rdi
  108275:      	movl	$0x2, %esi
  10827a:      	xorl	%edx, %edx
  10827c:      	callq	0x108400 <shllvm_constant>
  108281:      	movq	%r12, %rdi
  108284:      	movq	%rbx, %rsi
  108287:      	movq	%r14, %rdx
  10828a:      	callq	0x108dc0 <shllvm_env_from_frame>
  10828f:      	movq	-0x30(%rbp), %r13
  108293:      	movq	%r13, %rdi
  108296:      	movq	%r12, %rsi
  108299:      	xorl	%edx, %edx
  10829b:      	callq	0x108eb0 <shllvm_env_load>
  1082a0:      	movq	-0x50(%rbp), %r15
  1082a4:      	movq	%r15, %rdi
  1082a7:      	movq	%rbx, %rsi
  1082aa:      	movq	-0x48(%rbp), %rdx
  1082ae:      	movq	%r13, %rcx
  1082b1:      	movl	$0x2, %r8d
  1082b7:      	xorl	%r9d, %r9d
  1082ba:      	callq	0x1099c0 <shllvm_get_id>
  1082bf:      	movq	0x48(%r12), %rax
  1082c4:      	movq	%rax, 0x18(%r12)
  1082c9:      	leaq	-0x80(%rbp), %rax
  1082cd:      	movq	-0x58(%rbp), %r13
  1082d1:      	movq	%r13, %rdi
  1082d4:      	movq	%rbx, %rsi
  1082d7:      	movq	%r14, %rdx
  1082da:      	movq	%r15, %rcx
  1082dd:      	movq	-0x30(%rbp), %r8
  1082e1:      	movq	-0x60(%rbp), %r9
  1082e5:      	pushq	%rax
  1082e6:      	pushq	$0x0
  1082e8:      	callq	0x109090 <shllvm_call>
  1082ed:      	addq	$0x10, %rsp
  1082f1:      	movq	-0x68(%rbp), %r15
  1082f5:      	movq	%r15, %rdi
  1082f8:      	movq	%r14, %rsi
  1082fb:      	movl	$0x1, %edx
  108300:      	callq	0x108a20 <shllvm_param>
  108305:      	movq	-0x70(%rbp), %rdi
  108309:      	movq	%rbx, %rsi
  10830c:      	xorl	%edx, %edx
  10830e:      	movq	%r13, %rcx
  108311:      	movq	%r15, %r8
  108314:      	callq	0x109360 <shllvm_binary>
  108319:      	movq	0x30(%r12), %r12
  10831e:      	movq	%rbx, %rdi
  108321:      	movq	-0x78(%rbp), %rsi
  108325:      	movq	%r14, %rdx
  108328:      	callq	0x108980 <shllvm_leave>
  10832d:      	movq	%r12, %rax
  108330:      	leaq	-0x28(%rbp), %rsp
  108334:      	popq	%rbx
  108335:      	popq	%r12
  108337:      	popq	%r13
  108339:      	popq	%r14
  10833b:      	popq	%r15
  10833d:      	popq	%rbp
  10833e:      	retq
  10833f:      	nop

0000000000108340 <sh_export_this_unit>:
  108340:      	pushq	%rax
  108341:      	subq	$0x8, %rsp
  108345:      	leaq	0x15af4(%rip), %rax     # 0x11de40 <shllvm_unit_name>
  10834c:      	leaq	-0x16b3(%rip), %r10     # 0x106ca0 <shllvm_f0>
  108353:      	leaq	0x15b06(%rip), %r11     # 0x11de60 <shllvm_functions>
  10835a:      	leaq	0x992f3f(%rip), %rdi    # 0xa9b2a0 <shllvm_unit_index>
  108361:      	leaq	0x15958(%rip), %rdx     # 0x11dcc0 <shllvm_ascii>
  108368:      	leaq	0x159d1(%rip), %rcx     # 0x11dd40 <shllvm_utf16>
  10836f:      	leaq	0x159ea(%rip), %r8      # 0x11dd60 <shllvm_strings>
  108376:      	movl	$0xf, %esi
  10837b:      	movl	$0x9, %r9d
  108381:      	pushq	%rax
  108382:      	pushq	%r10
  108384:      	pushq	%r11
  108386:      	callq	0x109fc0 <shllvm_create_unit>
  10838b:      	addq	$0x20, %rsp
  10838f:      	popq	%rcx
  108390:      	retq
  108391:      	nopw	%cs:(%rax,%rax)

0000000000108530 <shllvm_frame_size>:
  108530:      	pushq	%rbp
  108531:      	movq	%rsp, %rbp
  108534:      	movl	%edi, %eax
  108536:      	leaq	0x20(,%rax,8), %rax
  10853e:      	popq	%rbp
  10853f:      	retq

