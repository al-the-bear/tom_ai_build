// csra6: the Cs*Ref typed cross-part reference const family
// (`codespecs_mapping.md` §5.23).
//
// The design these tests pin: a cross-part edge inside CodeSpecs code is a Dart
// const reference, never a string literal. The owning part declares each
// referenceable identity ONCE on its catalogue class; every citing site holds
// that const. So a rename is a compile error rather than a dangling id.
//
// Three properties carry the whole design, and each is asserted below:
//
//  1. Every ref is const-constructible — const is what makes it legal in an
//     annotation argument list, which is where csrb4 will put them.
//  2. The kinds are DISTINCT TYPES. Passing a route ref where an operation ref
//     is expected is itself a compile error (`codespecs_mapping.md` §5.23: "not
//     one generic CsRef").
//  3. The stable string id still exists, authored once INSIDE the const — it is
//     what `codespecs_mapping.md` §9.2/§9.3 serialization and the generated
//     lowered runtime forms carry. Citations never repeat it.

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:test/test.dart';

// The `codespecs_mapping.md` §5.23 declaration pattern, on a real annotated
// class: the CE-API operation catalogue declares each operation's ref const
// exactly once. Per N7 this is the one `<canonical>_catalog.dart` file per
// catalogue.
@CsEndpoint()
@CodeSpec('API-CATALOG', source: ['IFM-OPS'])
class _OperationCatalog {
  static const login = CsOperationRef('login');
  static const customerSave = CsOperationRef('customer.save');
}

// A citing part holds the OTHER part's const — never a copy of its string.
// Renaming `_OperationCatalog.login` breaks this line at compile time, which is
// the entire point of the family (`codespecs_mapping.md` §5.23: the compiler is
// the `codespecs_mapping.md` §4.2 cross-part integrity checker).
@CsServerCall()
@CodeSpec('SC-LOGIN', source: ['ISC-LOGIN'])
class _LoginServerCall {
  static const operation = _OperationCatalog.login;
}

// Refs must be legal ANNOTATION ARGUMENTS — that is what they exist for, and
// what `const` buys. `csrb4` authors the real per-marker constructors from
// `codespecs_derivation_contract.md` §5.1; this local marker asserts only the
// property (a Cs*Ref may be passed to an annotation), never a chosen shape.
class _RefBearingMarker {
  final CsRouteRef route;

  const _RefBearingMarker(this.route);
}

@_RefBearingMarker(_RouteCatalog.orderList)
class _OrderListScreen {}

@CsRoute()
@CodeSpec('NV-ROUTES', source: ['XDS-NAV'])
class _RouteCatalog {
  static const orderList = CsRouteRef('orderList');
}

void main() {
  group('csra6: shared-locus refs', () {
    test('CsOperationRef carries the operation name verbatim (N5)', () {
      // Operation names are authored keys, so N9 takes them character for
      // character rather than re-deriving a name from them.
      expect(_OperationCatalog.customerSave.id, 'customer.save');
      expect(_OperationCatalog.login.id, 'login');
    });

    test('CsMessageKey and CsErrorCode wrap their authored keys', () {
      expect(const CsMessageKey('order.shipped').id, 'order.shipped');
      expect(const CsErrorCode('ERR-ORD-014').id, 'ERR-ORD-014');
    });

    test('CsRoleRef and CsResourceKeyRef wrap the CE-AZ catalogues', () {
      expect(const CsRoleRef('orderApprover').id, 'orderApprover');
      expect(const CsResourceKeyRef('customer.iban').id, 'customer.iban');
    });
  });

  group('csra6: client-locus refs', () {
    test(
      'CsCallRef, CsActionRef and CsRouteRef wrap their declaration names',
      () {
        expect(const CsCallRef('loginServerCall').id, 'loginServerCall');
        expect(const CsActionRef('submitOrder').id, 'submitOrder');
        expect(const CsRouteRef('orderList').id, 'orderList');
      },
    );

    test('CsFormRef wraps the form declaration name', () {
      expect(const CsFormRef('customerForm').id, 'customerForm');
    });

    // csrb15's member-level question. A standalone element (Button, MenuEntry)
    // is a class-level target; a form-member element is a MEMBER of the
    // `@CsForm` class. One type with an optional owning-form qualifier covers
    // both, because `codespecs_derivation_contract.md` §5.1's `@CsTrigger`
    // takes `CsElementRef` in both its
    // `element` and `formField` slots — two types could not fill one parameter.
    test('CsElementRef defaults to a standalone, class-level element', () {
      const ref = CsElementRef('submitButton');
      expect(ref.id, 'submitButton');
      expect(ref.form, isNull);
      expect(ref.path, 'submitButton');
    });

    test('CsElementRef qualified by a form yields the dotted N9 path', () {
      const ref = CsElementRef('email', form: 'customerForm');
      expect(ref.id, 'email');
      expect(ref.form, 'customerForm');
      expect(ref.path, 'customerForm.email');
    });
  });

  group('csra6: server-locus refs', () {
    test('CsServiceUnitRef, CsReportRef and CsJobRef wrap their names', () {
      expect(const CsServiceUnitRef('orderService').id, 'orderService');
      expect(const CsReportRef('salesByRegion').id, 'salesByRegion');
      expect(
        const CsJobRef('nightlyReconciliation').id,
        'nightlyReconciliation',
      );
    });
  });

  group('csra6: the family-wide invariants', () {
    // Const canonicalization gives value equality for free: two consts built
    // from the same argument ARE the same instance. The family therefore needs
    // no hand-written `==`, and a spec that declares an identity twice by
    // accident still compares equal rather than silently differing.
    test('equal ids canonicalize to one instance', () {
      expect(
        identical(const CsRouteRef('home'), const CsRouteRef('home')),
        isTrue,
      );
      expect(
        identical(
          const CsElementRef('email', form: 'customerForm'),
          const CsElementRef('email', form: 'customerForm'),
        ),
        isTrue,
      );
    });

    // `codespecs_mapping.md` §5.23: "Distinct types, not one generic CsRef" —
    // cross-KIND misuse must be type-checked. There is deliberately no shared
    // supertype: a parameter typed as one would accept every kind, which is the
    // generic ref the design rejects. The runtime assertion below stands in for
    // the compile-time one (a `CsRouteRef` simply cannot be written where a
    // `CsOperationRef` is required, so the negative case is unwritable in
    // Dart).
    test('no two ref kinds share a type', () {
      const refs = <Object>[
        CsOperationRef('x'),
        CsCallRef('x'),
        CsActionRef('x'),
        CsRouteRef('x'),
        CsMessageKey('x'),
        CsErrorCode('x'),
        CsRoleRef('x'),
        CsResourceKeyRef('x'),
        CsServiceUnitRef('x'),
        CsReportRef('x'),
        CsJobRef('x'),
        CsElementRef('x'),
        CsFormRef('x'),
      ];
      expect(
        refs.length,
        13,
        reason: 'codespecs_mapping.md §5.23 eleven + csrb15 two',
      );
      expect(refs.map((r) => r.runtimeType).toSet().length, refs.length);
    });

    test('a ref is a legal annotation argument', () {
      // Reaching the annotated class at all means the annotation compiled,
      // which is the assertion; the const is the citation, not its string.
      expect(_OrderListScreen(), isA<_OrderListScreen>());
    });

    test('citations hold the const, not a copy of the id string', () {
      expect(
        identical(_LoginServerCall.operation, _OperationCatalog.login),
        isTrue,
      );
      expect(_LoginServerCall.operation.id, 'login');
    });
  });
}
