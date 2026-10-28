0000000000106c90 <shllvm_f0>:
  106c90:      	pushq	%rbp
  106c91:      	movq	%rsp, %rbp
  106c94:      	pushq	%r15
  106c96:      	pushq	%r14
  106c98:      	pushq	%r13
  106c9a:      	pushq	%r12
  106c9c:      	pushq	%rbx
  106c9d:      	subq	$0x148, %rsp            # imm = 0x148
  106ca4:      	movq	%rdi, %rbx
  106ca7:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  106cac:      	movl	$0x35, %edi
  106cb1:      	callq	0x108270 <shllvm_frame_size>
  106cb6:      	movq	%rsp, %r15
  106cb9:      	addq	$0xf, %rax
  106cbd:      	andq	$-0x10, %rax
  106cc1:      	subq	%rax, %r15
  106cc4:      	movq	%r15, %rsp
  106cc7:      	movl	0x9945d2(%rip), %r14d   # 0xa9b2a0 <shllvm_unit_index>
  106cce:      	movq	%rbx, %rdi
  106cd1:      	movq	%r15, %rsi
  106cd4:      	movq	%r15, -0x170(%rbp)
  106cdb:      	movl	$0x35, %edx
  106ce0:      	movl	$0x5, %ecx
  106ce5:      	movl	%r14d, %r8d
  106ce8:      	callq	0x108300 <shllvm_enter>
  106ced:      	movq	%rax, -0x40(%rbp)
  106cf1:      	movq	%r15, %rdi
  106cf4:      	callq	0x1086b0 <shllvm_roots>
  106cf9:      	movq	%rax, %r12
  106cfc:      	movq	%rbx, %rdi
  106cff:      	movl	%r14d, %esi
  106d02:      	callq	0x108280 <shllvm_get_unit>
  106d07:      	movq	%rax, %r14
  106d0a:      	leaq	0x28(%r12), %rax
  106d0f:      	movq	%rax, -0x38(%rbp)
  106d13:      	leaq	0x30(%r12), %rax
  106d18:      	movq	%rax, -0xe8(%rbp)
  106d1f:      	leaq	0x40(%r12), %rax
  106d24:      	movq	%rax, -0xf0(%rbp)
  106d2b:      	leaq	0x50(%r12), %rax
  106d30:      	movq	%rax, -0xf8(%rbp)
  106d37:      	leaq	0x60(%r12), %rax
  106d3c:      	movq	%rax, -0x100(%rbp)
  106d43:      	leaq	0x70(%r12), %rax
  106d48:      	movq	%rax, -0x108(%rbp)
  106d4f:      	leaq	0x80(%r12), %rax
  106d57:      	movq	%rax, -0x78(%rbp)
  106d5b:      	leaq	0x88(%r12), %rax
  106d63:      	movq	%rax, -0x110(%rbp)
  106d6a:      	leaq	0x98(%r12), %rax
  106d72:      	movq	%rax, -0x30(%rbp)
  106d76:      	leaq	0xa0(%r12), %rax
  106d7e:      	movq	%rax, -0x118(%rbp)
  106d85:      	leaq	0xa8(%r12), %rax
  106d8d:      	movq	%rax, -0x120(%rbp)
  106d94:      	leaq	0xb8(%r12), %rax
  106d9c:      	movq	%rax, -0x128(%rbp)
  106da3:      	leaq	0xc0(%r12), %rax
  106dab:      	movq	%rax, -0x130(%rbp)
  106db2:      	leaq	0xd0(%r12), %rax
  106dba:      	movq	%rax, -0x138(%rbp)
  106dc1:      	leaq	0xd8(%r12), %rax
  106dc9:      	movq	%rax, -0x70(%rbp)
  106dcd:      	leaq	0xe8(%r12), %rax
  106dd5:      	movq	%rax, -0x140(%rbp)
  106ddc:      	leaq	0xf0(%r12), %rax
  106de4:      	movq	%rax, -0x148(%rbp)
  106deb:      	leaq	0xf8(%r12), %rax
  106df3:      	movq	%rax, -0x150(%rbp)
  106dfa:      	leaq	0x108(%r12), %rax
  106e02:      	movq	%rax, -0x158(%rbp)
  106e09:      	leaq	0x118(%r12), %rax
  106e11:      	movq	%rax, -0x160(%rbp)
  106e18:      	leaq	0x120(%r12), %rax
  106e20:      	movq	%rax, -0x168(%rbp)
  106e27:      	leaq	0x130(%r12), %r13
  106e2f:      	leaq	0x138(%r12), %r15
  106e37:      	leaq	0x140(%r12), %rax
  106e3f:      	movq	%rax, -0x88(%rbp)
  106e46:      	leaq	0x148(%r12), %rax
  106e4e:      	movq	%rax, -0x90(%rbp)
  106e55:      	leaq	0x150(%r12), %rax
  106e5d:      	movq	%rax, -0x98(%rbp)
  106e64:      	leaq	0x158(%r12), %rax
  106e6c:      	movq	%rax, -0xa0(%rbp)
  106e73:      	leaq	0x160(%r12), %rax
  106e7b:      	movq	%rax, -0xa8(%rbp)
  106e82:      	leaq	0x168(%r12), %rax
  106e8a:      	movq	%rax, -0xb0(%rbp)
  106e91:      	leaq	0x170(%r12), %rax
  106e99:      	movq	%rax, -0xb8(%rbp)
  106ea0:      	leaq	0x178(%r12), %rax
  106ea8:      	movq	%rax, -0xc0(%rbp)
  106eaf:      	leaq	0x180(%r12), %rax
  106eb7:      	movq	%rax, -0xc8(%rbp)
  106ebe:      	leaq	0x188(%r12), %rax
  106ec6:      	movq	%rax, -0xd0(%rbp)
  106ecd:      	leaq	0x190(%r12), %rax
  106ed5:      	movq	%rax, -0xd8(%rbp)
  106edc:      	leaq	0x198(%r12), %rax
  106ee4:      	movq	%rax, -0xe0(%rbp)
  106eeb:      	movq	%rbx, %rdi
  106eee:      	movq	-0x40(%rbp), %rsi
  106ef2:      	xorl	%edx, %edx
  106ef4:      	callq	0x10a5d0 <shllvm_check_invocation>
  106ef9:      	movq	%r13, %rdi
  106efc:      	movq	%rbx, %rsi
  106eff:      	movq	%r14, %rdx
  106f02:      	movl	$0x1, %ecx
  106f07:      	callq	0x108820 <shllvm_symbol>
  106f0c:      	movq	%r15, %rdi
  106f0f:      	movq	%rbx, %rsi
  106f12:      	movq	%r14, %rdx
  106f15:      	movl	$0x2, %ecx
  106f1a:      	callq	0x108820 <shllvm_symbol>
  106f1f:      	movq	-0x88(%rbp), %rdi
  106f26:      	movq	%rbx, %rsi
  106f29:      	movq	%r14, %rdx
  106f2c:      	movl	$0x3, %ecx
  106f31:      	callq	0x108820 <shllvm_symbol>
  106f36:      	movq	-0x90(%rbp), %rdi
  106f3d:      	movq	%rbx, %rsi
  106f40:      	movq	%r14, %rdx
  106f43:      	movl	$0x4, %ecx
  106f48:      	callq	0x108820 <shllvm_symbol>
  106f4d:      	movq	-0x98(%rbp), %rdi
  106f54:      	movq	%rbx, %rsi
  106f57:      	movq	%r14, %rdx
  106f5a:      	movl	$0x5, %ecx
  106f5f:      	callq	0x108820 <shllvm_symbol>
  106f64:      	movq	-0xa0(%rbp), %rdi
  106f6b:      	movq	%rbx, %rsi
  106f6e:      	movq	%r14, %rdx
  106f71:      	movl	$0x8, %ecx
  106f76:      	callq	0x108820 <shllvm_symbol>
  106f7b:      	movabsq	$0x4020000000000000, %rdx # imm = 0x4020000000000000
  106f85:      	movq	-0xa8(%rbp), %rdi
  106f8c:      	movl	$0x3, %esi
  106f91:      	callq	0x108140 <shllvm_constant>
  106f96:      	movq	-0xb0(%rbp), %rdi
  106f9d:      	xorl	%esi, %esi
  106f9f:      	xorl	%edx, %edx
  106fa1:      	callq	0x108140 <shllvm_constant>
  106fa6:      	movq	-0xb8(%rbp), %rdi
  106fad:      	movl	$0x2, %esi
  106fb2:      	xorl	%edx, %edx
  106fb4:      	callq	0x108140 <shllvm_constant>
  106fb9:      	movabsq	$0x4028000000000000, %rdx # imm = 0x4028000000000000
  106fc3:      	movq	-0xc0(%rbp), %rdi
  106fca:      	movl	$0x3, %esi
  106fcf:      	callq	0x108140 <shllvm_constant>
  106fd4:      	movabsq	$0x402a000000000000, %rdx # imm = 0x402A000000000000
  106fde:      	movq	-0xc8(%rbp), %rdi
  106fe5:      	movl	$0x3, %esi
  106fea:      	callq	0x108140 <shllvm_constant>
  106fef:      	movabsq	$0x4035000000000000, %rdx # imm = 0x4035000000000000
  106ff9:      	movq	-0xd0(%rbp), %rdi
  107000:      	movl	$0x3, %esi
  107005:      	callq	0x108140 <shllvm_constant>
  10700a:      	movabsq	$0x4033000000000000, %rdx # imm = 0x4033000000000000
  107014:      	movq	-0xd8(%rbp), %rdi
  10701b:      	movl	$0x3, %esi
  107020:      	callq	0x108140 <shllvm_constant>
  107025:      	movabsq	$0x4037000000000000, %rdx # imm = 0x4037000000000000
  10702f:      	movq	-0xe0(%rbp), %rdi
  107036:      	movl	$0x3, %esi
  10703b:      	callq	0x108140 <shllvm_constant>
  107040:      	movq	%rbx, %rdi
  107043:      	movq	%r14, %rsi
  107046:      	movl	$0x1, %edx
  10704b:      	callq	0x108920 <shllvm_declare_global>
  107050:      	movq	%rbx, %rdi
  107053:      	movq	%r14, %rsi
  107056:      	movl	$0x2, %edx
  10705b:      	callq	0x108920 <shllvm_declare_global>
  107060:      	movq	%rbx, %rdi
  107063:      	movq	%r14, %rsi
  107066:      	movl	$0x3, %edx
  10706b:      	callq	0x108920 <shllvm_declare_global>
  107070:      	movq	%rbx, %rdi
  107073:      	movq	%r14, %rsi
  107076:      	movl	$0x4, %edx
  10707b:      	callq	0x108920 <shllvm_declare_global>
  107080:      	movq	%rbx, %rdi
  107083:      	movq	%r14, %rsi
  107086:      	movl	$0x5, %edx
  10708b:      	callq	0x108920 <shllvm_declare_global>
  107090:      	movq	-0x38(%rbp), %r15
  107094:      	movq	%r15, %rdi
  107097:      	movq	%rbx, %rsi
  10709a:      	callq	0x1087e0 <shllvm_global>
  10709f:      	leaq	0x46a(%rip), %r8        # 0x107510 <shllvm_f1>
  1070a6:      	movq	-0xe8(%rbp), %r13
  1070ad:      	movq	%r13, %rdi
  1070b0:      	movq	%rbx, %rsi
  1070b3:      	xorl	%edx, %edx
  1070b5:      	movq	%r14, %rcx
  1070b8:      	movl	$0x1, %r9d
  1070be:      	callq	0x108ca0 <shllvm_closure>
  1070c3:      	subq	$0x8, %rsp
  1070c7:      	movq	%rbx, %rdi
  1070ca:      	movq	%r14, %rsi
  1070cd:      	movq	%r15, %rdx
  1070d0:      	movl	$0x1, %ecx
  1070d5:      	movq	%r13, %r8
  1070d8:      	xorl	%r9d, %r9d
  1070db:      	pushq	$0x0
  1070dd:      	callq	0x109870 <shllvm_set_id>
  1070e2:      	addq	$0x10, %rsp
  1070e6:      	leaq	0x663(%rip), %r8        # 0x107750 <shllvm_f2>
  1070ed:      	movq	-0xf0(%rbp), %r15
  1070f4:      	movq	%r15, %rdi
  1070f7:      	movq	%rbx, %rsi
  1070fa:      	xorl	%edx, %edx
  1070fc:      	movq	%r14, %rcx
  1070ff:      	movl	$0x2, %r9d
  107105:      	callq	0x108ca0 <shllvm_closure>
  10710a:      	subq	$0x8, %rsp
  10710e:      	movq	%rbx, %rdi
  107111:      	movq	%r14, %rsi
  107114:      	movq	-0x38(%rbp), %r13
  107118:      	movq	%r13, %rdx
  10711b:      	movl	$0x2, %ecx
  107120:      	movq	%r15, %r8
  107123:      	xorl	%r9d, %r9d
  107126:      	pushq	$0x0
  107128:      	callq	0x109870 <shllvm_set_id>
  10712d:      	addq	$0x10, %rsp
  107131:      	leaq	0x898(%rip), %r8        # 0x1079d0 <shllvm_f3>
  107138:      	movq	-0xf8(%rbp), %r15
  10713f:      	movq	%r15, %rdi
  107142:      	movq	%rbx, %rsi
  107145:      	xorl	%edx, %edx
  107147:      	movq	%r14, %rcx
  10714a:      	movl	$0x3, %r9d
  107150:      	callq	0x108ca0 <shllvm_closure>
  107155:      	subq	$0x8, %rsp
  107159:      	movq	%rbx, %rdi
  10715c:      	movq	%r14, %rsi
  10715f:      	movq	%r13, %rdx
  107162:      	movl	$0x3, %ecx
  107167:      	movq	%r15, %r8
  10716a:      	xorl	%r9d, %r9d
  10716d:      	pushq	$0x0
  10716f:      	callq	0x109870 <shllvm_set_id>
  107174:      	addq	$0x10, %rsp
  107178:      	leaq	0xab1(%rip), %r8        # 0x107c30 <shllvm_f4>
  10717f:      	movq	-0x100(%rbp), %r15
  107186:      	movq	%r15, %rdi
  107189:      	movq	%rbx, %rsi
  10718c:      	xorl	%edx, %edx
  10718e:      	movq	%r14, %rcx
  107191:      	movl	$0x4, %r9d
  107197:      	callq	0x108ca0 <shllvm_closure>
  10719c:      	subq	$0x8, %rsp
  1071a0:      	movq	%rbx, %rdi
  1071a3:      	movq	%r14, %rsi
  1071a6:      	movq	%r13, %rdx
  1071a9:      	movl	$0x4, %ecx
  1071ae:      	movq	%r15, %r8
  1071b1:      	xorl	%r9d, %r9d
  1071b4:      	pushq	$0x0
  1071b6:      	callq	0x109870 <shllvm_set_id>
  1071bb:      	addq	$0x10, %rsp
  1071bf:      	leaq	0xbaa(%rip), %r8        # 0x107d70 <shllvm_f5>
  1071c6:      	movq	-0x108(%rbp), %r15
  1071cd:      	movq	%r15, %rdi
  1071d0:      	movq	%rbx, %rsi
  1071d3:      	xorl	%edx, %edx
  1071d5:      	movq	%r14, %rcx
  1071d8:      	movl	$0x5, %r9d
  1071de:      	callq	0x108ca0 <shllvm_closure>
  1071e3:      	subq	$0x8, %rsp
  1071e7:      	movq	%rbx, %rdi
  1071ea:      	movq	%r14, %rsi
  1071ed:      	movq	%r13, %rdx
  1071f0:      	movl	$0x5, %ecx
  1071f5:      	movq	%r15, %r8
  1071f8:      	xorl	%r9d, %r9d
  1071fb:      	pushq	$0x0
  1071fd:      	callq	0x109870 <shllvm_set_id>
  107202:      	addq	$0x10, %rsp
  107206:      	movq	-0x78(%rbp), %rdi
  10720a:      	movq	%rbx, %rsi
  10720d:      	movq	%r14, %rdx
  107210:      	movq	%r13, %rcx
  107213:      	movl	$0x8, %r8d
  107219:      	movl	$0x1, %r9d
  10721f:      	callq	0x109700 <shllvm_get_id>
  107224:      	movq	-0x110(%rbp), %r15
  10722b:      	movq	%r15, %rdi
  10722e:      	movq	%rbx, %rsi
  107231:      	movq	%r14, %rdx
  107234:      	movq	%r13, %rcx
  107237:      	movl	$0x1, %r8d
  10723d:      	xorl	%r9d, %r9d
  107240:      	callq	0x109700 <shllvm_get_id>
  107245:      	movups	0x160(%r12), %xmm0
  10724e:      	movups	%xmm0, 0x90(%r12)
  107257:      	movlps	%xmm0, -0x68(%rbp)
  10725b:      	leaq	-0x68(%rbp), %rax
  10725f:      	movq	-0x118(%rbp), %rdi
  107266:      	movq	%rbx, %rsi
  107269:      	movq	-0x40(%rbp), %r13
  10726d:      	movq	%r13, %rdx
  107270:      	movq	%r15, %rcx
  107273:      	movq	-0x30(%rbp), %r8
  107277:      	movq	%r8, %r9
  10727a:      	pushq	%rax
  10727b:      	pushq	$0x1
  10727d:      	callq	0x108dd0 <shllvm_call>
  107282:      	addq	$0x10, %rsp
  107286:      	movq	-0x120(%rbp), %r15
  10728d:      	movq	%r15, %rdi
  107290:      	movq	%rbx, %rsi
  107293:      	movq	%r14, %rdx
  107296:      	movq	%r14, -0x80(%rbp)
  10729a:      	movq	-0x38(%rbp), %rcx
  10729e:      	movl	$0x2, %r8d
  1072a4:      	xorl	%r9d, %r9d
  1072a7:      	callq	0x109700 <shllvm_get_id>
  1072ac:      	movq	0x178(%r12), %rax
  1072b4:      	movq	%rax, 0xb0(%r12)
  1072bc:      	movq	%rax, -0x68(%rbp)
  1072c0:      	movq	-0x128(%rbp), %rdi
  1072c7:      	movq	%rbx, %rsi
  1072ca:      	movq	%r13, %rdx
  1072cd:      	movq	%r15, %rcx
  1072d0:      	movq	-0x30(%rbp), %r8
  1072d4:      	movq	%r8, %r9
  1072d7:      	leaq	-0x68(%rbp), %rax
  1072db:      	pushq	%rax
  1072dc:      	pushq	$0x1
  1072de:      	callq	0x108dd0 <shllvm_call>
  1072e3:      	addq	$0x10, %rsp
  1072e7:      	movq	-0x130(%rbp), %r13
  1072ee:      	movq	%r13, %rdi
  1072f1:      	movq	%rbx, %rsi
  1072f4:      	movq	%r14, %rdx
  1072f7:      	movq	-0x38(%rbp), %r15
  1072fb:      	movq	%r15, %rcx
  1072fe:      	movl	$0x3, %r8d
  107304:      	xorl	%r9d, %r9d
  107307:      	callq	0x109700 <shllvm_get_id>
  10730c:      	movq	0x180(%r12), %rax
  107314:      	movq	%rax, 0xc8(%r12)
  10731c:      	movq	%rax, -0x68(%rbp)
  107320:      	movq	-0x138(%rbp), %rdi
  107327:      	movq	%rbx, %rsi
  10732a:      	movq	-0x40(%rbp), %r14
  10732e:      	movq	%r14, %rdx
  107331:      	movq	%r13, %rcx
  107334:      	movq	-0x30(%rbp), %r8
  107338:      	movq	%r8, %r9
  10733b:      	leaq	-0x68(%rbp), %rax
  10733f:      	pushq	%rax
  107340:      	pushq	$0x1
  107342:      	callq	0x108dd0 <shllvm_call>
  107347:      	addq	$0x10, %rsp
  10734b:      	movq	-0x70(%rbp), %rdi
  10734f:      	movq	%rbx, %rsi
  107352:      	movq	-0x80(%rbp), %r13
  107356:      	movq	%r13, %rdx
  107359:      	movq	%r15, %rcx
  10735c:      	movl	$0x4, %r8d
  107362:      	xorl	%r9d, %r9d
  107365:      	callq	0x109700 <shllvm_get_id>
  10736a:      	movq	0x188(%r12), %rax
  107372:      	movq	%rax, 0xe0(%r12)
  10737a:      	leaq	0xaef(%rip), %r8        # 0x107e70 <shllvm_f6>
  107381:      	movq	-0x140(%rbp), %rdi
  107388:      	movq	%rbx, %rsi
  10738b:      	xorl	%edx, %edx
  10738d:      	movq	%r13, %rcx
  107390:      	movl	$0x6, %r9d
  107396:      	callq	0x108ca0 <shllvm_closure>
  10739b:      	movq	0xe8(%r12), %rax
  1073a3:      	movq	%rax, -0x68(%rbp)
  1073a7:      	movq	0xe0(%r12), %rax
  1073af:      	movq	%rax, -0x60(%rbp)
  1073b3:      	movq	-0x148(%rbp), %rdi
  1073ba:      	movq	%rbx, %rsi
  1073bd:      	movq	%r14, %rdx
  1073c0:      	movq	-0x70(%rbp), %rcx
  1073c4:      	movq	-0x30(%rbp), %r8
  1073c8:      	movq	%r8, %r9
  1073cb:      	leaq	-0x68(%rbp), %rax
  1073cf:      	pushq	%rax
  1073d0:      	pushq	$0x2
  1073d2:      	callq	0x108dd0 <shllvm_call>
  1073d7:      	addq	$0x10, %rsp
  1073db:      	movq	-0x150(%rbp), %r14
  1073e2:      	movq	%r14, %rdi
  1073e5:      	movq	%rbx, %rsi
  1073e8:      	movq	%r13, %rdx
  1073eb:      	movq	%r15, %rcx
  1073ee:      	movl	$0x5, %r8d
  1073f4:      	xorl	%r9d, %r9d
  1073f7:      	callq	0x109700 <shllvm_get_id>
  1073fc:      	movq	0x190(%r12), %rax
  107404:      	movq	%rax, 0x100(%r12)
  10740c:      	movq	%rax, -0x68(%rbp)
  107410:      	movq	-0x158(%rbp), %r15
  107417:      	movq	%r15, %rdi
  10741a:      	movq	%rbx, %rsi
  10741d:      	movq	-0x40(%rbp), %r13
  107421:      	movq	%r13, %rdx
  107424:      	movq	%r14, %rcx
  107427:      	movq	-0x30(%rbp), %r14
  10742b:      	movq	%r14, %r8
  10742e:      	movq	%r14, %r9
  107431:      	leaq	-0x68(%rbp), %rax
  107435:      	pushq	%rax
  107436:      	pushq	$0x1
  107438:      	callq	0x108dd0 <shllvm_call>
  10743d:      	addq	$0x10, %rsp
  107441:      	movq	0x198(%r12), %rax
  107449:      	movq	%rax, 0x110(%r12)
  107451:      	movq	%rax, -0x68(%rbp)
  107455:      	movq	-0x160(%rbp), %rdi
  10745c:      	movq	%rbx, %rsi
  10745f:      	movq	%r13, %rdx
  107462:      	movq	%r15, %rcx
  107465:      	movq	%r14, %r8
  107468:      	movq	%r14, %r9
  10746b:      	leaq	-0x68(%rbp), %rax
  10746f:      	pushq	%rax
  107470:      	pushq	$0x1
  107472:      	callq	0x108dd0 <shllvm_call>
  107477:      	addq	$0x10, %rsp
  10747b:      	movq	0xa0(%r12), %rax
  107483:      	movq	%rax, -0x68(%rbp)
  107487:      	movq	0xb8(%r12), %rax
  10748f:      	movq	%rax, -0x60(%rbp)
  107493:      	movq	0xd0(%r12), %rax
  10749b:      	movq	%rax, -0x58(%rbp)
  10749f:      	movq	0xf0(%r12), %rax
  1074a7:      	movq	%rax, -0x50(%rbp)
  1074ab:      	movq	0x118(%r12), %rax
  1074b3:      	movq	%rax, -0x48(%rbp)
  1074b7:      	movq	-0x168(%rbp), %rdi
  1074be:      	movq	%rbx, %rsi
  1074c1:      	movq	%r13, %rdx
  1074c4:      	movq	-0x78(%rbp), %rcx
  1074c8:      	movq	%r14, %r8
  1074cb:      	movq	%r14, %r9
  1074ce:      	leaq	-0x68(%rbp), %rax
  1074d2:      	pushq	%rax
  1074d3:      	pushq	$0x5
  1074d5:      	callq	0x108dd0 <shllvm_call>
  1074da:      	addq	$0x10, %rsp
  1074de:      	movq	0x120(%r12), %r14
  1074e6:      	movq	%rbx, %rdi
  1074e9:      	movq	-0x170(%rbp), %rsi
  1074f0:      	movq	%r13, %rdx
  1074f3:      	callq	0x1086c0 <shllvm_leave>
  1074f8:      	movq	%r14, %rax
  1074fb:      	leaq	-0x28(%rbp), %rsp
  1074ff:      	popq	%rbx
  107500:      	popq	%r12
  107502:      	popq	%r13
  107504:      	popq	%r14
  107506:      	popq	%r15
  107508:      	popq	%rbp
  107509:      	retq
  10750a:      	nopw	(%rax,%rax)

0000000000107510 <shllvm_f1>:
  107510:      	pushq	%rbp
  107511:      	movq	%rsp, %rbp
  107514:      	pushq	%r15
  107516:      	pushq	%r14
  107518:      	pushq	%r13
  10751a:      	pushq	%r12
  10751c:      	pushq	%rbx
  10751d:      	subq	$0x48, %rsp
  107521:      	movq	%rdi, %rbx
  107524:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107529:      	movl	$0x11, %edi
  10752e:      	callq	0x108270 <shllvm_frame_size>
  107533:      	movq	%rsp, %r14
  107536:      	addq	$0xf, %rax
  10753a:      	andq	$-0x10, %rax
  10753e:      	subq	%rax, %r14
  107541:      	movq	%r14, %rsp
  107544:      	movl	0x993d55(%rip), %r15d   # 0xa9b2a0 <shllvm_unit_index>
  10754b:      	movq	%rbx, %rdi
  10754e:      	movq	%r14, %rsi
  107551:      	movl	$0x11, %edx
  107556:      	movl	$0x1, %ecx
  10755b:      	movl	%r15d, %r8d
  10755e:      	callq	0x108300 <shllvm_enter>
  107563:      	movq	%rax, %r13
  107566:      	movq	%r14, -0x68(%rbp)
  10756a:      	movq	%r14, %rdi
  10756d:      	callq	0x1086b0 <shllvm_roots>
  107572:      	movq	%rax, %r12
  107575:      	movq	%rbx, %rdi
  107578:      	movl	%r15d, %esi
  10757b:      	callq	0x108280 <shllvm_get_unit>
  107580:      	movq	%rax, %r15
  107583:      	leaq	0x8(%r12), %rax
  107588:      	movq	%rax, -0x50(%rbp)
  10758c:      	leaq	0x10(%r12), %rax
  107591:      	movq	%rax, -0x48(%rbp)
  107595:      	leaq	0x60(%r12), %r14
  10759a:      	leaq	0x68(%r12), %rax
  10759f:      	movq	%rax, -0x30(%rbp)
  1075a3:      	leaq	0x70(%r12), %rax
  1075a8:      	movq	%rax, -0x38(%rbp)
  1075ac:      	leaq	0x78(%r12), %rax
  1075b1:      	movq	%rax, -0x40(%rbp)
  1075b5:      	movq	%rbx, %rdi
  1075b8:      	movq	%r13, %rsi
  1075bb:      	xorl	%edx, %edx
  1075bd:      	callq	0x10a5d0 <shllvm_check_invocation>
  1075c2:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  1075cc:      	movq	%r14, %rdi
  1075cf:      	movq	-0x50(%rbp), %r14
  1075d3:      	movl	$0x3, %esi
  1075d8:      	callq	0x108140 <shllvm_constant>
  1075dd:      	movq	-0x30(%rbp), %rdi
  1075e1:      	movq	%rbx, %rsi
  1075e4:      	movq	%r15, -0x30(%rbp)
  1075e8:      	movq	%r15, %rdx
  1075eb:      	movl	$0x1, %ecx
  1075f0:      	callq	0x108820 <shllvm_symbol>
  1075f5:      	movq	-0x38(%rbp), %rdi
  1075f9:      	xorl	%esi, %esi
  1075fb:      	xorl	%edx, %edx
  1075fd:      	callq	0x108140 <shllvm_constant>
  107602:      	movq	-0x40(%rbp), %rdi
  107606:      	movl	$0x2, %esi
  10760b:      	xorl	%edx, %edx
  10760d:      	callq	0x108140 <shllvm_constant>
  107612:      	movq	%r12, %rdi
  107615:      	movq	%r13, %rsi
  107618:      	movl	$0x1, %edx
  10761d:      	callq	0x108760 <shllvm_param>
  107622:      	movq	0x60(%r12), %rax
  107627:      	movq	%rax, 0x8(%r12)
  10762c:      	movq	-0x48(%rbp), %r15
  107630:      	movq	%r15, %rdi
  107633:      	movq	%rbx, %rsi
  107636:      	movl	$0xa, %edx
  10763b:      	movq	%r12, %rcx
  10763e:      	movq	%r14, %r8
  107641:      	callq	0x1090a0 <shllvm_binary>
  107646:      	movq	%r15, %rdi
  107649:      	callq	0x1095a0 <shllvm_truthy>
  10764e:      	testl	%eax, %eax
  107650:      	jne	0x107723 <shllvm_f1+0x213>
  107656:      	leaq	0x50(%r12), %rax
  10765b:      	movq	%rax, -0x48(%rbp)
  10765f:      	leaq	0x48(%r12), %rax
  107664:      	movq	%rax, -0x38(%rbp)
  107668:      	leaq	0x40(%r12), %rax
  10766d:      	movq	%rax, -0x40(%rbp)
  107671:      	leaq	0x38(%r12), %rax
  107676:      	movq	%rax, -0x58(%rbp)
  10767a:      	leaq	0x30(%r12), %r15
  10767f:      	movq	%r15, -0x60(%rbp)
  107683:      	movq	%r13, %r14
  107686:      	movq	%r12, %r13
  107689:      	addq	$0x28, %r13
  10768d:      	movq	%r13, %rdi
  107690:      	movq	%rbx, %rsi
  107693:      	callq	0x1087e0 <shllvm_global>
  107698:      	movq	%r15, %rdi
  10769b:      	movq	%rbx, %rsi
  10769e:      	movq	-0x30(%rbp), %rdx
  1076a2:      	movq	%r13, %rcx
  1076a5:      	movq	%r14, %r13
  1076a8:      	movl	$0x1, %r8d
  1076ae:      	xorl	%r9d, %r9d
  1076b1:      	callq	0x109700 <shllvm_get_id>
  1076b6:      	movq	-0x58(%rbp), %rdi
  1076ba:      	movq	%rbx, %rsi
  1076bd:      	movl	$0x1, %edx
  1076c2:      	movq	%r12, %rcx
  1076c5:      	movq	-0x50(%rbp), %r8
  1076c9:      	callq	0x1090a0 <shllvm_binary>
  1076ce:      	movq	0x38(%r12), %rax
  1076d3:      	movq	0x70(%r12), %rcx
  1076d8:      	movq	%rcx, 0x40(%r12)
  1076dd:      	movq	%rax, -0x70(%rbp)
  1076e1:      	leaq	-0x70(%rbp), %rax
  1076e5:      	movq	-0x38(%rbp), %r15
  1076e9:      	movq	%r15, %rdi
  1076ec:      	movq	%rbx, %rsi
  1076ef:      	movq	%r14, %rdx
  1076f2:      	movq	-0x60(%rbp), %rcx
  1076f6:      	movq	-0x40(%rbp), %r8
  1076fa:      	movq	%r8, %r9
  1076fd:      	pushq	%rax
  1076fe:      	pushq	$0x1
  107700:      	callq	0x108dd0 <shllvm_call>
  107705:      	addq	$0x10, %rsp
  107709:      	movq	-0x48(%rbp), %r14
  10770d:      	movq	%r14, %rdi
  107710:      	movq	%rbx, %rsi
  107713:      	movl	$0x2, %edx
  107718:      	movq	%r12, %rcx
  10771b:      	movq	%r15, %r8
  10771e:      	callq	0x1090a0 <shllvm_binary>
  107723:      	movq	(%r14), %r14
  107726:      	movq	%rbx, %rdi
  107729:      	movq	-0x68(%rbp), %rsi
  10772d:      	movq	%r13, %rdx
  107730:      	callq	0x1086c0 <shllvm_leave>
  107735:      	movq	%r14, %rax
  107738:      	leaq	-0x28(%rbp), %rsp
  10773c:      	popq	%rbx
  10773d:      	popq	%r12
  10773f:      	popq	%r13
  107741:      	popq	%r14
  107743:      	popq	%r15
  107745:      	popq	%rbp
  107746:      	retq
  107747:      	nopw	(%rax,%rax)

0000000000107750 <shllvm_f2>:
  107750:      	pushq	%rbp
  107751:      	movq	%rsp, %rbp
  107754:      	pushq	%r15
  107756:      	pushq	%r14
  107758:      	pushq	%r13
  10775a:      	pushq	%r12
  10775c:      	pushq	%rbx
  10775d:      	subq	$0x48, %rsp
  107761:      	movq	%rdi, %rbx
  107764:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107769:      	movl	$0x15, %edi
  10776e:      	callq	0x108270 <shllvm_frame_size>
  107773:      	movq	%rsp, %r14
  107776:      	addq	$0xf, %rax
  10777a:      	andq	$-0x10, %rax
  10777e:      	subq	%rax, %r14
  107781:      	movq	%r14, %rsp
  107784:      	movl	0x993b15(%rip), %r15d   # 0xa9b2a0 <shllvm_unit_index>
  10778b:      	movq	%rbx, %rdi
  10778e:      	movq	%r14, %rsi
  107791:      	movl	$0x15, %edx
  107796:      	movl	$0x1, %ecx
  10779b:      	movl	%r15d, %r8d
  10779e:      	callq	0x108300 <shllvm_enter>
  1077a3:      	movq	%rax, %r13
  1077a6:      	movq	%r14, -0x68(%rbp)
  1077aa:      	movq	%r14, %rdi
  1077ad:      	callq	0x1086b0 <shllvm_roots>
  1077b2:      	movq	%rax, %r12
  1077b5:      	movq	%rbx, %rdi
  1077b8:      	movl	%r15d, %esi
  1077bb:      	callq	0x108280 <shllvm_get_unit>
  1077c0:      	movq	%rax, %r14
  1077c3:      	leaq	0x10(%r12), %rax
  1077c8:      	movq	%rax, -0x30(%rbp)
  1077cc:      	leaq	0x18(%r12), %rax
  1077d1:      	movq	%rax, -0x50(%rbp)
  1077d5:      	leaq	0x70(%r12), %r15
  1077da:      	leaq	0x78(%r12), %rax
  1077df:      	movq	%rax, -0x58(%rbp)
  1077e3:      	leaq	0x80(%r12), %rax
  1077eb:      	movq	%rax, -0x38(%rbp)
  1077ef:      	leaq	0x88(%r12), %rax
  1077f7:      	movq	%rax, -0x60(%rbp)
  1077fb:      	leaq	0x90(%r12), %rax
  107803:      	movq	%rax, -0x40(%rbp)
  107807:      	leaq	0x98(%r12), %rax
  10780f:      	movq	%rax, -0x48(%rbp)
  107813:      	movq	%rbx, %rdi
  107816:      	movq	%r13, %rsi
  107819:      	xorl	%edx, %edx
  10781b:      	callq	0x10a5d0 <shllvm_check_invocation>
  107820:      	movl	$0x1, %edx
  107825:      	movq	%r15, %rdi
  107828:      	movq	%r13, %r15
  10782b:      	movl	$0x2, %esi
  107830:      	callq	0x108140 <shllvm_constant>
  107835:      	movq	-0x58(%rbp), %rdi
  107839:      	movl	$0x3, %esi
  10783e:      	xorl	%edx, %edx
  107840:      	callq	0x108140 <shllvm_constant>
  107845:      	movq	-0x38(%rbp), %rdi
  107849:      	movq	%rbx, %rsi
  10784c:      	movq	%r14, -0x38(%rbp)
  107850:      	movq	%r14, %rdx
  107853:      	movl	$0x3, %ecx
  107858:      	callq	0x108820 <shllvm_symbol>
  10785d:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  107867:      	movq	-0x60(%rbp), %rdi
  10786b:      	movl	$0x3, %esi
  107870:      	callq	0x108140 <shllvm_constant>
  107875:      	movq	-0x40(%rbp), %rdi
  107879:      	xorl	%esi, %esi
  10787b:      	xorl	%edx, %edx
  10787d:      	callq	0x108140 <shllvm_constant>
  107882:      	movq	-0x48(%rbp), %rdi
  107886:      	movl	$0x2, %esi
  10788b:      	xorl	%edx, %edx
  10788d:      	callq	0x108140 <shllvm_constant>
  107892:      	movq	%r12, %rdi
  107895:      	movq	%r13, %rsi
  107898:      	movl	$0x1, %edx
  10789d:      	callq	0x108760 <shllvm_param>
  1078a2:      	movups	0x70(%r12), %xmm0
  1078a8:      	movups	%xmm0, 0x8(%r12)
  1078ae:      	movq	-0x50(%rbp), %r14
  1078b2:      	movq	%r14, %rdi
  1078b5:      	movq	%rbx, %rsi
  1078b8:      	movl	$0x7, %edx
  1078bd:      	movq	%r12, %rcx
  1078c0:      	movq	-0x30(%rbp), %r8
  1078c4:      	callq	0x1090a0 <shllvm_binary>
  1078c9:      	movq	%r14, %rdi
  1078cc:      	callq	0x1095a0 <shllvm_truthy>
  1078d1:      	testl	%eax, %eax
  1078d3:      	je	0x1078e1 <shllvm_f2+0x191>
  1078d5:      	movq	%r12, %r13
  1078d8:      	addq	$0x8, %r13
  1078dc:      	jmp	0x10799a <shllvm_f2+0x24a>
  1078e1:      	leaq	0x50(%r12), %r13
  1078e6:      	leaq	0x48(%r12), %rax
  1078eb:      	movq	%rax, -0x50(%rbp)
  1078ef:      	leaq	0x40(%r12), %rax
  1078f4:      	movq	%rax, -0x40(%rbp)
  1078f8:      	leaq	0x38(%r12), %rax
  1078fd:      	movq	%rax, -0x48(%rbp)
  107901:      	movq	%r15, -0x30(%rbp)
  107905:      	leaq	0x30(%r12), %r15
  10790a:      	movq	%r12, %r14
  10790d:      	addq	$0x28, %r14
  107911:      	movq	%r14, %rdi
  107914:      	movq	%rbx, %rsi
  107917:      	callq	0x1087e0 <shllvm_global>
  10791c:      	movq	%r15, %rdi
  10791f:      	movq	%rbx, %rsi
  107922:      	movq	-0x38(%rbp), %rdx
  107926:      	movq	%r14, %rcx
  107929:      	movl	$0x3, %r8d
  10792f:      	xorl	%r9d, %r9d
  107932:      	callq	0x109700 <shllvm_get_id>
  107937:      	movq	0x88(%r12), %rax
  10793f:      	movq	%rax, 0x38(%r12)
  107944:      	movq	-0x40(%rbp), %rdi
  107948:      	movq	%rbx, %rsi
  10794b:      	movl	$0x1, %edx
  107950:      	movq	%r12, %rcx
  107953:      	movq	-0x48(%rbp), %r8
  107957:      	callq	0x1090a0 <shllvm_binary>
  10795c:      	movq	0x40(%r12), %rax
  107961:      	movq	0x90(%r12), %rcx
  107969:      	movq	%rcx, 0x48(%r12)
  10796e:      	movq	%rax, -0x70(%rbp)
  107972:      	leaq	-0x70(%rbp), %rax
  107976:      	movq	%r13, %rdi
  107979:      	movq	%rbx, %rsi
  10797c:      	movq	-0x30(%rbp), %rdx
  107980:      	movq	%r15, %rcx
  107983:      	movq	-0x30(%rbp), %r15
  107987:      	movq	-0x50(%rbp), %r8
  10798b:      	movq	%r8, %r9
  10798e:      	pushq	%rax
  10798f:      	pushq	$0x1
  107991:      	callq	0x108dd0 <shllvm_call>
  107996:      	addq	$0x10, %rsp
  10799a:      	movq	(%r13), %r14
  10799e:      	movq	%r14, 0x60(%r12)
  1079a3:      	movq	%rbx, %rdi
  1079a6:      	movq	-0x68(%rbp), %rsi
  1079aa:      	movq	%r15, %rdx
  1079ad:      	callq	0x1086c0 <shllvm_leave>
  1079b2:      	movq	%r14, %rax
  1079b5:      	leaq	-0x28(%rbp), %rsp
  1079b9:      	popq	%rbx
  1079ba:      	popq	%r12
  1079bc:      	popq	%r13
  1079be:      	popq	%r14
  1079c0:      	popq	%r15
  1079c2:      	popq	%rbp
  1079c3:      	retq
  1079c4:      	nopw	%cs:(%rax,%rax)

00000000001079d0 <shllvm_f3>:
  1079d0:      	pushq	%rbp
  1079d1:      	movq	%rsp, %rbp
  1079d4:      	pushq	%r15
  1079d6:      	pushq	%r14
  1079d8:      	pushq	%r13
  1079da:      	pushq	%r12
  1079dc:      	pushq	%rbx
  1079dd:      	subq	$0x48, %rsp
  1079e1:      	movq	%rdi, %rbx
  1079e4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  1079e9:      	movl	$0x14, %edi
  1079ee:      	callq	0x108270 <shllvm_frame_size>
  1079f3:      	movq	%rsp, %r14
  1079f6:      	addq	$0xf, %rax
  1079fa:      	andq	$-0x10, %rax
  1079fe:      	subq	%rax, %r14
  107a01:      	movq	%r14, %rsp
  107a04:      	movl	0x993895(%rip), %r15d   # 0xa9b2a0 <shllvm_unit_index>
  107a0b:      	movq	%rbx, %rdi
  107a0e:      	movq	%r14, %rsi
  107a11:      	movl	$0x14, %edx
  107a16:      	movl	$0x1, %ecx
  107a1b:      	movl	%r15d, %r8d
  107a1e:      	callq	0x108300 <shllvm_enter>
  107a23:      	movq	%rax, -0x50(%rbp)
  107a27:      	movq	%r14, -0x68(%rbp)
  107a2b:      	movq	%r14, %rdi
  107a2e:      	callq	0x1086b0 <shllvm_roots>
  107a33:      	movq	%rax, %r12
  107a36:      	movq	%rbx, %rdi
  107a39:      	movl	%r15d, %esi
  107a3c:      	callq	0x108280 <shllvm_get_unit>
  107a41:      	movq	%rax, %r14
  107a44:      	leaq	0x10(%r12), %rax
  107a49:      	movq	%rax, -0x48(%rbp)
  107a4d:      	leaq	0x18(%r12), %rax
  107a52:      	movq	%rax, -0x40(%rbp)
  107a56:      	leaq	0x70(%r12), %r13
  107a5b:      	leaq	0x78(%r12), %rax
  107a60:      	movq	%rax, -0x58(%rbp)
  107a64:      	leaq	0x80(%r12), %rax
  107a6c:      	movq	%rax, -0x30(%rbp)
  107a70:      	leaq	0x88(%r12), %rax
  107a78:      	movq	%rax, -0x60(%rbp)
  107a7c:      	leaq	0x90(%r12), %rax
  107a84:      	movq	%rax, -0x38(%rbp)
  107a88:      	movq	%rbx, %rdi
  107a8b:      	movq	-0x50(%rbp), %r15
  107a8f:      	movq	%r15, %rsi
  107a92:      	xorl	%edx, %edx
  107a94:      	callq	0x10a5d0 <shllvm_check_invocation>
  107a99:      	movq	%r13, %rdi
  107a9c:      	movl	$0x2, %esi
  107aa1:      	xorl	%edx, %edx
  107aa3:      	callq	0x108140 <shllvm_constant>
  107aa8:      	movq	-0x58(%rbp), %rdi
  107aac:      	movl	$0x3, %esi
  107ab1:      	xorl	%edx, %edx
  107ab3:      	callq	0x108140 <shllvm_constant>
  107ab8:      	movq	-0x30(%rbp), %rdi
  107abc:      	movq	%rbx, %rsi
  107abf:      	movq	%r14, -0x30(%rbp)
  107ac3:      	movq	%r14, %rdx
  107ac6:      	movl	$0x2, %ecx
  107acb:      	callq	0x108820 <shllvm_symbol>
  107ad0:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  107ada:      	movq	-0x60(%rbp), %rdi
  107ade:      	movl	$0x3, %esi
  107ae3:      	callq	0x108140 <shllvm_constant>
  107ae8:      	movq	-0x38(%rbp), %rdi
  107aec:      	xorl	%esi, %esi
  107aee:      	xorl	%edx, %edx
  107af0:      	callq	0x108140 <shllvm_constant>
  107af5:      	movq	%r12, %rdi
  107af8:      	movq	%r15, %rsi
  107afb:      	movl	$0x1, %edx
  107b00:      	callq	0x108760 <shllvm_param>
  107b05:      	movups	0x70(%r12), %xmm0
  107b0b:      	movups	%xmm0, 0x8(%r12)
  107b11:      	movq	-0x40(%rbp), %r14
  107b15:      	movq	%r14, %rdi
  107b18:      	movq	%rbx, %rsi
  107b1b:      	movl	$0x7, %edx
  107b20:      	movq	%r12, %rcx
  107b23:      	movq	-0x48(%rbp), %r8
  107b27:      	callq	0x1090a0 <shllvm_binary>
  107b2c:      	movq	%r14, %rdi
  107b2f:      	callq	0x1095a0 <shllvm_truthy>
  107b34:      	testl	%eax, %eax
  107b36:      	je	0x107b44 <shllvm_f3+0x174>
  107b38:      	movq	%r12, %r13
  107b3b:      	addq	$0x8, %r13
  107b3f:      	jmp	0x107bf9 <shllvm_f3+0x229>
  107b44:      	leaq	0x50(%r12), %r13
  107b49:      	leaq	0x48(%r12), %rax
  107b4e:      	movq	%rax, -0x48(%rbp)
  107b52:      	leaq	0x40(%r12), %rax
  107b57:      	movq	%rax, -0x38(%rbp)
  107b5b:      	leaq	0x38(%r12), %rax
  107b60:      	movq	%rax, -0x40(%rbp)
  107b64:      	leaq	0x30(%r12), %r15
  107b69:      	movq	%r12, %r14
  107b6c:      	addq	$0x28, %r14
  107b70:      	movq	%r14, %rdi
  107b73:      	movq	%rbx, %rsi
  107b76:      	callq	0x1087e0 <shllvm_global>
  107b7b:      	movq	%r15, %rdi
  107b7e:      	movq	%rbx, %rsi
  107b81:      	movq	-0x30(%rbp), %rdx
  107b85:      	movq	%r14, %rcx
  107b88:      	movl	$0x2, %r8d
  107b8e:      	xorl	%r9d, %r9d
  107b91:      	callq	0x109700 <shllvm_get_id>
  107b96:      	movq	0x88(%r12), %rax
  107b9e:      	movq	%rax, 0x38(%r12)
  107ba3:      	movq	-0x38(%rbp), %rdi
  107ba7:      	movq	%rbx, %rsi
  107baa:      	movl	$0x1, %edx
  107baf:      	movq	%r12, %rcx
  107bb2:      	movq	-0x40(%rbp), %r8
  107bb6:      	callq	0x1090a0 <shllvm_binary>
  107bbb:      	movq	0x40(%r12), %rax
  107bc0:      	movq	0x90(%r12), %rcx
  107bc8:      	movq	%rcx, 0x48(%r12)
  107bcd:      	movq	%rax, -0x70(%rbp)
  107bd1:      	leaq	-0x70(%rbp), %rax
  107bd5:      	movq	%r13, %rdi
  107bd8:      	movq	%rbx, %rsi
  107bdb:      	movq	-0x50(%rbp), %rdx
  107bdf:      	movq	%r15, %rcx
  107be2:      	movq	-0x50(%rbp), %r15
  107be6:      	movq	-0x48(%rbp), %r8
  107bea:      	movq	%r8, %r9
  107bed:      	pushq	%rax
  107bee:      	pushq	$0x1
  107bf0:      	callq	0x108dd0 <shllvm_call>
  107bf5:      	addq	$0x10, %rsp
  107bf9:      	movq	(%r13), %r14
  107bfd:      	movq	%r14, 0x60(%r12)
  107c02:      	movq	%rbx, %rdi
  107c05:      	movq	-0x68(%rbp), %rsi
  107c09:      	movq	%r15, %rdx
  107c0c:      	callq	0x1086c0 <shllvm_leave>
  107c11:      	movq	%r14, %rax
  107c14:      	leaq	-0x28(%rbp), %rsp
  107c18:      	popq	%rbx
  107c19:      	popq	%r12
  107c1b:      	popq	%r13
  107c1d:      	popq	%r14
  107c1f:      	popq	%r15
  107c21:      	popq	%rbp
  107c22:      	retq
  107c23:      	nopw	%cs:(%rax,%rax)

0000000000107c30 <shllvm_f4>:
  107c30:      	pushq	%rbp
  107c31:      	movq	%rsp, %rbp
  107c34:      	pushq	%r15
  107c36:      	pushq	%r14
  107c38:      	pushq	%r13
  107c3a:      	pushq	%r12
  107c3c:      	pushq	%rbx
  107c3d:      	subq	$0x28, %rsp
  107c41:      	movq	%rdi, %rbx
  107c44:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107c49:      	movl	$0x8, %edi
  107c4e:      	callq	0x108270 <shllvm_frame_size>
  107c53:      	movq	%rsp, %r14
  107c56:      	addq	$0xf, %rax
  107c5a:      	andq	$-0x10, %rax
  107c5e:      	subq	%rax, %r14
  107c61:      	movq	%r14, %rsp
  107c64:      	movl	0x993635(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107c6b:      	movq	%rbx, %rdi
  107c6e:      	movq	%r14, %rsi
  107c71:      	movl	$0x8, %edx
  107c76:      	movl	$0x1, %ecx
  107c7b:      	movl	%r13d, %r8d
  107c7e:      	callq	0x108300 <shllvm_enter>
  107c83:      	movq	%rax, %r15
  107c86:      	movq	%r14, %rdi
  107c89:      	callq	0x1086b0 <shllvm_roots>
  107c8e:      	movq	%rax, %r12
  107c91:      	movq	%rbx, %rdi
  107c94:      	movl	%r13d, %esi
  107c97:      	callq	0x108280 <shllvm_get_unit>
  107c9c:      	leaq	0x8(%r12), %rax
  107ca1:      	movq	%rax, -0x38(%rbp)
  107ca5:      	leaq	0x10(%r12), %rax
  107caa:      	movq	%rax, -0x40(%rbp)
  107cae:      	leaq	0x18(%r12), %rax
  107cb3:      	movq	%rax, -0x48(%rbp)
  107cb7:      	leaq	0x28(%r12), %r13
  107cbc:      	leaq	0x30(%r12), %rax
  107cc1:      	movq	%rax, -0x30(%rbp)
  107cc5:      	movq	%rbx, %rdi
  107cc8:      	movq	%r15, %rsi
  107ccb:      	xorl	%edx, %edx
  107ccd:      	callq	0x10a5d0 <shllvm_check_invocation>
  107cd2:      	movq	%r13, %rdi
  107cd5:      	xorl	%esi, %esi
  107cd7:      	xorl	%edx, %edx
  107cd9:      	callq	0x108140 <shllvm_constant>
  107cde:      	movq	-0x30(%rbp), %rdi
  107ce2:      	movl	$0x2, %esi
  107ce7:      	xorl	%edx, %edx
  107ce9:      	callq	0x108140 <shllvm_constant>
  107cee:      	movq	0x28(%r12), %rax
  107cf3:      	movq	%rax, (%r12)
  107cf7:      	movq	-0x38(%rbp), %rdi
  107cfb:      	movq	%r15, %rsi
  107cfe:      	movl	$0x2, %edx
  107d03:      	callq	0x108760 <shllvm_param>
  107d08:      	movq	-0x40(%rbp), %r13
  107d0c:      	movq	%r13, %rdi
  107d0f:      	movq	%r15, %rsi
  107d12:      	movl	$0x1, %edx
  107d17:      	callq	0x108760 <shllvm_param>
  107d1c:      	movq	0x8(%r12), %rax
  107d21:      	movq	%rax, -0x50(%rbp)
  107d25:      	leaq	-0x50(%rbp), %rax
  107d29:      	movq	-0x48(%rbp), %rdi
  107d2d:      	movq	%rbx, %rsi
  107d30:      	movq	%r15, %rdx
  107d33:      	movq	%r13, %rcx
  107d36:      	movq	%r12, %r8
  107d39:      	movq	%r12, %r9
  107d3c:      	pushq	%rax
  107d3d:      	pushq	$0x1
  107d3f:      	callq	0x108dd0 <shllvm_call>
  107d44:      	addq	$0x10, %rsp
  107d48:      	movq	0x18(%r12), %r12
  107d4d:      	movq	%rbx, %rdi
  107d50:      	movq	%r14, %rsi
  107d53:      	movq	%r15, %rdx
  107d56:      	callq	0x1086c0 <shllvm_leave>
  107d5b:      	movq	%r12, %rax
  107d5e:      	leaq	-0x28(%rbp), %rsp
  107d62:      	popq	%rbx
  107d63:      	popq	%r12
  107d65:      	popq	%r13
  107d67:      	popq	%r14
  107d69:      	popq	%r15
  107d6b:      	popq	%rbp
  107d6c:      	retq
  107d6d:      	nopl	(%rax)

0000000000107d70 <shllvm_f5>:
  107d70:      	pushq	%rbp
  107d71:      	movq	%rsp, %rbp
  107d74:      	pushq	%r15
  107d76:      	pushq	%r14
  107d78:      	pushq	%r13
  107d7a:      	pushq	%r12
  107d7c:      	pushq	%rbx
  107d7d:      	subq	$0x18, %rsp
  107d81:      	movq	%rdi, %rbx
  107d84:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107d89:      	movl	$0x6, %edi
  107d8e:      	callq	0x108270 <shllvm_frame_size>
  107d93:      	movq	%rsp, %r14
  107d96:      	addq	$0xf, %rax
  107d9a:      	andq	$-0x10, %rax
  107d9e:      	subq	%rax, %r14
  107da1:      	movq	%r14, %rsp
  107da4:      	movl	0x9934f5(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107dab:      	movq	%rbx, %rdi
  107dae:      	movq	%r14, %rsi
  107db1:      	movl	$0x6, %edx
  107db6:      	xorl	%ecx, %ecx
  107db8:      	movl	%r13d, %r8d
  107dbb:      	callq	0x108300 <shllvm_enter>
  107dc0:      	movq	%rax, %r15
  107dc3:      	movq	%r14, %rdi
  107dc6:      	callq	0x1086b0 <shllvm_roots>
  107dcb:      	movq	%rax, %r12
  107dce:      	movq	%rbx, %rdi
  107dd1:      	movl	%r13d, %esi
  107dd4:      	callq	0x108280 <shllvm_get_unit>
  107dd9:      	movq	%rax, -0x38(%rbp)
  107ddd:      	leaq	0x8(%r12), %r13
  107de2:      	leaq	0x18(%r12), %rax
  107de7:      	movq	%rax, -0x30(%rbp)
  107deb:      	movq	%rbx, %rdi
  107dee:      	movq	%r15, %rsi
  107df1:      	xorl	%edx, %edx
  107df3:      	callq	0x10a5d0 <shllvm_check_invocation>
  107df8:      	movq	%r12, %rdi
  107dfb:      	movq	%rbx, %rsi
  107dfe:      	xorl	%edx, %edx
  107e00:      	movl	$0x1, %ecx
  107e05:      	callq	0x108a00 <shllvm_env_create>
  107e0a:      	movq	%r13, %rdi
  107e0d:      	movq	%r15, %rsi
  107e10:      	movl	$0x1, %edx
  107e15:      	callq	0x108760 <shllvm_param>
  107e1a:      	movq	%rbx, %rdi
  107e1d:      	movq	%r12, %rsi
  107e20:      	movq	%r13, %rdx
  107e23:      	xorl	%ecx, %ecx
  107e25:      	callq	0x108c60 <shllvm_env_store>
  107e2a:      	leaq	0x14f(%rip), %r8        # 0x107f80 <shllvm_f7>
  107e31:      	movq	-0x30(%rbp), %rdi
  107e35:      	movq	%rbx, %rsi
  107e38:      	movq	%r12, %rdx
  107e3b:      	movq	-0x38(%rbp), %rcx
  107e3f:      	movl	$0x7, %r9d
  107e45:      	callq	0x108ca0 <shllvm_closure>
  107e4a:      	movq	0x18(%r12), %r12
  107e4f:      	movq	%rbx, %rdi
  107e52:      	movq	%r14, %rsi
  107e55:      	movq	%r15, %rdx
  107e58:      	callq	0x1086c0 <shllvm_leave>
  107e5d:      	movq	%r12, %rax
  107e60:      	leaq	-0x28(%rbp), %rsp
  107e64:      	popq	%rbx
  107e65:      	popq	%r12
  107e67:      	popq	%r13
  107e69:      	popq	%r14
  107e6b:      	popq	%r15
  107e6d:      	popq	%rbp
  107e6e:      	retq
  107e6f:      	nop

0000000000107e70 <shllvm_f6>:
  107e70:      	pushq	%rbp
  107e71:      	movq	%rsp, %rbp
  107e74:      	pushq	%r15
  107e76:      	pushq	%r14
  107e78:      	pushq	%r13
  107e7a:      	pushq	%r12
  107e7c:      	pushq	%rbx
  107e7d:      	subq	$0x18, %rsp
  107e81:      	movq	%rdi, %rbx
  107e84:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107e89:      	movl	$0x6, %edi
  107e8e:      	callq	0x108270 <shllvm_frame_size>
  107e93:      	movq	%rsp, %r14
  107e96:      	addq	$0xf, %rax
  107e9a:      	andq	$-0x10, %rax
  107e9e:      	subq	%rax, %r14
  107ea1:      	movq	%r14, %rsp
  107ea4:      	movl	0x9933f5(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107eab:      	movq	%rbx, %rdi
  107eae:      	movq	%r14, %rsi
  107eb1:      	movl	$0x6, %edx
  107eb6:      	xorl	%ecx, %ecx
  107eb8:      	movl	%r13d, %r8d
  107ebb:      	callq	0x108300 <shllvm_enter>
  107ec0:      	movq	%rax, -0x30(%rbp)
  107ec4:      	movq	%r14, %rdi
  107ec7:      	callq	0x1086b0 <shllvm_roots>
  107ecc:      	movq	%rax, %r12
  107ecf:      	movq	%rbx, %rdi
  107ed2:      	movl	%r13d, %esi
  107ed5:      	callq	0x108280 <shllvm_get_unit>
  107eda:      	leaq	0x8(%r12), %rax
  107edf:      	movq	%rax, -0x38(%rbp)
  107ee3:      	leaq	0x10(%r12), %rax
  107ee8:      	movq	%rax, -0x40(%rbp)
  107eec:      	leaq	0x20(%r12), %r15
  107ef1:      	movq	%rbx, %rdi
  107ef4:      	movq	-0x30(%rbp), %r13
  107ef8:      	movq	%r13, %rsi
  107efb:      	movl	$0x1, %edx
  107f00:      	callq	0x10a5d0 <shllvm_check_invocation>
  107f05:      	movabsq	$0x4000000000000000, %rdx # imm = 0x4000000000000000
  107f0f:      	movq	%r15, %rdi
  107f12:      	movl	$0x3, %esi
  107f17:      	callq	0x108140 <shllvm_constant>
  107f1c:      	movq	0x20(%r12), %rax
  107f21:      	movq	%rax, (%r12)
  107f25:      	movq	-0x38(%rbp), %r15
  107f29:      	movq	%r15, %rdi
  107f2c:      	movq	%r13, %rsi
  107f2f:      	movl	$0x1, %edx
  107f34:      	callq	0x108760 <shllvm_param>
  107f39:      	movq	-0x40(%rbp), %rdi
  107f3d:      	movq	%rbx, %rsi
  107f40:      	movl	$0x2, %edx
  107f45:      	movq	%r15, %rcx
  107f48:      	movq	%r12, %r8
  107f4b:      	callq	0x1090a0 <shllvm_binary>
  107f50:      	movq	0x10(%r12), %r15
  107f55:      	movq	%rbx, %rdi
  107f58:      	movq	%r14, %rsi
  107f5b:      	movq	%r13, %rdx
  107f5e:      	callq	0x1086c0 <shllvm_leave>
  107f63:      	movq	%r15, %rax
  107f66:      	leaq	-0x28(%rbp), %rsp
  107f6a:      	popq	%rbx
  107f6b:      	popq	%r12
  107f6d:      	popq	%r13
  107f6f:      	popq	%r14
  107f71:      	popq	%r15
  107f73:      	popq	%rbp
  107f74:      	retq
  107f75:      	nopw	%cs:(%rax,%rax)

0000000000107f80 <shllvm_f7>:
  107f80:      	pushq	%rbp
  107f81:      	movq	%rsp, %rbp
  107f84:      	pushq	%r15
  107f86:      	pushq	%r14
  107f88:      	pushq	%r13
  107f8a:      	pushq	%r12
  107f8c:      	pushq	%rbx
  107f8d:      	subq	$0x18, %rsp
  107f91:      	movq	%rdi, %rbx
  107f94:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107f99:      	movl	$0x6, %edi
  107f9e:      	callq	0x108270 <shllvm_frame_size>
  107fa3:      	movq	%rsp, %r14
  107fa6:      	addq	$0xf, %rax
  107faa:      	andq	$-0x10, %rax
  107fae:      	subq	%rax, %r14
  107fb1:      	movq	%r14, %rsp
  107fb4:      	movl	0x9932e5(%rip), %r13d   # 0xa9b2a0 <shllvm_unit_index>
  107fbb:      	movq	%rbx, %rdi
  107fbe:      	movq	%r14, %rsi
  107fc1:      	movl	$0x6, %edx
  107fc6:      	xorl	%ecx, %ecx
  107fc8:      	movl	%r13d, %r8d
  107fcb:      	callq	0x108300 <shllvm_enter>
  107fd0:      	movq	%rax, %r15
  107fd3:      	movq	%r14, %rdi
  107fd6:      	callq	0x1086b0 <shllvm_roots>
  107fdb:      	movq	%rax, %r12
  107fde:      	movq	%rbx, %rdi
  107fe1:      	movl	%r13d, %esi
  107fe4:      	callq	0x108280 <shllvm_get_unit>
  107fe9:      	leaq	0x8(%r12), %r13
  107fee:      	movq	%r13, -0x30(%rbp)
  107ff2:      	leaq	0x10(%r12), %rax
  107ff7:      	movq	%rax, -0x38(%rbp)
  107ffb:      	leaq	0x18(%r12), %rax
  108000:      	movq	%rax, -0x40(%rbp)
  108004:      	movq	%rbx, %rdi
  108007:      	movq	%r15, %rsi
  10800a:      	xorl	%edx, %edx
  10800c:      	callq	0x10a5d0 <shllvm_check_invocation>
  108011:      	movq	%r12, %rdi
  108014:      	movq	%rbx, %rsi
  108017:      	movq	%r15, %rdx
  10801a:      	callq	0x108b00 <shllvm_env_from_frame>
  10801f:      	movq	%r13, %rdi
  108022:      	movq	%r12, %rsi
  108025:      	xorl	%edx, %edx
  108027:      	callq	0x108bf0 <shllvm_env_load>
  10802c:      	movq	-0x38(%rbp), %r13
  108030:      	movq	%r13, %rdi
  108033:      	movq	%r15, %rsi
  108036:      	movl	$0x1, %edx
  10803b:      	callq	0x108760 <shllvm_param>
  108040:      	movq	-0x40(%rbp), %rdi
  108044:      	movq	%rbx, %rsi
  108047:      	xorl	%edx, %edx
  108049:      	movq	-0x30(%rbp), %rcx
  10804d:      	movq	%r13, %r8
  108050:      	callq	0x1090a0 <shllvm_binary>
  108055:      	movq	0x18(%r12), %r12
  10805a:      	movq	%rbx, %rdi
  10805d:      	movq	%r14, %rsi
  108060:      	movq	%r15, %rdx
  108063:      	callq	0x1086c0 <shllvm_leave>
  108068:      	movq	%r12, %rax
  10806b:      	leaq	-0x28(%rbp), %rsp
  10806f:      	popq	%rbx
  108070:      	popq	%r12
  108072:      	popq	%r13
  108074:      	popq	%r14
  108076:      	popq	%r15
  108078:      	popq	%rbp
  108079:      	retq
  10807a:      	nopw	(%rax,%rax)

0000000000108080 <sh_export_this_unit>:
  108080:      	pushq	%rax
  108081:      	subq	$0x8, %rsp
  108085:      	leaq	0x15d54(%rip), %rax     # 0x11dde0 <shllvm_unit_name>
  10808c:      	leaq	-0x1403(%rip), %r10     # 0x106c90 <shllvm_f0>
  108093:      	leaq	0x15d66(%rip), %r11     # 0x11de00 <shllvm_functions>
  10809a:      	leaq	0x9931ff(%rip), %rdi    # 0xa9b2a0 <shllvm_unit_index>
  1080a1:      	leaq	0x15c18(%rip), %rdx     # 0x11dcc0 <shllvm_ascii>
  1080a8:      	leaq	0x15c71(%rip), %rcx     # 0x11dd20 <shllvm_utf16>
  1080af:      	leaq	0x15c8a(%rip), %r8      # 0x11dd40 <shllvm_strings>
  1080b6:      	movl	$0x9, %esi
  1080bb:      	movl	$0x8, %r9d
  1080c1:      	pushq	%rax
  1080c2:      	pushq	%r10
  1080c4:      	pushq	%r11
  1080c6:      	callq	0x109d00 <shllvm_create_unit>
  1080cb:      	addq	$0x20, %rsp
  1080cf:      	popq	%rcx
  1080d0:      	retq
  1080d1:      	nopw	%cs:(%rax,%rax)

0000000000108270 <shllvm_frame_size>:
  108270:      	pushq	%rbp
  108271:      	movq	%rsp, %rbp
  108274:      	movl	%edi, %eax
  108276:      	leaq	0x20(,%rax,8), %rax
  10827e:      	popq	%rbp
  10827f:      	retq

