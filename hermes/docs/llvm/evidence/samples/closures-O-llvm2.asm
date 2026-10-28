0000000000106c90 <shllvm_f0>:
  106c90:      	pushq	%rbp
  106c91:      	movq	%rsp, %rbp
  106c94:      	pushq	%r15
  106c96:      	pushq	%r14
  106c98:      	pushq	%r13
  106c9a:      	pushq	%r12
  106c9c:      	pushq	%rbx
  106c9d:      	subq	$0x1e8, %rsp            # imm = 0x1E8
  106ca4:      	movq	%rdi, %rbx
  106ca7:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  106cac:      	movl	$0x42, %edi
  106cb1:      	callq	0x108750 <shllvm_frame_size>
  106cb6:      	movq	%rsp, %r15
  106cb9:      	addq	$0xf, %rax
  106cbd:      	andq	$-0x10, %rax
  106cc1:      	subq	%rax, %r15
  106cc4:      	movq	%r15, %rsp
  106cc7:      	movl	0x9955d2(%rip), %r14d   # 0xa9c2a0 <shllvm_unit_index>
  106cce:      	movq	%rbx, %rdi
  106cd1:      	movq	%r15, %rsi
  106cd4:      	movq	%r15, -0x208(%rbp)
  106cdb:      	movl	$0x42, %edx
  106ce0:      	movl	$0x6, %ecx
  106ce5:      	movl	%r14d, %r8d
  106ce8:      	callq	0x1087e0 <shllvm_enter>
  106ced:      	movq	%rax, %r13
  106cf0:      	movq	%rax, -0x30(%rbp)
  106cf4:      	movq	%r15, %rdi
  106cf7:      	callq	0x108b90 <shllvm_roots>
  106cfc:      	movq	%rax, %r12
  106cff:      	movq	%rbx, %rdi
  106d02:      	movl	%r14d, %esi
  106d05:      	callq	0x108760 <shllvm_get_unit>
  106d0a:      	movq	%rax, %r14
  106d0d:      	leaq	0x18(%r12), %rax
  106d12:      	movq	%rax, -0x40(%rbp)
  106d16:      	leaq	0x20(%r12), %rax
  106d1b:      	movq	%rax, -0x150(%rbp)
  106d22:      	leaq	0x30(%r12), %rax
  106d27:      	movq	%rax, -0x158(%rbp)
  106d2e:      	leaq	0x40(%r12), %rax
  106d33:      	movq	%rax, -0x160(%rbp)
  106d3a:      	leaq	0x50(%r12), %rax
  106d3f:      	movq	%rax, -0x168(%rbp)
  106d46:      	leaq	0x60(%r12), %rax
  106d4b:      	movq	%rax, -0x48(%rbp)
  106d4f:      	leaq	0x68(%r12), %rax
  106d54:      	movq	%rax, -0x80(%rbp)
  106d58:      	leaq	0x70(%r12), %rax
  106d5d:      	movq	%rax, -0x170(%rbp)
  106d64:      	leaq	0x80(%r12), %rax
  106d6c:      	movq	%rax, -0x98(%rbp)
  106d73:      	leaq	0x88(%r12), %rax
  106d7b:      	movq	%rax, -0xa8(%rbp)
  106d82:      	leaq	0x90(%r12), %rax
  106d8a:      	movq	%rax, -0x178(%rbp)
  106d91:      	leaq	0x98(%r12), %rax
  106d99:      	movq	%rax, -0x180(%rbp)
  106da0:      	leaq	0xa0(%r12), %rax
  106da8:      	movq	%rax, -0x188(%rbp)
  106daf:      	leaq	0xa8(%r12), %rax
  106db7:      	movq	%rax, -0x190(%rbp)
  106dbe:      	leaq	0xb0(%r12), %rax
  106dc6:      	movq	%rax, -0x198(%rbp)
  106dcd:      	leaq	0xb8(%r12), %rax
  106dd5:      	movq	%rax, -0x1a0(%rbp)
  106ddc:      	leaq	0xc0(%r12), %rax
  106de4:      	movq	%rax, -0x88(%rbp)
  106deb:      	leaq	0xc8(%r12), %rax
  106df3:      	movq	%rax, -0x1a8(%rbp)
  106dfa:      	leaq	0xd0(%r12), %rax
  106e02:      	movq	%rax, -0x90(%rbp)
  106e09:      	leaq	0xd8(%r12), %rax
  106e11:      	movq	%rax, -0x1b0(%rbp)
  106e18:      	leaq	0xe0(%r12), %rax
  106e20:      	movq	%rax, -0xa0(%rbp)
  106e27:      	leaq	0xe8(%r12), %rax
  106e2f:      	movq	%rax, -0x1b8(%rbp)
  106e36:      	leaq	0xf0(%r12), %rax
  106e3e:      	movq	%rax, -0x1c0(%rbp)
  106e45:      	leaq	0xf8(%r12), %rax
  106e4d:      	movq	%rax, -0x1c8(%rbp)
  106e54:      	leaq	0x108(%r12), %rax
  106e5c:      	movq	%rax, -0xb0(%rbp)
  106e63:      	leaq	0x118(%r12), %rax
  106e6b:      	movq	%rax, -0xb8(%rbp)
  106e72:      	leaq	0x120(%r12), %rax
  106e7a:      	movq	%rax, -0xc0(%rbp)
  106e81:      	leaq	0x130(%r12), %rax
  106e89:      	movq	%rax, -0x1d0(%rbp)
  106e90:      	leaq	0x140(%r12), %rax
  106e98:      	movq	%rax, -0x1d8(%rbp)
  106e9f:      	leaq	0x148(%r12), %rax
  106ea7:      	movq	%rax, -0x1e0(%rbp)
  106eae:      	leaq	0x150(%r12), %rax
  106eb6:      	movq	%rax, -0xc8(%rbp)
  106ebd:      	leaq	0x158(%r12), %rax
  106ec5:      	movq	%rax, -0x1e8(%rbp)
  106ecc:      	leaq	0x160(%r12), %rax
  106ed4:      	movq	%rax, -0x1f0(%rbp)
  106edb:      	leaq	0x170(%r12), %rax
  106ee3:      	movq	%rax, -0x1f8(%rbp)
  106eea:      	leaq	0x178(%r12), %rax
  106ef2:      	movq	%rax, -0x200(%rbp)
  106ef9:      	leaq	0x188(%r12), %r15
  106f01:      	leaq	0x190(%r12), %rax
  106f09:      	movq	%rax, -0xd8(%rbp)
  106f10:      	leaq	0x198(%r12), %rax
  106f18:      	movq	%rax, -0xe0(%rbp)
  106f1f:      	leaq	0x1a0(%r12), %rax
  106f27:      	movq	%rax, -0xe8(%rbp)
  106f2e:      	leaq	0x1a8(%r12), %rax
  106f36:      	movq	%rax, -0xf0(%rbp)
  106f3d:      	leaq	0x1b0(%r12), %rax
  106f45:      	movq	%rax, -0xf8(%rbp)
  106f4c:      	leaq	0x1b8(%r12), %rax
  106f54:      	movq	%rax, -0x100(%rbp)
  106f5b:      	leaq	0x1c0(%r12), %rax
  106f63:      	movq	%rax, -0x108(%rbp)
  106f6a:      	leaq	0x1c8(%r12), %rax
  106f72:      	movq	%rax, -0x110(%rbp)
  106f79:      	leaq	0x1d0(%r12), %rax
  106f81:      	movq	%rax, -0x118(%rbp)
  106f88:      	leaq	0x1d8(%r12), %rax
  106f90:      	movq	%rax, -0x120(%rbp)
  106f97:      	leaq	0x1e0(%r12), %rax
  106f9f:      	movq	%rax, -0x128(%rbp)
  106fa6:      	leaq	0x1e8(%r12), %rax
  106fae:      	movq	%rax, -0x130(%rbp)
  106fb5:      	leaq	0x1f0(%r12), %rax
  106fbd:      	movq	%rax, -0x138(%rbp)
  106fc4:      	leaq	0x1f8(%r12), %rax
  106fcc:      	movq	%rax, -0x140(%rbp)
  106fd3:      	leaq	0x200(%r12), %rax
  106fdb:      	movq	%rax, -0x148(%rbp)
  106fe2:      	movq	%rbx, %rdi
  106fe5:      	movq	%r13, %rsi
  106fe8:      	xorl	%edx, %edx
  106fea:      	callq	0x10aab0 <shllvm_check_invocation>
  106fef:      	movq	%r15, %rdi
  106ff2:      	movq	%rbx, %rsi
  106ff5:      	movq	%r14, %rdx
  106ff8:      	movl	$0x1, %ecx
  106ffd:      	callq	0x108d00 <shllvm_symbol>
  107002:      	movq	-0xd8(%rbp), %rdi
  107009:      	movq	%rbx, %rsi
  10700c:      	movq	%r14, %rdx
  10700f:      	movl	$0x2, %ecx
  107014:      	callq	0x108d00 <shllvm_symbol>
  107019:      	movq	-0xe0(%rbp), %rdi
  107020:      	movq	%rbx, %rsi
  107023:      	movq	%r14, %rdx
  107026:      	movl	$0x3, %ecx
  10702b:      	callq	0x108d00 <shllvm_symbol>
  107030:      	movabsq	$0x4044000000000000, %rdx # imm = 0x4044000000000000
  10703a:      	movq	-0xe8(%rbp), %rdi
  107041:      	movl	$0x3, %esi
  107046:      	callq	0x108620 <shllvm_constant>
  10704b:      	movq	-0xf0(%rbp), %rdi
  107052:      	xorl	%esi, %esi
  107054:      	xorl	%edx, %edx
  107056:      	callq	0x108620 <shllvm_constant>
  10705b:      	movq	-0xf8(%rbp), %rdi
  107062:      	movl	$0x2, %esi
  107067:      	xorl	%edx, %edx
  107069:      	callq	0x108620 <shllvm_constant>
  10706e:      	movabsq	$0x4059000000000000, %rdx # imm = 0x4059000000000000
  107078:      	movq	-0x100(%rbp), %rdi
  10707f:      	movl	$0x3, %esi
  107084:      	callq	0x108620 <shllvm_constant>
  107089:      	movq	-0x108(%rbp), %rdi
  107090:      	movq	%rbx, %rsi
  107093:      	movq	%r14, %rdx
  107096:      	movl	$0x9, %ecx
  10709b:      	callq	0x108d00 <shllvm_symbol>
  1070a0:      	movq	-0x110(%rbp), %rdi
  1070a7:      	movq	%rbx, %rsi
  1070aa:      	movq	%r14, %rdx
  1070ad:      	movl	$0x4, %ecx
  1070b2:      	callq	0x108d00 <shllvm_symbol>
  1070b7:      	movq	-0x118(%rbp), %rdi
  1070be:      	movq	%rbx, %rsi
  1070c1:      	movq	%r14, %rdx
  1070c4:      	movl	$0x5, %ecx
  1070c9:      	callq	0x108d00 <shllvm_symbol>
  1070ce:      	movq	-0x120(%rbp), %rdi
  1070d5:      	movq	%rbx, %rsi
  1070d8:      	movq	%r14, %rdx
  1070db:      	movl	$0x6, %ecx
  1070e0:      	callq	0x108d00 <shllvm_symbol>
  1070e5:      	movabsq	$0x401c000000000000, %rdx # imm = 0x401C000000000000
  1070ef:      	movq	-0x128(%rbp), %rdi
  1070f6:      	movl	$0x3, %esi
  1070fb:      	callq	0x108620 <shllvm_constant>
  107100:      	movabsq	$0x4026000000000000, %rdx # imm = 0x4026000000000000
  10710a:      	movq	-0x130(%rbp), %rdi
  107111:      	movl	$0x3, %esi
  107116:      	callq	0x108620 <shllvm_constant>
  10711b:      	movabsq	$0x4038000000000000, %rdx # imm = 0x4038000000000000
  107125:      	movq	-0x138(%rbp), %rdi
  10712c:      	movl	$0x3, %esi
  107131:      	callq	0x108620 <shllvm_constant>
  107136:      	movabsq	$0x4039000000000000, %rdx # imm = 0x4039000000000000
  107140:      	movq	-0x140(%rbp), %rdi
  107147:      	movl	$0x3, %esi
  10714c:      	callq	0x108620 <shllvm_constant>
  107151:      	movabsq	$0x4034000000000000, %rdx # imm = 0x4034000000000000
  10715b:      	movq	-0x148(%rbp), %rdi
  107162:      	movl	$0x3, %esi
  107167:      	callq	0x108620 <shllvm_constant>
  10716c:      	movq	%rbx, %rdi
  10716f:      	movq	%r14, %rsi
  107172:      	movl	$0x1, %edx
  107177:      	callq	0x108e00 <shllvm_declare_global>
  10717c:      	movq	%rbx, %rdi
  10717f:      	movq	%r14, %rsi
  107182:      	movl	$0x2, %edx
  107187:      	callq	0x108e00 <shllvm_declare_global>
  10718c:      	movq	%rbx, %rdi
  10718f:      	movq	%r14, %rsi
  107192:      	movl	$0x3, %edx
  107197:      	callq	0x108e00 <shllvm_declare_global>
  10719c:      	movq	-0x40(%rbp), %r15
  1071a0:      	movq	%r15, %rdi
  1071a3:      	movq	%rbx, %rsi
  1071a6:      	callq	0x108cc0 <shllvm_global>
  1071ab:      	leaq	0x6ae(%rip), %r8        # 0x107860 <shllvm_f1>
  1071b2:      	movq	-0x150(%rbp), %r13
  1071b9:      	movq	%r13, %rdi
  1071bc:      	movq	%rbx, %rsi
  1071bf:      	xorl	%edx, %edx
  1071c1:      	movq	%r14, %rcx
  1071c4:      	movl	$0x1, %r9d
  1071ca:      	callq	0x109180 <shllvm_closure>
  1071cf:      	subq	$0x8, %rsp
  1071d3:      	movq	%rbx, %rdi
  1071d6:      	movq	%r14, %rsi
  1071d9:      	movq	%r15, %rdx
  1071dc:      	movl	$0x1, %ecx
  1071e1:      	movq	%r13, %r8
  1071e4:      	xorl	%r9d, %r9d
  1071e7:      	pushq	$0x0
  1071e9:      	callq	0x109d50 <shllvm_set_id>
  1071ee:      	addq	$0x10, %rsp
  1071f2:      	leaq	0x9b7(%rip), %r8        # 0x107bb0 <shllvm_f2>
  1071f9:      	movq	-0x158(%rbp), %r13
  107200:      	movq	%r13, %rdi
  107203:      	movq	%rbx, %rsi
  107206:      	xorl	%edx, %edx
  107208:      	movq	%r14, %rcx
  10720b:      	movl	$0x2, %r9d
  107211:      	callq	0x109180 <shllvm_closure>
  107216:      	subq	$0x8, %rsp
  10721a:      	movq	%rbx, %rdi
  10721d:      	movq	%r14, %rsi
  107220:      	movq	%r15, %rdx
  107223:      	movl	$0x2, %ecx
  107228:      	movq	%r13, %r8
  10722b:      	xorl	%r9d, %r9d
  10722e:      	pushq	$0x0
  107230:      	callq	0x109d50 <shllvm_set_id>
  107235:      	addq	$0x10, %rsp
  107239:      	leaq	0xa70(%rip), %r8        # 0x107cb0 <shllvm_f3>
  107240:      	movq	-0x160(%rbp), %r13
  107247:      	movq	%r13, %rdi
  10724a:      	movq	%rbx, %rsi
  10724d:      	xorl	%edx, %edx
  10724f:      	movq	%r14, %rcx
  107252:      	movl	$0x3, %r9d
  107258:      	callq	0x109180 <shllvm_closure>
  10725d:      	subq	$0x8, %rsp
  107261:      	movq	%rbx, %rdi
  107264:      	movq	%r14, %rsi
  107267:      	movq	%r15, %rdx
  10726a:      	movl	$0x3, %ecx
  10726f:      	movq	%r13, %r8
  107272:      	xorl	%r9d, %r9d
  107275:      	pushq	$0x0
  107277:      	callq	0x109d50 <shllvm_set_id>
  10727c:      	addq	$0x10, %rsp
  107280:      	movq	-0x168(%rbp), %r13
  107287:      	movq	%r13, %rdi
  10728a:      	movq	%rbx, %rsi
  10728d:      	movq	%r14, %rdx
  107290:      	movq	%r15, %rcx
  107293:      	movl	$0x1, %r8d
  107299:      	xorl	%r9d, %r9d
  10729c:      	callq	0x109be0 <shllvm_get_id>
  1072a1:      	movups	0x1a0(%r12), %xmm0
  1072aa:      	movups	%xmm0, 0x58(%r12)
  1072b0:      	movlps	%xmm0, -0x78(%rbp)
  1072b4:      	leaq	-0x78(%rbp), %rax
  1072b8:      	movq	-0x80(%rbp), %rdi
  1072bc:      	movq	%rbx, %rsi
  1072bf:      	movq	-0x30(%rbp), %r15
  1072c3:      	movq	%r15, %rdx
  1072c6:      	movq	%r13, %rcx
  1072c9:      	movq	-0x48(%rbp), %r8
  1072cd:      	movq	%r8, %r9
  1072d0:      	pushq	%rax
  1072d1:      	pushq	$0x1
  1072d3:      	callq	0x1092b0 <shllvm_call>
  1072d8:      	addq	$0x10, %rsp
  1072dc:      	movq	-0x170(%rbp), %r13
  1072e3:      	movq	%r13, %rdi
  1072e6:      	movq	%rbx, %rsi
  1072e9:      	movq	%r14, %rdx
  1072ec:      	movq	-0x40(%rbp), %rcx
  1072f0:      	movl	$0x1, %r8d
  1072f6:      	xorl	%r9d, %r9d
  1072f9:      	callq	0x109be0 <shllvm_get_id>
  1072fe:      	movq	0x1b8(%r12), %rax
  107306:      	movq	%rax, 0x78(%r12)
  10730b:      	movq	%rax, -0x78(%rbp)
  10730f:      	movq	-0x98(%rbp), %rdi
  107316:      	movq	%rbx, %rsi
  107319:      	movq	%r15, %rdx
  10731c:      	movq	%r13, %rcx
  10731f:      	movq	-0x48(%rbp), %r13
  107323:      	movq	%r13, %r8
  107326:      	movq	%r13, %r9
  107329:      	leaq	-0x78(%rbp), %rax
  10732d:      	pushq	%rax
  10732e:      	pushq	$0x1
  107330:      	callq	0x1092b0 <shllvm_call>
  107335:      	addq	$0x10, %rsp
  107339:      	movq	-0xa8(%rbp), %rdi
  107340:      	movq	%rbx, %rsi
  107343:      	movq	%r14, -0x38(%rbp)
  107347:      	movq	%r14, %rdx
  10734a:      	movq	-0x40(%rbp), %rcx
  10734e:      	movl	$0x9, %r8d
  107354:      	movl	$0x1, %r9d
  10735a:      	callq	0x109be0 <shllvm_get_id>
  10735f:      	movq	-0x178(%rbp), %r15
  107366:      	movq	%r15, %rdi
  107369:      	movq	%rbx, %rsi
  10736c:      	movq	%r14, %rdx
  10736f:      	movq	-0x80(%rbp), %r14
  107373:      	movq	%r14, %rcx
  107376:      	movl	$0x4, %r8d
  10737c:      	xorl	%r9d, %r9d
  10737f:      	callq	0x109be0 <shllvm_get_id>
  107384:      	movq	-0x180(%rbp), %rdi
  10738b:      	movq	%rbx, %rsi
  10738e:      	movq	-0x30(%rbp), %rdx
  107392:      	movq	%r15, %rcx
  107395:      	movq	%r14, %r8
  107398:      	movq	%r13, %r9
  10739b:      	leaq	-0x78(%rbp), %rax
  10739f:      	pushq	%rax
  1073a0:      	pushq	$0x0
  1073a2:      	callq	0x1092b0 <shllvm_call>
  1073a7:      	addq	$0x10, %rsp
  1073ab:      	movq	-0x188(%rbp), %r15
  1073b2:      	movq	%r15, %rdi
  1073b5:      	movq	%rbx, %rsi
  1073b8:      	movq	-0x38(%rbp), %rdx
  1073bc:      	movq	%r14, %rcx
  1073bf:      	movl	$0x4, %r8d
  1073c5:      	xorl	%r9d, %r9d
  1073c8:      	callq	0x109be0 <shllvm_get_id>
  1073cd:      	movq	-0x190(%rbp), %rdi
  1073d4:      	movq	%rbx, %rsi
  1073d7:      	movq	-0x30(%rbp), %rdx
  1073db:      	movq	%r15, %rcx
  1073de:      	movq	%r14, %r8
  1073e1:      	movq	%r13, %r9
  1073e4:      	leaq	-0x78(%rbp), %rax
  1073e8:      	pushq	%rax
  1073e9:      	pushq	$0x0
  1073eb:      	callq	0x1092b0 <shllvm_call>
  1073f0:      	addq	$0x10, %rsp
  1073f4:      	movq	-0x198(%rbp), %r15
  1073fb:      	movq	%r15, %rdi
  1073fe:      	movq	%rbx, %rsi
  107401:      	movq	-0x38(%rbp), %r13
  107405:      	movq	%r13, %rdx
  107408:      	movq	%r14, %rcx
  10740b:      	movl	$0x5, %r8d
  107411:      	xorl	%r9d, %r9d
  107414:      	callq	0x109be0 <shllvm_get_id>
  107419:      	movq	-0x1a0(%rbp), %rdi
  107420:      	movq	%rbx, %rsi
  107423:      	movq	-0x30(%rbp), %rdx
  107427:      	movq	%r15, %rcx
  10742a:      	movq	%r14, %r8
  10742d:      	movq	-0x48(%rbp), %r15
  107431:      	movq	%r15, %r9
  107434:      	leaq	-0x78(%rbp), %rax
  107438:      	pushq	%rax
  107439:      	pushq	$0x0
  10743b:      	callq	0x1092b0 <shllvm_call>
  107440:      	addq	$0x10, %rsp
  107444:      	movq	-0x88(%rbp), %rdi
  10744b:      	movq	%rbx, %rsi
  10744e:      	movq	%r13, %rdx
  107451:      	movq	%r14, %rcx
  107454:      	movl	$0x6, %r8d
  10745a:      	xorl	%r9d, %r9d
  10745d:      	callq	0x109be0 <shllvm_get_id>
  107462:      	movq	-0x1a8(%rbp), %rdi
  107469:      	movq	%rbx, %rsi
  10746c:      	movq	%rbx, %r13
  10746f:      	movq	-0x30(%rbp), %rbx
  107473:      	movq	%rbx, %rdx
  107476:      	movq	-0x88(%rbp), %rcx
  10747d:      	movq	%r14, %r8
  107480:      	movq	%r15, %r9
  107483:      	leaq	-0x78(%rbp), %rax
  107487:      	pushq	%rax
  107488:      	pushq	$0x0
  10748a:      	callq	0x1092b0 <shllvm_call>
  10748f:      	addq	$0x10, %rsp
  107493:      	movq	-0x90(%rbp), %rdi
  10749a:      	movq	%r13, -0xd0(%rbp)
  1074a1:      	movq	%r13, %rsi
  1074a4:      	movq	-0x38(%rbp), %r14
  1074a8:      	movq	%r14, %rdx
  1074ab:      	movq	-0x98(%rbp), %r15
  1074b2:      	movq	%r15, %rcx
  1074b5:      	movl	$0x4, %r8d
  1074bb:      	xorl	%r9d, %r9d
  1074be:      	callq	0x109be0 <shllvm_get_id>
  1074c3:      	movq	-0x1b0(%rbp), %rdi
  1074ca:      	movq	%r13, %rsi
  1074cd:      	movq	%rbx, %rdx
  1074d0:      	movq	-0x90(%rbp), %rcx
  1074d7:      	movq	%r15, %r8
  1074da:      	movq	-0x48(%rbp), %r13
  1074de:      	movq	%r13, %r9
  1074e1:      	leaq	-0x78(%rbp), %rax
  1074e5:      	pushq	%rax
  1074e6:      	pushq	$0x0
  1074e8:      	callq	0x1092b0 <shllvm_call>
  1074ed:      	addq	$0x10, %rsp
  1074f1:      	movq	-0xa0(%rbp), %rdi
  1074f8:      	movq	-0xd0(%rbp), %rbx
  1074ff:      	movq	%rbx, %rsi
  107502:      	movq	%r14, %rdx
  107505:      	movq	-0x80(%rbp), %r15
  107509:      	movq	%r15, %rcx
  10750c:      	movl	$0x6, %r8d
  107512:      	xorl	%r9d, %r9d
  107515:      	callq	0x109be0 <shllvm_get_id>
  10751a:      	movq	-0x1b8(%rbp), %rdi
  107521:      	movq	%rbx, %rsi
  107524:      	movq	-0x30(%rbp), %r14
  107528:      	movq	%r14, %rdx
  10752b:      	movq	-0xa0(%rbp), %rcx
  107532:      	movq	%r15, %r8
  107535:      	movq	%r13, %r9
  107538:      	leaq	-0x78(%rbp), %r15
  10753c:      	pushq	%r15
  10753e:      	pushq	$0x0
  107540:      	callq	0x1092b0 <shllvm_call>
  107545:      	addq	$0x10, %rsp
  107549:      	movq	0x98(%r12), %rax
  107551:      	movq	%rax, -0x78(%rbp)
  107555:      	movq	0xa8(%r12), %rax
  10755d:      	movq	%rax, -0x70(%rbp)
  107561:      	movq	0xb8(%r12), %rax
  107569:      	movq	%rax, -0x68(%rbp)
  10756d:      	movq	0xc8(%r12), %rax
  107575:      	movq	%rax, -0x60(%rbp)
  107579:      	movq	0xd8(%r12), %rax
  107581:      	movq	%rax, -0x58(%rbp)
  107585:      	movq	0xe8(%r12), %rax
  10758d:      	movq	%rax, -0x50(%rbp)
  107591:      	movq	-0x1c0(%rbp), %rdi
  107598:      	movq	%rbx, %rsi
  10759b:      	movq	%r14, %rdx
  10759e:      	movq	-0xa8(%rbp), %rcx
  1075a5:      	movq	%r13, %r8
  1075a8:      	movq	%r13, %r9
  1075ab:      	pushq	%r15
  1075ad:      	pushq	$0x6
  1075af:      	callq	0x1092b0 <shllvm_call>
  1075b4:      	addq	$0x10, %rsp
  1075b8:      	movq	-0x1c8(%rbp), %r15
  1075bf:      	movq	%r15, %rdi
  1075c2:      	movq	%rbx, %rsi
  1075c5:      	movq	-0x38(%rbp), %rdx
  1075c9:      	movq	-0x40(%rbp), %rcx
  1075cd:      	movl	$0x2, %r8d
  1075d3:      	xorl	%r9d, %r9d
  1075d6:      	callq	0x109be0 <shllvm_get_id>
  1075db:      	movq	0x1e0(%r12), %rax
  1075e3:      	movq	%rax, 0x100(%r12)
  1075eb:      	movq	%rax, -0x78(%rbp)
  1075ef:      	movq	-0xb0(%rbp), %rdi
  1075f6:      	movq	%rbx, %rsi
  1075f9:      	movq	%r14, %rdx
  1075fc:      	movq	%r15, %rcx
  1075ff:      	movq	%r13, %r8
  107602:      	movq	%r13, %r9
  107605:      	movq	%r13, %r15
  107608:      	leaq	-0x78(%rbp), %rax
  10760c:      	pushq	%rax
  10760d:      	pushq	$0x1
  10760f:      	callq	0x1092b0 <shllvm_call>
  107614:      	addq	$0x10, %rsp
  107618:      	movq	0x1e8(%r12), %rax
  107620:      	movq	%rax, 0x110(%r12)
  107628:      	movq	%rax, -0x78(%rbp)
  10762c:      	movq	-0xb8(%rbp), %r13
  107633:      	movq	%r13, %rdi
  107636:      	movq	%rbx, %rsi
  107639:      	movq	%r14, %rdx
  10763c:      	movq	-0xb0(%rbp), %rcx
  107643:      	movq	%r15, %r8
  107646:      	movq	%r15, %r9
  107649:      	leaq	-0x78(%rbp), %rax
  10764d:      	pushq	%rax
  10764e:      	pushq	$0x1
  107650:      	callq	0x1092b0 <shllvm_call>
  107655:      	addq	$0x10, %rsp
  107659:      	movq	-0xc0(%rbp), %rdi
  107660:      	movq	%rbx, %rsi
  107663:      	movq	-0x38(%rbp), %rdx
  107667:      	movq	-0x40(%rbp), %rcx
  10766b:      	movl	$0x9, %r8d
  107671:      	movl	$0x1, %r9d
  107677:      	callq	0x109be0 <shllvm_get_id>
  10767c:      	movq	0x1f0(%r12), %rax
  107684:      	movq	%rax, 0x128(%r12)
  10768c:      	movq	%rax, -0x78(%rbp)
  107690:      	movq	-0x1d0(%rbp), %rdi
  107697:      	movq	%rbx, %rsi
  10769a:      	movq	%r14, %rdx
  10769d:      	movq	%r13, %rcx
  1076a0:      	movq	%r15, %r8
  1076a3:      	movq	%r15, %r9
  1076a6:      	leaq	-0x78(%rbp), %rax
  1076aa:      	pushq	%rax
  1076ab:      	pushq	$0x1
  1076ad:      	callq	0x1092b0 <shllvm_call>
  1076b2:      	addq	$0x10, %rsp
  1076b6:      	movq	0x1f8(%r12), %rax
  1076be:      	movq	%rax, 0x138(%r12)
  1076c6:      	movq	%rax, -0x78(%rbp)
  1076ca:      	movq	-0x1d8(%rbp), %rdi
  1076d1:      	movq	%rbx, %rsi
  1076d4:      	movq	%r14, %r13
  1076d7:      	movq	%r14, %rdx
  1076da:      	movq	-0xb8(%rbp), %rcx
  1076e1:      	movq	%r15, %r8
  1076e4:      	movq	%r15, %r9
  1076e7:      	leaq	-0x78(%rbp), %r14
  1076eb:      	pushq	%r14
  1076ed:      	pushq	$0x1
  1076ef:      	callq	0x1092b0 <shllvm_call>
  1076f4:      	addq	$0x10, %rsp
  1076f8:      	movq	0x130(%r12), %rax
  107700:      	movq	%rax, -0x78(%rbp)
  107704:      	movq	0x140(%r12), %rax
  10770c:      	movq	%rax, -0x70(%rbp)
  107710:      	movq	-0x1e0(%rbp), %rdi
  107717:      	movq	%rbx, %rsi
  10771a:      	movq	%r13, %rdx
  10771d:      	movq	-0xc0(%rbp), %rcx
  107724:      	movq	%r15, %r8
  107727:      	movq	%r15, %r9
  10772a:      	pushq	%r14
  10772c:      	pushq	$0x2
  10772e:      	callq	0x1092b0 <shllvm_call>
  107733:      	addq	$0x10, %rsp
  107737:      	movq	-0xc8(%rbp), %rdi
  10773e:      	movq	%rbx, %rsi
  107741:      	movq	-0x38(%rbp), %r15
  107745:      	movq	%r15, %rdx
  107748:      	movq	-0x40(%rbp), %r14
  10774c:      	movq	%r14, %rcx
  10774f:      	movl	$0x9, %r8d
  107755:      	movl	$0x1, %r9d
  10775b:      	callq	0x109be0 <shllvm_get_id>
  107760:      	movq	-0x1e8(%rbp), %r13
  107767:      	movq	%r13, %rdi
  10776a:      	movq	%rbx, %rsi
  10776d:      	movq	%r15, %rdx
  107770:      	movq	%r14, %rcx
  107773:      	movl	$0x3, %r8d
  107779:      	xorl	%r9d, %r9d
  10777c:      	callq	0x109be0 <shllvm_get_id>
  107781:      	movq	-0x1f0(%rbp), %r14
  107788:      	movq	%r14, %rdi
  10778b:      	movq	%rbx, %rsi
  10778e:      	movq	-0x30(%rbp), %r15
  107792:      	movq	%r15, %rdx
  107795:      	movq	%r13, %rcx
  107798:      	movq	-0x48(%rbp), %r8
  10779c:      	movq	%r8, %r9
  10779f:      	movq	%r8, %r13
  1077a2:      	leaq	-0x78(%rbp), %rax
  1077a6:      	pushq	%rax
  1077a7:      	pushq	$0x0
  1077a9:      	callq	0x1092b0 <shllvm_call>
  1077ae:      	addq	$0x10, %rsp
  1077b2:      	movq	0x200(%r12), %rax
  1077ba:      	movq	%rax, 0x168(%r12)
  1077c2:      	movq	%rax, -0x78(%rbp)
  1077c6:      	movq	-0x1f8(%rbp), %rdi
  1077cd:      	movq	%rbx, %rsi
  1077d0:      	movq	%r15, %rdx
  1077d3:      	movq	%r14, %rcx
  1077d6:      	movq	%r13, %r14
  1077d9:      	movq	%r13, %r8
  1077dc:      	movq	%r13, %r9
  1077df:      	leaq	-0x78(%rbp), %rax
  1077e3:      	pushq	%rax
  1077e4:      	movq	%rax, %r13
  1077e7:      	pushq	$0x1
  1077e9:      	callq	0x1092b0 <shllvm_call>
  1077ee:      	addq	$0x10, %rsp
  1077f2:      	movq	0x170(%r12), %rax
  1077fa:      	movq	%rax, -0x78(%rbp)
  1077fe:      	movq	-0x200(%rbp), %rdi
  107805:      	movq	%rbx, %rsi
  107808:      	movq	%r15, %rdx
  10780b:      	movq	-0xc8(%rbp), %rcx
  107812:      	movq	%r14, %r8
  107815:      	movq	%r14, %r9
  107818:      	pushq	%r13
  10781a:      	pushq	$0x1
  10781c:      	callq	0x1092b0 <shllvm_call>
  107821:      	addq	$0x10, %rsp
  107825:      	movq	0x178(%r12), %r14
  10782d:      	movq	%rbx, %rdi
  107830:      	movq	-0x208(%rbp), %rsi
  107837:      	movq	%r15, %rdx
  10783a:      	callq	0x108ba0 <shllvm_leave>
  10783f:      	movq	%r14, %rax
  107842:      	leaq	-0x28(%rbp), %rsp
  107846:      	popq	%rbx
  107847:      	popq	%r12
  107849:      	popq	%r13
  10784b:      	popq	%r14
  10784d:      	popq	%r15
  10784f:      	popq	%rbp
  107850:      	retq
  107851:      	nopw	%cs:(%rax,%rax)

0000000000107860 <shllvm_f1>:
  107860:      	pushq	%rbp
  107861:      	movq	%rsp, %rbp
  107864:      	pushq	%r15
  107866:      	pushq	%r14
  107868:      	pushq	%r13
  10786a:      	pushq	%r12
  10786c:      	pushq	%rbx
  10786d:      	subq	$0x88, %rsp
  107874:      	movq	%rdi, %rbx
  107877:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  10787c:      	movl	$0x14, %edi
  107881:      	callq	0x108750 <shllvm_frame_size>
  107886:      	movq	%rsp, %r15
  107889:      	addq	$0xf, %rax
  10788d:      	andq	$-0x10, %rax
  107891:      	subq	%rax, %r15
  107894:      	movq	%r15, -0xa8(%rbp)
  10789b:      	movq	%r15, %rsp
  10789e:      	movl	0x9949fb(%rip), %r14d   # 0xa9c2a0 <shllvm_unit_index>
  1078a5:      	movq	%rbx, %rdi
  1078a8:      	movq	%r15, %rsi
  1078ab:      	movl	$0x14, %edx
  1078b0:      	xorl	%ecx, %ecx
  1078b2:      	movl	%r14d, %r8d
  1078b5:      	callq	0x1087e0 <shllvm_enter>
  1078ba:      	movq	%rax, %r13
  1078bd:      	movq	%r15, %rdi
  1078c0:      	callq	0x108b90 <shllvm_roots>
  1078c5:      	movq	%rax, %r12
  1078c8:      	movq	%rbx, %rdi
  1078cb:      	movl	%r14d, %esi
  1078ce:      	callq	0x108760 <shllvm_get_unit>
  1078d3:      	movq	%rax, -0x40(%rbp)
  1078d7:      	leaq	0x8(%r12), %rax
  1078dc:      	movq	%rax, -0x70(%rbp)
  1078e0:      	leaq	0x18(%r12), %rax
  1078e5:      	movq	%rax, -0x80(%rbp)
  1078e9:      	leaq	0x20(%r12), %rax
  1078ee:      	movq	%rax, -0x90(%rbp)
  1078f5:      	leaq	0x30(%r12), %rax
  1078fa:      	movq	%rax, -0x98(%rbp)
  107901:      	leaq	0x40(%r12), %rax
  107906:      	movq	%rax, -0xa0(%rbp)
  10790d:      	leaq	0x58(%r12), %r14
  107912:      	movq	%r14, -0x78(%rbp)
  107916:      	leaq	0x60(%r12), %r15
  10791b:      	movq	%r15, -0x68(%rbp)
  10791f:      	leaq	0x68(%r12), %rax
  107924:      	movq	%rax, -0x30(%rbp)
  107928:      	leaq	0x70(%r12), %rax
  10792d:      	movq	%rax, -0x38(%rbp)
  107931:      	leaq	0x78(%r12), %rax
  107936:      	movq	%rax, -0x48(%rbp)
  10793a:      	leaq	0x80(%r12), %rax
  107942:      	movq	%rax, -0x50(%rbp)
  107946:      	leaq	0x88(%r12), %rax
  10794e:      	movq	%rax, -0x58(%rbp)
  107952:      	leaq	0x90(%r12), %rax
  10795a:      	movq	%rax, -0x60(%rbp)
  10795e:      	movq	%rbx, %rdi
  107961:      	movq	%r13, %rsi
  107964:      	movq	%r13, -0x88(%rbp)
  10796b:      	xorl	%edx, %edx
  10796d:      	callq	0x10aab0 <shllvm_check_invocation>
  107972:      	movq	%r14, %rdi
  107975:      	movq	%rbx, %rsi
  107978:      	movq	-0x40(%rbp), %r14
  10797c:      	movq	%r14, %rdx
  10797f:      	movl	$0x4, %ecx
  107984:      	callq	0x108d00 <shllvm_symbol>
  107989:      	movq	%r15, %rdi
  10798c:      	movl	$0x1, %esi
  107991:      	xorl	%edx, %edx
  107993:      	callq	0x108620 <shllvm_constant>
  107998:      	movq	-0x30(%rbp), %rdi
  10799c:      	movq	%rbx, %rsi
  10799f:      	movq	%r14, %rdx
  1079a2:      	movl	$0x5, %ecx
  1079a7:      	callq	0x108d00 <shllvm_symbol>
  1079ac:      	movq	-0x38(%rbp), %rdi
  1079b0:      	movq	%rbx, %rsi
  1079b3:      	movq	%r14, %rdx
  1079b6:      	movl	$0x6, %ecx
  1079bb:      	callq	0x108d00 <shllvm_symbol>
  1079c0:      	movq	-0x48(%rbp), %rdi
  1079c4:      	movl	$0x3, %esi
  1079c9:      	xorl	%edx, %edx
  1079cb:      	callq	0x108620 <shllvm_constant>
  1079d0:      	movq	-0x50(%rbp), %rdi
  1079d4:      	movl	$0x2, %esi
  1079d9:      	xorl	%edx, %edx
  1079db:      	callq	0x108620 <shllvm_constant>
  1079e0:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  1079ea:      	movq	-0x58(%rbp), %rdi
  1079ee:      	movl	$0x3, %esi
  1079f3:      	callq	0x108620 <shllvm_constant>
  1079f8:      	movabsq	$0x4000000000000000, %rdx # imm = 0x4000000000000000
  107a02:      	movq	-0x60(%rbp), %rdi
  107a06:      	movl	$0x3, %esi
  107a0b:      	callq	0x108620 <shllvm_constant>
  107a10:      	movq	%r12, %rdi
  107a13:      	movq	%rbx, %rsi
  107a16:      	xorl	%edx, %edx
  107a18:      	movl	$0x1, %ecx
  107a1d:      	callq	0x108ee0 <shllvm_env_create>
  107a22:      	movq	-0x70(%rbp), %r15
  107a26:      	movq	%r15, %rdi
  107a29:      	movq	%r13, %rsi
  107a2c:      	movl	$0x1, %edx
  107a31:      	callq	0x108c40 <shllvm_param>
  107a36:      	movq	%rbx, %rdi
  107a39:      	movq	%r12, %rsi
  107a3c:      	movq	%r15, %rdx
  107a3f:      	xorl	%ecx, %ecx
  107a41:      	callq	0x109140 <shllvm_env_store>
  107a46:      	movq	-0x80(%rbp), %r15
  107a4a:      	movq	%r15, %rdi
  107a4d:      	movq	%rbx, %rsi
  107a50:      	callq	0x109ae0 <shllvm_object>
  107a55:      	movq	%rbx, %rdi
  107a58:      	movq	%r15, %rsi
  107a5b:      	movq	-0x78(%rbp), %rdx
  107a5f:      	movq	-0x68(%rbp), %r13
  107a63:      	movq	%r13, %rcx
  107a66:      	movl	$0x1, %r8d
  107a6c:      	callq	0x109eb0 <shllvm_define>
  107a71:      	movq	%rbx, %rdi
  107a74:      	movq	%r15, %rsi
  107a77:      	movq	-0x30(%rbp), %rdx
  107a7b:      	movq	%r13, %rcx
  107a7e:      	movl	$0x1, %r8d
  107a84:      	callq	0x109eb0 <shllvm_define>
  107a89:      	movq	%rbx, %rdi
  107a8c:      	movq	%r15, %rsi
  107a8f:      	movq	-0x38(%rbp), %rdx
  107a93:      	movq	%r13, %rcx
  107a96:      	movl	$0x1, %r8d
  107a9c:      	callq	0x109eb0 <shllvm_define>
  107aa1:      	leaq	0x2f8(%rip), %r8        # 0x107da0 <shllvm_f4>
  107aa8:      	movq	-0x90(%rbp), %r13
  107aaf:      	movq	%r13, %rdi
  107ab2:      	movq	%rbx, %rsi
  107ab5:      	movq	%r12, %rdx
  107ab8:      	movq	%r14, %rcx
  107abb:      	movl	$0x4, %r9d
  107ac1:      	callq	0x109180 <shllvm_closure>
  107ac6:      	subq	$0x8, %rsp
  107aca:      	movq	%rbx, %rdi
  107acd:      	movq	%r14, %rsi
  107ad0:      	movq	%r15, %rdx
  107ad3:      	movl	$0x4, %ecx
  107ad8:      	movq	%r13, %r8
  107adb:      	movl	$0x1, %r9d
  107ae1:      	pushq	$0x0
  107ae3:      	callq	0x109d50 <shllvm_set_id>
  107ae8:      	addq	$0x10, %rsp
  107aec:      	leaq	0x3ad(%rip), %r8        # 0x107ea0 <shllvm_f5>
  107af3:      	movq	-0x98(%rbp), %r13
  107afa:      	movq	%r13, %rdi
  107afd:      	movq	%rbx, %rsi
  107b00:      	movq	%r12, %rdx
  107b03:      	movq	%r14, %rcx
  107b06:      	movl	$0x5, %r9d
  107b0c:      	callq	0x109180 <shllvm_closure>
  107b11:      	subq	$0x8, %rsp
  107b15:      	movq	%rbx, %rdi
  107b18:      	movq	%r14, %rsi
  107b1b:      	movq	%r15, %rdx
  107b1e:      	movl	$0x5, %ecx
  107b23:      	movq	%r13, %r8
  107b26:      	movl	$0x1, %r9d
  107b2c:      	pushq	$0x0
  107b2e:      	callq	0x109d50 <shllvm_set_id>
  107b33:      	addq	$0x10, %rsp
  107b37:      	leaq	0x462(%rip), %r8        # 0x107fa0 <shllvm_f6>
  107b3e:      	movq	-0xa0(%rbp), %r13
  107b45:      	movq	%r13, %rdi
  107b48:      	movq	%rbx, %rsi
  107b4b:      	movq	%r12, %rdx
  107b4e:      	movq	%r14, %rcx
  107b51:      	movl	$0x6, %r9d
  107b57:      	callq	0x109180 <shllvm_closure>
  107b5c:      	subq	$0x8, %rsp
  107b60:      	movq	%rbx, %rdi
  107b63:      	movq	%r14, %rsi
  107b66:      	movq	%r15, %rdx
  107b69:      	movl	$0x6, %ecx
  107b6e:      	movq	%r13, %r8
  107b71:      	movl	$0x1, %r9d
  107b77:      	pushq	$0x0
  107b79:      	callq	0x109d50 <shllvm_set_id>
  107b7e:      	addq	$0x10, %rsp
  107b82:      	movq	0x18(%r12), %r14
  107b87:      	movq	%rbx, %rdi
  107b8a:      	movq	-0xa8(%rbp), %rsi
  107b91:      	movq	-0x88(%rbp), %rdx
  107b98:      	callq	0x108ba0 <shllvm_leave>
  107b9d:      	movq	%r14, %rax
  107ba0:      	leaq	-0x28(%rbp), %rsp
  107ba4:      	popq	%rbx
  107ba5:      	popq	%r12
  107ba7:      	popq	%r13
  107ba9:      	popq	%r14
  107bab:      	popq	%r15
  107bad:      	popq	%rbp
  107bae:      	retq
  107baf:      	nop

0000000000107bb0 <shllvm_f2>:
  107bb0:      	pushq	%rbp
  107bb1:      	movq	%rsp, %rbp
  107bb4:      	pushq	%r15
  107bb6:      	pushq	%r14
  107bb8:      	pushq	%r13
  107bba:      	pushq	%r12
  107bbc:      	pushq	%rbx
  107bbd:      	subq	$0x18, %rsp
  107bc1:      	movq	%rdi, %rbx
  107bc4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107bc9:      	movl	$0x6, %edi
  107bce:      	callq	0x108750 <shllvm_frame_size>
  107bd3:      	movq	%rsp, %r14
  107bd6:      	addq	$0xf, %rax
  107bda:      	andq	$-0x10, %rax
  107bde:      	subq	%rax, %r14
  107be1:      	movq	%r14, %rsp
  107be4:      	movl	0x9946b5(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  107beb:      	movq	%rbx, %rdi
  107bee:      	movq	%r14, %rsi
  107bf1:      	movl	$0x6, %edx
  107bf6:      	xorl	%ecx, %ecx
  107bf8:      	movl	%r13d, %r8d
  107bfb:      	callq	0x1087e0 <shllvm_enter>
  107c00:      	movq	%rax, %r15
  107c03:      	movq	%r14, %rdi
  107c06:      	callq	0x108b90 <shllvm_roots>
  107c0b:      	movq	%rax, %r12
  107c0e:      	movq	%rbx, %rdi
  107c11:      	movl	%r13d, %esi
  107c14:      	callq	0x108760 <shllvm_get_unit>
  107c19:      	movq	%rax, -0x38(%rbp)
  107c1d:      	leaq	0x8(%r12), %r13
  107c22:      	leaq	0x18(%r12), %rax
  107c27:      	movq	%rax, -0x30(%rbp)
  107c2b:      	movq	%rbx, %rdi
  107c2e:      	movq	%r15, %rsi
  107c31:      	xorl	%edx, %edx
  107c33:      	callq	0x10aab0 <shllvm_check_invocation>
  107c38:      	movq	%r12, %rdi
  107c3b:      	movq	%rbx, %rsi
  107c3e:      	xorl	%edx, %edx
  107c40:      	movl	$0x1, %ecx
  107c45:      	callq	0x108ee0 <shllvm_env_create>
  107c4a:      	movq	%r13, %rdi
  107c4d:      	movq	%r15, %rsi
  107c50:      	movl	$0x1, %edx
  107c55:      	callq	0x108c40 <shllvm_param>
  107c5a:      	movq	%rbx, %rdi
  107c5d:      	movq	%r12, %rsi
  107c60:      	movq	%r13, %rdx
  107c63:      	xorl	%ecx, %ecx
  107c65:      	callq	0x109140 <shllvm_env_store>
  107c6a:      	leaq	0x3ef(%rip), %r8        # 0x108060 <shllvm_f7>
  107c71:      	movq	-0x30(%rbp), %rdi
  107c75:      	movq	%rbx, %rsi
  107c78:      	movq	%r12, %rdx
  107c7b:      	movq	-0x38(%rbp), %rcx
  107c7f:      	movl	$0x7, %r9d
  107c85:      	callq	0x109180 <shllvm_closure>
  107c8a:      	movq	0x18(%r12), %r12
  107c8f:      	movq	%rbx, %rdi
  107c92:      	movq	%r14, %rsi
  107c95:      	movq	%r15, %rdx
  107c98:      	callq	0x108ba0 <shllvm_leave>
  107c9d:      	movq	%r12, %rax
  107ca0:      	leaq	-0x28(%rbp), %rsp
  107ca4:      	popq	%rbx
  107ca5:      	popq	%r12
  107ca7:      	popq	%r13
  107ca9:      	popq	%r14
  107cab:      	popq	%r15
  107cad:      	popq	%rbp
  107cae:      	retq
  107caf:      	nop

0000000000107cb0 <shllvm_f3>:
  107cb0:      	pushq	%rbp
  107cb1:      	movq	%rsp, %rbp
  107cb4:      	pushq	%r15
  107cb6:      	pushq	%r14
  107cb8:      	pushq	%r13
  107cba:      	pushq	%r12
  107cbc:      	pushq	%rbx
  107cbd:      	subq	$0x18, %rsp
  107cc1:      	movq	%rdi, %rbx
  107cc4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107cc9:      	movl	$0x5, %edi
  107cce:      	callq	0x108750 <shllvm_frame_size>
  107cd3:      	movq	%rsp, %r14
  107cd6:      	addq	$0xf, %rax
  107cda:      	andq	$-0x10, %rax
  107cde:      	subq	%rax, %r14
  107ce1:      	movq	%r14, %rsp
  107ce4:      	movl	0x9945b5(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  107ceb:      	movq	%rbx, %rdi
  107cee:      	movq	%r14, %rsi
  107cf1:      	movl	$0x5, %edx
  107cf6:      	xorl	%ecx, %ecx
  107cf8:      	movl	%r13d, %r8d
  107cfb:      	callq	0x1087e0 <shllvm_enter>
  107d00:      	movq	%rax, %r15
  107d03:      	movq	%rax, -0x38(%rbp)
  107d07:      	movq	%r14, %rdi
  107d0a:      	callq	0x108b90 <shllvm_roots>
  107d0f:      	movq	%rax, %r12
  107d12:      	movq	%rbx, %rdi
  107d15:      	movl	%r13d, %esi
  107d18:      	callq	0x108760 <shllvm_get_unit>
  107d1d:      	movq	%rax, -0x30(%rbp)
  107d21:      	leaq	0x8(%r12), %r13
  107d26:      	movq	%rbx, %rdi
  107d29:      	movq	%r15, %rsi
  107d2c:      	xorl	%edx, %edx
  107d2e:      	callq	0x10aab0 <shllvm_check_invocation>
  107d33:      	movq	%r12, %rdi
  107d36:      	movq	%rbx, %rsi
  107d39:      	xorl	%edx, %edx
  107d3b:      	movl	$0x1, %ecx
  107d40:      	callq	0x108ee0 <shllvm_env_create>
  107d45:      	leaq	0x444(%rip), %r8        # 0x108190 <shllvm_f8>
  107d4c:      	movq	%r13, %rdi
  107d4f:      	movq	%rbx, %rsi
  107d52:      	movq	%r12, %rdx
  107d55:      	movq	-0x30(%rbp), %rcx
  107d59:      	movl	$0x8, %r9d
  107d5f:      	callq	0x109180 <shllvm_closure>
  107d64:      	movq	%rbx, %rdi
  107d67:      	movq	%r12, %rsi
  107d6a:      	movq	%r13, %rdx
  107d6d:      	xorl	%ecx, %ecx
  107d6f:      	callq	0x109140 <shllvm_env_store>
  107d74:      	movq	0x8(%r12), %r15
  107d79:      	movq	%rbx, %rdi
  107d7c:      	movq	%r14, %rsi
  107d7f:      	movq	-0x38(%rbp), %rdx
  107d83:      	callq	0x108ba0 <shllvm_leave>
  107d88:      	movq	%r15, %rax
  107d8b:      	leaq	-0x28(%rbp), %rsp
  107d8f:      	popq	%rbx
  107d90:      	popq	%r12
  107d92:      	popq	%r13
  107d94:      	popq	%r14
  107d96:      	popq	%r15
  107d98:      	popq	%rbp
  107d99:      	retq
  107d9a:      	nopw	(%rax,%rax)

0000000000107da0 <shllvm_f4>:
  107da0:      	pushq	%rbp
  107da1:      	movq	%rsp, %rbp
  107da4:      	pushq	%r15
  107da6:      	pushq	%r14
  107da8:      	pushq	%r13
  107daa:      	pushq	%r12
  107dac:      	pushq	%rbx
  107dad:      	subq	$0x18, %rsp
  107db1:      	movq	%rdi, %rbx
  107db4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107db9:      	movl	$0x6, %edi
  107dbe:      	callq	0x108750 <shllvm_frame_size>
  107dc3:      	movq	%rsp, %r14
  107dc6:      	addq	$0xf, %rax
  107dca:      	andq	$-0x10, %rax
  107dce:      	subq	%rax, %r14
  107dd1:      	movq	%r14, %rsp
  107dd4:      	movl	0x9944c5(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  107ddb:      	movq	%rbx, %rdi
  107dde:      	movq	%r14, %rsi
  107de1:      	movl	$0x6, %edx
  107de6:      	xorl	%ecx, %ecx
  107de8:      	movl	%r13d, %r8d
  107deb:      	callq	0x1087e0 <shllvm_enter>
  107df0:      	movq	%rax, -0x30(%rbp)
  107df4:      	movq	%r14, %rdi
  107df7:      	callq	0x108b90 <shllvm_roots>
  107dfc:      	movq	%rax, %r12
  107dff:      	movq	%rbx, %rdi
  107e02:      	movl	%r13d, %esi
  107e05:      	callq	0x108760 <shllvm_get_unit>
  107e0a:      	leaq	0x8(%r12), %r15
  107e0f:      	leaq	0x10(%r12), %rax
  107e14:      	movq	%rax, -0x38(%rbp)
  107e18:      	movq	%rbx, %rdi
  107e1b:      	movq	-0x30(%rbp), %r13
  107e1f:      	movq	%r13, %rsi
  107e22:      	movl	$0x1, %edx
  107e27:      	callq	0x10aab0 <shllvm_check_invocation>
  107e2c:      	movq	%r12, %rdi
  107e2f:      	movq	%rbx, %rsi
  107e32:      	movq	%r13, %rdx
  107e35:      	callq	0x108fe0 <shllvm_env_from_frame>
  107e3a:      	movq	%r15, %rdi
  107e3d:      	movq	%r12, %rsi
  107e40:      	xorl	%edx, %edx
  107e42:      	callq	0x1090d0 <shllvm_env_load>
  107e47:      	movq	-0x38(%rbp), %r13
  107e4b:      	movq	%r13, %rdi
  107e4e:      	movq	%rbx, %rsi
  107e51:      	movl	$0x5, %edx
  107e56:      	movq	%r15, %rcx
  107e59:      	callq	0x109800 <shllvm_unary>
  107e5e:      	movq	%rbx, %rdi
  107e61:      	movq	%r12, %rsi
  107e64:      	movq	%r13, %rdx
  107e67:      	xorl	%ecx, %ecx
  107e69:      	callq	0x109140 <shllvm_env_store>
  107e6e:      	movq	0x10(%r12), %r15
  107e73:      	movq	%rbx, %rdi
  107e76:      	movq	%r14, %rsi
  107e79:      	movq	-0x30(%rbp), %rdx
  107e7d:      	callq	0x108ba0 <shllvm_leave>
  107e82:      	movq	%r15, %rax
  107e85:      	leaq	-0x28(%rbp), %rsp
  107e89:      	popq	%rbx
  107e8a:      	popq	%r12
  107e8c:      	popq	%r13
  107e8e:      	popq	%r14
  107e90:      	popq	%r15
  107e92:      	popq	%rbp
  107e93:      	retq
  107e94:      	nopw	%cs:(%rax,%rax)

0000000000107ea0 <shllvm_f5>:
  107ea0:      	pushq	%rbp
  107ea1:      	movq	%rsp, %rbp
  107ea4:      	pushq	%r15
  107ea6:      	pushq	%r14
  107ea8:      	pushq	%r13
  107eaa:      	pushq	%r12
  107eac:      	pushq	%rbx
  107ead:      	subq	$0x18, %rsp
  107eb1:      	movq	%rdi, %rbx
  107eb4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107eb9:      	movl	$0x6, %edi
  107ebe:      	callq	0x108750 <shllvm_frame_size>
  107ec3:      	movq	%rsp, %r14
  107ec6:      	addq	$0xf, %rax
  107eca:      	andq	$-0x10, %rax
  107ece:      	subq	%rax, %r14
  107ed1:      	movq	%r14, %rsp
  107ed4:      	movl	0x9943c5(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  107edb:      	movq	%rbx, %rdi
  107ede:      	movq	%r14, %rsi
  107ee1:      	movl	$0x6, %edx
  107ee6:      	xorl	%ecx, %ecx
  107ee8:      	movl	%r13d, %r8d
  107eeb:      	callq	0x1087e0 <shllvm_enter>
  107ef0:      	movq	%rax, -0x30(%rbp)
  107ef4:      	movq	%r14, %rdi
  107ef7:      	callq	0x108b90 <shllvm_roots>
  107efc:      	movq	%rax, %r12
  107eff:      	movq	%rbx, %rdi
  107f02:      	movl	%r13d, %esi
  107f05:      	callq	0x108760 <shllvm_get_unit>
  107f0a:      	leaq	0x8(%r12), %r15
  107f0f:      	leaq	0x10(%r12), %rax
  107f14:      	movq	%rax, -0x38(%rbp)
  107f18:      	movq	%rbx, %rdi
  107f1b:      	movq	-0x30(%rbp), %r13
  107f1f:      	movq	%r13, %rsi
  107f22:      	xorl	%edx, %edx
  107f24:      	callq	0x10aab0 <shllvm_check_invocation>
  107f29:      	movq	%r12, %rdi
  107f2c:      	movq	%rbx, %rsi
  107f2f:      	movq	%r13, %rdx
  107f32:      	callq	0x108fe0 <shllvm_env_from_frame>
  107f37:      	movq	%r15, %rdi
  107f3a:      	movq	%r12, %rsi
  107f3d:      	xorl	%edx, %edx
  107f3f:      	callq	0x1090d0 <shllvm_env_load>
  107f44:      	movq	-0x38(%rbp), %r13
  107f48:      	movq	%r13, %rdi
  107f4b:      	movq	%rbx, %rsi
  107f4e:      	movl	$0x6, %edx
  107f53:      	movq	%r15, %rcx
  107f56:      	callq	0x109800 <shllvm_unary>
  107f5b:      	movq	%rbx, %rdi
  107f5e:      	movq	%r12, %rsi
  107f61:      	movq	%r13, %rdx
  107f64:      	xorl	%ecx, %ecx
  107f66:      	callq	0x109140 <shllvm_env_store>
  107f6b:      	movq	0x10(%r12), %r15
  107f70:      	movq	%rbx, %rdi
  107f73:      	movq	%r14, %rsi
  107f76:      	movq	-0x30(%rbp), %rdx
  107f7a:      	callq	0x108ba0 <shllvm_leave>
  107f7f:      	movq	%r15, %rax
  107f82:      	leaq	-0x28(%rbp), %rsp
  107f86:      	popq	%rbx
  107f87:      	popq	%r12
  107f89:      	popq	%r13
  107f8b:      	popq	%r14
  107f8d:      	popq	%r15
  107f8f:      	popq	%rbp
  107f90:      	retq
  107f91:      	nopw	%cs:(%rax,%rax)

0000000000107fa0 <shllvm_f6>:
  107fa0:      	pushq	%rbp
  107fa1:      	movq	%rsp, %rbp
  107fa4:      	pushq	%r15
  107fa6:      	pushq	%r14
  107fa8:      	pushq	%r13
  107faa:      	pushq	%r12
  107fac:      	pushq	%rbx
  107fad:      	pushq	%rax
  107fae:      	movq	%rdi, %rbx
  107fb1:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107fb6:      	movl	$0x4, %edi
  107fbb:      	callq	0x108750 <shllvm_frame_size>
  107fc0:      	movq	%rsp, %r14
  107fc3:      	addq	$0xf, %rax
  107fc7:      	andq	$-0x10, %rax
  107fcb:      	subq	%rax, %r14
  107fce:      	movq	%r14, %rsp
  107fd1:      	movl	0x9942c8(%rip), %r12d   # 0xa9c2a0 <shllvm_unit_index>
  107fd8:      	movq	%rbx, %rdi
  107fdb:      	movq	%r14, %rsi
  107fde:      	movl	$0x4, %edx
  107fe3:      	xorl	%ecx, %ecx
  107fe5:      	movl	%r12d, %r8d
  107fe8:      	callq	0x1087e0 <shllvm_enter>
  107fed:      	movq	%rax, %r15
  107ff0:      	movq	%r14, %rdi
  107ff3:      	callq	0x108b90 <shllvm_roots>
  107ff8:      	movq	%rax, %r13
  107ffb:      	movq	%rbx, %rdi
  107ffe:      	movl	%r12d, %esi
  108001:      	callq	0x108760 <shllvm_get_unit>
  108006:      	leaq	0x8(%r13), %r12
  10800a:      	movq	%rbx, %rdi
  10800d:      	movq	%r15, %rsi
  108010:      	movl	$0x1, %edx
  108015:      	callq	0x10aab0 <shllvm_check_invocation>
  10801a:      	movq	%r13, %rdi
  10801d:      	movq	%rbx, %rsi
  108020:      	movq	%r15, %rdx
  108023:      	callq	0x108fe0 <shllvm_env_from_frame>
  108028:      	movq	%r12, %rdi
  10802b:      	movq	%r13, %rsi
  10802e:      	xorl	%edx, %edx
  108030:      	callq	0x1090d0 <shllvm_env_load>
  108035:      	movq	0x8(%r13), %r12
  108039:      	movq	%rbx, %rdi
  10803c:      	movq	%r14, %rsi
  10803f:      	movq	%r15, %rdx
  108042:      	callq	0x108ba0 <shllvm_leave>
  108047:      	movq	%r12, %rax
  10804a:      	leaq	-0x28(%rbp), %rsp
  10804e:      	popq	%rbx
  10804f:      	popq	%r12
  108051:      	popq	%r13
  108053:      	popq	%r14
  108055:      	popq	%r15
  108057:      	popq	%rbp
  108058:      	retq
  108059:      	nopl	(%rax)

0000000000108060 <shllvm_f7>:
  108060:      	pushq	%rbp
  108061:      	movq	%rsp, %rbp
  108064:      	pushq	%r15
  108066:      	pushq	%r14
  108068:      	pushq	%r13
  10806a:      	pushq	%r12
  10806c:      	pushq	%rbx
  10806d:      	subq	$0x28, %rsp
  108071:      	movq	%rdi, %rbx
  108074:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  108079:      	movl	$0x7, %edi
  10807e:      	callq	0x108750 <shllvm_frame_size>
  108083:      	movq	%rsp, %r14
  108086:      	addq	$0xf, %rax
  10808a:      	andq	$-0x10, %rax
  10808e:      	subq	%rax, %r14
  108091:      	movq	%r14, %rsp
  108094:      	movl	0x994205(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  10809b:      	movq	%rbx, %rdi
  10809e:      	movq	%r14, %rsi
  1080a1:      	movq	%r14, -0x40(%rbp)
  1080a5:      	movl	$0x7, %edx
  1080aa:      	xorl	%ecx, %ecx
  1080ac:      	movl	%r13d, %r8d
  1080af:      	callq	0x1087e0 <shllvm_enter>
  1080b4:      	movq	%rax, %r15
  1080b7:      	movq	%r14, %rdi
  1080ba:      	callq	0x108b90 <shllvm_roots>
  1080bf:      	movq	%rax, %r12
  1080c2:      	movq	%rbx, %rdi
  1080c5:      	movl	%r13d, %esi
  1080c8:      	callq	0x108760 <shllvm_get_unit>
  1080cd:      	movq	%rax, -0x50(%rbp)
  1080d1:      	leaq	0x8(%r12), %r14
  1080d6:      	leaq	0x10(%r12), %rax
  1080db:      	movq	%rax, -0x30(%rbp)
  1080df:      	leaq	0x20(%r12), %rax
  1080e4:      	movq	%rax, -0x48(%rbp)
  1080e8:      	movq	%rbx, %rdi
  1080eb:      	movq	%r15, %r13
  1080ee:      	movq	%r15, %rsi
  1080f1:      	movl	$0x1, %edx
  1080f6:      	callq	0x10aab0 <shllvm_check_invocation>
  1080fb:      	movq	%r12, %rdi
  1080fe:      	movq	%rbx, %rsi
  108101:      	movq	%r15, %rdx
  108104:      	movq	%r15, -0x38(%rbp)
  108108:      	callq	0x108fe0 <shllvm_env_from_frame>
  10810d:      	movq	%r14, %rdi
  108110:      	movq	%rbx, %rsi
  108113:      	movq	%r12, %rdx
  108116:      	movl	$0x1, %ecx
  10811b:      	callq	0x108ee0 <shllvm_env_create>
  108120:      	movq	-0x30(%rbp), %r15
  108124:      	movq	%r15, %rdi
  108127:      	movq	%r13, %rsi
  10812a:      	movl	$0x1, %edx
  10812f:      	callq	0x108c40 <shllvm_param>
  108134:      	movq	%rbx, %rdi
  108137:      	movq	%r14, %rsi
  10813a:      	movq	%r15, %rdx
  10813d:      	xorl	%ecx, %ecx
  10813f:      	callq	0x109140 <shllvm_env_store>
  108144:      	leaq	0x295(%rip), %r8        # 0x1083e0 <shllvm_f9>
  10814b:      	movq	-0x48(%rbp), %rdi
  10814f:      	movq	%rbx, %rsi
  108152:      	movq	%r14, %rdx
  108155:      	movq	-0x50(%rbp), %rcx
  108159:      	movl	$0x9, %r9d
  10815f:      	callq	0x109180 <shllvm_closure>
  108164:      	movq	0x20(%r12), %r12
  108169:      	movq	%rbx, %rdi
  10816c:      	movq	-0x40(%rbp), %rsi
  108170:      	movq	-0x38(%rbp), %rdx
  108174:      	callq	0x108ba0 <shllvm_leave>
  108179:      	movq	%r12, %rax
  10817c:      	leaq	-0x28(%rbp), %rsp
  108180:      	popq	%rbx
  108181:      	popq	%r12
  108183:      	popq	%r13
  108185:      	popq	%r14
  108187:      	popq	%r15
  108189:      	popq	%rbp
  10818a:      	retq
  10818b:      	nopl	(%rax,%rax)

0000000000108190 <shllvm_f8>:
  108190:      	pushq	%rbp
  108191:      	movq	%rsp, %rbp
  108194:      	pushq	%r15
  108196:      	pushq	%r14
  108198:      	pushq	%r13
  10819a:      	pushq	%r12
  10819c:      	pushq	%rbx
  10819d:      	subq	$0x48, %rsp
  1081a1:      	movq	%rdi, %rbx
  1081a4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  1081a9:      	movl	$0x13, %edi
  1081ae:      	callq	0x108750 <shllvm_frame_size>
  1081b3:      	movq	%rsp, %r14
  1081b6:      	addq	$0xf, %rax
  1081ba:      	andq	$-0x10, %rax
  1081be:      	subq	%rax, %r14
  1081c1:      	movq	%r14, %rsp
  1081c4:      	movl	0x9940d5(%rip), %r15d   # 0xa9c2a0 <shllvm_unit_index>
  1081cb:      	movq	%rbx, %rdi
  1081ce:      	movq	%r14, %rsi
  1081d1:      	movl	$0x13, %edx
  1081d6:      	movl	$0x1, %ecx
  1081db:      	movl	%r15d, %r8d
  1081de:      	callq	0x1087e0 <shllvm_enter>
  1081e3:      	movq	%rax, %r13
  1081e6:      	movq	%r14, -0x60(%rbp)
  1081ea:      	movq	%r14, %rdi
  1081ed:      	callq	0x108b90 <shllvm_roots>
  1081f2:      	movq	%rax, %r12
  1081f5:      	movq	%rbx, %rdi
  1081f8:      	movl	%r15d, %esi
  1081fb:      	callq	0x108760 <shllvm_get_unit>
  108200:      	leaq	0x8(%r12), %rax
  108205:      	movq	%rax, -0x48(%rbp)
  108209:      	leaq	0x10(%r12), %rax
  10820e:      	movq	%rax, -0x40(%rbp)
  108212:      	leaq	0x70(%r12), %r15
  108217:      	leaq	0x78(%r12), %r14
  10821c:      	leaq	0x80(%r12), %rax
  108224:      	movq	%rax, -0x30(%rbp)
  108228:      	leaq	0x88(%r12), %rax
  108230:      	movq	%rax, -0x38(%rbp)
  108234:      	movq	%rbx, %rdi
  108237:      	movq	%r13, %rsi
  10823a:      	movl	$0x1, %edx
  10823f:      	callq	0x10aab0 <shllvm_check_invocation>
  108244:      	movq	%r15, %rdi
  108247:      	movq	%r13, %r15
  10824a:      	movl	$0x3, %esi
  10824f:      	xorl	%edx, %edx
  108251:      	callq	0x108620 <shllvm_constant>
  108256:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  108260:      	movq	%r14, %rdi
  108263:      	movq	-0x48(%rbp), %r14
  108267:      	movl	$0x3, %esi
  10826c:      	callq	0x108620 <shllvm_constant>
  108271:      	movq	-0x30(%rbp), %rdi
  108275:      	xorl	%esi, %esi
  108277:      	xorl	%edx, %edx
  108279:      	callq	0x108620 <shllvm_constant>
  10827e:      	movl	$0x1, %edx
  108283:      	movq	-0x38(%rbp), %rdi
  108287:      	movl	$0x2, %esi
  10828c:      	callq	0x108620 <shllvm_constant>
  108291:      	movq	%r12, %rdi
  108294:      	movq	%r13, %rsi
  108297:      	movl	$0x1, %edx
  10829c:      	callq	0x108c40 <shllvm_param>
  1082a1:      	movq	0x70(%r12), %rax
  1082a6:      	movq	%rax, 0x8(%r12)
  1082ab:      	movq	-0x40(%rbp), %r13
  1082af:      	movq	%r13, %rdi
  1082b2:      	movq	%rbx, %rsi
  1082b5:      	movl	$0x7, %edx
  1082ba:      	movq	%r12, %rcx
  1082bd:      	movq	%r14, %r8
  1082c0:      	callq	0x109580 <shllvm_binary>
  1082c5:      	movq	%r13, %rdi
  1082c8:      	callq	0x109a80 <shllvm_truthy>
  1082cd:      	testl	%eax, %eax
  1082cf:      	jne	0x1083b0 <shllvm_f8+0x220>
  1082d5:      	leaq	0x50(%r12), %rax
  1082da:      	movq	%rax, -0x48(%rbp)
  1082de:      	leaq	0x48(%r12), %rax
  1082e3:      	movq	%rax, -0x38(%rbp)
  1082e7:      	leaq	0x40(%r12), %rax
  1082ec:      	movq	%rax, -0x40(%rbp)
  1082f0:      	movq	%rbx, %r13
  1082f3:      	leaq	0x38(%r12), %rax
  1082f8:      	movq	%rax, -0x50(%rbp)
  1082fc:      	leaq	0x30(%r12), %rax
  108301:      	movq	%rax, -0x58(%rbp)
  108305:      	leaq	0x28(%r12), %rbx
  10830a:      	movq	%rbx, -0x30(%rbp)
  10830e:      	movq	%r15, %r14
  108311:      	movq	%r12, %r15
  108314:      	addq	$0x20, %r15
  108318:      	movq	%r15, %rdi
  10831b:      	movq	%r13, %rsi
  10831e:      	movq	%r14, %rdx
  108321:      	callq	0x108fe0 <shllvm_env_from_frame>
  108326:      	movq	%rbx, %rdi
  108329:      	movq	%r15, %rsi
  10832c:      	movq	%r14, %r15
  10832f:      	movq	-0x48(%rbp), %r14
  108333:      	xorl	%edx, %edx
  108335:      	callq	0x1090d0 <shllvm_env_load>
  10833a:      	movq	0x78(%r12), %rax
  10833f:      	movq	%rax, 0x30(%r12)
  108344:      	movq	-0x50(%rbp), %rdi
  108348:      	movq	%r13, %rbx
  10834b:      	movq	%r13, %rsi
  10834e:      	movl	$0x1, %edx
  108353:      	movq	%r12, %rcx
  108356:      	movq	-0x58(%rbp), %r8
  10835a:      	callq	0x109580 <shllvm_binary>
  10835f:      	movq	0x38(%r12), %rax
  108364:      	movq	0x80(%r12), %rcx
  10836c:      	movq	%rcx, 0x40(%r12)
  108371:      	movq	%rax, -0x68(%rbp)
  108375:      	leaq	-0x68(%rbp), %rax
  108379:      	movq	-0x38(%rbp), %r13
  10837d:      	movq	%r13, %rdi
  108380:      	movq	%rbx, %rsi
  108383:      	movq	%r15, %rdx
  108386:      	movq	-0x30(%rbp), %rcx
  10838a:      	movq	-0x40(%rbp), %r8
  10838e:      	movq	%r8, %r9
  108391:      	pushq	%rax
  108392:      	pushq	$0x1
  108394:      	callq	0x1092b0 <shllvm_call>
  108399:      	addq	$0x10, %rsp
  10839d:      	movq	%r14, %rdi
  1083a0:      	movq	%rbx, %rsi
  1083a3:      	xorl	%edx, %edx
  1083a5:      	movq	%r12, %rcx
  1083a8:      	movq	%r13, %r8
  1083ab:      	callq	0x109580 <shllvm_binary>
  1083b0:      	movq	(%r14), %r14
  1083b3:      	movq	%r14, 0x60(%r12)
  1083b8:      	movq	%rbx, %rdi
  1083bb:      	movq	-0x60(%rbp), %rsi
  1083bf:      	movq	%r15, %rdx
  1083c2:      	callq	0x108ba0 <shllvm_leave>
  1083c7:      	movq	%r14, %rax
  1083ca:      	leaq	-0x28(%rbp), %rsp
  1083ce:      	popq	%rbx
  1083cf:      	popq	%r12
  1083d1:      	popq	%r13
  1083d3:      	popq	%r14
  1083d5:      	popq	%r15
  1083d7:      	popq	%rbp
  1083d8:      	retq
  1083d9:      	nopl	(%rax)

00000000001083e0 <shllvm_f9>:
  1083e0:      	pushq	%rbp
  1083e1:      	movq	%rsp, %rbp
  1083e4:      	pushq	%r15
  1083e6:      	pushq	%r14
  1083e8:      	pushq	%r13
  1083ea:      	pushq	%r12
  1083ec:      	pushq	%rbx
  1083ed:      	subq	$0x38, %rsp
  1083f1:      	movq	%rdi, %rbx
  1083f4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  1083f9:      	movl	$0xa, %edi
  1083fe:      	callq	0x108750 <shllvm_frame_size>
  108403:      	movq	%rsp, %r14
  108406:      	addq	$0xf, %rax
  10840a:      	andq	$-0x10, %rax
  10840e:      	subq	%rax, %r14
  108411:      	movq	%r14, %rsp
  108414:      	movl	0x993e85(%rip), %r13d   # 0xa9c2a0 <shllvm_unit_index>
  10841b:      	movq	%rbx, %rdi
  10841e:      	movq	%r14, %rsi
  108421:      	movq	%r14, -0x50(%rbp)
  108425:      	movl	$0xa, %edx
  10842a:      	xorl	%ecx, %ecx
  10842c:      	movl	%r13d, %r8d
  10842f:      	callq	0x1087e0 <shllvm_enter>
  108434:      	movq	%rax, -0x30(%rbp)
  108438:      	movq	%r14, %rdi
  10843b:      	callq	0x108b90 <shllvm_roots>
  108440:      	movq	%rax, %r12
  108443:      	movq	%rbx, %rdi
  108446:      	movl	%r13d, %esi
  108449:      	callq	0x108760 <shllvm_get_unit>
  10844e:      	leaq	0x8(%r12), %r14
  108453:      	leaq	0x10(%r12), %rax
  108458:      	movq	%rax, -0x38(%rbp)
  10845c:      	leaq	0x18(%r12), %rax
  108461:      	movq	%rax, -0x40(%rbp)
  108465:      	leaq	0x20(%r12), %rax
  10846a:      	movq	%rax, -0x48(%rbp)
  10846e:      	leaq	0x28(%r12), %rax
  108473:      	movq	%rax, -0x58(%rbp)
  108477:      	leaq	0x30(%r12), %rax
  10847c:      	movq	%rax, -0x60(%rbp)
  108480:      	leaq	0x40(%r12), %r15
  108485:      	movq	%rbx, %rdi
  108488:      	movq	-0x30(%rbp), %r13
  10848c:      	movq	%r13, %rsi
  10848f:      	movl	$0x1, %edx
  108494:      	callq	0x10aab0 <shllvm_check_invocation>
  108499:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  1084a3:      	movq	%r15, %rdi
  1084a6:      	movl	$0x3, %esi
  1084ab:      	callq	0x108620 <shllvm_constant>
  1084b0:      	movq	%r12, %rdi
  1084b3:      	movq	%rbx, %rsi
  1084b6:      	movq	%r13, %rdx
  1084b9:      	callq	0x108fe0 <shllvm_env_from_frame>
  1084be:      	movq	%r14, %rdi
  1084c1:      	movq	%rbx, %rsi
  1084c4:      	movq	%r12, %rdx
  1084c7:      	movl	$0x1, %ecx
  1084cc:      	callq	0x109070 <shllvm_env_resolve>
  1084d1:      	movq	-0x38(%rbp), %r13
  1084d5:      	movq	%r13, %rdi
  1084d8:      	movq	%r14, %rsi
  1084db:      	xorl	%edx, %edx
  1084dd:      	callq	0x1090d0 <shllvm_env_load>
  1084e2:      	movq	-0x40(%rbp), %r14
  1084e6:      	movq	%r14, %rdi
  1084e9:      	movq	%r12, %rsi
  1084ec:      	xorl	%edx, %edx
  1084ee:      	callq	0x1090d0 <shllvm_env_load>
  1084f3:      	movq	-0x48(%rbp), %r15
  1084f7:      	movq	%r15, %rdi
  1084fa:      	movq	%rbx, %rsi
  1084fd:      	xorl	%edx, %edx
  1084ff:      	movq	%r13, %rcx
  108502:      	movq	%r14, %r8
  108505:      	callq	0x109580 <shllvm_binary>
  10850a:      	movq	-0x58(%rbp), %r13
  10850e:      	movq	%r13, %rdi
  108511:      	movq	-0x30(%rbp), %r14
  108515:      	movq	%r14, %rsi
  108518:      	movl	$0x1, %edx
  10851d:      	callq	0x108c40 <shllvm_param>
  108522:      	movq	-0x60(%rbp), %rdi
  108526:      	movq	%rbx, %rsi
  108529:      	xorl	%edx, %edx
  10852b:      	movq	%r15, %rcx
  10852e:      	movq	%r13, %r8
  108531:      	callq	0x109580 <shllvm_binary>
  108536:      	movq	0x30(%r12), %r15
  10853b:      	movq	%rbx, %rdi
  10853e:      	movq	-0x50(%rbp), %rsi
  108542:      	movq	%r14, %rdx
  108545:      	callq	0x108ba0 <shllvm_leave>
  10854a:      	movq	%r15, %rax
  10854d:      	leaq	-0x28(%rbp), %rsp
  108551:      	popq	%rbx
  108552:      	popq	%r12
  108554:      	popq	%r13
  108556:      	popq	%r14
  108558:      	popq	%r15
  10855a:      	popq	%rbp
  10855b:      	retq
  10855c:      	nopl	(%rax)

0000000000108560 <sh_export_this_unit>:
  108560:      	pushq	%rax
  108561:      	subq	$0x8, %rsp
  108565:      	leaq	0x16874(%rip), %rax     # 0x11ede0 <shllvm_unit_name>
  10856c:      	leaq	-0x18e3(%rip), %r10     # 0x106c90 <shllvm_f0>
  108573:      	leaq	0x16886(%rip), %r11     # 0x11ee00 <shllvm_functions>
  10857a:      	leaq	0x993d1f(%rip), %rdi    # 0xa9c2a0 <shllvm_unit_index>
  108581:      	leaq	0x16738(%rip), %rdx     # 0x11ecc0 <shllvm_ascii>
  108588:      	leaq	0x16791(%rip), %rcx     # 0x11ed20 <shllvm_utf16>
  10858f:      	leaq	0x167aa(%rip), %r8      # 0x11ed40 <shllvm_strings>
  108596:      	movl	$0xa, %esi
  10859b:      	movl	$0xa, %r9d
  1085a1:      	pushq	%rax
  1085a2:      	pushq	%r10
  1085a4:      	pushq	%r11
  1085a6:      	callq	0x10a1e0 <shllvm_create_unit>
  1085ab:      	addq	$0x20, %rsp
  1085af:      	popq	%rcx
  1085b0:      	retq
  1085b1:      	nopw	%cs:(%rax,%rax)

0000000000108750 <shllvm_frame_size>:
  108750:      	pushq	%rbp
  108751:      	movq	%rsp, %rbp
  108754:      	movl	%edi, %eax
  108756:      	leaq	0x20(,%rax,8), %rax
  10875e:      	popq	%rbp
  10875f:      	retq

