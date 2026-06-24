/// Tests for the §11 [AgentContext] — the per-application context
/// ({guidelines doc, tool set, scope profile}) realised over Tom Brain
/// profiles/sessions/memory (plan step 17).
///
/// The done-criterion: *switching application swaps profile → guidelines +
/// tools + scopes + memory*, exercised with the DocSpecs profile.
library;

import 'package:tom_spec_engine/tom_spec_engine.dart';
import 'package:test/test.dart';

import 'support/agent_test_fixture.dart';

/// A trivial scope with no libraries/globals/grants, used only to assert the
/// profile-driven environment lists the right scope names.
ScriptScope _emptyScope(String name) => ScriptScope(name: name);

ScopeRegistry _registryWith(Iterable<String> names) {
  final registry = ScopeRegistry();
  for (final name in names) {
    registry.register(_emptyScope(name));
  }
  return registry;
}

void main() {
  group('canonical application mapping (Q1 / F1)', () {
    test('the three applications are the phase-ordered profile names', () {
      expect(docSpecsApplication, 'docspecs');
      expect(codeSpecsApplication, 'codespecs');
      expect(implementationApplication, 'implementation');
      expect(tomSpecsApplications, [
        docSpecsApplication,
        codeSpecsApplication,
        implementationApplication,
      ]);
    });

    test('the application names are distinct', () {
      expect(tomSpecsApplications.toSet(), hasLength(3));
    });

    test('DocSpecs is the reference application and binds its profile name', () {
      expect(docSpecsAgentContext().application, docSpecsApplication);
      expect(docSpecsAgentContext().profileName, docSpecsApplication);
    });
  });

  group('docSpecsAgentContext', () {
    test('binds the DocSpecs guidelines, all four tool groups, and the three '
        'base scopes', () {
      final context = docSpecsAgentContext();

      expect(context.application, 'docspecs');
      expect(context.guidelinesName, docSpecsGuidelinesName);
      expect(context.guidelinesName, 'guidelines_specification.md');
      expect(
        context.toolset,
        {
          AgentToolGroup.doc,
          AgentToolGroup.memory,
          AgentToolGroup.file,
          AgentToolGroup.script,
        },
      );
      expect(context.scopeProfile.name, 'docspecs');
      expect(context.scopeProfile.scopeNames, ['spec', 'files', 'memory']);
    });

    test('profileName is the application; memoryScope addresses session + '
        'document with the document as the Tom Brain profile', () {
      final context = docSpecsAgentContext();

      expect(context.profileName, 'docspecs');

      final scope = context.memoryScope(session: 'phase3', document: 'PD00');
      expect(scope.application, 'docspecs');
      expect(scope.session, 'phase3');
      expect(scope.document, 'PD00');
      expect(scope.profileName, 'PD00');
    });

    test('buildEnvironment unions exactly the profile scopes', () {
      final context = docSpecsAgentContext();
      final registry = _registryWith(['spec', 'files', 'memory']);

      final env = context.buildEnvironment(registry);

      expect(env.scopeNames, ['spec', 'files', 'memory']);
    });
  });

  group('codeSpecsAgentContext (item 10 / F10)', () {
    test('binds the CodeSpecs guidelines, the full four-group surface, and the '
        'three base scopes', () {
      final context = codeSpecsAgentContext();

      expect(context.application, codeSpecsApplication);
      expect(context.application, 'codespecs');
      expect(context.profileName, codeSpecsApplication);
      expect(context.guidelinesName, codeSpecsGuidelinesName);
      expect(context.guidelinesName, 'guidelines_codespecs.md');
      expect(context.toolset, {
        AgentToolGroup.doc,
        AgentToolGroup.memory,
        AgentToolGroup.file,
        AgentToolGroup.script,
      });
      expect(context.scopeProfile.name, 'codespecs');
      expect(context.scopeProfile.scopeNames, ['spec', 'files', 'memory']);
    });

    test('memoryScope addresses the CodeSpecs profile + session + document', () {
      final scope = codeSpecsAgentContext()
          .memoryScope(session: 'phase4', document: 'CS00');
      expect(scope.application, 'codespecs');
      expect(scope.session, 'phase4');
      expect(scope.document, 'CS00');
      expect(scope.profileName, 'CS00');
    });
  });

  group('implementationAgentContext (item 10 / F10)', () {
    test('binds the Implementation guidelines, the full four-group surface, and '
        'the three base scopes', () {
      final context = implementationAgentContext();

      expect(context.application, implementationApplication);
      expect(context.application, 'implementation');
      expect(context.profileName, implementationApplication);
      expect(context.guidelinesName, implementationGuidelinesName);
      expect(context.guidelinesName, 'guidelines_implementation.md');
      expect(context.toolset, {
        AgentToolGroup.doc,
        AgentToolGroup.memory,
        AgentToolGroup.file,
        AgentToolGroup.script,
      });
      expect(context.scopeProfile.name, 'implementation');
      expect(context.scopeProfile.scopeNames, ['spec', 'files', 'memory']);
    });
  });

  group('the three contexts are distinct applications with distinct prompts',
      () {
    test('each canonical application binds its own guidelines + profile name',
        () {
      final contexts = [
        docSpecsAgentContext(),
        codeSpecsAgentContext(),
        implementationAgentContext(),
      ];

      expect(
        contexts.map((c) => c.application).toList(),
        tomSpecsApplications,
      );
      // Distinct guidelines prompts — the real differentiator (F10).
      expect(
        contexts.map((c) => c.guidelinesName).toSet(),
        hasLength(3),
      );
      // Distinct scope-profile labels.
      expect(
        contexts.map((c) => c.scopeProfile.name).toSet(),
        {'docspecs', 'codespecs', 'implementation'},
      );
    });
  });

  group('tomSpecsContextRegistry (item 10 / F10)', () {
    test('registers all three canonical applications, each resolving to its own '
        'context', () {
      final registry = tomSpecsContextRegistry();

      expect(registry.applications.toSet(), tomSpecsApplications.toSet());
      for (final application in tomSpecsApplications) {
        expect(registry.has(application), isTrue);
        expect(registry.context(application).application, application);
      }

      expect(registry.context(codeSpecsApplication).guidelinesName,
          codeSpecsGuidelinesName);
      expect(registry.context(implementationApplication).guidelinesName,
          implementationGuidelinesName);
    });
  });

  group('AgentContext construction', () {
    test('rejects a toolset whose tool needs a scope the profile omits', () {
      expect(
        () => AgentContext(
          application: 'broken',
          guidelinesName: 'g.md',
          toolset: {AgentToolGroup.file},
          scopeProfile: ScopeProfile(name: 'broken', scopeNames: ['spec']),
        ),
        throwsArgumentError,
      );
    });

    test('accepts a toolset fully covered by the profile scopes', () {
      final context = AgentContext(
        application: 'readonly',
        guidelinesName: 'readonly_guidelines.md',
        toolset: {AgentToolGroup.doc, AgentToolGroup.memory},
        scopeProfile: ScopeProfile(name: 'readonly', scopeNames: ['spec', 'memory']),
      );

      expect(context.toolset, {AgentToolGroup.doc, AgentToolGroup.memory});
      expect(context.scopeProfile.scopeNames, ['spec', 'memory']);
    });
  });

  group('AgentContextRegistry', () {
    test('switching application swaps guidelines + tools + scopes', () {
      final readonly = AgentContext(
        application: 'readonly',
        guidelinesName: 'readonly_guidelines.md',
        toolset: {AgentToolGroup.doc, AgentToolGroup.memory},
        scopeProfile:
            ScopeProfile(name: 'readonly', scopeNames: ['spec', 'memory']),
      );
      final registry = AgentContextRegistry()
        ..register(docSpecsAgentContext())
        ..register(readonly);

      expect(registry.applications, containsAll(['docspecs', 'readonly']));

      final docspecs = registry.context('docspecs');
      expect(docspecs.guidelinesName, 'guidelines_specification.md');
      expect(docspecs.toolset, hasLength(4));
      expect(docspecs.scopeProfile.scopeNames, ['spec', 'files', 'memory']);

      final ro = registry.context('readonly');
      expect(ro.guidelinesName, 'readonly_guidelines.md');
      expect(ro.toolset, {AgentToolGroup.doc, AgentToolGroup.memory});
      expect(ro.scopeProfile.scopeNames, ['spec', 'memory']);
    });

    test('an unknown application throws', () {
      final registry = AgentContextRegistry()..register(docSpecsAgentContext());
      expect(() => registry.context('nope'), throwsA(isA<ArgumentError>()));
      expect(registry.has('nope'), isFalse);
      expect(registry.has('docspecs'), isTrue);
    });
  });

  group('brainSubstrate', () {
    test('builds a tom_brain substrate addressed by the context memory scope',
        () {
      final context = docSpecsAgentContext();
      final fixture = buildAgentFixture();
      final envelope = RecordingBrainEnvelope();

      final substrate = context.brainSubstrate(
        tools: fixture.tools,
        envelope: envelope,
        session: 'phase3',
        document: 'PD00',
      );

      expect(substrate.mode, 'tom_brain');
      expect(
        substrate.scope,
        context.memoryScope(session: 'phase3', document: 'PD00'),
      );
    });
  });
}
