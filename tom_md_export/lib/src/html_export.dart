/// Markdown with the reading notation to HTML, through the MD Browser's own
/// renderer.
///
/// The VS Code extension's MD Browser renders Markdown with `marked` and the
/// notation's extensions; their scanning (`mdbReadingDivToken`,
/// `mdbReadingSpan`, `mdbCitation`, `mdbReadingBlockStart`, the kind table
/// `MDB_READING_KINDS`) is `media/markdownBrowser/blocks.js`. The export runs
/// that file and the extension's `marked` in Node, **in place** — loaded from
/// the extension's checkout, never copied — so the HTML a stakeholder gets is
/// tokenised as the reviewer saw it. Only the HTML of the kinds is the
/// export's own: a collapsed kind is a `<details>` element (no script), a
/// compact one its content, an unknown kind its content plainly.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'kind_styles.dart' show wideTableColumns;

/// Node or the MD Browser is missing.
class HtmlExportUnavailable implements Exception {
  /// The error, naming what was looked for.
  const HtmlExportUnavailable(this.message);

  /// What is missing and how to provide it.
  final String message;

  @override
  String toString() => 'HtmlExportUnavailable: $message';
}

/// The base style of an exported HTML page.
const String htmlBaseCss = '''
body { margin: 0; background: #fff; color: #1f2328; }
main { max-width: 60rem; margin: 0 auto; padding: 2rem 1.5rem 4rem;
  font: 15px/1.55 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
h1, h2, h3, h4, h5, h6, .heading7, [class^="heading"] { line-height: 1.25; }
h1 { font-size: 1.9em; border-bottom: 1px solid #d8dee4; padding-bottom: .3em; }
h2 { font-size: 1.45em; border-bottom: 1px solid #d8dee4; padding-bottom: .25em; }
code { font: .88em ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  background: #f3f4f6; padding: .1em .3em; border-radius: 4px; }
pre { background: #f6f8fa; padding: .8em 1em; border-radius: 6px; overflow-x: auto; }
pre code { background: none; padding: 0; }
blockquote { margin: 0 0 1em; padding: 0 1em; color: #57606a; border-left: .25em solid #d0d7de; }
table { border-collapse: collapse; margin: 0 0 1em; display: block; overflow-x: auto; max-width: 100%; }
th, td { border: 1px solid #d0d7de; padding: .3em .6em; vertical-align: top; text-align: left; }
th { background: #f6f8fa; }
table.tm-wide { font-size: .8em; }
a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }
''';

/// The built-in kinds stylesheet: the secondary kinds smaller and muted, a
/// collapsed kind a `<details>` with its kind and a preview, `refs` compact,
/// `rejected` framed — as the MD Browser shows them.
const String htmlKindCss = '''
details.tm-kind { margin: .4em 0; color: #57606a; font-size: .88em; }
details.tm-kind > summary { cursor: pointer; list-style: none; }
details.tm-kind > summary::-webkit-details-marker { display: none; }
details.tm-kind > summary::before { content: "\\25B8  "; }
details.tm-kind[open] > summary::before { content: "\\25BE  "; }
.tm-kind-name { font-variant: small-caps; font-weight: 600; letter-spacing: .03em; }
.tm-preview { opacity: .75; }
details.tm-kind[open] .tm-preview { display: none; }
details.tm-kind > .tm-body { border-left: 2px solid #d0d7de; padding-left: .8em; margin-top: .3em; }
details.tm-kind[data-kind="rejected"] { color: #a40e26; }
details.tm-kind[data-kind="rejected"] > .tm-body { border-left-color: #cf222e; }
.tm-source { font-size: .9em; margin-bottom: .3em; }
div.tm-kind[data-kind="refs"] { font-size: .9em; }
div.tm-kind[data-kind="refs"] p { margin: .2em 0; }
.tm-span, .tm-cite { color: #6e7781; font-size: .85em; }
''';

/// The Node script that renders. It reads its configuration (JSON) from its
/// first argument: `extension` (the extension's checkout), `input`,
/// `output`, `notation`, `css`, `documentNames`, `wideColumns`.
const String htmlExportScript = r'''
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const cfg = JSON.parse(process.argv[2]);
const { Marked, Renderer } = require(path.join(cfg.extension, 'node_modules', 'marked'));
const ctx = { console: console };
vm.createContext(ctx);
const blocks = path.join(cfg.extension, 'media', 'markdownBrowser', 'blocks.js');
vm.runInContext(fs.readFileSync(blocks, 'utf8'), ctx, { filename: blocks });
const KINDS = ctx.MDB_READING_KINDS;
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
const plain = (md) => String(md || '').replace(/`+/g, '').replace(/\*{1,3}|~~/g, '')
  .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
const known = (k) => Object.prototype.hasOwnProperty.call(KINDS, k);
const self = new Set(cfg.documentNames);
const md = new Marked({ gfm: true });
// Links to this document's own renditions become links within the page.
// A link renderer rather than walkTokens: marked's walkTokens collects its
// results by concatenation, quadratic in the number of tokens (66 s on Tom
// UAM's Information Model against 0.5 s without it).
const base = new Renderer();
md.use({
  renderer: {
    link(token) {
      const i = token.href.indexOf('#');
      if (i > 0) {
        const file = token.href.slice(0, i);
        if (self.has(file) || self.has(file.split('/').pop())) {
          return base.link.call(this, Object.assign({}, token, { href: token.href.slice(i) }));
        }
      }
      return base.link.call(this, token);
    },
    table(token) {
      const html = base.table.call(this, token);
      return token.header.length >= cfg.wideColumns ? html.replace('<table>', '<table class="tm-wide">') : html;
    },
  },
});
if (cfg.notation) {
  md.use({ extensions: [{
    name: 'readingDiv',
    level: 'block',
    start(src) { return ctx.mdbReadingBlockStart(src); },
    tokenizer(src) { return ctx.mdbReadingDivToken(src, this.lexer); },
    renderer(token) {
      if (token.stray) return '<p>:::</p>\n';
      const inner = this.parser.parse(token.tokens);
      const kind = token.kind || '';
      if (!known(kind)) return inner;
      const attrs = token.attrs || {};
      const source = kind === 'provenance' && attrs.source
        ? '<div class="tm-source">source: <a href="' + esc(attrs.source) + '">' + esc(attrs.source) + '</a></div>' : '';
      if (ctx.mdbReadingMode(null, kind, false) === 'collapsed') {
        const p = plain(token.text);
        const preview = p.length > 60 ? p.slice(0, 60) + '…' : p;
        return '<details class="tm-kind" data-kind="' + esc(kind) + '"><summary><span class="tm-kind-name">'
          + esc(attrs.label || kind) + '</span>' + (preview ? ' <span class="tm-preview">— ' + esc(preview) + '</span>' : '')
          + '</summary><div class="tm-body">' + source + inner + '</div></details>\n';
      }
      return '<div class="tm-kind" data-kind="' + esc(kind) + '">' + source + inner + '</div>\n';
    },
  }, {
    name: 'readingSpan',
    level: 'inline',
    start(src) { const i = src.indexOf('['); return i < 0 || src.indexOf(']{', i) < 0 ? undefined : i; },
    tokenizer(src) {
      const m = ctx.mdbReadingSpan(src);
      if (!m) return undefined;
      return { type: 'readingSpan', raw: m.raw, kind: m.kind, attrs: m.attrs, tokens: this.lexer.inlineTokens(m.text) };
    },
    renderer(token) {
      const inner = this.parser.parseInline(token.tokens);
      if (!known(token.kind)) return inner;
      const label = (token.attrs && token.attrs.label) || token.kind;
      return '<span class="tm-span" data-kind="' + esc(token.kind) + '" title="' + esc(label) + '">' + inner + '</span>';
    },
  }, {
    name: 'citation',
    level: 'inline',
    start(src) { const i = src.search(/\((->|<-|<~) /); return i < 0 ? undefined : i; },
    tokenizer(src) {
      const m = ctx.mdbCitation(src);
      if (!m) return undefined;
      return { type: 'citation', raw: m.raw, arrow: m.arrow, content: m.content, kind: m.kind, tokens: this.lexer.inlineTokens(m.content) };
    },
    renderer(token) {
      let inner = this.parser.parseInline(token.tokens);
      if (token.arrow !== '->' && /^[^\s<>()]+$/.test(token.content) && /[./#]/.test(token.content)) {
        inner = '<a href="' + esc(token.content) + '">' + esc(token.content) + '</a>';
      }
      const what = token.arrow === '->' ? 'backed by' : token.arrow === '<-' ? 'taken from' : 'extrapolated from';
      return '<span class="tm-cite" data-kind="' + esc(token.kind) + '" title="' + esc(what + ' ' + token.content) + '">('
        + esc(token.arrow) + ' ' + inner + ')</span>';
    },
  }] });
}
const source = fs.readFileSync(cfg.input, 'utf8');
const body = md.parse(source);
const h1 = /^#\s+(.*)$/m.exec(source);
const title = h1 ? plain(h1[1].replace(/<!--.*?-->/g, '')) : path.basename(cfg.input);
fs.writeFileSync(cfg.output, '<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
  + '<meta name="viewport" content="width=device-width, initial-scale=1">\n<title>' + esc(title) + '</title>\n'
  + '<meta name="generator" content="tom_md_export">\n<style>\n' + cfg.css + '\n</style>\n</head>\n<body>\n<main>\n'
  + body + '</main>\n</body>\n</html>\n');
''';

/// Renders Markdown with the reading notation to HTML through Node and the
/// MD Browser's renderer.
class HtmlExporter {
  /// An exporter using [node] and the VS Code extension at [extension].
  const HtmlExporter({required this.node, required this.extension});

  /// The `node` binary.
  final String node;

  /// The `tom_vscode_extension` checkout holding `media/markdownBrowser/` and
  /// `node_modules/marked`.
  final String extension;

  /// Locates Node ([node], else `node` on `PATH`, `$NVM_BIN`, the newest
  /// `~/.nvm` install or Homebrew's) and the extension
  /// ([extension], else `$TOM_VSCODE_EXTENSION`, else the checkout beside
  /// this package in the workspace — `tom_ai/vscode/tom_vscode_extension` —
  /// found from the package's own location or from the working directory
  /// upwards). Throws [HtmlExportUnavailable] naming what is missing.
  static Future<HtmlExporter> find({String? node, String? extension}) async {
    final candidates = node != null ? [node] : _nodeCandidates();
    String? nodeExe;
    for (final c in candidates) {
      if (await _runs(c)) {
        nodeExe = c;
        break;
      }
    }
    if (nodeExe == null) {
      throw HtmlExportUnavailable(
        'node not found (looked for ${candidates.join(', ')}); the HTML '
        'export runs the MD Browser renderer in Node — install Node or pass '
        '--node <path>',
      );
    }
    final ext = extension ?? await _findExtension();
    if (ext == null) {
      throw const HtmlExportUnavailable(
        'the VS Code extension checkout (tom_ai/vscode/tom_vscode_extension) '
        'was not found; pass --md-browser <dir> or set TOM_VSCODE_EXTENSION',
      );
    }
    if (!File(
      p.join(ext, 'media', 'markdownBrowser', 'blocks.js'),
    ).existsSync()) {
      throw HtmlExportUnavailable(
        '$ext holds no media/markdownBrowser/blocks.js',
      );
    }
    if (!Directory(p.join(ext, 'node_modules', 'marked')).existsSync()) {
      throw HtmlExportUnavailable(
        '$ext has no node_modules/marked; run `npm install` there',
      );
    }
    return HtmlExporter(node: nodeExe, extension: ext);
  }

  /// Where Node is looked for: `node` on `PATH`, then `$NVM_BIN/node`, the
  /// newest `~/.nvm/versions/node/*/bin/node`, and Homebrew's.
  static List<String> _nodeCandidates() {
    final env = Platform.environment;
    final exe = Platform.isWindows ? 'node.exe' : 'node';
    final out = <String>[exe];
    final nvmBin = env['NVM_BIN'];
    if (nvmBin != null && nvmBin.isNotEmpty) out.add(p.join(nvmBin, exe));
    final home = env['HOME'] ?? env['USERPROFILE'];
    if (home != null) {
      final versions = Directory(p.join(home, '.nvm', 'versions', 'node'));
      if (versions.existsSync()) {
        final dirs =
            versions
                .listSync()
                .whereType<Directory>()
                .map((d) => d.path)
                .toList()
              ..sort(_byVersion);
        for (final d in dirs.reversed) {
          out.add(p.join(d, 'bin', exe));
        }
      }
    }
    out.addAll(['/opt/homebrew/bin/node', '/usr/local/bin/node']);
    return out;
  }

  /// Orders `…/v22.22.3` before `…/v24.1.0` by their numbers.
  static int _byVersion(String a, String b) {
    List<int> v(String s) => [
      for (final m in RegExp(r'\d+').allMatches(p.basename(s)))
        int.parse(m.group(0)!),
    ];
    final x = v(a), y = v(b);
    for (var i = 0; i < x.length && i < y.length; i++) {
      if (x[i] != y[i]) return x[i].compareTo(y[i]);
    }
    return x.length.compareTo(y.length);
  }

  static Future<bool> _runs(String exe) async {
    try {
      return (await Process.run(exe, ['--version'])).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static Future<String?> _findExtension() async {
    final env = Platform.environment['TOM_VSCODE_EXTENSION'];
    if (env != null && env.isNotEmpty) return env;
    const rel = ['tom_ai', 'vscode', 'tom_vscode_extension'];
    final own = await Isolate.resolvePackageUri(
      Uri.parse('package:tom_md_export/tom_md_export.dart'),
    );
    final starts = [
      if (own != null) p.dirname(p.dirname(own.toFilePath())),
      Directory.current.path,
    ];
    for (final start in starts) {
      var dir = p.normalize(p.absolute(start));
      while (true) {
        final candidate = p.joinAll([dir, ...rel]);
        if (Directory(candidate).existsSync()) return candidate;
        final up = p.dirname(dir);
        if (up == dir) break;
        dir = up;
      }
    }
    return null;
  }

  /// Renders the Markdown file [input] to the HTML file [output]; [css] is
  /// the page's stylesheet, [notation] false reads the notation as text,
  /// [documentNames] the names links to this document use.
  Future<({int exitCode, String errors})> render(
    String input,
    String output, {
    required String css,
    bool notation = true,
    Set<String> documentNames = const {},
  }) async {
    final config = jsonEncode({
      'extension': p.absolute(extension),
      'input': p.absolute(input),
      'output': p.absolute(output),
      'notation': notation,
      'css': css,
      'documentNames': documentNames.toList(),
      'wideColumns': wideTableColumns,
    });
    final process = await Process.start(node, ['-', config]);
    process.stdin.write(htmlExportScript);
    await process.stdin.close();
    final errors = process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain<void>();
    final code = await process.exitCode;
    return (exitCode: code, errors: await errors);
  }
}
