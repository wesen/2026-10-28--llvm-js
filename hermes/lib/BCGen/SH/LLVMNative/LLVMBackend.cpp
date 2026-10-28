/*
 * Direct textual LLVM IR backend for Static Hermes.
 * Licensed under the MIT license in the repository root.
 */

#include "hermes/BCGen/SH/LLVM.h"
#include "hermes/BCGen/FunctionInfo.h"
#include "hermes/IR/Analysis.h"
#include "hermes/IR/IR.h"
#include "hermes/IR/IRVerifier.h"
#include "hermes/IR/Instrs.h"
#include "hermes/Support/HashString.h"
#include "hermes/Support/UTF8.h"
#include "runtime.h"
#include "llvh/Support/raw_ostream.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

using namespace hermes;

namespace {

/// An explicitly typed operand of a bridge call.
struct Arg {
  std::string type;
  std::string value;
};
Arg ptr(std::string value) { return {"ptr", std::move(value)}; }
Arg u32(uint32_t value) { return {"i32", std::to_string(value)}; }
Arg u64(uint64_t value) { return {"i64", std::to_string(value)}; }

class ModuleEmitter;

/// Each guest value lives in a GC root slot. LLVM SSA temporaries are used only
/// between safepoints; no movable heap pointer is cached in an LLVM register.
class FunctionEmitter {
  ModuleEmitter &module_;
  Function &function_;
  std::string text_;
  llvh::raw_string_ostream os_;
  std::map<const Value *, unsigned> slots_;
  std::vector<Value *> constants_;
  std::map<BasicBlock *, unsigned> blocks_;
  struct Edge {
    BasicBlock *from;
    BasicBlock *to;
    std::string name;
  };
  std::vector<Edge> edges_;
  std::map<TryStartInst *, uint32_t> tries_;
  llvh::DenseMap<BasicBlock *, TryStartInst *> enclosingTries_;
  unsigned temporary_ = 0;
  unsigned maxArgs_ = 0;
  unsigned scratch_ = 0;
  bool ok_ = true;

  std::string temporary() { return "%t" + std::to_string(temporary_++); }
  std::string slot(Value *value);
  std::string block(BasicBlock *bb) {
    return "b" + std::to_string(blocks_.at(bb));
  }
  std::string edge(BasicBlock *from, BasicBlock *to);
  std::string call(
      const std::string &name,
      std::initializer_list<Arg> args,
      const std::string &result = "void");
  std::string raw(Value *value);
  void copy(Value *destination, Value *source);
  void copyTo(const std::string &destination, Value *source);
  void emitConstant(Value *value);
  void emitInstruction(Instruction &instruction);
  void emitEdges();
  void emitCatchDispatch();
  void emitCall(BaseCallInst &instruction, bool builtin);
  void unary(Instruction &instruction, Value *value, unsigned op);
  void binary(Instruction &instruction, Value *lhs, Value *rhs, unsigned op);
  void floating(
      Instruction &instruction,
      Value *lhs,
      Value *rhs,
      const std::string &operation);
  void compare(
      Instruction &instruction,
      Value *lhs,
      Value *rhs,
      const std::string &predicate);
  void getProperty(Instruction &instruction, Value *object, Value *key, bool tryFlag);
  void setProperty(
      Value *object, Value *key, Value *value, bool strict, bool tryFlag);
  void fail(Instruction *instruction, const std::string &message);

 public:
  FunctionEmitter(ModuleEmitter &module, Function &function);
  bool generate();
  const std::string &text() { os_.flush(); return text_; }
};

/// LLVM types for generated data intentionally describe only our bridge ABI.
/// The native SHUnit and SHNativeFuncInfo layouts stay in runtime.c.
class ModuleEmitter {
 public:
  Module *module;
  const BytecodeGenerationOptions &options;
  std::map<Function *, unsigned> functionIDs;
  std::vector<Function *> functions;
  std::map<std::string, unsigned> stringIDs;
  std::vector<std::string> strings;
  std::map<std::string, std::pair<std::string, std::vector<std::string>>> imports;

  ModuleEmitter(Module *m, const BytecodeGenerationOptions &o)
      : module(m), options(o) {
    functions.push_back(m->getTopLevelFunction());
    for (auto &f : *m)
      if (&f != functions[0])
        functions.push_back(&f);
    for (unsigned i = 0; i != functions.size(); ++i) {
      functionIDs[functions[i]] = i;
      string(functions[i]->getOriginalOrInferredName().str());
    }
  }
  unsigned string(llvh::StringRef value) {
    auto key = value.str();
    auto entry = stringIDs.emplace(key, strings.size());
    if (entry.second)
      strings.push_back(std::move(key));
    return entry.first->second;
  }
  std::string functionName(Function *f) {
    return "@shllvm_f" + std::to_string(functionIDs.at(f));
  }
  void import(
      const std::string &name,
      const std::string &result,
      std::initializer_list<Arg> args) {
    std::vector<std::string> types;
    for (const auto &arg : args)
      types.push_back(arg.type);
    auto signature = std::make_pair(result, types);
    auto entry = imports.emplace(name, signature);
    assert(entry.second || entry.first->second == signature);
    (void)entry;
  }
  void emitData(llvh::raw_ostream &os);
  bool generate(llvh::raw_ostream &os);
};

bool isConstant(Value *value) {
  return llvh::isa<LiteralNumber>(value) ||
      llvh::isa<LiteralString>(value) ||
      llvh::isa<LiteralBool>(value) ||
      llvh::isa<LiteralUndefined>(value) ||
      llvh::isa<LiteralNull>(value) ||
      llvh::isa<LiteralEmpty>(value) ||
      llvh::isa<LiteralUninit>(value) ||
      llvh::isa<GlobalObject>(value);
}

FunctionEmitter::FunctionEmitter(ModuleEmitter &module, Function &function)
    : module_(module), function_(function), os_(text_) {
  for (auto &bb : function_) {
    blocks_[&bb] = blocks_.size();
    for (auto &instruction : bb) {
      // Including side-effect-only instructions keeps numbering simple and
      // deterministic. Unused slots hold undefined and are safe for the GC.
      slots_.emplace(&instruction, slots_.size());
      if (auto *call = llvh::dyn_cast<BaseCallInst>(&instruction))
        maxArgs_ = std::max(maxArgs_, call->getNumArguments() - 1);
      if (auto *start = llvh::dyn_cast<TryStartInst>(&instruction))
        tries_[start] = tries_.size() + 1;
    }
  }
  for (auto &bb : function_)
    for (auto &instruction : bb)
      for (unsigned i = 0; i != instruction.getNumOperands(); ++i) {
        Value *value = instruction.getOperand(i);
        if (isConstant(value) &&
            slots_.emplace(value, slots_.size()).second)
          constants_.push_back(value);
      }
  scratch_ = slots_.size();
  if (!tries_.empty()) {
    auto analysis = findEnclosingTrysPerBlock(&function_);
    if (analysis)
      enclosingTries_ = *analysis;
    else
      fail(nullptr, "cannot analyze exception regions");
  }
}

void FunctionEmitter::fail(
    Instruction *instruction, const std::string &message) {
  if (ok_) {
    auto location = instruction ? instruction->getLocation()
                                : function_.getSourceRange().Start;
    module_.module->getContext().getSourceErrorManager().error(
        location, "direct LLVM backend: " + message);
  }
  ok_ = false;
}

std::string FunctionEmitter::slot(Value *value) {
  auto it = slots_.find(value);
  if (it == slots_.end()) {
    fail(nullptr, "unrepresentable value operand");
    return "%scratch";
  }
  return "%s" + std::to_string(it->second);
}

std::string FunctionEmitter::call(
    const std::string &name,
    std::initializer_list<Arg> args,
    const std::string &result) {
  module_.import(name, result, args);
  auto output = result == "void" ? "" : temporary();
  os_ << "  ";
  if (!output.empty())
    os_ << output << " = ";
  os_ << "call " << result << " @" << name << "(";
  bool first = true;
  for (const auto &arg : args) {
    if (!first)
      os_ << ", ";
    first = false;
    os_ << arg.type << " " << arg.value;
  }
  os_ << ")\n";
  return output;
}

std::string FunctionEmitter::raw(Value *value) {
  auto result = temporary();
  os_ << "  " << result << " = load " << (tries_.empty() ? "" : "volatile ")
      << "i64, ptr " << slot(value)
      << ", align 8\n";
  return result;
}
void FunctionEmitter::copyTo(const std::string &destination, Value *source) {
  auto value = raw(source);
  os_ << "  store " << (tries_.empty() ? "" : "volatile ")
      << "i64 " << value << ", ptr " << destination << ", align 8\n";
}
void FunctionEmitter::copy(Value *destination, Value *source) {
  copyTo(slot(destination), source);
}

void FunctionEmitter::emitConstant(Value *value) {
  if (auto *s = llvh::dyn_cast<LiteralString>(value)) {
    call("shllvm_symbol", {
        ptr(slot(value)), ptr("%shr"), ptr("%unit"),
        u32(module_.string(s->getValue().str()))});
  } else if (llvh::isa<GlobalObject>(value)) {
    call("shllvm_global", {ptr(slot(value)), ptr("%shr")});
  } else {
    unsigned kind = SHLLVM_UNDEFINED;
    uint64_t bits = 0;
    if (auto *n = llvh::dyn_cast<LiteralNumber>(value)) {
      kind = SHLLVM_NUMBER;
      double number = n->getValue();
      std::memcpy(&bits, &number, sizeof(bits));
    } else if (auto *b = llvh::dyn_cast<LiteralBool>(value)) {
      kind = SHLLVM_BOOLEAN;
      bits = b->getValue();
    } else if (llvh::isa<LiteralNull>(value)) {
      kind = SHLLVM_NULL;
    } else if (llvh::isa<LiteralEmpty>(value)) {
      kind = SHLLVM_EMPTY;
    } else if (llvh::isa<LiteralUninit>(value)) {
      kind = SHLLVM_UNINIT;
    }
    call("shllvm_constant", {ptr(slot(value)), u32(kind), u64(bits)});
  }
}

std::string FunctionEmitter::edge(BasicBlock *from, BasicBlock *to) {
  bool phi = false;
  for (auto &instruction : *to)
    if (llvh::isa<PhiInst>(&instruction))
      phi = true;
  if (!phi)
    return block(to);
  std::string name = "edge" + std::to_string(edges_.size());
  edges_.push_back({from, to, name});
  return name;
}

void FunctionEmitter::emitEdges() {
  for (const auto &edge : edges_) {
    os_ << edge.name << ":\n";
    std::vector<std::pair<Value *, std::string>> assignments;
    for (auto &instruction : *edge.to) {
      auto *phi = llvh::dyn_cast<PhiInst>(&instruction);
      if (!phi)
        continue;
      Value *incoming = nullptr;
      for (unsigned i = 0; i != phi->getNumEntries(); ++i)
        if (phi->getEntry(i).second == edge.from)
          incoming = phi->getEntry(i).first;
      if (!incoming) {
        fail(phi, "phi has no value for an incoming CFG edge");
        continue;
      }
      // Load every input before any destination is overwritten: loop-carried
      // swaps and mutually dependent phi nodes require parallel-copy semantics.
      assignments.emplace_back(phi, raw(incoming));
    }
    for (const auto &assignment : assignments)
      os_ << "  store " << (tries_.empty() ? "" : "volatile ")
          << "i64 " << assignment.second << ", ptr "
          << slot(assignment.first) << ", align 8\n";
    os_ << "  br label %" << block(edge.to) << "\n";
  }
}

void FunctionEmitter::emitCatchDispatch() {
  if (tries_.empty())
    return;
  os_ << "catch.dispatch:\n";
  auto state = temporary();
  os_ << "  " << state << " = load volatile i32, ptr %try_state, align 4\n";
  call("shllvm_catch_prepare", {
      ptr("%shr"), ptr("%storage"), ptr("%frame"), u32(maxArgs_)});
  std::vector<std::pair<uint32_t, std::string>> destinations;
  for (const auto &item : tries_)
    destinations.emplace_back(
        item.second, edge(item.first->getParent(), item.first->getCatchTarget()));
  os_ << "  switch i32 " << state << ", label %catch.rethrow [\n";
  for (const auto &destination : destinations)
    os_ << "    i32 " << destination.first << ", label %" << destination.second << "\n";
  os_ << "  ]\ncatch.rethrow:\n";
  call("shllvm_try_end", {ptr("%shr"), ptr("%try_storage")});
  call("shllvm_rethrow", {ptr("%shr")});
  os_ << "  unreachable\n";
}

void FunctionEmitter::unary(
    Instruction &instruction, Value *value, unsigned op) {
  call("shllvm_unary", {
      ptr(slot(&instruction)), ptr("%shr"), u32(op), ptr(slot(value))});
}
void FunctionEmitter::binary(
    Instruction &instruction, Value *lhs, Value *rhs, unsigned op) {
  call("shllvm_binary", {
      ptr(slot(&instruction)), ptr("%shr"), u32(op),
      ptr(slot(lhs)), ptr(slot(rhs))});
}

void FunctionEmitter::floating(
    Instruction &instruction,
    Value *lhs,
    Value *rhs,
    const std::string &operation) {
  auto left = raw(lhs);
  auto l = temporary();
  os_ << "  " << l << " = bitcast i64 " << left << " to double\n";
  std::string r;
  if (rhs) {
    auto right = raw(rhs);
    r = temporary();
    os_ << "  " << r << " = bitcast i64 " << right << " to double\n";
  }
  auto result = temporary();
  os_ << "  " << result << " = " << operation << " double " << l;
  if (rhs)
    os_ << ", " << r;
  os_ << "\n";
  // No fast-math flags: signed zero, infinities and NaNs stay observable.
  call("shllvm_number", {ptr(slot(&instruction)), {"double", result}});
}

void FunctionEmitter::compare(
    Instruction &instruction,
    Value *lhs,
    Value *rhs,
    const std::string &predicate) {
  auto left = raw(lhs);
  auto right = raw(rhs);
  auto l = temporary(), r = temporary(), result = temporary(), extended = temporary();
  os_ << "  " << l << " = bitcast i64 " << left << " to double\n"
      << "  " << r << " = bitcast i64 " << right << " to double\n"
      << "  " << result << " = fcmp " << predicate << " double " << l
      << ", " << r << "\n"
      << "  " << extended << " = zext i1 " << result << " to i32\n";
  call("shllvm_boolean", {ptr(slot(&instruction)), {"i32", extended}});
}

void FunctionEmitter::getProperty(
    Instruction &instruction, Value *object, Value *key, bool tryFlag) {
  if (auto *name = llvh::dyn_cast<LiteralString>(key)) {
    call("shllvm_get_id", {
        ptr(slot(&instruction)), ptr("%shr"), ptr("%unit"), ptr(slot(object)),
        u32(module_.string(name->getValue().str())), u32(tryFlag)});
  } else {
    call("shllvm_get", {
        ptr(slot(&instruction)), ptr("%shr"), ptr(slot(object)), ptr(slot(key))});
  }
}

void FunctionEmitter::setProperty(
    Value *object, Value *key, Value *value, bool strict, bool tryFlag) {
  if (auto *name = llvh::dyn_cast<LiteralString>(key)) {
    call("shllvm_set_id", {
        ptr("%shr"), ptr("%unit"), ptr(slot(object)),
        u32(module_.string(name->getValue().str())), ptr(slot(value)),
        u32(strict), u32(tryFlag)});
  } else {
    call("shllvm_set", {
        ptr("%shr"), ptr(slot(object)), ptr(slot(key)), ptr(slot(value)),
        u32(strict)});
  }
}

void FunctionEmitter::emitCall(BaseCallInst &instruction, bool builtin) {
  auto count = instruction.getNumArguments() - 1;
  for (unsigned i = 0; i != count; ++i) {
    auto address = temporary();
    os_ << "  " << address << " = getelementptr i64, ptr %argv, i32 " << i << "\n";
    copyTo(address, instruction.getArgument(i + 1));
  }
  if (builtin) {
    auto &bi = llvh::cast<CallBuiltinInst>(instruction);
    call("shllvm_builtin", {
        ptr(slot(&instruction)), ptr("%shr"), ptr("%frame"),
        u32(static_cast<uint32_t>(bi.getBuiltinIndex())), u32(count), ptr("%argv")});
  } else {
    call("shllvm_call", {
        ptr(slot(&instruction)), ptr("%shr"), ptr("%frame"),
        ptr(slot(instruction.getCallee())), ptr(slot(instruction.getArgument(0))),
        ptr(slot(instruction.getNewTarget())), u32(count), ptr("%argv")});
  }
}

void FunctionEmitter::emitInstruction(Instruction &i) {
  os_ << "  ; Hermes " << i.getName() << "\n";
  if (llvh::isa<PhiInst>(&i) || llvh::isa<AllocStackInst>(&i))
    return;
  if (auto *x = llvh::dyn_cast<LIRLoadConstInst>(&i)) {
    copy(x, x->getConst());
  } else if (auto *x = llvh::dyn_cast<LoadStackInst>(&i)) {
    copy(x, x->getPtr());
  } else if (auto *x = llvh::dyn_cast<StoreStackInst>(&i)) {
    copy(x->getPtr(), x->getValue());
  } else if (auto *x = llvh::dyn_cast<MovInst>(&i)) {
    copy(x, x->getSingleOperand());
  } else if (auto *x = llvh::dyn_cast<UnionNarrowTrustedInst>(&i)) {
    copy(x, x->getSingleOperand());
  } else if (auto *x = llvh::dyn_cast<LoadParamInst>(&i)) {
    call("shllvm_param", {
        ptr(slot(x)), ptr("%frame"), u32(x->getParam()->getIndexInParamList())});
  } else if (auto *x = llvh::dyn_cast<GetParentScopeInst>(&i)) {
    call("shllvm_env_from_frame", {ptr(slot(x)), ptr("%shr"), ptr("%frame")});
  } else if (auto *x = llvh::dyn_cast<GetClosureScopeInst>(&i)) {
    call("shllvm_env_from_closure", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getClosure()))});
  } else if (auto *x = llvh::dyn_cast<LIRResolveScopeInst>(&i)) {
    call("shllvm_env_resolve", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getStartScope())),
        u32(x->getNumLevels()->asUInt32())});
  } else if (auto *x = llvh::dyn_cast<CreateScopeInst>(&i)) {
    auto parent = llvh::isa<EmptySentinel>(x->getParentScope())
        ? "null" : slot(x->getParentScope());
    call("shllvm_env_create", {
        ptr(slot(x)), ptr("%shr"), ptr(parent),
        u32(x->getVariableScope()->getVariables().size())});
  } else if (auto *x = llvh::dyn_cast<LoadFrameInst>(&i)) {
    call("shllvm_env_load", {
        ptr(slot(x)), ptr(slot(x->getScope())),
        u32(x->getLoadVariable()->getIndexInVariableList())});
  } else if (auto *x = llvh::dyn_cast<StoreFrameInst>(&i)) {
    call("shllvm_env_store", {
        ptr("%shr"), ptr(slot(x->getScope())), ptr(slot(x->getValue())),
        u32(x->getVariable()->getIndexInVariableList())});
  } else if (auto *x = llvh::dyn_cast<CreateFunctionInst>(&i)) {
    auto environment = llvh::isa<EmptySentinel>(x->getScope())
        ? "null" : slot(x->getScope());
    call("shllvm_closure", {
        ptr(slot(x)), ptr("%shr"), ptr(environment), ptr("%unit"),
        ptr(module_.functionName(x->getFunctionCode())),
        u32(module_.functionIDs.at(x->getFunctionCode()))});
  } else if (auto *x = llvh::dyn_cast<CreateClassInst>(&i)) {
    auto environment = llvh::isa<EmptySentinel>(x->getScope())
        ? "null" : slot(x->getScope());
    auto super = llvh::isa<EmptySentinel>(x->getSuperClass())
        ? "null" : slot(x->getSuperClass());
    call("shllvm_class", {
        ptr(slot(x)), ptr("%shr"), ptr(environment), ptr("%unit"),
        ptr(module_.functionName(x->getFunctionCode())),
        u32(module_.functionIDs.at(x->getFunctionCode())),
        ptr(slot(x->getHomeObjectOutput())), ptr(super)});
  } else if (auto *x = llvh::dyn_cast<CallInst>(&i)) {
    emitCall(*x, false);
  } else if (auto *x = llvh::dyn_cast<CallBuiltinInst>(&i)) {
    emitCall(*x, true);
  } else if (auto *x = llvh::dyn_cast<GetBuiltinClosureInst>(&i)) {
    call("shllvm_builtin_closure", {
        ptr(slot(x)), ptr("%shr"), u32(static_cast<unsigned>(x->getBuiltinIndex()))});
  } else if (auto *x = llvh::dyn_cast<BranchIfBuiltinInst>(&i)) {
    call("shllvm_builtin_closure", {
        ptr("%scratch"), ptr("%shr"),
        u32(static_cast<unsigned>(x->getBuiltinIndex()))});
    auto expected = temporary();
    auto actual = raw(x->getArgument());
    auto matches = temporary();
    os_ << "  " << expected << " = load i64, ptr %scratch, align 8\n"
        << "  " << matches << " = icmp eq i64 " << actual << ", " << expected << "\n";
    auto yes = edge(i.getParent(), x->getTrueBlock());
    auto no = edge(i.getParent(), x->getFalseBlock());
    os_ << "  br i1 " << matches << ", label %" << yes << ", label %" << no << "\n";
  } else if (auto *x = llvh::dyn_cast<BranchInst>(&i)) {
    auto destination = edge(i.getParent(), x->getBranchDest());
    os_ << "  br label %" << destination << "\n";
  } else if (auto *x = llvh::dyn_cast<TryStartInst>(&i)) {
    os_ << "  store volatile i32 " << tries_.at(x)
        << ", ptr %try_state, align 4\n";
    auto destination = edge(i.getParent(), x->getTryBody());
    os_ << "  br label %" << destination << "\n";
  } else if (auto *x = llvh::dyn_cast<TryEndInst>(&i)) {
    auto *outer = enclosingTries_.lookup(x->getBranchDest());
    os_ << "  store volatile i32 " << (outer ? tries_.at(outer) : 0)
        << ", ptr %try_state, align 4\n";
    auto destination = edge(i.getParent(), x->getBranchDest());
    os_ << "  br label %" << destination << "\n";
  } else if (auto *x = llvh::dyn_cast<CatchInst>(&i)) {
    auto *outer = enclosingTries_.lookup(x->getParent());
    os_ << "  store volatile i32 " << (outer ? tries_.at(outer) : 0)
        << ", ptr %try_state, align 4\n";
    call("shllvm_catch_value", {ptr(slot(x)), ptr("%shr")});
  } else if (auto *x = llvh::dyn_cast<CondBranchInst>(&i)) {
    auto truth = call("shllvm_truthy", {ptr(slot(x->getCondition()))}, "i32");
    auto condition = temporary();
    os_ << "  " << condition << " = icmp ne i32 " << truth << ", 0\n";
    auto yes = edge(i.getParent(), x->getTrueDest());
    auto no = edge(i.getParent(), x->getFalseDest());
    os_ << "  br i1 " << condition << ", label %" << yes
        << ", label %" << no << "\n";
  } else if (auto *x = llvh::dyn_cast<ReturnInst>(&i)) {
    auto value = raw(x->getValue());
    if (!tries_.empty())
      call("shllvm_try_end", {ptr("%shr"), ptr("%try_storage")});
    call("shllvm_leave", {ptr("%shr"), ptr("%storage"), ptr("%frame")});
    os_ << "  ret i64 " << value << "\n";
  } else if (auto *x = llvh::dyn_cast<ThrowInst>(&i)) {
    call("shllvm_throw", {ptr("%shr"), ptr(slot(x->getThrownValue()))});
    os_ << "  unreachable\n";
  } else if (auto *x = llvh::dyn_cast<ThrowTypeErrorInst>(&i)) {
    call("shllvm_throw_type_error", {ptr("%shr"), ptr(slot(x->getMessage()))});
    os_ << "  unreachable\n";
  } else if (llvh::isa<UnreachableInst>(&i)) {
    os_ << "  unreachable\n";
  } else if (auto *x = llvh::dyn_cast<ThrowIfInst>(&i)) {
    auto &tc = module_.module->getTypeContext();
    auto bad = x->getInvalidTypes()->getData();
    unsigned mask = 0;
    if (!tc.intersectTy(bad, Type::createEmpty()).isNoType()) mask |= 1;
    if (!tc.intersectTy(bad, Type::createUninit()).isNoType()) mask |= 2;
    call("shllvm_check_tdz", {
        ptr("%shr"), ptr(slot(x->getCheckedValue())), u32(mask)});
    copy(x, x->getCheckedValue());
  } else if (auto *x = llvh::dyn_cast<ThrowIfThisInitializedInst>(&i)) {
    call("shllvm_check_this_initialized", {
        ptr("%shr"), ptr(slot(x->getDerivedClassCheckedThis()))});
  } else if (auto *x = llvh::dyn_cast<DeclareGlobalVarInst>(&i)) {
    call("shllvm_declare_global", {
        ptr("%shr"), ptr("%unit"), u32(module_.string(x->getName()->getValue().str()))});
  } else if (auto *x = llvh::dyn_cast<LIRGetGlobalObjectInst>(&i)) {
    call("shllvm_global", {ptr(slot(x)), ptr("%shr")});
  } else if (auto *x = llvh::dyn_cast<LoadPropertyInst>(&i)) {
    getProperty(*x, x->getObject(), x->getProperty(), false);
  } else if (auto *x = llvh::dyn_cast<PrLoadInst>(&i)) {
    auto *name = llvh::dyn_cast<LiteralString>(x->getOperand(PrLoadInst::PropNameIdx));
    if (!name) {
      fail(x, "private fixed-slot properties are not implemented");
      return;
    }
    // Literal expansion uses ordinary Hermes objects. Preserve the field name
    // rather than assuming the C emitter's optimized storage-slot layout.
    getProperty(*x, x->getObject(), name, false);
  } else if (auto *x = llvh::dyn_cast<LoadPropertyWithReceiverInst>(&i)) {
    call("shllvm_get_receiver", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getObject())),
        ptr(slot(x->getProperty())), ptr(slot(x->getReceiver()))});
  } else if (auto *x = llvh::dyn_cast<TryLoadGlobalPropertyInst>(&i)) {
    getProperty(*x, x->getObject(), x->getProperty(), true);
  } else if (auto *x = llvh::dyn_cast<StorePropertyInst>(&i)) {
    setProperty(x->getObject(), x->getProperty(), x->getStoredValue(),
                llvh::isa<StorePropertyStrictInst>(x), false);
  } else if (auto *x = llvh::dyn_cast<PrStoreInst>(&i)) {
    auto *name = llvh::dyn_cast<LiteralString>(x->getOperand(PrStoreInst::PropNameIdx));
    if (!name) {
      fail(x, "private fixed-slot properties are not implemented");
      return;
    }
    setProperty(x->getObject(), name, x->getStoredValue(), true, false);
  } else if (auto *x = llvh::dyn_cast<TryStoreGlobalPropertyInst>(&i)) {
    setProperty(x->getObject(), x->getProperty(), x->getStoredValue(),
                llvh::isa<TryStoreGlobalPropertyStrictInst>(x), true);
  } else if (auto *x = llvh::dyn_cast<StorePropertyWithReceiverInst>(&i)) {
    call("shllvm_set_receiver", {
        ptr("%shr"), ptr(slot(x->getObject())), ptr(slot(x->getProperty())),
        ptr(slot(x->getStoredValue())), ptr(slot(x->getReceiver())),
        u32(x->getIsStrict())});
  } else if (auto *x = llvh::dyn_cast<DefineOwnPropertyInst>(&i)) {
    call("shllvm_define", {
        ptr("%shr"), ptr(slot(x->getObject())), ptr(slot(x->getProperty())),
        ptr(slot(x->getStoredValue())), u32(x->getIsEnumerable())});
  } else if (auto *x = llvh::dyn_cast<DefineOwnInDenseArrayInst>(&i)) {
    call("shllvm_define_index", {
        ptr("%shr"), ptr(slot(x->getArray())),
        u32(x->getArrayIndex()->asUInt32()), ptr(slot(x->getStoredValue()))});
  } else if (auto *x = llvh::dyn_cast<DefineOwnGetterSetterInst>(&i)) {
    call("shllvm_define_accessor", {
        ptr("%shr"), ptr(slot(x->getObject())), ptr(slot(x->getProperty())),
        ptr(slot(x->getStoredGetter())), ptr(slot(x->getStoredSetter())),
        u32(x->getIsEnumerable())});
  } else if (auto *x = llvh::dyn_cast<DeletePropertyInst>(&i)) {
    call("shllvm_delete", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getObject())),
        ptr(slot(x->getProperty())), u32(llvh::isa<DeletePropertyStrictInst>(x))});
  } else if (auto *x = llvh::dyn_cast<BaseAllocObjectLiteralInst>(&i)) {
    if (!llvh::isa<AllocObjectLiteralInst>(x)) {
      fail(x, "typed object allocation is outside the dynamic-JS backend");
      return;
    }
    if (!llvh::isa<EmptySentinel>(x->getParentObject())) {
      call("shllvm_object_parent", {
          ptr(slot(x)), ptr("%shr"), ptr("%unit"), ptr(slot(x->getParentObject()))});
    } else {
      call("shllvm_object", {ptr(slot(x)), ptr("%shr")});
    }
    for (unsigned n = 0; n != x->getKeyValuePairCount(); ++n)
      call("shllvm_define", {
          ptr("%shr"), ptr(slot(x)), ptr(slot(x->getKey(n))),
          ptr(slot(x->getValue(n))), u32(1)});
  } else if (auto *x = llvh::dyn_cast<LIRAllocObjectFromBufferInst>(&i)) {
    if (!llvh::isa<EmptySentinel>(x->getParentObject())) {
      call("shllvm_object_parent", {
          ptr(slot(x)), ptr("%shr"), ptr("%unit"), ptr(slot(x->getParentObject()))});
    } else {
      call("shllvm_object", {ptr(slot(x)), ptr("%shr")});
    }
    for (unsigned n = 0; n != x->getKeyValuePairCount(); ++n) {
      auto pair = x->getKeyValuePair(n);
      call("shllvm_define", {
          ptr("%shr"), ptr(slot(x)), ptr(slot(pair.first)),
          ptr(slot(pair.second)), u32(1)});
    }
  } else if (auto *x = llvh::dyn_cast<AllocArrayInst>(&i)) {
    call("shllvm_array", {
        ptr(slot(x)), ptr("%shr"),
        u32(std::max(x->getSizeHint()->asUInt32(), x->getElementCount()))});
    for (unsigned n = 0; n != x->getElementCount(); ++n)
      if (!llvh::isa<LiteralEmpty>(x->getArrayElement(n)))
        call("shllvm_define_index", {
            ptr("%shr"), ptr(slot(x)), u32(n), ptr(slot(x->getArrayElement(n)))});
  } else if (auto *x = llvh::dyn_cast<CoerceThisNSInst>(&i)) {
    call("shllvm_coerce_this", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getSingleOperand()))});
  } else if (auto *x = llvh::dyn_cast<LIRGetThisNSInst>(&i)) {
    call("shllvm_param", {ptr("%scratch"), ptr("%frame"), u32(0)});
    call("shllvm_coerce_this", {ptr(slot(x)), ptr("%shr"), ptr("%scratch")});
  } else if (auto *x = llvh::dyn_cast<GetNewTargetInst>(&i)) {
    call("shllvm_new_target", {ptr(slot(x)), ptr("%frame")});
  } else if (auto *x = llvh::dyn_cast<CreateThisInst>(&i)) {
    call("shllvm_create_this", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getClosure())),
        ptr(slot(x->getNewTarget()))});
  } else if (auto *x = llvh::dyn_cast<GetConstructedObjectInst>(&i)) {
    call("shllvm_constructed_object", {
        ptr(slot(x)), ptr(slot(x->getThisValue())),
        ptr(slot(x->getConstructorReturnValue()))});
  } else if (auto *x = llvh::dyn_cast<LoadParentNoTrapsInst>(&i)) {
    call("shllvm_get_parent", {
        ptr(slot(x)), ptr("%shr"), ptr(slot(x->getObject()))});
  } else if (auto *x = llvh::dyn_cast<LIRGetArgumentsLengthInst>(&i)) {
    call("shllvm_args_length", {
        ptr(slot(x)), ptr("%shr"), ptr("%frame"), ptr(slot(x->getLazyRegister()))});
  } else if (auto *x = llvh::dyn_cast<LIRGetArgumentsPropByValLooseInst>(&i)) {
    call("shllvm_args_get", {
        ptr(slot(x)), ptr("%shr"), ptr("%frame"), ptr(slot(x->getIndex())),
        ptr(slot(x->getLazyRegister())), u32(0)});
  } else if (auto *x = llvh::dyn_cast<LIRGetArgumentsPropByValStrictInst>(&i)) {
    call("shllvm_args_get", {
        ptr(slot(x)), ptr("%shr"), ptr("%frame"), ptr(slot(x->getIndex())),
        ptr(slot(x->getLazyRegister())), u32(1)});
  } else if (auto *x = llvh::dyn_cast<LIRReifyArgumentsLooseInst>(&i)) {
    call("shllvm_args_reify", {
        ptr("%shr"), ptr("%frame"), ptr(slot(x->getLazyRegister())), u32(0)});
  } else if (auto *x = llvh::dyn_cast<LIRReifyArgumentsStrictInst>(&i)) {
    call("shllvm_args_reify", {
        ptr("%shr"), ptr("%frame"), ptr(slot(x->getLazyRegister())), u32(1)});
  } else if (auto *x = llvh::dyn_cast<TypeOfInst>(&i)) {
    unary(*x, x->getArgument(), SHLLVM_TYPEOF);
  } else if (auto *x = llvh::dyn_cast<TypeOfIsInst>(&i)) {
    call("shllvm_typeof_is", {
        ptr(slot(x)), ptr(slot(x->getArgument())),
        u32(x->getTypes()->getData().getRaw())});
  } else if (auto *x = llvh::dyn_cast<AsNumberInst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_POS);
  } else if (auto *x = llvh::dyn_cast<AsNumericInst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_TO_NUMERIC);
  } else if (auto *x = llvh::dyn_cast<AsInt32Inst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_TO_INT32);
  } else if (auto *x = llvh::dyn_cast<AsUint32Inst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_TO_UINT32);
  } else if (auto *x = llvh::dyn_cast<AddEmptyStringInst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_TO_STRING);
  } else if (auto *x = llvh::dyn_cast<ToPropertyKeyInst>(&i)) {
    unary(*x, x->getSingleOperand(), SHLLVM_TO_PROPERTY_KEY);
  } else if (auto *x = llvh::dyn_cast<StringConcatInst>(&i)) {
    if (!x->getNumOperands()) {
      fail(x, "empty StringConcatInst");
      return;
    }
    copy(x, x->getOperand(0));
    for (unsigned n = 1; n != x->getNumOperands(); ++n)
      binary(*x, x, x->getOperand(n), SHLLVM_ADD);
  } else if (auto *x = llvh::dyn_cast<UnaryOperatorInst>(&i)) {
    unsigned op;
    switch (x->getKind()) {
      case ValueKind::UnaryIncInstKind: op = SHLLVM_INC; break;
      case ValueKind::UnaryDecInstKind: op = SHLLVM_DEC; break;
      case ValueKind::UnaryTildeInstKind: op = SHLLVM_BIT_NOT; break;
      case ValueKind::UnaryMinusInstKind: op = SHLLVM_NEG; break;
      case ValueKind::UnaryBangInstKind: op = SHLLVM_NOT; break;
      case ValueKind::UnaryVoidInstKind:
        call("shllvm_constant", {ptr(slot(x)), u32(SHLLVM_UNDEFINED), u64(0)});
        return;
      default: fail(x, "unsupported unary operation"); return;
    }
    unary(*x, x->getSingleOperand(), op);
  } else if (auto *x = llvh::dyn_cast<BinaryOperatorInst>(&i)) {
    unsigned op;
    switch (x->getKind()) {
      case ValueKind::BinaryAddInstKind: op = SHLLVM_ADD; break;
      case ValueKind::BinarySubtractInstKind: op = SHLLVM_SUB; break;
      case ValueKind::BinaryMultiplyInstKind: op = SHLLVM_MUL; break;
      case ValueKind::BinaryDivideInstKind: op = SHLLVM_DIV; break;
      case ValueKind::BinaryModuloInstKind: op = SHLLVM_MOD; break;
      case ValueKind::BinaryEqualInstKind: op = SHLLVM_EQ; break;
      case ValueKind::BinaryNotEqualInstKind: op = SHLLVM_NE; break;
      case ValueKind::BinaryStrictlyEqualInstKind: op = SHLLVM_STRICT_EQ; break;
      case ValueKind::BinaryStrictlyNotEqualInstKind: op = SHLLVM_STRICT_NE; break;
      case ValueKind::BinaryLessThanInstKind: op = SHLLVM_LT; break;
      case ValueKind::BinaryLessThanOrEqualInstKind: op = SHLLVM_LE; break;
      case ValueKind::BinaryGreaterThanInstKind: op = SHLLVM_GT; break;
      case ValueKind::BinaryGreaterThanOrEqualInstKind: op = SHLLVM_GE; break;
      case ValueKind::BinaryOrInstKind: op = SHLLVM_BIT_OR; break;
      case ValueKind::BinaryAndInstKind: op = SHLLVM_BIT_AND; break;
      case ValueKind::BinaryXorInstKind: op = SHLLVM_BIT_XOR; break;
      case ValueKind::BinaryLeftShiftInstKind: op = SHLLVM_SHL; break;
      case ValueKind::BinaryRightShiftInstKind: op = SHLLVM_SHR; break;
      case ValueKind::BinaryUnsignedRightShiftInstKind: op = SHLLVM_USHR; break;
      case ValueKind::BinaryInInstKind: op = SHLLVM_IN; break;
      case ValueKind::BinaryInstanceOfInstKind: op = SHLLVM_INSTANCEOF; break;
      default: fail(x, "unsupported binary operation"); return;
    }
    binary(*x, x->getLeftHandSide(), x->getRightHandSide(), op);
  } else if (auto *x = llvh::dyn_cast<FBinaryMathInst>(&i)) {
    const char *op = nullptr;
    switch (x->getKind()) {
      case ValueKind::FAddInstKind: op = "fadd"; break;
      case ValueKind::FSubtractInstKind: op = "fsub"; break;
      case ValueKind::FMultiplyInstKind: op = "fmul"; break;
      case ValueKind::FDivideInstKind: op = "fdiv"; break;
      case ValueKind::FModuloInstKind: op = "frem"; break;
      default: fail(x, "unsupported floating operation"); return;
    }
    floating(*x, x->getLeft(), x->getRight(), op);
  } else if (auto *x = llvh::dyn_cast<FUnaryMathInst>(&i)) {
    floating(*x, x->getArg(), nullptr, "fneg");
  } else if (auto *x = llvh::dyn_cast<FCompareInst>(&i)) {
    const char *predicate = nullptr;
    switch (x->getKind()) {
      case ValueKind::FEqualInstKind: predicate = "oeq"; break;
      case ValueKind::FNotEqualInstKind: predicate = "une"; break;
      case ValueKind::FLessThanInstKind: predicate = "olt"; break;
      case ValueKind::FLessThanOrEqualInstKind: predicate = "ole"; break;
      case ValueKind::FGreaterThanInstKind: predicate = "ogt"; break;
      case ValueKind::FGreaterThanOrEqualInstKind: predicate = "oge"; break;
      default: fail(x, "unsupported floating comparison"); return;
    }
    compare(*x, x->getLeft(), x->getRight(), predicate);
  } else {
    fail(&i, std::string("unsupported instruction ") + i.getName().str());
  }
}

bool FunctionEmitter::generate() {
  // Keep explicit root/argument storage below 8 KiB. The upstream stack check
  // has a fixed safety gap; admitting a half-megabyte dynamic alloca could jump
  // over that gap before the next check. This is an admission limit, not a total
  // memory bound (LLVM spills and runtime/recursive frames also consume stack).
  if (slots_.size() + 1 + std::max(1u, maxArgs_) > 1024) {
    fail(nullptr, "function exceeds 1024 combined root/argument-slot admission limit");
    return false;
  }
  os_ << "define internal i64 " << module_.functionName(&function_)
      << "(ptr %shr) {\nentry:\n";
  call("_sh_check_native_stack_overflow", {ptr("%shr")});
  auto size = call("shllvm_frame_size", {u32(slots_.size() + 1)}, "i64");
  os_ << "  %storage = alloca i8, i64 " << size << ", align 16\n"
      << "  %argv = alloca [" << std::max(1u, maxArgs_) << " x i64], align 8\n"
      << "  %unit_index = load i32, ptr @shllvm_unit_index, align 4\n";
  module_.import("shllvm_enter", "ptr", {
      ptr(""), ptr(""), u32(0), u32(0), {"i32", ""}});
  os_ << "  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 "
      << slots_.size() + 1 << ", i32 " << maxArgs_ << ", i32 %unit_index)\n";
  module_.import("shllvm_roots", "ptr", {ptr("")});
  os_ << "  %roots = call ptr @shllvm_roots(ptr %storage)\n";
  module_.import("shllvm_get_unit", "ptr", {ptr(""), u32(0)});
  os_ << "  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)\n";
  for (unsigned n = 0; n != slots_.size(); ++n)
    os_ << "  %s" << n << " = getelementptr i64, ptr %roots, i32 " << n << "\n";
  os_ << "  %scratch = getelementptr i64, ptr %roots, i32 " << scratch_ << "\n";
  call("shllvm_check_invocation", {
      ptr("%shr"), ptr("%frame"),
      u32(static_cast<uint32_t>(function_.getProhibitInvoke()))});
  for (auto *constant : constants_)
    emitConstant(constant);
  if (function_.begin() == function_.end()) {
    fail(nullptr, "function has no entry block");
    return false;
  }
  if (!tries_.empty()) {
    auto size = call("shllvm_try_size", {}, "i64");
    os_ << "  %try_storage = alloca i8, i64 " << size << ", align 16\n"
        << "  %try_state = alloca i32, align 4\n"
        << "  store volatile i32 0, ptr %try_state, align 4\n";
    auto buffer = call("shllvm_try_begin", {ptr("%shr"), ptr("%try_storage")}, "ptr");
    module_.import("_setjmp", "i32", {ptr("")});
    auto status = temporary(), exceptional = temporary();
    os_ << "  " << status << " = call i32 @_setjmp(ptr " << buffer << ") returns_twice\n"
        << "  " << exceptional << " = icmp ne i32 " << status << ", 0\n"
        << "  br i1 " << exceptional << ", label %catch.dispatch, label %"
        << block(&function_.front()) << "\n";
  } else {
    os_ << "  br label %" << block(&function_.front()) << "\n";
  }
  for (auto &bb : function_) {
    os_ << block(&bb) << ":\n";
    for (auto &instruction : bb)
      emitInstruction(instruction);
  }
  emitCatchDispatch();
  emitEdges();
  os_ << "}\n\n";
  os_.flush();
  return ok_;
}

void ModuleEmitter::emitData(llvh::raw_ostream &os) {
  std::vector<uint8_t> ascii;
  std::vector<char16_t> utf16;
  std::vector<uint32_t> triples;
  for (const auto &str : strings) {
    if (isAllASCII(str)) {
      triples.push_back(ascii.size());
      triples.push_back(str.size());
      triples.push_back(hashString(llvh::ArrayRef<char>(str.data(), str.size())));
      ascii.insert(ascii.end(), str.begin(), str.end());
      ascii.push_back(0);
    } else {
      std::u16string converted;
      convertUTF8WithSurrogatesToUTF16(
          std::back_inserter(converted), str.data(), str.data() + str.size());
      triples.push_back(utf16.size() | (1u << 31));
      triples.push_back(converted.size());
      triples.push_back(hashString(
          llvh::ArrayRef<char16_t>(converted.data(), converted.size())));
      utf16.insert(utf16.end(), converted.begin(), converted.end());
      utf16.push_back(0);
    }
  }
  if (ascii.empty()) ascii.push_back(0);
  if (utf16.empty()) utf16.push_back(0);
  auto array = [&os](const char *name, const char *type, const auto &values) {
    os << "@" << name << " = private constant [" << values.size()
       << " x " << type << "] [";
    for (size_t i = 0; i != values.size(); ++i) {
      if (i) os << ", ";
      os << type << " " << static_cast<uint64_t>(values[i]);
    }
    os << "]\n";
  };
  array("shllvm_ascii", "i8", ascii);
  array("shllvm_utf16", "i16", utf16);
  array("shllvm_strings", "i32", triples);
  os << "@shllvm_unit_index = internal global i32 0, align 4\n"
     << "@shllvm_unit_name = private constant [12 x i8] c\"llvm_module\\00\"\n"
     << "%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }\n"
     << "@shllvm_functions = private constant [" << functions.size()
     << " x %SHLLVMFunctionInfo] [\n";
  for (unsigned i = 0; i != functions.size(); ++i) {
    auto *f = functions[i];
    if (i) os << ",\n";
    os << "  %SHLLVMFunctionInfo { i32 "
       << string(f->getOriginalOrInferredName().str()) << ", i32 "
       << f->getExpectedParamCountIncludingThis() - 1 << ", i32 "
       << computeFuncKind(f->getKind()) << ", i32 "
       << computeProhibitInvoke(f->getProhibitInvoke()) << " }";
  }
  os << "\n]\n\n";
}

bool ModuleEmitter::generate(llvh::raw_ostream &os) {
  std::vector<std::string> bodies;
  for (auto *function : functions) {
    FunctionEmitter emitter(*this, *function);
    if (!emitter.generate())
      return false;
    bodies.push_back(emitter.text());
  }
  os << "; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.\n"
     << "; Runtime bridge ABI v1; opaque pointers; host native callback ABI.\n"
     << "source_filename = \"hermes-direct-llvm\"\n\n";
  emitData(os);
  import("shllvm_create_unit", "ptr", {
      ptr(""), u32(0), ptr(""), ptr(""), ptr(""), u32(0), ptr(""), ptr(""), ptr("")});
  if (options.emitMain)
    import("shllvm_run", "i32", {{"i32", ""}, ptr(""), ptr("")});
  for (const auto &entry : imports) {
    os << "declare " << entry.second.first << " @" << entry.first << "(";
    for (size_t i = 0; i != entry.second.second.size(); ++i) {
      if (i) os << ", ";
      os << entry.second.second[i];
    }
    os << ")";
    if (entry.first == "_setjmp")
      os << " returns_twice";
    os << "\n";
  }
  os << "\n";
  for (const auto &body : bodies)
    os << body;
  std::string unitName = options.unitName;
  if (unitName.empty())
    unitName = "main";
  // Unit names have already been validated by the shermes driver.
  os << "define ptr @sh_export_" << unitName << "() {\nentry:\n"
     << "  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 "
     << strings.size() << ", ptr @shllvm_ascii, ptr @shllvm_utf16, ptr "
     << "@shllvm_strings, i32 " << functions.size()
     << ", ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)\n"
     << "  ret ptr %unit\n}\n";
  if (options.emitMain)
    os << "\ndefine i32 @main(i32 %argc, ptr %argv) {\nentry:\n"
       << "  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_"
       << unitName << ")\n  ret i32 %status\n}\n";
  return true;
}

} // namespace

bool sh::generateLLVM(
    Module *module,
    llvh::raw_ostream &os,
    const BytecodeGenerationOptions &options) {
  for (char c : options.unitName) {
    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
          (c >= '0' && c <= '9') || c == '_')) {
      module->getContext().getSourceErrorManager().error(
          module->getTopLevelFunction()->getSourceRange().Start,
          "direct LLVM backend: exported unit name must contain only ASCII letters, digits or underscores");
      return false;
    }
  }
  if (!sh::lowerForLLVM(module, options.optimizationEnabled))
    return false;
  if (options.verifyIR) {
    if (!verifyModule(*module, &llvh::errs(), VerificationMode::IR_LOWERED)) {
      module->getContext().getSourceErrorManager().error(
          llvh::SMLoc{}, "Lowered IR verification failed");
      return false;
    }
  }
  module->assignIndexToVariables();
  ModuleEmitter emitter(module, options);
  return emitter.generate(os);
}
