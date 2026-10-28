0000000000106ca0 <shllvm_f0>:
  106ca0:      	pushq	%rbp
  106ca1:      	movq	%rsp, %rbp
  106ca4:      	pushq	%r15
  106ca6:      	pushq	%r14
  106ca8:      	pushq	%r13
  106caa:      	pushq	%r12
  106cac:      	pushq	%rbx
  106cad:      	subq	$0x1f8, %rsp            # imm = 0x1F8
  106cb4:      	movq	%rdi, %r13
  106cb7:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  106cbc:      	movl	$0x7c, %edi
  106cc1:      	callq	0x1087b0 <shllvm_frame_size>
  106cc6:      	movq	%rsp, %rbx
  106cc9:      	addq	$0xf, %rax
  106ccd:      	andq	$-0x10, %rax
  106cd1:      	subq	%rax, %rbx
  106cd4:      	movq	%rbx, %rsp
  106cd7:      	movl	0x9955c2(%rip), %r14d   # 0xa9c2a0 <shllvm_unit_index>
  106cde:      	movq	%r13, %rdi
  106ce1:      	movq	%rbx, %rsi
  106ce4:      	movl	$0x7c, %edx
  106ce9:      	movl	$0x2, %ecx
  106cee:      	movl	%r14d, %r8d
  106cf1:      	callq	0x108840 <shllvm_enter>
  106cf6:      	movq	%rax, %r12
  106cf9:      	movq	%rax, -0x40(%rbp)
  106cfd:      	movq	%rbx, -0xb0(%rbp)
  106d04:      	movq	%rbx, %rdi
  106d07:      	callq	0x108bf0 <shllvm_roots>
  106d0c:      	movq	%rax, %rbx
  106d0f:      	movq	%rax, %r15
  106d12:      	movq	%r13, %rdi
  106d15:      	movl	%r14d, %esi
  106d18:      	callq	0x1087c0 <shllvm_get_unit>
  106d1d:      	movq	%rax, %r14
  106d20:      	movq	%rax, -0x60(%rbp)
  106d24:      	leaq	0x28(%rbx), %rax
  106d28:      	movq	%rax, -0x58(%rbp)
  106d2c:      	leaq	0x58(%rbx), %rax
  106d30:      	movq	%rax, -0x70(%rbp)
  106d34:      	leaq	0xf8(%rbx), %rax
  106d3b:      	movq	%rax, -0x78(%rbp)
  106d3f:      	leaq	0x358(%rbx), %rax
  106d46:      	movq	%rax, -0xe8(%rbp)
  106d4d:      	leaq	0x360(%rbx), %rax
  106d54:      	movq	%rax, -0xf8(%rbp)
  106d5b:      	leaq	0x368(%rbx), %rax
  106d62:      	movq	%rax, -0x100(%rbp)
  106d69:      	leaq	0x370(%rbx), %rax
  106d70:      	movq	%rax, -0x108(%rbp)
  106d77:      	leaq	0x378(%rbx), %rax
  106d7e:      	movq	%rax, -0x110(%rbp)
  106d85:      	leaq	0x380(%rbx), %rax
  106d8c:      	movq	%rax, -0x118(%rbp)
  106d93:      	leaq	0x388(%rbx), %rax
  106d9a:      	movq	%rax, -0x120(%rbp)
  106da1:      	leaq	0x390(%rbx), %rax
  106da8:      	movq	%rax, -0x128(%rbp)
  106daf:      	leaq	0x398(%rbx), %rax
  106db6:      	movq	%rax, -0x130(%rbp)
  106dbd:      	leaq	0x3a0(%rbx), %rax
  106dc4:      	movq	%rax, -0x138(%rbp)
  106dcb:      	leaq	0x3a8(%rbx), %rax
  106dd2:      	movq	%rax, -0x148(%rbp)
  106dd9:      	leaq	0x3b0(%rbx), %rax
  106de0:      	movq	%rax, -0x150(%rbp)
  106de7:      	leaq	0x3b8(%rbx), %rax
  106dee:      	movq	%rax, -0x158(%rbp)
  106df5:      	leaq	0x3c0(%rbx), %rax
  106dfc:      	movq	%rax, -0x168(%rbp)
  106e03:      	leaq	0x3c8(%rbx), %rax
  106e0a:      	movq	%rax, -0x170(%rbp)
  106e11:      	leaq	0x3d0(%rbx), %rax
  106e18:      	movq	%rax, -0x180(%rbp)
  106e1f:      	movq	%r13, %rdi
  106e22:      	movq	%r12, %rsi
  106e25:      	xorl	%edx, %edx
  106e27:      	callq	0x10ab10 <shllvm_check_invocation>
  106e2c:      	movq	-0xe8(%rbp), %rdi
  106e33:      	movq	%r13, %rsi
  106e36:      	movq	%r14, %rdx
  106e39:      	movl	$0x1, %ecx
  106e3e:      	callq	0x108d60 <shllvm_symbol>
  106e43:      	movq	-0xf8(%rbp), %rdi
  106e4a:      	movq	%r13, %rsi
  106e4d:      	movq	%r14, %rdx
  106e50:      	movl	$0x2, %ecx
  106e55:      	callq	0x108d60 <shllvm_symbol>
  106e5a:      	xorl	%eax, %eax
  106e5c:      	movl	%eax, %r12d
  106e5f:      	movq	-0x100(%rbp), %rdi
  106e66:      	movl	$0x4, %esi
  106e6b:      	movq	%r12, %rdx
  106e6e:      	callq	0x108680 <shllvm_constant>
  106e73:      	movq	-0x108(%rbp), %rdi
  106e7a:      	xorl	%esi, %esi
  106e7c:      	movq	%r12, %rdx
  106e7f:      	callq	0x108680 <shllvm_constant>
  106e84:      	movq	-0x110(%rbp), %rdi
  106e8b:      	movq	%r13, %rsi
  106e8e:      	movq	%r14, %rdx
  106e91:      	movl	$0x5, %ecx
  106e96:      	callq	0x108d60 <shllvm_symbol>
  106e9b:      	movq	-0x118(%rbp), %rdi
  106ea2:      	movl	$0x3, %esi
  106ea7:      	movq	%r12, %rdx
  106eaa:      	callq	0x108680 <shllvm_constant>
  106eaf:      	movq	-0x120(%rbp), %rdi
  106eb6:      	movl	$0x2, %esi
  106ebb:      	movq	%r12, %rdx
  106ebe:      	callq	0x108680 <shllvm_constant>
  106ec3:      	movabsq	$0x4008000000000000, %rdx # imm = 0x4008000000000000
  106ecd:      	movq	-0x128(%rbp), %rdi
  106ed4:      	movl	$0x3, %esi
  106ed9:      	callq	0x108680 <shllvm_constant>
  106ede:      	movq	-0x130(%rbp), %rdi
  106ee5:      	movq	%r13, %rsi
  106ee8:      	movq	%r14, %rdx
  106eeb:      	movl	$0x6, %ecx
  106ef0:      	callq	0x108d60 <shllvm_symbol>
  106ef5:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  106eff:      	movq	-0x138(%rbp), %rdi
  106f06:      	movl	$0x3, %esi
  106f0b:      	callq	0x108680 <shllvm_constant>
  106f10:      	movabsq	$0x4010000000000000, %rdx # imm = 0x4010000000000000
  106f1a:      	movq	-0x148(%rbp), %rdi
  106f21:      	movl	$0x3, %esi
  106f26:      	callq	0x108680 <shllvm_constant>
  106f2b:      	movq	-0x150(%rbp), %rdi
  106f32:      	movq	%r13, %rsi
  106f35:      	movq	%r14, %rdx
  106f38:      	movl	$0x3, %ecx
  106f3d:      	callq	0x108d60 <shllvm_symbol>
  106f42:      	movq	-0x158(%rbp), %rdi
  106f49:      	movq	%r13, %rsi
  106f4c:      	movq	%r14, %rdx
  106f4f:      	movl	$0x7, %ecx
  106f54:      	callq	0x108d60 <shllvm_symbol>
  106f59:      	movq	-0x168(%rbp), %rdi
  106f60:      	movq	%r13, %rsi
  106f63:      	movq	%r14, %rdx
  106f66:      	movl	$0x8, %ecx
  106f6b:      	callq	0x108d60 <shllvm_symbol>
  106f70:      	movl	$0x1, %edx
  106f75:      	movq	-0x170(%rbp), %rdi
  106f7c:      	movl	$0x2, %esi
  106f81:      	callq	0x108680 <shllvm_constant>
  106f86:      	movq	-0x180(%rbp), %rdi
  106f8d:      	movq	%r13, %rsi
  106f90:      	movq	%r14, %rdx
  106f93:      	movl	$0x9, %ecx
  106f98:      	callq	0x108d60 <shllvm_symbol>
  106f9d:      	callq	0x10af10 <shllvm_try_size>
  106fa2:      	movq	%rsp, %r12
  106fa5:      	addq	$0xf, %rax
  106fa9:      	andq	$-0x10, %rax
  106fad:      	subq	%rax, %r12
  106fb0:      	movq	%r12, %rsp
  106fb3:      	movl	$0x0, -0x2c(%rbp)
  106fba:      	movq	%r13, %rdi
  106fbd:      	movq	%r12, %rsi
  106fc0:      	callq	0x10af20 <shllvm_try_begin>
  106fc5:      	movq	%rax, %rdi
  106fc8:      	callq	0x2d5b0 <_setjmp@plt>
  106fcd:      	testl	%eax, %eax
  106fcf:      	movq	%r13, -0x38(%rbp)
  106fd3:      	movq	%r12, -0xa8(%rbp)
  106fda:      	movq	%rbx, -0x68(%rbp)
  106fde:      	je	0x1070d4 <shllvm_f0+0x434>
  106fe4:      	movl	-0x2c(%rbp), %r14d
  106fe8:      	movq	%r13, %rdi
  106feb:      	movq	-0xb0(%rbp), %rsi
  106ff2:      	movq	-0x40(%rbp), %rdx
  106ff6:      	movl	$0x2, %ecx
  106ffb:      	callq	0x10afb0 <shllvm_catch_prepare>
  107000:      	cmpl	$0x2, %r14d
  107004:      	jne	0x10775f <shllvm_f0+0xabf>
  10700a:      	movq	-0x68(%rbp), %rbx
  10700e:      	leaq	0x288(%rbx), %r13
  107015:      	leaq	0x290(%rbx), %r14
  10701c:      	leaq	0x298(%rbx), %rax
  107023:      	movq	%rax, -0xc0(%rbp)
  10702a:      	leaq	0x2a0(%rbx), %rax
  107031:      	movq	%rax, -0xf0(%rbp)
  107038:      	movl	$0x0, -0x2c(%rbp)
  10703f:      	movq	%r13, %rdi
  107042:      	movq	-0x38(%rbp), %rsi
  107046:      	callq	0x10afc0 <shllvm_catch_value>
  10704b:      	movq	%r14, %rdi
  10704e:      	movq	-0x38(%rbp), %rsi
  107052:      	movq	-0x60(%rbp), %r12
  107056:      	movq	%r12, %rdx
  107059:      	movq	-0x58(%rbp), %rcx
  10705d:      	movl	$0x5, %r8d
  107063:      	movl	$0x1, %r9d
  107069:      	callq	0x109c40 <shllvm_get_id>
  10706e:      	movq	-0xc0(%rbp), %rdi
  107075:      	movq	-0x38(%rbp), %rsi
  107079:      	movq	%r12, %rdx
  10707c:      	movq	%r13, %rcx
  10707f:      	movq	-0x38(%rbp), %r13
  107083:      	movl	$0x7, %r8d
  107089:      	xorl	%r9d, %r9d
  10708c:      	callq	0x109c40 <shllvm_get_id>
  107091:      	movq	0x298(%r15), %rax
  107098:      	movq	%rax, -0x50(%rbp)
  10709c:      	leaq	-0x50(%rbp), %rax
  1070a0:      	movq	-0xf0(%rbp), %rdi
  1070a7:      	movq	%r13, %rsi
  1070aa:      	movq	-0x40(%rbp), %rdx
  1070ae:      	movq	%r14, %rcx
  1070b1:      	movq	-0x70(%rbp), %r8
  1070b5:      	movq	%r8, %r9
  1070b8:      	pushq	%rax
  1070b9:      	pushq	$0x1
  1070bb:      	callq	0x109310 <shllvm_call>
  1070c0:      	addq	$0x10, %rsp
  1070c4:      	movq	0x2a0(%r15), %rax
  1070cb:      	movq	%rax, 0x50(%r15)
  1070cf:      	jmp	0x1079b5 <shllvm_f0+0xd15>
  1070d4:      	leaq	0x108(%rbx), %rax
  1070db:      	movq	%rax, -0x1f0(%rbp)
  1070e2:      	leaq	0x118(%rbx), %rax
  1070e9:      	movq	%rax, -0x208(%rbp)
  1070f0:      	leaq	0x130(%rbx), %rax
  1070f7:      	movq	%rax, -0x200(%rbp)
  1070fe:      	leaq	0x148(%rbx), %rax
  107105:      	movq	%rax, -0x1e8(%rbp)
  10710c:      	leaq	0x150(%rbx), %rax
  107113:      	movq	%rax, -0x1e0(%rbp)
  10711a:      	leaq	0x198(%rbx), %rax
  107121:      	movq	%rax, -0x1d8(%rbp)
  107128:      	leaq	0x1b0(%rbx), %rax
  10712f:      	movq	%rax, -0x1d0(%rbp)
  107136:      	leaq	0x1d0(%rbx), %rax
  10713d:      	movq	%rax, -0x1c8(%rbp)
  107144:      	leaq	0x200(%rbx), %rax
  10714b:      	movq	%rax, -0x1c0(%rbp)
  107152:      	leaq	0x208(%rbx), %rax
  107159:      	movq	%rax, -0x1b8(%rbp)
  107160:      	leaq	0x238(%rbx), %rax
  107167:      	movq	%rax, -0x1f8(%rbp)
  10716e:      	leaq	0x268(%rbx), %rax
  107175:      	movq	%rax, -0x1b0(%rbp)
  10717c:      	leaq	0x2c0(%rbx), %rax
  107183:      	movq	%rax, -0x220(%rbp)
  10718a:      	leaq	0x2c8(%rbx), %rax
  107191:      	movq	%rax, -0xa0(%rbp)
  107198:      	leaq	0x2d0(%rbx), %rax
  10719f:      	movq	%rax, -0x218(%rbp)
  1071a6:      	leaq	0x2d8(%rbx), %rax
  1071ad:      	movq	%rax, -0x210(%rbp)
  1071b4:      	leaq	0xc8(%rbx), %rax
  1071bb:      	movq	%rax, -0x1a0(%rbp)
  1071c2:      	leaq	0xc0(%rbx), %rax
  1071c9:      	movq	%rax, -0x198(%rbp)
  1071d0:      	leaq	0xb8(%rbx), %rax
  1071d7:      	movq	%rax, -0x90(%rbp)
  1071de:      	leaq	0xb0(%rbx), %rax
  1071e5:      	movq	%rax, -0x98(%rbp)
  1071ec:      	leaq	0xa0(%rbx), %rax
  1071f3:      	movq	%rax, -0x190(%rbp)
  1071fa:      	leaq	0x98(%rbx), %rax
  107201:      	movq	%rax, -0x188(%rbp)
  107208:      	leaq	0x88(%rbx), %rax
  10720f:      	movq	%rax, -0x178(%rbp)
  107216:      	leaq	0x80(%rbx), %rax
  10721d:      	movq	%rax, -0x160(%rbp)
  107224:      	leaq	0x78(%rbx), %rax
  107228:      	movq	%rax, -0x1a8(%rbp)
  10722f:      	leaq	0x70(%rbx), %rax
  107233:      	movq	%rax, -0x140(%rbp)
  10723a:      	leaq	0x68(%rbx), %rax
  10723e:      	movq	%rax, -0x88(%rbp)
  107245:      	leaq	0x40(%rbx), %rax
  107249:      	movq	%rax, -0x80(%rbp)
  10724d:      	leaq	0x30(%rbx), %r12
  107251:      	movq	%r13, %rbx
  107254:      	movq	%r13, %rdi
  107257:      	movq	-0x60(%rbp), %r14
  10725b:      	movq	%r14, %rsi
  10725e:      	movl	$0x1, %edx
  107263:      	callq	0x108e60 <shllvm_declare_global>
  107268:      	movq	%r13, %rdi
  10726b:      	movq	%r14, %rsi
  10726e:      	movl	$0x2, %edx
  107273:      	callq	0x108e60 <shllvm_declare_global>
  107278:      	movq	0x368(%r15), %rax
  10727f:      	movq	%rax, 0x18(%r15)
  107283:      	movq	0x18(%r15), %rax
  107287:      	movq	%rax, (%r15)
  10728a:      	movq	-0x58(%rbp), %r13
  10728e:      	movq	%r13, %rdi
  107291:      	movq	%rbx, %rsi
  107294:      	callq	0x108d20 <shllvm_global>
  107299:      	leaq	0x8c0(%rip), %r8        # 0x107b60 <shllvm_f1>
  1072a0:      	xorl	%eax, %eax
  1072a2:      	movl	%eax, %edx
  1072a4:      	movq	%rdx, -0xd0(%rbp)
  1072ab:      	movq	%r12, %rdi
  1072ae:      	movq	%rbx, %rsi
  1072b1:      	movq	%r14, %rcx
  1072b4:      	movl	$0x1, %r9d
  1072ba:      	callq	0x1091e0 <shllvm_closure>
  1072bf:      	subq	$0x8, %rsp
  1072c3:      	movq	%rbx, %rdi
  1072c6:      	movq	%r14, %rsi
  1072c9:      	movq	%r13, %rdx
  1072cc:      	movl	$0x1, %ecx
  1072d1:      	movq	%r12, %r8
  1072d4:      	xorl	%r9d, %r9d
  1072d7:      	pushq	$0x0
  1072d9:      	callq	0x109db0 <shllvm_set_id>
  1072de:      	addq	$0x10, %rsp
  1072e2:      	leaq	0xfe7(%rip), %r8        # 0x1082d0 <shllvm_f2>
  1072e9:      	movq	-0x80(%rbp), %rdi
  1072ed:      	movq	%rbx, %rsi
  1072f0:      	movq	-0xd0(%rbp), %rdx
  1072f7:      	movq	%r14, %rcx
  1072fa:      	movl	$0x2, %r9d
  107300:      	callq	0x1091e0 <shllvm_closure>
  107305:      	subq	$0x8, %rsp
  107309:      	movq	%rbx, %rdi
  10730c:      	movq	%r14, %rsi
  10730f:      	movq	%r13, %rdx
  107312:      	movl	$0x2, %ecx
  107317:      	movq	-0x80(%rbp), %r8
  10731b:      	xorl	%r9d, %r9d
  10731e:      	pushq	$0x0
  107320:      	callq	0x109db0 <shllvm_set_id>
  107325:      	addq	$0x10, %rsp
  107329:      	movq	0x370(%r15), %rax
  107330:      	movq	%rax, 0x58(%r15)
  107334:      	movq	0x58(%r15), %rax
  107338:      	movq	%rax, 0x50(%r15)
  10733c:      	movq	-0x88(%rbp), %rdi
  107343:      	movq	%rbx, %rsi
  107346:      	movq	%r14, %rdx
  107349:      	movq	%r13, %rcx
  10734c:      	movl	$0x5, %r8d
  107352:      	movl	$0x1, %r9d
  107358:      	callq	0x109c40 <shllvm_get_id>
  10735d:      	movq	-0x140(%rbp), %r12
  107364:      	movq	%r12, %rdi
  107367:      	movq	%rbx, %rsi
  10736a:      	movq	%r14, %rdx
  10736d:      	movq	%r13, %rcx
  107370:      	movl	$0x1, %r8d
  107376:      	xorl	%r9d, %r9d
  107379:      	callq	0x109c40 <shllvm_get_id>
  10737e:      	movq	0x380(%r15), %rax
  107385:      	movq	%rax, 0x78(%r15)
  107389:      	movq	0x78(%r15), %rax
  10738d:      	movq	%rax, -0x50(%rbp)
  107391:      	leaq	-0x50(%rbp), %rax
  107395:      	movq	-0x160(%rbp), %rdi
  10739c:      	movq	%rbx, %rsi
  10739f:      	movq	-0x40(%rbp), %rdx
  1073a3:      	movq	%r12, %rcx
  1073a6:      	movq	-0x70(%rbp), %r13
  1073aa:      	movq	%r13, %r8
  1073ad:      	movq	%r13, %r9
  1073b0:      	pushq	%rax
  1073b1:      	pushq	$0x1
  1073b3:      	callq	0x109310 <shllvm_call>
  1073b8:      	addq	$0x10, %rsp
  1073bc:      	movq	-0x178(%rbp), %r12
  1073c3:      	movq	%r12, %rdi
  1073c6:      	movq	%rbx, %rsi
  1073c9:      	movq	%r14, %rdx
  1073cc:      	movq	-0x58(%rbp), %rcx
  1073d0:      	movl	$0x1, %r8d
  1073d6:      	xorl	%r9d, %r9d
  1073d9:      	callq	0x109c40 <shllvm_get_id>
  1073de:      	movq	0x390(%r15), %rax
  1073e5:      	movq	%rax, 0x90(%r15)
  1073ec:      	movq	0x90(%r15), %rax
  1073f3:      	movq	%rax, -0x50(%rbp)
  1073f7:      	movq	-0x188(%rbp), %rdi
  1073fe:      	movq	%rbx, %rsi
  107401:      	movq	-0x40(%rbp), %r14
  107405:      	movq	%r14, %rdx
  107408:      	movq	%r12, %rcx
  10740b:      	movq	%r13, %r8
  10740e:      	movq	%r13, %r9
  107411:      	leaq	-0x50(%rbp), %r12
  107415:      	pushq	%r12
  107417:      	pushq	$0x1
  107419:      	callq	0x109310 <shllvm_call>
  10741e:      	addq	$0x10, %rsp
  107422:      	movq	0x80(%r15), %rax
  107429:      	movq	%rax, -0x50(%rbp)
  10742d:      	movq	0x98(%r15), %rax
  107434:      	movq	%rax, -0x48(%rbp)
  107438:      	movq	-0x190(%rbp), %rdi
  10743f:      	movq	%rbx, %rsi
  107442:      	movq	%r14, %rdx
  107445:      	movq	-0x88(%rbp), %rcx
  10744c:      	movq	%r13, %r8
  10744f:      	movq	%r13, %r9
  107452:      	pushq	%r12
  107454:      	pushq	$0x2
  107456:      	callq	0x109310 <shllvm_call>
  10745b:      	addq	$0x10, %rsp
  10745f:      	movq	0xa0(%r15), %rax
  107466:      	movq	%rax, 0x50(%r15)
  10746a:      	movq	-0x98(%rbp), %rdi
  107471:      	movq	%rbx, %rsi
  107474:      	movq	-0x60(%rbp), %r12
  107478:      	movq	%r12, %rdx
  10747b:      	movq	-0x58(%rbp), %r14
  10747f:      	movq	%r14, %rcx
  107482:      	movl	$0x5, %r8d
  107488:      	movl	$0x1, %r9d
  10748e:      	callq	0x109c40 <shllvm_get_id>
  107493:      	movq	-0x90(%rbp), %rdi
  10749a:      	movq	%rbx, %rsi
  10749d:      	movq	%r12, %rdx
  1074a0:      	movq	%r14, %rcx
  1074a3:      	movl	$0x2, %r8d
  1074a9:      	xorl	%r9d, %r9d
  1074ac:      	callq	0x109c40 <shllvm_get_id>
  1074b1:      	movq	-0x198(%rbp), %rdi
  1074b8:      	movq	%rbx, %rsi
  1074bb:      	movq	-0x40(%rbp), %r14
  1074bf:      	movq	%r14, %rdx
  1074c2:      	movq	-0x90(%rbp), %rcx
  1074c9:      	movq	%r13, %r8
  1074cc:      	movq	%r13, %r9
  1074cf:      	leaq	-0x50(%rbp), %r12
  1074d3:      	pushq	%r12
  1074d5:      	pushq	$0x0
  1074d7:      	callq	0x109310 <shllvm_call>
  1074dc:      	addq	$0x10, %rsp
  1074e0:      	movq	0xc0(%r15), %rax
  1074e7:      	movq	%rax, -0x50(%rbp)
  1074eb:      	movq	-0x1a0(%rbp), %rdi
  1074f2:      	movq	%rbx, %rsi
  1074f5:      	movq	%r14, %rdx
  1074f8:      	movq	-0x98(%rbp), %rcx
  1074ff:      	movq	%r13, %r8
  107502:      	movq	%r13, %r9
  107505:      	pushq	%r12
  107507:      	pushq	$0x1
  107509:      	callq	0x109310 <shllvm_call>
  10750e:      	addq	$0x10, %rsp
  107512:      	movq	0xc8(%r15), %rax
  107519:      	movq	%rax, 0x50(%r15)
  10751d:      	movq	0x398(%r15), %rax
  107524:      	movq	%rax, 0xd8(%r15)
  10752b:      	movq	0xd8(%r15), %rax
  107532:      	movq	%rax, (%r15)
  107535:      	movq	0x3a0(%r15), %rax
  10753c:      	movq	%rax, 0xe8(%r15)
  107543:      	movq	0x3a8(%r15), %rax
  10754a:      	movq	%rax, 0xf0(%r15)
  107551:      	movq	0x3b0(%r15), %rax
  107558:      	movq	%rax, 0xf8(%r15)
  10755f:      	movq	-0x1a8(%rbp), %rcx
  107566:      	movq	%r13, %rbx
  107569:      	movq	-0x78(%rbp), %r13
  10756d:      	jmp	0x107636 <shllvm_f0+0x996>
  107572:      	nopw	%cs:(%rax,%rax)
  107580:      	movl	$0x0, -0x2c(%rbp)
  107587:      	movq	(%r15), %rax
  10758a:      	movq	%rax, 0x1c0(%r15)
  107591:      	movq	0x1c0(%r15), %rax
  107598:      	movq	%rax, 0x1c8(%r15)
  10759f:      	movq	0x1c8(%r15), %rax
  1075a6:      	movq	%rax, 0x1d0(%r15)
  1075ad:      	movq	-0x1c8(%rbp), %r14
  1075b4:      	movq	%r14, %rdi
  1075b7:      	movq	-0x38(%rbp), %rsi
  1075bb:      	xorl	%edx, %edx
  1075bd:      	movq	%r14, %rcx
  1075c0:      	movq	%r13, %r8
  1075c3:      	callq	0x1095e0 <shllvm_binary>
  1075c8:      	movq	(%r14), %rcx
  1075cb:      	movq	%rcx, (%r15)
  1075ce:      	movq	(%r14), %rax
  1075d1:      	movq	%rax, 0x50(%r15)
  1075d5:      	movsd	0x108(%r15), %xmm0
  1075de:      	addsd	0xe8(%r15), %xmm0
  1075e7:      	movq	-0x1e8(%rbp), %r12
  1075ee:      	movq	%r12, %rdi
  1075f1:      	callq	0x108750 <shllvm_number>
  1075f6:      	movsd	0x148(%r15), %xmm0
  1075ff:      	movsd	0xf0(%r15), %xmm1
  107608:      	xorl	%esi, %esi
  10760a:      	ucomisd	%xmm0, %xmm1
  10760e:      	seta	%al
  107611:      	movb	%al, %sil
  107614:      	movq	-0x1e0(%rbp), %r14
  10761b:      	movq	%r14, %rdi
  10761e:      	callq	0x108780 <shllvm_boolean>
  107623:      	movq	%r14, %rdi
  107626:      	callq	0x109ae0 <shllvm_truthy>
  10762b:      	movq	%r12, %rcx
  10762e:      	testl	%eax, %eax
  107630:      	je	0x10788d <shllvm_f0+0xbed>
  107636:      	movq	(%rcx), %rax
  107639:      	movq	%rax, 0x108(%r15)
  107640:      	movl	$0x1, -0x2c(%rbp)
  107647:      	movsd	0x108(%r15), %xmm0
  107650:      	cmpeqsd	0xe8(%r15), %xmm0
  10765a:      	movq	%xmm0, %rax
  10765f:      	movl	%eax, %esi
  107661:      	andl	$0x1, %esi
  107664:      	movq	-0x1d8(%rbp), %r14
  10766b:      	movq	%r14, %rdi
  10766e:      	callq	0x108780 <shllvm_boolean>
  107673:      	movq	%r14, %rdi
  107676:      	callq	0x109ae0 <shllvm_truthy>
  10767b:      	testl	%eax, %eax
  10767d:      	jne	0x107580 <shllvm_f0+0x8e0>
  107683:      	movsd	0x108(%r15), %xmm0
  10768c:      	cmpeqsd	0x90(%r15), %xmm0
  107696:      	movq	%xmm0, %rax
  10769b:      	movl	%eax, %esi
  10769d:      	andl	$0x1, %esi
  1076a0:      	movq	-0x1d0(%rbp), %r14
  1076a7:      	movq	%r14, %rdi
  1076aa:      	callq	0x108780 <shllvm_boolean>
  1076af:      	movq	%r14, %rdi
  1076b2:      	callq	0x109ae0 <shllvm_truthy>
  1076b7:      	testl	%eax, %eax
  1076b9:      	jne	0x107833 <shllvm_f0+0xb93>
  1076bf:      	movq	(%r15), %rax
  1076c2:      	movq	%rax, 0x1f8(%r15)
  1076c9:      	movq	0x1f8(%r15), %rax
  1076d0:      	movq	%rax, 0x200(%r15)
  1076d7:      	movq	-0x1b8(%rbp), %rdi
  1076de:      	movq	%rbx, %r13
  1076e1:      	movq	-0x38(%rbp), %r12
  1076e5:      	movq	%r12, %rsi
  1076e8:      	xorl	%ebx, %ebx
  1076ea:      	movl	%ebx, %edx
  1076ec:      	movq	-0x1c0(%rbp), %rcx
  1076f3:      	movq	-0x1f0(%rbp), %r8
  1076fa:      	callq	0x1095e0 <shllvm_binary>
  1076ff:      	movq	0x208(%r15), %rax
  107706:      	movq	%rax, (%r15)
  107709:      	movq	0x208(%r15), %rax
  107710:      	movq	%rax, 0x50(%r15)
  107714:      	movl	$0x0, -0x2c(%rbp)
  10771b:      	movq	(%r15), %rax
  10771e:      	movq	%rax, 0x258(%r15)
  107725:      	movq	0x258(%r15), %rax
  10772c:      	movq	%rax, 0x260(%r15)
  107733:      	movq	0x260(%r15), %rax
  10773a:      	movq	%rax, 0x268(%r15)
  107741:      	movq	-0x1b0(%rbp), %r14
  107748:      	movq	%r14, %rdi
  10774b:      	movq	%r12, %rsi
  10774e:      	movq	%r13, %rax
  107751:      	movq	-0x78(%rbp), %r13
  107755:      	movl	%ebx, %edx
  107757:      	movq	%rax, %rbx
  10775a:      	jmp	0x1075bd <shllvm_f0+0x91d>
  10775f:      	cmpl	$0x3, %r14d
  107763:      	movq	-0x68(%rbp), %rbx
  107767:      	jne	0x107aaf <shllvm_f0+0xe0f>
  10776d:      	leaq	0x2f0(%rbx), %r12
  107774:      	leaq	0x2f8(%rbx), %r14
  10777b:      	movq	%r14, -0xe0(%rbp)
  107782:      	leaq	0x300(%rbx), %rax
  107789:      	movq	%rax, -0xc8(%rbp)
  107790:      	addq	$0x308, %rbx            # imm = 0x308
  107797:      	movl	$0x0, -0x2c(%rbp)
  10779e:      	movq	%r12, %rdi
  1077a1:      	movq	-0x38(%rbp), %r13
  1077a5:      	movq	%r13, %rsi
  1077a8:      	callq	0x10afc0 <shllvm_catch_value>
  1077ad:      	movq	%r14, %rdi
  1077b0:      	movq	%r13, %rsi
  1077b3:      	movq	-0x60(%rbp), %r14
  1077b7:      	movq	%r14, %rdx
  1077ba:      	movq	-0x58(%rbp), %rcx
  1077be:      	movl	$0x5, %r8d
  1077c4:      	movl	$0x1, %r9d
  1077ca:      	callq	0x109c40 <shllvm_get_id>
  1077cf:      	movq	-0xc8(%rbp), %rdi
  1077d6:      	movq	%r13, %rsi
  1077d9:      	movq	%r14, %rdx
  1077dc:      	movq	%r12, %rcx
  1077df:      	movl	$0x7, %r8d
  1077e5:      	xorl	%r9d, %r9d
  1077e8:      	callq	0x109c40 <shllvm_get_id>
  1077ed:      	movq	0x300(%r15), %rax
  1077f4:      	movq	%rax, -0x50(%rbp)
  1077f8:      	leaq	-0x50(%rbp), %rax
  1077fc:      	movq	%rbx, %rdi
  1077ff:      	movq	%r13, %rsi
  107802:      	movq	-0x40(%rbp), %rbx
  107806:      	movq	%rbx, %rdx
  107809:      	movq	-0xe0(%rbp), %rcx
  107810:      	movq	-0x70(%rbp), %r8
  107814:      	movq	%r8, %r9
  107817:      	pushq	%rax
  107818:      	pushq	$0x1
  10781a:      	callq	0x109310 <shllvm_call>
  10781f:      	addq	$0x10, %rsp
  107823:      	movq	0x308(%r15), %rax
  10782a:      	movq	%rax, 0x50(%r15)
  10782e:      	jmp	0x107a6a <shllvm_f0+0xdca>
  107833:      	movl	$0x0, -0x2c(%rbp)
  10783a:      	movq	(%r15), %rax
  10783d:      	movq	%rax, 0x228(%r15)
  107844:      	movq	0x228(%r15), %rax
  10784b:      	movq	%rax, 0x230(%r15)
  107852:      	movq	0x230(%r15), %rax
  107859:      	movq	%rax, 0x238(%r15)
  107860:      	movq	-0x1f8(%rbp), %rcx
  107867:      	movq	%rcx, %rdi
  10786a:      	movq	-0x38(%rbp), %rsi
  10786e:      	xorl	%edx, %edx
  107870:      	movq	%r13, %r8
  107873:      	callq	0x1095e0 <shllvm_binary>
  107878:      	movq	0x238(%r15), %rax
  10787f:      	movq	%rax, (%r15)
  107882:      	movq	0x238(%r15), %rax
  107889:      	movq	%rax, 0x50(%r15)
  10788d:      	movq	-0x208(%rbp), %r14
  107894:      	movq	%r14, %rdi
  107897:      	movq	-0x38(%rbp), %r13
  10789b:      	movq	%r13, %rsi
  10789e:      	movq	-0x60(%rbp), %rdx
  1078a2:      	movq	-0x58(%rbp), %rcx
  1078a6:      	movl	$0x5, %r8d
  1078ac:      	movl	$0x1, %r9d
  1078b2:      	callq	0x109c40 <shllvm_get_id>
  1078b7:      	movq	(%r15), %rax
  1078ba:      	movq	%rax, 0x120(%r15)
  1078c1:      	movq	0x120(%r15), %rax
  1078c8:      	movq	%rax, 0x128(%r15)
  1078cf:      	movq	0x128(%r15), %rax
  1078d6:      	movq	%rax, -0x50(%rbp)
  1078da:      	movq	-0x200(%rbp), %rdi
  1078e1:      	movq	%r13, %rsi
  1078e4:      	movq	-0x40(%rbp), %rdx
  1078e8:      	movq	%r14, %rcx
  1078eb:      	movq	%rbx, %r8
  1078ee:      	movq	%rbx, %r9
  1078f1:      	leaq	-0x50(%rbp), %r12
  1078f5:      	pushq	%r12
  1078f7:      	pushq	$0x1
  1078f9:      	callq	0x109310 <shllvm_call>
  1078fe:      	addq	$0x10, %rsp
  107902:      	movq	0x130(%r15), %rax
  107909:      	movq	%rax, 0x50(%r15)
  10790d:      	movl	$0x2, -0x2c(%rbp)
  107914:      	leaq	0xb25(%rip), %r8        # 0x108440 <shllvm_f3>
  10791b:      	xorl	%eax, %eax
  10791d:      	movl	%eax, %edx
  10791f:      	movq	-0x220(%rbp), %r14
  107926:      	movq	%r14, %rdi
  107929:      	movq	%r13, %rsi
  10792c:      	movq	-0x60(%rbp), %r12
  107930:      	movq	%r12, %rcx
  107933:      	movl	$0x3, %r9d
  107939:      	callq	0x1091e0 <shllvm_closure>
  10793e:      	movq	-0xa0(%rbp), %rdi
  107945:      	movq	%r13, %rsi
  107948:      	movq	%r12, %rdx
  10794b:      	movq	%r14, %rcx
  10794e:      	movl	$0x8, %r8d
  107954:      	xorl	%r9d, %r9d
  107957:      	callq	0x109c40 <shllvm_get_id>
  10795c:      	movq	-0x218(%rbp), %rbx
  107963:      	movq	%rbx, %rdi
  107966:      	movq	%r13, %rsi
  107969:      	movq	%r12, %rdx
  10796c:      	movq	-0xa0(%rbp), %rcx
  107973:      	callq	0x109b80 <shllvm_object_parent>
  107978:      	movq	-0x210(%rbp), %rdi
  10797f:      	movq	%r13, %rsi
  107982:      	movq	-0x40(%rbp), %rdx
  107986:      	movq	%r14, %rcx
  107989:      	movq	%rbx, %r8
  10798c:      	movq	%r14, %r9
  10798f:      	leaq	-0x50(%rbp), %rax
  107993:      	pushq	%rax
  107994:      	pushq	$0x0
  107996:      	callq	0x109310 <shllvm_call>
  10799b:      	addq	$0x10, %rsp
  10799f:      	movq	0x2d0(%r15), %rax
  1079a6:      	movq	%rax, 0x50(%r15)
  1079aa:      	movl	$0x0, -0x2c(%rbp)
  1079b1:      	movq	-0x68(%rbp), %rbx
  1079b5:      	leaq	0x330(%rbx), %rdi
  1079bc:      	movq	%rdi, -0xd8(%rbp)
  1079c3:      	leaq	0x338(%rbx), %rax
  1079ca:      	movq	%rax, -0xb8(%rbp)
  1079d1:      	addq	$0x340, %rbx            # imm = 0x340
  1079d8:      	movl	$0x3, -0x2c(%rbp)
  1079df:      	movq	%r13, %rsi
  1079e2:      	movq	-0x60(%rbp), %r14
  1079e6:      	movq	%r14, %rdx
  1079e9:      	movq	-0x58(%rbp), %r12
  1079ed:      	movq	%r12, %rcx
  1079f0:      	movl	$0x5, %r8d
  1079f6:      	movl	$0x1, %r9d
  1079fc:      	callq	0x109c40 <shllvm_get_id>
  107a01:      	movq	-0xb8(%rbp), %rdi
  107a08:      	movq	%r13, %rsi
  107a0b:      	movq	%r14, %rdx
  107a0e:      	movq	%r12, %rcx
  107a11:      	movl	$0x9, %r8d
  107a17:      	movl	$0x1, %r9d
  107a1d:      	callq	0x109c40 <shllvm_get_id>
  107a22:      	movq	0x338(%r15), %rax
  107a29:      	movq	%rax, -0x50(%rbp)
  107a2d:      	leaq	-0x50(%rbp), %rax
  107a31:      	movq	%rbx, %rdi
  107a34:      	movq	%r13, %rsi
  107a37:      	movq	-0x40(%rbp), %rbx
  107a3b:      	movq	%rbx, %rdx
  107a3e:      	movq	-0xd8(%rbp), %rcx
  107a45:      	movq	-0x70(%rbp), %r8
  107a49:      	movq	%r8, %r9
  107a4c:      	pushq	%rax
  107a4d:      	pushq	$0x1
  107a4f:      	callq	0x109310 <shllvm_call>
  107a54:      	addq	$0x10, %rsp
  107a58:      	movq	0x340(%r15), %rax
  107a5f:      	movq	%rax, 0x50(%r15)
  107a63:      	movl	$0x0, -0x2c(%rbp)
  107a6a:      	movq	0x50(%r15), %rax
  107a6e:      	movq	%rax, 0x320(%r15)
  107a75:      	movq	0x320(%r15), %r14
  107a7c:      	movq	%r13, %rdi
  107a7f:      	movq	-0xa8(%rbp), %rsi
  107a86:      	callq	0x10af70 <shllvm_try_end>
  107a8b:      	movq	%r13, %rdi
  107a8e:      	movq	-0xb0(%rbp), %rsi
  107a95:      	movq	%rbx, %rdx
  107a98:      	callq	0x108c00 <shllvm_leave>
  107a9d:      	movq	%r14, %rax
  107aa0:      	leaq	-0x28(%rbp), %rsp
  107aa4:      	popq	%rbx
  107aa5:      	popq	%r12
  107aa7:      	popq	%r13
  107aa9:      	popq	%r14
  107aab:      	popq	%r15
  107aad:      	popq	%rbp
  107aae:      	retq
  107aaf:      	cmpl	$0x1, %r14d
  107ab3:      	jne	0x107b3b <shllvm_f0+0xe9b>
  107ab9:      	movq	-0x68(%rbp), %rbx
  107abd:      	leaq	0x178(%rbx), %r14
  107ac4:      	addq	$0x160, %rbx            # imm = 0x160
  107acb:      	movl	$0x0, -0x2c(%rbp)
  107ad2:      	movq	%rbx, %rdi
  107ad5:      	movq	-0x38(%rbp), %r12
  107ad9:      	movq	%r12, %rsi
  107adc:      	callq	0x10afc0 <shllvm_catch_value>
  107ae1:      	movq	(%r15), %rax
  107ae4:      	movq	%rax, 0x168(%r15)
  107aeb:      	movq	0x168(%r15), %rax
  107af2:      	movq	%rax, 0x170(%r15)
  107af9:      	movq	0x170(%r15), %rax
  107b00:      	movq	%rax, 0x178(%r15)
  107b07:      	movq	%r14, %rdi
  107b0a:      	movq	%r12, %rsi
  107b0d:      	xorl	%edx, %edx
  107b0f:      	movq	%r14, %rcx
  107b12:      	movq	-0x78(%rbp), %r8
  107b16:      	callq	0x1095e0 <shllvm_binary>
  107b1b:      	movq	0x178(%r15), %rax
  107b22:      	movq	%rax, (%r15)
  107b25:      	movq	0x178(%r15), %rax
  107b2c:      	movq	%rax, 0x50(%r15)
  107b30:      	movq	%r12, %rdi
  107b33:      	movq	%rbx, %rsi
  107b36:      	callq	0x10a190 <shllvm_throw>
  107b3b:      	movq	-0x38(%rbp), %rbx
  107b3f:      	movq	%rbx, %rdi
  107b42:      	movq	-0xa8(%rbp), %rsi
  107b49:      	callq	0x10af70 <shllvm_try_end>
  107b4e:      	movq	%rbx, %rdi
  107b51:      	callq	0x10b000 <shllvm_rethrow>
  107b56:      	nopw	%cs:(%rax,%rax)

0000000000107b60 <shllvm_f1>:
  107b60:      	pushq	%rbp
  107b61:      	movq	%rsp, %rbp
  107b64:      	pushq	%r15
  107b66:      	pushq	%r14
  107b68:      	pushq	%r13
  107b6a:      	pushq	%r12
  107b6c:      	pushq	%rbx
  107b6d:      	subq	$0xf8, %rsp
  107b74:      	movq	%rdi, %r15
  107b77:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  107b7c:      	movl	$0x41, %edi
  107b81:      	callq	0x1087b0 <shllvm_frame_size>
  107b86:      	movq	%rsp, %r12
  107b89:      	addq	$0xf, %rax
  107b8d:      	andq	$-0x10, %rax
  107b91:      	subq	%rax, %r12
  107b94:      	movq	%r12, %rsp
  107b97:      	movl	0x994702(%rip), %r14d   # 0xa9c2a0 <shllvm_unit_index>
  107b9e:      	movq	%r15, %rdi
  107ba1:      	movq	%r12, %rsi
  107ba4:      	movl	$0x41, %edx
  107ba9:      	xorl	%ecx, %ecx
  107bab:      	movl	%r14d, %r8d
  107bae:      	callq	0x108840 <shllvm_enter>
  107bb3:      	movq	%rax, %rbx
  107bb6:      	movq	%rax, -0x38(%rbp)
  107bba:      	movq	%r12, -0x40(%rbp)
  107bbe:      	movq	%r12, %rdi
  107bc1:      	callq	0x108bf0 <shllvm_roots>
  107bc6:      	movq	%rax, %r12
  107bc9:      	movq	%rax, -0x58(%rbp)
  107bcd:      	movq	%r15, %rdi
  107bd0:      	movl	%r14d, %esi
  107bd3:      	callq	0x1087c0 <shllvm_get_unit>
  107bd8:      	movq	%rax, %r13
  107bdb:      	movq	%rax, -0x70(%rbp)
  107bdf:      	leaq	0x1a8(%r12), %rax
  107be7:      	movq	%rax, -0x88(%rbp)
  107bee:      	leaq	0x1b0(%r12), %rax
  107bf6:      	movq	%rax, -0xa8(%rbp)
  107bfd:      	leaq	0x1b8(%r12), %rax
  107c05:      	movq	%rax, -0x60(%rbp)
  107c09:      	leaq	0x1c0(%r12), %rax
  107c11:      	leaq	0x1c8(%r12), %rcx
  107c19:      	movq	%rcx, -0xd0(%rbp)
  107c20:      	leaq	0x1d0(%r12), %rcx
  107c28:      	movq	%rcx, -0xd8(%rbp)
  107c2f:      	leaq	0x1d8(%r12), %rcx
  107c37:      	movq	%rcx, -0xe8(%rbp)
  107c3e:      	leaq	0x1e0(%r12), %rcx
  107c46:      	movq	%rcx, -0xf8(%rbp)
  107c4d:      	leaq	0x1e8(%r12), %r14
  107c55:      	leaq	0x1f0(%r12), %rcx
  107c5d:      	movq	%rcx, -0x100(%rbp)
  107c64:      	leaq	0x1f8(%r12), %rcx
  107c6c:      	movq	%rcx, -0x108(%rbp)
  107c73:      	movq	%r15, %rdi
  107c76:      	movq	%rbx, %rsi
  107c79:      	movq	%rax, %rbx
  107c7c:      	xorl	%edx, %edx
  107c7e:      	callq	0x10ab10 <shllvm_check_invocation>
  107c83:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  107c8d:      	movq	-0x88(%rbp), %rdi
  107c94:      	movl	$0x3, %esi
  107c99:      	callq	0x108680 <shllvm_constant>
  107c9e:      	movabsq	$0x4030000000000000, %rdx # imm = 0x4030000000000000
  107ca8:      	movq	-0xa8(%rbp), %rdi
  107caf:      	movl	$0x3, %esi
  107cb4:      	callq	0x108680 <shllvm_constant>
  107cb9:      	movq	-0x60(%rbp), %rdi
  107cbd:      	movq	%r15, %rsi
  107cc0:      	movq	%r13, %rdx
  107cc3:      	movl	$0xa, %ecx
  107cc8:      	callq	0x108d60 <shllvm_symbol>
  107ccd:      	movq	%rbx, %rdi
  107cd0:      	movq	%r15, %rsi
  107cd3:      	movq	%r13, %rdx
  107cd6:      	movl	$0x4, %ecx
  107cdb:      	callq	0x108d60 <shllvm_symbol>
  107ce0:      	xorl	%eax, %eax
  107ce2:      	movl	%eax, %r13d
  107ce5:      	movq	-0xd0(%rbp), %rdi
  107cec:      	xorl	%esi, %esi
  107cee:      	movq	%r13, %rdx
  107cf1:      	callq	0x108680 <shllvm_constant>
  107cf6:      	movq	-0xd8(%rbp), %rdi
  107cfd:      	movl	$0x2, %esi
  107d02:      	movq	%r13, %rdx
  107d05:      	callq	0x108680 <shllvm_constant>
  107d0a:      	movabsq	$0x4010000000000000, %rdx # imm = 0x4010000000000000
  107d14:      	movq	-0xe8(%rbp), %rdi
  107d1b:      	movl	$0x3, %esi
  107d20:      	callq	0x108680 <shllvm_constant>
  107d25:      	movabsq	$0x4000000000000000, %rdx # imm = 0x4000000000000000
  107d2f:      	movq	-0xf8(%rbp), %rdi
  107d36:      	movl	$0x3, %esi
  107d3b:      	callq	0x108680 <shllvm_constant>
  107d40:      	movq	%r14, %rdi
  107d43:      	movl	$0x1, %esi
  107d48:      	movq	%r13, %rdx
  107d4b:      	callq	0x108680 <shllvm_constant>
  107d50:      	movq	-0x100(%rbp), %rdi
  107d57:      	movl	$0x3, %esi
  107d5c:      	movq	%r13, %rdx
  107d5f:      	callq	0x108680 <shllvm_constant>
  107d64:      	movabsq	$0x4020000000000000, %rdx # imm = 0x4020000000000000
  107d6e:      	movq	-0x108(%rbp), %rdi
  107d75:      	movl	$0x3, %esi
  107d7a:      	callq	0x108680 <shllvm_constant>
  107d7f:      	callq	0x10af10 <shllvm_try_size>
  107d84:      	movq	%rsp, %r13
  107d87:      	addq	$0xf, %rax
  107d8b:      	andq	$-0x10, %rax
  107d8f:      	movq	%r13, %rsi
  107d92:      	subq	%rax, %rsi
  107d95:      	movq	%rsi, %rsp
  107d98:      	movl	$0x0, -0x2c(%rbp)
  107d9f:      	movq	%r15, %rdi
  107da2:      	movq	%rsi, -0x68(%rbp)
  107da6:      	callq	0x10af20 <shllvm_try_begin>
  107dab:      	movq	%rax, %rdi
  107dae:      	callq	0x2d5b0 <_setjmp@plt>
  107db3:      	testl	%eax, %eax
  107db5:      	je	0x107f15 <shllvm_f1+0x3b5>
  107dbb:      	movq	-0x58(%rbp), %rbx
  107dbf:      	movl	-0x2c(%rbp), %r14d
  107dc3:      	movq	%r15, %rdi
  107dc6:      	movq	-0x40(%rbp), %rsi
  107dca:      	movq	-0x38(%rbp), %rdx
  107dce:      	xorl	%ecx, %ecx
  107dd0:      	callq	0x10afb0 <shllvm_catch_prepare>
  107dd5:      	cmpl	$0x2, %r14d
  107dd9:      	jne	0x1080fb <shllvm_f1+0x59b>
  107ddf:      	leaq	0x58(%r12), %r14
  107de4:      	leaq	0x60(%r12), %rax
  107de9:      	movq	%rax, -0xf0(%rbp)
  107df0:      	leaq	0x68(%r12), %r13
  107df5:      	movq	%r13, -0xb8(%rbp)
  107dfc:      	leaq	0x70(%r12), %rax
  107e01:      	movq	%rax, -0x48(%rbp)
  107e05:      	leaq	0x78(%r12), %rax
  107e0a:      	movq	%rax, -0xc0(%rbp)
  107e11:      	leaq	0x80(%r12), %rax
  107e19:      	movq	%rax, -0xb0(%rbp)
  107e20:      	leaq	0x88(%r12), %rax
  107e28:      	movq	%rax, -0xc8(%rbp)
  107e2f:      	leaq	0x90(%r12), %rax
  107e37:      	movq	%rax, -0xe0(%rbp)
  107e3e:      	movl	$0x1, -0x2c(%rbp)
  107e45:      	movq	%r14, %rdi
  107e48:      	movq	%r15, %rsi
  107e4b:      	callq	0x10afc0 <shllvm_catch_value>
  107e50:      	movq	(%rbx), %rax
  107e53:      	movq	%rax, 0x60(%rbx)
  107e57:      	movq	%r13, %rdi
  107e5a:      	movq	%r15, %rsi
  107e5d:      	movq	-0x70(%rbp), %r13
  107e61:      	movq	%r13, %rdx
  107e64:      	movq	%r14, %rcx
  107e67:      	movl	$0xa, %r8d
  107e6d:      	xorl	%r9d, %r9d
  107e70:      	callq	0x109c40 <shllvm_get_id>
  107e75:      	movq	-0x48(%rbp), %rdi
  107e79:      	movq	%r15, %rsi
  107e7c:      	movq	%r13, %rdx
  107e7f:      	movq	%r14, %rcx
  107e82:      	movl	$0x4, %r8d
  107e88:      	xorl	%r9d, %r9d
  107e8b:      	callq	0x109c40 <shllvm_get_id>
  107e90:      	movq	0x1c8(%rbx), %rax
  107e97:      	movq	%rax, 0x78(%rbx)
  107e9b:      	leaq	-0x120(%rbp), %rax
  107ea2:      	movq	-0xb0(%rbp), %r13
  107ea9:      	movq	%r13, %rdi
  107eac:      	movq	%r15, %rsi
  107eaf:      	movq	-0x38(%rbp), %rdx
  107eb3:      	movq	-0x48(%rbp), %rcx
  107eb7:      	movq	%r14, %r8
  107eba:      	movq	-0xc0(%rbp), %r9
  107ec1:      	pushq	%rax
  107ec2:      	pushq	$0x0
  107ec4:      	callq	0x109310 <shllvm_call>
  107ec9:      	addq	$0x10, %rsp
  107ecd:      	movq	-0xc8(%rbp), %r14
  107ed4:      	movq	%r14, %rdi
  107ed7:      	movq	%r15, %rsi
  107eda:      	xorl	%edx, %edx
  107edc:      	movq	-0xb8(%rbp), %rcx
  107ee3:      	movq	%r13, %r8
  107ee6:      	callq	0x1095e0 <shllvm_binary>
  107eeb:      	movq	-0xe0(%rbp), %rdi
  107ef2:      	movq	%r15, %rsi
  107ef5:      	xorl	%edx, %edx
  107ef7:      	movq	-0xf0(%rbp), %rcx
  107efe:      	movq	%r14, %r8
  107f01:      	callq	0x1095e0 <shllvm_binary>
  107f06:      	movq	0x90(%rbx), %rax
  107f0d:      	movq	%rax, (%rbx)
  107f10:      	jmp	0x108076 <shllvm_f1+0x516>
  107f15:      	movq	%r14, -0x110(%rbp)
  107f1c:      	movq	%rbx, -0x118(%rbp)
  107f23:      	leaq	0xe8(%r12), %r13
  107f2b:      	leaq	0x100(%r12), %r14
  107f33:      	leaq	0xf8(%r12), %rax
  107f3b:      	movq	%rax, -0x98(%rbp)
  107f42:      	leaq	0xf0(%r12), %rax
  107f4a:      	movq	%rax, -0x90(%rbp)
  107f51:      	movq	-0x58(%rbp), %rbx
  107f55:      	movq	0x1a8(%rbx), %rax
  107f5c:      	movq	%rax, 0x8(%rbx)
  107f60:      	movq	0x8(%rbx), %rax
  107f64:      	movq	%rax, (%rbx)
  107f67:      	movl	$0x1, -0x2c(%rbp)
  107f6e:      	movl	$0x2, -0x2c(%rbp)
  107f75:      	movl	$0x3, -0x2c(%rbp)
  107f7c:      	movq	%r13, %rdi
  107f7f:      	movq	-0x38(%rbp), %rsi
  107f83:      	movl	$0x1, %edx
  107f88:      	callq	0x108ca0 <shllvm_param>
  107f8d:      	movq	(%rbx), %rax
  107f90:      	movq	%rax, 0xf0(%rbx)
  107f97:      	movq	0x1e0(%rbx), %rax
  107f9e:      	movq	%rax, 0xf8(%rbx)
  107fa5:      	movq	%r14, %rdi
  107fa8:      	movq	%r15, -0x50(%rbp)
  107fac:      	movq	%r15, %rsi
  107faf:      	xorl	%edx, %edx
  107fb1:      	movq	-0x90(%rbp), %rcx
  107fb8:      	movq	-0x98(%rbp), %r8
  107fbf:      	callq	0x1095e0 <shllvm_binary>
  107fc4:      	movq	0x100(%rbx), %rax
  107fcb:      	movq	%rax, (%rbx)
  107fce:      	movq	%r13, %rdi
  107fd1:      	callq	0x109ae0 <shllvm_truthy>
  107fd6:      	testl	%eax, %eax
  107fd8:      	jne	0x108163 <shllvm_f1+0x603>
  107fde:      	leaq	0x148(%r12), %rcx
  107fe6:      	leaq	0x150(%r12), %rax
  107fee:      	movq	%rax, -0xa0(%rbp)
  107ff5:      	leaq	0x158(%r12), %r8
  107ffd:      	leaq	0x160(%r12), %r14
  108005:      	leaq	0x168(%r12), %r15
  10800d:      	movl	$0x2, -0x2c(%rbp)
  108014:      	movq	(%rbx), %rax
  108017:      	movq	%rax, 0x148(%rbx)
  10801e:      	movq	0x1f8(%rbx), %rax
  108025:      	movq	%rax, 0x150(%rbx)
  10802c:      	movq	0x1d8(%rbx), %rax
  108033:      	movq	%rax, 0x158(%rbx)
  10803a:      	movq	%r14, %rdi
  10803d:      	movq	-0x50(%rbp), %r13
  108041:      	movq	%r13, %rsi
  108044:      	xorl	%edx, %edx
  108046:      	callq	0x1095e0 <shllvm_binary>
  10804b:      	movq	%r15, %rdi
  10804e:      	movq	%r13, %rsi
  108051:      	xorl	%edx, %edx
  108053:      	movq	%r14, %rcx
  108056:      	movq	-0xa0(%rbp), %r8
  10805d:      	callq	0x1095e0 <shllvm_binary>
  108062:      	movq	0x168(%rbx), %rax
  108069:      	movq	%rax, (%rbx)
  10806c:      	movl	$0x1, -0x2c(%rbp)
  108073:      	movq	%r13, %r15
  108076:      	movq	-0x40(%rbp), %r14
  10807a:      	leaq	0x190(%r12), %rdi
  108082:      	leaq	0x188(%r12), %r8
  10808a:      	addq	$0x180, %r12            # imm = 0x180
  108091:      	movl	$0x0, -0x2c(%rbp)
  108098:      	movq	(%rbx), %rax
  10809b:      	movq	%rax, 0x180(%rbx)
  1080a2:      	movq	0x1b0(%rbx), %rax
  1080a9:      	movq	%rax, 0x188(%rbx)
  1080b0:      	movq	%r15, %rsi
  1080b3:      	xorl	%edx, %edx
  1080b5:      	movq	%r12, %rcx
  1080b8:      	callq	0x1095e0 <shllvm_binary>
  1080bd:      	movq	0x190(%rbx), %rax
  1080c4:      	movq	%rax, (%rbx)
  1080c7:      	movq	0x190(%rbx), %rbx
  1080ce:      	movq	%r15, %rdi
  1080d1:      	movq	-0x68(%rbp), %rsi
  1080d5:      	callq	0x10af70 <shllvm_try_end>
  1080da:      	movq	%r15, %rdi
  1080dd:      	movq	%r14, %rsi
  1080e0:      	movq	-0x38(%rbp), %rdx
  1080e4:      	callq	0x108c00 <shllvm_leave>
  1080e9:      	movq	%rbx, %rax
  1080ec:      	leaq	-0x28(%rbp), %rsp
  1080f0:      	popq	%rbx
  1080f1:      	popq	%r12
  1080f3:      	popq	%r13
  1080f5:      	popq	%r14
  1080f7:      	popq	%r15
  1080f9:      	popq	%rbp
  1080fa:      	retq
  1080fb:      	movq	%r15, %rax
  1080fe:      	cmpl	$0x1, %r14d
  108102:      	jne	0x108235 <shllvm_f1+0x6d5>
  108108:      	leaq	0x38(%r12), %r13
  10810d:      	leaq	0x30(%r12), %rcx
  108112:      	movq	%rcx, -0x78(%rbp)
  108116:      	leaq	0x28(%r12), %r15
  10811b:      	addq	$0x20, %r12
  10811f:      	movl	$0x0, -0x2c(%rbp)
  108126:      	movq	%r12, %rdi
  108129:      	movq	%rax, %r14
  10812c:      	movq	%rax, %rsi
  10812f:      	callq	0x10afc0 <shllvm_catch_value>
  108134:      	movq	(%rbx), %rax
  108137:      	movq	%rax, 0x28(%rbx)
  10813b:      	movq	0x1b0(%rbx), %rax
  108142:      	movq	%rax, 0x30(%rbx)
  108146:      	movq	%r13, %rdi
  108149:      	movq	%r14, %rsi
  10814c:      	xorl	%edx, %edx
  10814e:      	movq	%r15, %rcx
  108151:      	movq	-0x78(%rbp), %r8
  108155:      	callq	0x1095e0 <shllvm_binary>
  10815a:      	movq	0x38(%rbx), %rax
  10815e:      	jmp	0x1082a6 <shllvm_f1+0x746>
  108163:      	leaq	0x128(%r12), %r14
  10816b:      	addq	$0x118, %r12            # imm = 0x118
  108172:      	movq	%r12, %rdi
  108175:      	movq	-0x50(%rbp), %r15
  108179:      	movq	%r15, %rsi
  10817c:      	callq	0x109b40 <shllvm_object>
  108181:      	movq	%r15, %rdi
  108184:      	movq	%r12, %rsi
  108187:      	movq	-0x60(%rbp), %rdx
  10818b:      	movq	-0x110(%rbp), %rbx
  108192:      	movq	%rbx, %rcx
  108195:      	movl	$0x1, %r8d
  10819b:      	callq	0x109f10 <shllvm_define>
  1081a0:      	movq	%r15, %rdi
  1081a3:      	movq	%r12, %rsi
  1081a6:      	movq	-0x118(%rbp), %rdx
  1081ad:      	movq	%rbx, %rcx
  1081b0:      	movl	$0x1, %r8d
  1081b6:      	callq	0x109f10 <shllvm_define>
  1081bb:      	subq	$0x8, %rsp
  1081bf:      	movq	%r15, %rdi
  1081c2:      	movq	-0x70(%rbp), %rbx
  1081c6:      	movq	%rbx, %rsi
  1081c9:      	movq	%r12, %rdx
  1081cc:      	movl	$0xa, %ecx
  1081d1:      	movq	%r13, %r8
  1081d4:      	movl	$0x1, %r9d
  1081da:      	pushq	$0x0
  1081dc:      	callq	0x109db0 <shllvm_set_id>
  1081e1:      	addq	$0x10, %rsp
  1081e5:      	leaq	0x314(%rip), %r8        # 0x108500 <shllvm_f4>
  1081ec:      	xorl	%eax, %eax
  1081ee:      	movl	%eax, %edx
  1081f0:      	movq	%r14, %rdi
  1081f3:      	movq	%r15, %rsi
  1081f6:      	movq	%rbx, %rcx
  1081f9:      	movl	$0x4, %r9d
  1081ff:      	callq	0x1091e0 <shllvm_closure>
  108204:      	subq	$0x8, %rsp
  108208:      	movq	%r15, %rdi
  10820b:      	movq	%rbx, %rsi
  10820e:      	movq	%r12, %rdx
  108211:      	movl	$0x4, %ecx
  108216:      	movq	%r14, %r8
  108219:      	movl	$0x1, %r9d
  10821f:      	pushq	$0x0
  108221:      	callq	0x109db0 <shllvm_set_id>
  108226:      	addq	$0x10, %rsp
  10822a:      	movq	%r15, %rdi
  10822d:      	movq	%r12, %rsi
  108230:      	callq	0x10a190 <shllvm_throw>
  108235:      	cmpl	$0x3, %r14d
  108239:      	jne	0x1082b4 <shllvm_f1+0x754>
  10823b:      	leaq	0xd0(%r12), %r13
  108243:      	leaq	0xc8(%r12), %rcx
  10824b:      	movq	%rcx, -0x80(%rbp)
  10824f:      	leaq	0xc0(%r12), %r15
  108257:      	addq	$0xb8, %r12
  10825e:      	movl	$0x2, -0x2c(%rbp)
  108265:      	movq	%r12, %rdi
  108268:      	movq	%rax, %r14
  10826b:      	movq	%rax, %rsi
  10826e:      	callq	0x10afc0 <shllvm_catch_value>
  108273:      	movq	(%rbx), %rax
  108276:      	movq	%rax, 0xc0(%rbx)
  10827d:      	movq	0x1d8(%rbx), %rax
  108284:      	movq	%rax, 0xc8(%rbx)
  10828b:      	movq	%r13, %rdi
  10828e:      	movq	%r14, %rsi
  108291:      	xorl	%edx, %edx
  108293:      	movq	%r15, %rcx
  108296:      	movq	-0x80(%rbp), %r8
  10829a:      	callq	0x1095e0 <shllvm_binary>
  10829f:      	movq	0xd0(%rbx), %rax
  1082a6:      	movq	%rax, (%rbx)
  1082a9:      	movq	%r14, %rdi
  1082ac:      	movq	%r12, %rsi
  1082af:      	callq	0x10a190 <shllvm_throw>
  1082b4:      	movq	%rax, %rbx
  1082b7:      	movq	%rax, %rdi
  1082ba:      	movq	-0x68(%rbp), %rsi
  1082be:      	callq	0x10af70 <shllvm_try_end>
  1082c3:      	movq	%rbx, %rdi
  1082c6:      	callq	0x10b000 <shllvm_rethrow>
  1082cb:      	nopl	(%rax,%rax)

00000000001082d0 <shllvm_f2>:
  1082d0:      	pushq	%rbp
  1082d1:      	movq	%rsp, %rbp
  1082d4:      	pushq	%r15
  1082d6:      	pushq	%r14
  1082d8:      	pushq	%r13
  1082da:      	pushq	%r12
  1082dc:      	pushq	%rbx
  1082dd:      	subq	$0x18, %rsp
  1082e1:      	movq	%rdi, %rbx
  1082e4:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  1082e9:      	movl	$0x9, %edi
  1082ee:      	callq	0x1087b0 <shllvm_frame_size>
  1082f3:      	movq	%rsp, %r14
  1082f6:      	addq	$0xf, %rax
  1082fa:      	andq	$-0x10, %rax
  1082fe:      	subq	%rax, %r14
  108301:      	movq	%r14, %rsp
  108304:      	movl	0x993f95(%rip), %r15d   # 0xa9c2a0 <shllvm_unit_index>
  10830b:      	movq	%rbx, %rdi
  10830e:      	movq	%r14, %rsi
  108311:      	movl	$0x9, %edx
  108316:      	xorl	%ecx, %ecx
  108318:      	movl	%r15d, %r8d
  10831b:      	callq	0x108840 <shllvm_enter>
  108320:      	movq	%rax, %r12
  108323:      	movq	%rax, -0x38(%rbp)
  108327:      	movq	%r14, %rdi
  10832a:      	callq	0x108bf0 <shllvm_roots>
  10832f:      	movq	%rax, %r13
  108332:      	movq	%rbx, %rdi
  108335:      	movl	%r15d, %esi
  108338:      	callq	0x1087c0 <shllvm_get_unit>
  10833d:      	leaq	0x38(%r13), %r15
  108341:      	movq	%rbx, %rdi
  108344:      	movq	%r12, %rsi
  108347:      	xorl	%edx, %edx
  108349:      	callq	0x10ab10 <shllvm_check_invocation>
  10834e:      	movabsq	$0x4045000000000000, %rdx # imm = 0x4045000000000000
  108358:      	movq	%r15, -0x40(%rbp)
  10835c:      	movq	%r15, %rdi
  10835f:      	movl	$0x3, %esi
  108364:      	callq	0x108680 <shllvm_constant>
  108369:      	callq	0x10af10 <shllvm_try_size>
  10836e:      	movq	%rsp, %r15
  108371:      	addq	$0xf, %rax
  108375:      	andq	$-0x10, %rax
  108379:      	subq	%rax, %r15
  10837c:      	movq	%r15, %rsp
  10837f:      	movl	$0x0, -0x2c(%rbp)
  108386:      	movq	%rbx, %rdi
  108389:      	movq	%r15, %rsi
  10838c:      	callq	0x10af20 <shllvm_try_begin>
  108391:      	movq	%rax, %rdi
  108394:      	callq	0x2d5b0 <_setjmp@plt>
  108399:      	testl	%eax, %eax
  10839b:      	je	0x1083d1 <shllvm_f2+0x101>
  10839d:      	movl	-0x2c(%rbp), %r12d
  1083a1:      	movq	%rbx, %rdi
  1083a4:      	movq	%r14, %rsi
  1083a7:      	movq	-0x38(%rbp), %rdx
  1083ab:      	xorl	%ecx, %ecx
  1083ad:      	callq	0x10afb0 <shllvm_catch_prepare>
  1083b2:      	cmpl	$0x1, %r12d
  1083b6:      	jne	0x10841e <shllvm_f2+0x14e>
  1083b8:      	leaq	0x8(%r13), %rdi
  1083bc:      	addq	$0x10, %r13
  1083c0:      	movl	$0x0, -0x2c(%rbp)
  1083c7:      	movq	%rbx, %rsi
  1083ca:      	callq	0x10afc0 <shllvm_catch_value>
  1083cf:      	jmp	0x1083e3 <shllvm_f2+0x113>
  1083d1:      	addq	$0x28, %r13
  1083d5:      	movl	$0x1, -0x2c(%rbp)
  1083dc:      	movl	$0x0, -0x2c(%rbp)
  1083e3:      	movq	-0x40(%rbp), %rcx
  1083e7:      	movq	(%rcx), %rcx
  1083ea:      	movq	%rcx, (%r13)
  1083ee:      	movq	(%r13), %r12
  1083f2:      	movq	%rbx, %rdi
  1083f5:      	movq	%r15, %rsi
  1083f8:      	callq	0x10af70 <shllvm_try_end>
  1083fd:      	movq	%rbx, %rdi
  108400:      	movq	%r14, %rsi
  108403:      	movq	-0x38(%rbp), %rdx
  108407:      	callq	0x108c00 <shllvm_leave>
  10840c:      	movq	%r12, %rax
  10840f:      	leaq	-0x28(%rbp), %rsp
  108413:      	popq	%rbx
  108414:      	popq	%r12
  108416:      	popq	%r13
  108418:      	popq	%r14
  10841a:      	popq	%r15
  10841c:      	popq	%rbp
  10841d:      	retq
  10841e:      	movq	%rbx, %rdi
  108421:      	movq	%r15, %rsi
  108424:      	callq	0x10af70 <shllvm_try_end>
  108429:      	movq	%rbx, %rdi
  10842c:      	callq	0x10b000 <shllvm_rethrow>
  108431:      	nopw	%cs:(%rax,%rax)

0000000000108440 <shllvm_f3>:
  108440:      	pushq	%rbp
  108441:      	movq	%rsp, %rbp
  108444:      	pushq	%r15
  108446:      	pushq	%r14
  108448:      	pushq	%r13
  10844a:      	pushq	%r12
  10844c:      	pushq	%rbx
  10844d:      	pushq	%rax
  10844e:      	movq	%rdi, %rbx
  108451:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  108456:      	movl	$0x4, %edi
  10845b:      	callq	0x1087b0 <shllvm_frame_size>
  108460:      	movq	%rsp, %r14
  108463:      	addq	$0xf, %rax
  108467:      	andq	$-0x10, %rax
  10846b:      	subq	%rax, %r14
  10846e:      	movq	%r14, %rsp
  108471:      	movl	0x993e28(%rip), %r12d   # 0xa9c2a0 <shllvm_unit_index>
  108478:      	movq	%rbx, %rdi
  10847b:      	movq	%r14, %rsi
  10847e:      	movl	$0x4, %edx
  108483:      	xorl	%ecx, %ecx
  108485:      	movl	%r12d, %r8d
  108488:      	callq	0x108840 <shllvm_enter>
  10848d:      	movq	%rax, %r15
  108490:      	movq	%r14, %rdi
  108493:      	callq	0x108bf0 <shllvm_roots>
  108498:      	movq	%rax, %r13
  10849b:      	movq	%rbx, %rdi
  10849e:      	movl	%r12d, %esi
  1084a1:      	callq	0x1087c0 <shllvm_get_unit>
  1084a6:      	leaq	0x10(%r13), %r12
  1084aa:      	movq	%rbx, %rdi
  1084ad:      	movq	%r15, %rsi
  1084b0:      	movl	$0x1, %edx
  1084b5:      	callq	0x10ab10 <shllvm_check_invocation>
  1084ba:      	movabsq	$0x3ff0000000000000, %rdx # imm = 0x3FF0000000000000
  1084c4:      	movq	%r12, %rdi
  1084c7:      	movl	$0x3, %esi
  1084cc:      	callq	0x108680 <shllvm_constant>
  1084d1:      	movq	0x10(%r13), %r12
  1084d5:      	movq	%r12, (%r13)
  1084d9:      	movq	%rbx, %rdi
  1084dc:      	movq	%r14, %rsi
  1084df:      	movq	%r15, %rdx
  1084e2:      	callq	0x108c00 <shllvm_leave>
  1084e7:      	movq	%r12, %rax
  1084ea:      	leaq	-0x28(%rbp), %rsp
  1084ee:      	popq	%rbx
  1084ef:      	popq	%r12
  1084f1:      	popq	%r13
  1084f3:      	popq	%r14
  1084f5:      	popq	%r15
  1084f7:      	popq	%rbp
  1084f8:      	retq
  1084f9:      	nopl	(%rax)

0000000000108500 <shllvm_f4>:
  108500:      	pushq	%rbp
  108501:      	movq	%rsp, %rbp
  108504:      	pushq	%r15
  108506:      	pushq	%r14
  108508:      	pushq	%r13
  10850a:      	pushq	%r12
  10850c:      	pushq	%rbx
  10850d:      	pushq	%rax
  10850e:      	movq	%rdi, %rbx
  108511:      	callq	0x2d410 <_sh_check_native_stack_overflow@plt>
  108516:      	movl	$0x4, %edi
  10851b:      	callq	0x1087b0 <shllvm_frame_size>
  108520:      	movq	%rsp, %r14
  108523:      	addq	$0xf, %rax
  108527:      	andq	$-0x10, %rax
  10852b:      	subq	%rax, %r14
  10852e:      	movq	%r14, %rsp
  108531:      	movl	0x993d68(%rip), %r12d   # 0xa9c2a0 <shllvm_unit_index>
  108538:      	movq	%rbx, %rdi
  10853b:      	movq	%r14, %rsi
  10853e:      	movl	$0x4, %edx
  108543:      	xorl	%ecx, %ecx
  108545:      	movl	%r12d, %r8d
  108548:      	callq	0x108840 <shllvm_enter>
  10854d:      	movq	%rax, %r15
  108550:      	movq	%r14, %rdi
  108553:      	callq	0x108bf0 <shllvm_roots>
  108558:      	movq	%rax, %r13
  10855b:      	movq	%rbx, %rdi
  10855e:      	movl	%r12d, %esi
  108561:      	callq	0x1087c0 <shllvm_get_unit>
  108566:      	leaq	0x10(%r13), %r12
  10856a:      	movq	%rbx, %rdi
  10856d:      	movq	%r15, %rsi
  108570:      	movl	$0x1, %edx
  108575:      	callq	0x10ab10 <shllvm_check_invocation>
  10857a:      	movabsq	$0x4044000000000000, %rdx # imm = 0x4044000000000000
  108584:      	movq	%r12, %rdi
  108587:      	movl	$0x3, %esi
  10858c:      	callq	0x108680 <shllvm_constant>
  108591:      	movq	0x10(%r13), %r12
  108595:      	movq	%r12, (%r13)
  108599:      	movq	%rbx, %rdi
  10859c:      	movq	%r14, %rsi
  10859f:      	movq	%r15, %rdx
  1085a2:      	callq	0x108c00 <shllvm_leave>
  1085a7:      	movq	%r12, %rax
  1085aa:      	leaq	-0x28(%rbp), %rsp
  1085ae:      	popq	%rbx
  1085af:      	popq	%r12
  1085b1:      	popq	%r13
  1085b3:      	popq	%r14
  1085b5:      	popq	%r15
  1085b7:      	popq	%rbp
  1085b8:      	retq
  1085b9:      	nopl	(%rax)

00000000001085c0 <sh_export_this_unit>:
  1085c0:      	pushq	%rax
  1085c1:      	subq	$0x8, %rsp
  1085c5:      	leaq	0x16854(%rip), %rax     # 0x11ee20 <shllvm_unit_name>
  1085cc:      	leaq	-0x1933(%rip), %r10     # 0x106ca0 <shllvm_f0>
  1085d3:      	leaq	0x16866(%rip), %r11     # 0x11ee40 <shllvm_functions>
  1085da:      	leaq	0x993cbf(%rip), %rdi    # 0xa9c2a0 <shllvm_unit_index>
  1085e1:      	leaq	0x166d8(%rip), %rdx     # 0x11ecc0 <shllvm_ascii>
  1085e8:      	leaq	0x16751(%rip), %rcx     # 0x11ed40 <shllvm_utf16>
  1085ef:      	leaq	0x1676a(%rip), %r8      # 0x11ed60 <shllvm_strings>
  1085f6:      	movl	$0xb, %esi
  1085fb:      	movl	$0x5, %r9d
  108601:      	pushq	%rax
  108602:      	pushq	%r10
  108604:      	pushq	%r11
  108606:      	callq	0x10a240 <shllvm_create_unit>
  10860b:      	addq	$0x20, %rsp
  10860f:      	popq	%rcx
  108610:      	retq
  108611:      	nopw	%cs:(%rax,%rax)

00000000001087b0 <shllvm_frame_size>:
  1087b0:      	pushq	%rbp
  1087b1:      	movq	%rsp, %rbp
  1087b4:      	movl	%edi, %eax
  1087b6:      	leaq	0x20(,%rax,8), %rax
  1087be:      	popq	%rbp
  1087bf:      	retq

