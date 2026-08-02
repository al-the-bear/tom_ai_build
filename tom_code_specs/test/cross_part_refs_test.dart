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
//     annotation argument list, which is where the `Cs*` markers take them
//     (`codespecs_derivation_contract.md` §5.1).
//  2. The kinds are DISTINCT TYPES. Passing a route ref where an operation ref
//     is expected is itself a compile error (`codespecs_mapping.md` §5.23: "not
//     one generic CsRef").
//  3. The stable string id still exists, authored once INSIDE the const — it is
//     what `codespecs_mapping.md` §9.2/§9.3 serialization and the generated
//     lowered runtime forms carry. Citations never repeat it.

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:test/test.dart';

// The `codespecs_mapping.md` §5.23 declaration pattern: the CE-API operation
// catalogue declares each operation's ref const exactly once. Per N7 this is the
// one `<canonical>_catalog.dart` file per catalogue. The catalogue itself is not
// a part — it holds the identities the parts cite — so it carries `@CodeSpec`
// for the back-trace and no part marker.
@CodeSpec('API-CATALOG', source: ['IFM-OPS'])
class _OperationCatalog {
  static const login = CsOperationRef('login');
  static const customerSave = CsOperationRef('customer.save');
}

// A citing part holds the OTHER part's const — never a copy of its string, and
// the citation is the ANNOTATION ARGUMENT, which is what `const` buys.
// Renaming `_OperationCatalog.login` breaks this line at compile time, which is
// the entire point of the family (`codespecs_mapping.md` §5.23: the compiler is
// the `codespecs_mapping.md` §4.2 cross-part integrity checker).
@CsServerCall(_OperationCatalog.login)
@CodeSpec('SC-LOGIN', source: ['ISC-LOGIN'])
class _LoginServerCall {
  static const operation = _OperationCatalog.login;
}

@CodeSpec('NV-ROUTES', source: ['XDS-NAV'])
class _RouteCatalog {
  @CsRoute()
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

    test('a route catalogue declares each route ref once', () {
      expect(_RouteCatalog.orderList.id, 'orderList');
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
        reason: 'codespecs_mapping.md §5.23 declares the family CLOSED at '
            'thirteen. A fourteenth entry here without that table changing '
            'means the set was widened silently.',
      );
      expect(refs.map((r) => r.runtimeType).toSet().length, refs.length);
    });

    test('a ref is a legal argument of the real Cs* markers', () {
      // Reaching the annotated class at all means `@CsServerCall(
      // _OperationCatalog.login)` compiled, which is the assertion; the const is
      // the citation, not its string.
      expect(_LoginServerCall(), isA<_LoginServerCall>());
    });

    test('citations hold the const, not a copy of the id string', () {
      expect(
        identical(_LoginServerCall.operation, _OperationCatalog.login),
        isTrue,
      );
      expect(_LoginServerCall.operation.id, 'login');
    });
  });

  // `codespecs_mapping.md` §5.23 scope rule: the family governs edges that LEAVE
  // the authoring part. An edge landing inside the same part is a local
  // coordinate, and typing it would widen the family from "how parts cite each
  // other" to "how any id is written". The CE-NT channel fallback is the live
  // case — a channel falls back to a SIBLING CHANNEL, so the edge never leaves
  // CE-NT.
  group('the intra-part boundary: a CE-NT channel fallback stays a string', () {
    test('@CsNotificationChannel takes no reference argument', () {
      // The assertion is that this line compiles with no argument at all. A
      // `CsChannelRef` added to the family would have to arrive here as a
      // parameter to be usable — the marker is the channel's only annotation —
      // so a bare construction failing is what would signal the decision being
      // reversed without the documents moving.
      const marker = CsNotificationChannel();
      expect(marker.note, isNull);
    });

    test('the fallback edge is carried as a plain id string', () {
      // Stands in for `TomNotificationChannelDeclaration` (`tom_core_codespecs`,
      // which this package deliberately does not depend on — the substrate must
      // never depend on the annotation framework). The shape is the point: the
      // fallback rides the DECLARATION as a String, not the annotation as a
      // const, so nothing here could hold a ref even if one existed.
      const channel = _SmsChannel();
      expect(channel.fallbackChannelId, 'email');
      expect(channel.fallbackChannelId, isA<String>());
    });
  });
}

/// A CE-NT channel declaration in the shape §3.2.9 emits: the marker carries
/// nothing, the substrate carries `channelId` and the sibling-channel fallback.
///
/// Resolution of that fallback is `codespecs_derivation_contract.md` §6
/// check 17's job — a generation-time validator check, because §5.23 rules the
/// edge a local coordinate and so no compile-time guard will ever cover it.
@CsNotificationChannel()
@CodeSpec('NT-SMS', source: ['NTFCH'])
class _SmsChannel {
  final String channelId = 'sms';
  final String fallbackChannelId = 'email';

  const _SmsChannel();
}
