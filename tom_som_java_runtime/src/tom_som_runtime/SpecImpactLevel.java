package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * How far the project has come (impact_evaluation.md § Level), from
 * {@link SpecImpactWalk#specImpactLevel}.
 */
public final class SpecImpactLevel {
  /** Every document root: whether the specification has it. */
  public final List<SpecImpactLevelDocument> documents;

  /** {@code phase1_project_idea/} holds a Markdown file. */
  public final boolean projectIdea;

  /** {@code CE-*.extract.yaml} files in {@code generated-doc/codespecs_extracts/}. */
  public final int extracts;

  /** {@code generated-doc/codespecs_extracts/gate.verdicts.yaml} exists. */
  public final boolean gateRecord;

  /** {@code *.ir.yaml} files in {@code irspecs/}. */
  public final int ir;

  /** Gate checklists and reports under {@code gates/} and {@code quality/evidence/gates/}. */
  public final List<String> gates;

  /** The test folders the caller passed; {@code null}: none given. */
  public final List<SpecImpactFolder> tests;

  /** The code folders the caller passed; {@code null}: none given. */
  public final List<SpecImpactFolder> code;

  /** The phases (1–6) the project has reached. */
  public final List<Integer> phasesReached;

  /** The phases (1–6) it has not, which a change leaves out (they run later in initial mode). */
  public final List<Integer> phasesLeftOut;

  public SpecImpactLevel(
      List<SpecImpactLevelDocument> documents,
      boolean projectIdea,
      int extracts,
      boolean gateRecord,
      int ir,
      List<String> gates,
      List<SpecImpactFolder> tests,
      List<SpecImpactFolder> code,
      List<Integer> phasesReached,
      List<Integer> phasesLeftOut) {
    this.documents = Collections.unmodifiableList(new ArrayList<>(documents));
    this.projectIdea = projectIdea;
    this.extracts = extracts;
    this.gateRecord = gateRecord;
    this.ir = ir;
    this.gates = Collections.unmodifiableList(new ArrayList<>(gates));
    this.tests = tests == null ? null : Collections.unmodifiableList(new ArrayList<>(tests));
    this.code = code == null ? null : Collections.unmodifiableList(new ArrayList<>(code));
    this.phasesReached = Collections.unmodifiableList(new ArrayList<>(phasesReached));
    this.phasesLeftOut = Collections.unmodifiableList(new ArrayList<>(phasesLeftOut));
  }

  private static List<Object> foldersJson(List<SpecImpactFolder> folders) {
    if (folders == null) {
      return null;
    }
    List<Object> out = new ArrayList<>();
    for (SpecImpactFolder f : folders) {
      out.add(f.toJson());
    }
    return out;
  }

  /** The level as JSON, keys as in every runtime. */
  public Map<String, Object> toJson() {
    Map<String, Object> o = new LinkedHashMap<>();
    List<Object> docs = new ArrayList<>();
    for (SpecImpactLevelDocument d : documents) {
      docs.add(d.toJson());
    }
    o.put("documents", docs);
    o.put("projectIdea", Boolean.valueOf(projectIdea));
    o.put("extracts", Integer.valueOf(extracts));
    o.put("gateRecord", Boolean.valueOf(gateRecord));
    o.put("ir", Integer.valueOf(ir));
    o.put("gates", new ArrayList<Object>(gates));
    o.put("tests", foldersJson(tests));
    o.put("code", foldersJson(code));
    o.put("phasesReached", new ArrayList<Object>(phasesReached));
    o.put("phasesLeftOut", new ArrayList<Object>(phasesLeftOut));
    return o;
  }
}
