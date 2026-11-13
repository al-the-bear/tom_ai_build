/// The AsyncAPI 3 emitter (`irspecs_ir.md` §10.1): what the IR says about
/// messages that are not request and response — the notification channels and
/// notification types (CE-NT), and the jobs a system event starts (CE-JB).
library;

import '../../codespecs/cs_model.dart';
import '../ir_model.dart';
import 'emit_common.dart';

/// The AsyncAPI version the document is written in.
const String kAsyncApiVersion = '3.0.0';

/// The file the AsyncAPI emitter writes.
const String kAsyncApiFile = 'asyncapi.json';

/// Emits [documents] as one AsyncAPI 3 document, `asyncapi.json`:
///
/// * each `@CsNotificationChannel` declaration a channel;
/// * each `@CsNotification` declaration a message under
///   `components.messages`, its payload the declaration's fields;
/// * each `@CsJob` whose trigger is `event` a channel named after the event
///   and a `receive` operation, named after the job, on it.
///
/// A document with neither still validates: it is the `info` alone.
IrEmission emitAsyncApi(List<IrDocument> documents) {
  final index = IrIndex(documents);
  final notExpressed = <String>[];
  final channels = <String, Object?>{};
  final operations = <String, Object?>{};
  final messages = <String, Object?>{};

  for (final e in index.inArea('CE-NT')) {
    final d = e.declaration;
    final doc = irDocText(d);
    if (irMarker(d, 'CsNotificationChannel') != null) {
      channels[_key(d.name)] = {'address': d.name, 'description': ?doc};
    }
    final notification = irMarker(d, 'CsNotification');
    if (notification != null) {
      messages[_key(d.name)] = {
        'name': d.name,
        'description': ?doc,
        'payload': _payload(index, e, notExpressed),
      };
      final body = irString(notification.named['body']);
      notExpressed.add(
        'CE-NT ${d.name}: the channels it goes out on and its body copy'
        '${body == null ? '' : ' `$body`'} (constructor values of '
        'TomNotificationType, not marker arguments; a message has no copy key)',
      );
    }
  }

  for (final e in index.inArea('CE-JB')) {
    final d = e.declaration;
    final job = irMarker(d, 'CsJob');
    if (job == null) continue;
    final trigger = irString(job.named['trigger']);
    final event = irString(job.named['event']);
    if (trigger == 'event' && event != null) {
      final channel = _key(event);
      channels.putIfAbsent(channel, () => {'address': event});
      operations[_key(d.name)] = {
        'action': 'receive',
        'channel': {r'$ref': '#/channels/$channel'},
        if (irDocText(d) != null) 'description': irDocText(d),
      };
      notExpressed.add(
        'CE-JB ${d.name}: its retries, backoff and timeout (job policy, not '
        'message shape)',
      );
    } else {
      notExpressed.add(
        'CE-JB ${d.name}: the ${trigger ?? 'unnamed'} trigger (a schedule, '
        'not a message)',
      );
    }
  }

  return IrEmission({
    kAsyncApiFile: irJson({
      'asyncapi': kAsyncApiVersion,
      'info': {
        'title': index.title,
        // The IR carries no API version.
        'version': 'unversioned',
      },
      if (channels.isNotEmpty) 'channels': channels,
      if (operations.isNotEmpty) 'operations': operations,
      if (messages.isNotEmpty) 'components': {'messages': messages},
    }),
  }, notExpressed);
}

/// An AsyncAPI component or channel key: `^[\w\d\.\-_]+$`, so any other
/// character becomes `_`.
String _key(String name) => name.replaceAll(RegExp(r'[^\w.\-]'), '_');

/// The payload schema of a notification type: an object of its fields.
Map<String, Object?> _payload(
  IrIndex index,
  IrEntry e,
  List<String> notExpressed,
) {
  final builder = IrSchemaBuilder(
    index,
    refBase: '#/components/schemas/',
    notExpressed: notExpressed,
  );
  final properties = <String, Object?>{};
  for (final m in index.membersOf(e)) {
    if (m.kind != CsDeclarationKind.field || m.isStatic) continue;
    final type = m.declaredType;
    properties[m.name] = type == null
        ? <String, Object?>{}
        : builder.fieldSchema(type, 'CE-NT ${e.declaration.name}.${m.name}');
  }
  return {'type': 'object', 'properties': properties};
}
