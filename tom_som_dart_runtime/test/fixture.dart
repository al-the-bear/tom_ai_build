import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// A small, hand-built spec-model meta-data map used across the runtime tests.
///
/// Shape mirrors `tom_specs_clitool/bin/model_json.dart`'s exporter: a class
/// graph keyed by class name, plus a `roots` list and a version stamp. Building
/// it through [SpecModel.fromJson] doubles as the decoder test.
Map<String, dynamic> fixtureJson() => {
      'modelVersion': 7,
      'modelVersionLabel': '0.7.0+7.abc1234',
      'roots': [
        {
          'type': 'ProjectDefinition',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'doc': 'Root of a project definition document.',
          'annotations': [
            {
              'name': 'Document',
              'arguments': {'title': 'Project Definition'},
            },
            {'name': 'SectionId', 'arguments': {'id': 'PD00'}},
          ],
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'vision',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
            {
              'name': 'owner',
              'kind': 'form',
              'sectionId': 'owner',
              'formFields': [
                {'name': 'name', 'label': 'Name', 'type': 'String'},
                {'name': 'role', 'label': 'Role', 'type': 'String'},
              ],
            },
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'risks',
              'elementType': 'Risk',
              'elementIsComplex': true,
              'min': 2,
              'annotations': [
                {'name': 'Min', 'arguments': {'value': 2}},
              ],
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'tags',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              'name': 'situation',
              'kind': 'complex',
              'sectionId': 'situation',
              'type': 'CurrentSituation',
            },
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'title',
              'contentType': 'text',
            },
            {
              'name': 'probability',
              'kind': 'enum',
              'sectionId': 'prob',
              'enumValues': ['low', 'medium', 'high'],
            },
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'fields': [
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'summary',
              'contentType': 'text',
            },
          ],
        },
      },
    };

/// The fixture decoded into a live [SpecModel].
SpecModel fixtureModel() => SpecModel.fromJson(fixtureJson());
