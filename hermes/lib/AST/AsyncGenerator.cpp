/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "hermes/AST/AsyncGenerator.h"
#include "hermes/AST/TransformationsBase.h"

namespace hermes {

/**
 * Transforms JS async generators to generators according to babel
 * transformation
 * https://babeljs.io/docs/babel-plugin-transform-async-generator-functions
 *
 * An async generator:
 *
 * async function* userFunction(arguments) {
 *   // body containing await calls
 * }
 *
 * is transformed into:
 *
 * let userFunction = (() => {
 *      let _ref = _wrapAsyncGenerator(function* (arguments) { // body
 * containing await calls }); return function userFunction() { return
 * _ref.apply(this, arguments);
 *      };
 * })();
 *
 * and an await call inside the async generator body:
 *  await 1;
 *
 * is transformed into:
 *  yield _awaitAsyncGenerator(1);
 *
 * where _awaitAsyncGenerator and _wrapAsyncGenerator are helper functions
 * defined in 04-AsyncIterator.js
 *
 */
class AsyncGenerator : public TransformationsBase {
 public:
  AsyncGenerator(Context &context) : TransformationsBase(context) {}

  void visit(ESTree::FunctionDeclarationNode *funcDecl, ESTree::Node **ppNode) {
    // Lazy functions are not transformed.
    if (llvh::cast<ESTree::BlockStatementNode>(funcDecl->_body)
            ->isLazyFunctionBody)
      return;

    recurseFunctionParameters(funcDecl->_params, funcDecl);
    if (funcDecl->_async && funcDecl->_generator) {
      recurseFunctionBody(funcDecl->_body, true);
      auto *refFunc = transformAsyncGeneratorFunction(
          funcDecl, funcDecl->_params, funcDecl->_body);

      *ppNode = createTransformedNode<ESTree::FunctionDeclarationNode>(
          funcDecl,
          funcDecl->_id,
          std::move(funcDecl->_params),
          refFunc,
          nullptr,
          nullptr,
          nullptr,
          false,
          false);
    } else {
      recurseFunctionBody(funcDecl->_body, false);
    }
  }

  void visit(ESTree::FunctionExpressionNode *funcExpr, ESTree::Node **ppNode) {
    // Lazy functions are not transformed.
    if (llvh::cast<ESTree::BlockStatementNode>(funcExpr->_body)
            ->isLazyFunctionBody)
      return;

    recurseFunctionParameters(funcExpr->_params, funcExpr);
    if (funcExpr->_async && funcExpr->_generator) {
      recurseFunctionBody(funcExpr->_body, true);
      auto *refFunc = transformAsyncGeneratorFunction(
          funcExpr, funcExpr->_params, funcExpr->_body);

      *ppNode = createTransformedNode<ESTree::FunctionExpressionNode>(
          funcExpr,
          funcExpr->_id,
          std::move(funcExpr->_params),
          refFunc,
          nullptr,
          nullptr,
          nullptr,
          false,
          false);
    } else {
      recurseFunctionBody(funcExpr->_body, false);
    }
  }

  void visit(ESTree::ArrowFunctionExpressionNode *arrow, ESTree::Node **) {
    // An arrow is a separate function context. Its returns and awaits must
    // not be rewritten as operations of an enclosing async generator.
    bool oldInsideAsyncGenerator = insideAsyncGenerator;
    insideAsyncGenerator = false;
    visitESTreeChildren(*this, arrow);
    insideAsyncGenerator = oldInsideAsyncGenerator;
  }

  void visit(ESTree::ReturnStatementNode *ret, ESTree::Node **) {
    // Visit the expression itself so direct await/yield roots and nested
    // function expressions are transformed before adding the return await.
    if (ret->_argument) {
      visitESTreeNode(*this, ret->_argument, ret);
    }
    if (!insideAsyncGenerator || !ret->_argument) {
      return;
    }

    // Async generator return expressions are awaited before leaving their
    // source try/catch/finally context. Awaiting the final iterator result
    // in the driver is too late: rejection can no longer enter a catch,
    // and finally may already have executed.
    auto *awaitCall = makeHermesInternalCall(
        ret, "_awaitAsyncGenerator", NodeVector{ret->_argument});
    ret->_argument = createTransformedNode<ESTree::YieldExpressionNode>(
        ret, awaitCall, false);
  }

  void visit(ESTree::AwaitExpressionNode *awaitExpr, ESTree::Node **ppNode) {
    // Transform the operand root, not only its children. This handles
    // nested awaits and async generators inside an awaited expression,
    // including awaits belonging to an ordinary async function.
    visitESTreeNode(*this, awaitExpr->_argument, awaitExpr);
    if (!insideAsyncGenerator) {
      return;
    }

    auto *awaitCall = makeHermesInternalCall(
        awaitExpr, "_awaitAsyncGenerator", NodeVector{awaitExpr->_argument});
    *ppNode = createTransformedNode<ESTree::YieldExpressionNode>(
        awaitExpr, awaitCall, false);
  }

  void visit(ESTree::YieldExpressionNode *yieldExpr, ESTree::Node **ppNode) {
    // Visit each original operand exactly once before adding helper calls.
    // In particular, `yield await value` must keep its explicit await and
    // `yield* await value` must transform that root before delegation.
    if (yieldExpr->_argument) {
      visitESTreeNode(*this, yieldExpr->_argument, yieldExpr);
    }
    if (!insideAsyncGenerator) {
      return;
    }

    if (yieldExpr->_delegate) {
      // Transform:  yield* expr
      //        to:  yield* _asyncGeneratorDelegate(expr)
      //
      // Problem: this async generator has been converted to a regular
      // generator. IRGen compiles `yield*` via genYieldStarExpr, which
      // calls emitGetIteratorSlow → Symbol.iterator. But the argument
      // is typically an async iterable that only has Symbol.asyncIterator,
      // so the lookup returns undefined → TypeError.
      //
      // Solution: _asyncGeneratorDelegate (04-AsyncIterator.js) wraps the
      // async iterable in a sync iterator facade. The wrapper's next/throw/
      // return methods call the corresponding method on the inner async
      // iterator and wrap the resulting promise in OverloadYield(promise, 1)
      // (kind=1 = delegate). The wrapper exposes Symbol.iterator, so IRGen's
      // sync yield* protocol works.
      //
      // At runtime, the outer AsyncGenerator driver (AsyncGenerator.resume)
      // sees the OverloadYield with kind=1, resolves the promise, and if
      // the inner iterator is not done, feeds the resolved {value, done}
      // back into the generator. The wrapper's "waiting" flag causes the
      // next call to return that result directly, completing the sync
      // iteration step. The cycle repeats until the inner iterator is done.
      //
      auto *delegateCall = makeHermesInternalCall(
          yieldExpr,
          "_asyncGeneratorDelegate",
          NodeVector{yieldExpr->_argument});
      *ppNode = createTransformedNode<ESTree::YieldExpressionNode>(
          yieldExpr, delegateCall, true);
      return;
    }

  }

  void visit(ESTree::Node *node) {
    visitESTreeChildren(*this, node);
  }

 private:
  void recurseFunctionParameters(
      ESTree::NodeList &params,
      ESTree::Node *function) {
    // Default expressions can contain async generator functions too. They
    // must be visited before moving the parameters into the wrapper, and
    // must not inherit an enclosing async generator's await/return context.
    bool oldInsideAsyncGenerator = insideAsyncGenerator;
    insideAsyncGenerator = false;
    visitESTreeNodeList(*this, params, function);
    insideAsyncGenerator = oldInsideAsyncGenerator;
  }

  void recurseFunctionBody(ESTree::Node *body, bool insideAsyncGenerator) {
    // recursively transforms all nested async generators and async expressions
    bool oldInsideAsyncGenerator = this->insideAsyncGenerator;
    this->insideAsyncGenerator = insideAsyncGenerator;
    visitESTreeChildren(*this, body);
    this->insideAsyncGenerator = oldInsideAsyncGenerator;
  }

  ESTree::Node *transformAsyncGeneratorFunction(
      ESTree::Node *funcNode,
      ESTree::NodeList &params,
      ESTree::Node *body) {
    auto *refFunc = createTransformedNode<ESTree::FunctionExpressionNode>(
        funcNode,
        nullptr, // id is null for anonymous function
        std::move(params), // params
        body,
        nullptr, // typeParameters
        nullptr, // returnType
        nullptr, // predicate
        true, // generator
        false); // async

    // Empty async generators still require Promise-returning iterator
    // methods and Symbol.asyncIterator, so they must use the driver too.
    auto *wrappedRef = makeHermesInternalCall(
        funcNode, "_wrapAsyncGenerator", NodeVector{refFunc});

    // Create a function body that calls apply on the wrapped function
    auto appliedBody = createTransformedNode<ESTree::BlockStatementNode>(
        funcNode,
        NodeVector{
            createTransformedNode<ESTree::ReturnStatementNode>(
                funcNode,
                createTransformedNode<ESTree::CallExpressionNode>(
                    funcNode,
                    createTransformedNode<ESTree::MemberExpressionNode>(
                        funcNode,
                        wrappedRef,
                        makeIdentifierNode(funcNode, "apply"),
                        false),
                    nullptr,
                    NodeVector{
                        createTransformedNode<ESTree::ThisExpressionNode>(
                            funcNode),
                        makeIdentifierNode(funcNode, "arguments")}
                        .toNodeList()))}
            .toNodeList(),
        /* implicit */ false);

    return appliedBody;
  }

  ESTree::Node *getHermesInternalIdentifier(ESTree::Node *srcNode) override {
    return makeIdentifierNode(srcNode, "HermesAsyncIteratorsInternal");
  };

  bool insideAsyncGenerator = false;
};

ESTree::Node *transformAsyncGenerators(Context &context, ESTree::Node *node) {
  AsyncGenerator transformer(context);
  visitESTreeNode(transformer, node, nullptr);
  return node;
}

} // namespace hermes
