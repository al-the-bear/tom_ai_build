#!/usr/bin/env python3
"""Stage 3 migration: Convert form classes to @Form annotations.

For each class with form/text/long/ref fields:
1. form + text fields -> @Form([Field(...)]) annotation on content
2. long fields -> TextSection (replace String? in place)
3. ref fields -> @Reference annotation (keep String? or use typed ref)
4. Remove old String? lines that went into @Form

The script reads field_classification.md for classifications and
processes all model source files.
"""

import re
import os
import sys
from collections import defaultdict, OrderedDict


# ============================================================================
# Parse field_classification.md
# ============================================================================

def parse_classification(path):
    """Parse the field classification doc.
    
    Returns: dict[className] -> list of (fieldName, category, sourceFile)
    Field names with colons like 'priority:Priority' encode enum types.
    """
    classes = defaultdict(list)
    current_file = None

    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith('## ') and line.endswith('.dart'):
                current_file = line[3:]
            elif line.startswith('|') and '|' in line[1:]:
                parts = [p.strip() for p in line.split('|')]
                # parts[0] is empty, parts[1]=Class, parts[2]=Field, parts[3]=Category
                if len(parts) >= 4 and parts[1] and parts[1] != 'Class' and not parts[1].startswith('--'):
                    cls = parts[1]
                    field = parts[2]
                    cat = parts[3]
                    if cat in ('form', 'text', 'long', 'ref'):
                        classes[cls].append((field, cat, current_file))
    return classes


# ============================================================================
# Reference type resolution — same-file typed refs vs String? fallback
# ============================================================================

# For ref fields where target class is in the SAME file, use typed reference.
# For cross-file or unclear targets, keep String?.
REF_TYPED = {
    # current_state_analysis.dart — all target types in same file
    'SystemDependencyEntry.sourceSystem': 'ExistingSystemEntry',
    'SystemDependencyEntry.targetSystem': 'ExistingSystemEntry',
    'SystemIntegrationEntry.sourceSystem': 'ExistingSystemEntry',
    'SystemIntegrationEntry.targetSystem': 'ExistingSystemEntry',
    'ProcessMetricEntry.processReference': 'CurrentBusinessProcess',
    # business_data_model.dart — all target types in same file
    'KeyAttributeEntry.referencedEntity': 'DataEntityEntry',
    'EntityRelationshipEntry.sourceEntity': 'DataEntityEntry',
    'EntityRelationshipEntry.targetEntity': 'DataEntityEntry',
    # target_business_process.dart — same file
    'ProcessRelationshipEntry.sourceProcess': 'BusinessProcessDescription',
    'ProcessRelationshipEntry.targetProcess': 'BusinessProcessDescription',
    'InteractionEntry.processReference': 'BusinessProcessDescription',
}
# All others (cross-file or no target class) keep String?


# ============================================================================
# Human-readable description for @Form Field and @Reference
# ============================================================================

def field_desc(field_name):
    """Generate a human-readable description for a field."""
    KNOWN = {
        'description': 'Short description',
        'name': 'Name',
        'title': 'Title',
        'rationale': 'Rationale',
        'purpose': 'Purpose',
        'impact': 'Impact assessment',
        'mitigation': 'Mitigation strategy',
        'scope': 'Scope',
        'status': 'Current status',
        'version': 'Version',
        'date': 'Date',
        'author': 'Author',
        'role': 'Role',
        'category': 'Category',
        'type': 'Type',
        'format': 'Format',
        'frequency': 'Frequency',
        'priority': 'Priority level',
        'source': 'Source',
        'severity': 'Severity level',
        'workaround': 'Current workaround',
        'requirement': 'Requirement',
        'criterion': 'Criterion',
        'allocation': 'Allocation',
        'department': 'Department',
        'organization': 'Organization',
        'schedule': 'Schedule',
        'duration': 'Duration',
        'budget': 'Budget',
    }
    if field_name in KNOWN:
        return KNOWN[field_name]
    # Convert camelCase to words
    words = re.sub(r'([A-Z])', r' \1', field_name).strip()
    return words[0].upper() + words[1:]


# Fields that should have 'required: true' in @Form
REQUIRED_FIELDS = {
    'requirementId', 'name', 'entityName', 'processName', 'roleName',
    'componentName', 'goalId', 'riskId', 'title', 'systemName',
    'interfaceId', 'screenId', 'processId', 'scenarioName', 'stageNumber',
    'stageName', 'categoryName', 'patternName', 'channelName', 'taskName',
    'goalName', 'stepName', 'actorName', 'criterion', 'painPoint',
    'gapName', 'metricName', 'deliverableName', 'documentTitle', 'toolName',
    'environmentName', 'attributeName', 'objectName', 'ruleId', 'ruleName',
    'groupName', 'entitlementName', 'resourceKey', 'eventName', 'methodName',
    'personaName', 'screenName', 'reportName', 'breakpointName',
    'protocolName', 'standardName', 'phaseName', 'gateName',
    'interactionId', 'flowName', 'dataStoreName', 'limitation',
    'roleTitle', 'principle', 'goal', 'assumption',
}


# ============================================================================
# Process a single Dart file
# ============================================================================

def process_file(filepath, classifications):
    """Apply Stage 3 transformations to a Dart file.
    
    Returns number of classes modified.
    """
    with open(filepath) as f:
        content = f.read()
    
    lines = content.split('\n')
    output = []
    modified_count = 0
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detect class declaration
        cm = re.match(r'^class\s+(\w+)\s*\{', line)
        if not cm:
            output.append(line)
            i += 1
            continue
        
        cls_name = cm.group(1)
        cls_fields = classifications.get(cls_name)
        
        if not cls_fields:
            output.append(line)
            i += 1
            continue
        
        # ---- Process this class ----
        # Collect all lines until closing brace (matching depth)
        class_start = i
        body_lines = [line]  # includes the 'class Foo {' line
        depth = line.count('{') - line.count('}')
        i += 1
        while i < len(lines) and depth > 0:
            body_lines.append(lines[i])
            depth += lines[i].count('{') - lines[i].count('}')
            i += 1
        
        # Categorise the class's classified fields
        form_fields = [(f, c) for f, c, _ in cls_fields if c in ('form', 'text')]
        long_fields = [(f, c) for f, c, _ in cls_fields if c == 'long']
        ref_fields  = [(f, c) for f, c, _ in cls_fields if c == 'ref']
        
        # Build sets of field names to remove (form/text go into @Form, so remove)
        form_field_names = set()
        for f, _ in form_fields:
            fname = f.split(':')[0] if ':' in f else f
            form_field_names.add(fname)
        
        long_field_names = set(f for f, _ in long_fields)
        ref_field_names  = set(f for f, _ in ref_fields)
        
        # Build @Form annotation text
        form_annotation = ''
        if form_fields:
            field_entries = []
            for f, _ in form_fields:
                if ':' in f:
                    fname = f.split(':')[0]
                    ftype = f.split(':')[1]
                else:
                    fname = f
                    ftype = 'String'
                desc = field_desc(fname)
                req = ', required: true' if fname in REQUIRED_FIELDS else ''
                field_entries.append(f"    Field('{fname}', {ftype}, '{desc}'{req}),")
            form_annotation = '  @Form([\n' + '\n'.join(field_entries) + '\n  ])\n'
        
        # Build replacement lines for long fields → TextSection
        long_replacements = {}
        for f, _ in long_fields:
            desc = field_desc(f)
            long_replacements[f] = f'  /// {desc}.\n  TextSection {f} = TextSection();'
        
        # Build replacement lines for ref fields → @Reference
        ref_replacements = {}
        for f, _ in ref_fields:
            key = f'{cls_name}.{f}'
            desc = field_desc(f)
            target_type = REF_TYPED.get(key)
            if target_type:
                ref_replacements[f] = f"  @Reference('{desc}')\n  {target_type}? {f};"
            else:
                ref_replacements[f] = f"  @Reference('{desc}')\n  String? {f};"
        
        # ---- Rewrite class body ----
        new_body = []
        skip_next_blank = False
        j = 0
        while j < len(body_lines):
            bl = body_lines[j]
            stripped = bl.strip()
            
            # Class declaration line — emit as-is
            if j == 0:
                new_body.append(bl)
                j += 1
                continue
            
            # Closing brace — emit as-is
            if j == len(body_lines) - 1:
                # Before closing, add long and ref fields that haven't been placed yet
                # (they get placed in-situ when we see the original field; this handles
                # fields whose original String? line was not found for some reason)
                new_body.append(bl)
                j += 1
                continue
            
            # Check if this is a field line we need to handle
            # Match: String? fieldName;  or  EnumType? fieldName;  or  EnumType fieldName = ...;
            field_match = re.match(r'\s+(?:String|(\w+))\??\s+(\w+)\s*(?:=\s*\S+)?;', bl)
            if field_match:
                ftype_or_none = field_match.group(1)
                fname = field_match.group(2)
                
                # Content field — inject @Form before it
                if fname == 'content' and re.match(r'\s+String\?\s+content;', bl):
                    if form_annotation:
                        new_body.append(form_annotation.rstrip('\n'))
                        new_body.append('')
                    new_body.append(bl)
                    j += 1
                    continue
                
                # Form/text field → remove (already captured in @Form)
                if fname in form_field_names:
                    # Also skip preceding doc comment lines
                    while new_body and new_body[-1].strip().startswith('///'):
                        new_body.pop()
                    # Skip trailing blank line
                    skip_next_blank = True
                    j += 1
                    continue
                
                # Long field → replace with TextSection
                if fname in long_field_names and fname in long_replacements:
                    # Remove preceding doc comments
                    while new_body and new_body[-1].strip().startswith('///'):
                        new_body.pop()
                    new_body.append(long_replacements.pop(fname))
                    j += 1
                    continue
                
                # Ref field → replace with @Reference
                if fname in ref_field_names and fname in ref_replacements:
                    # Remove preceding doc comments
                    while new_body and new_body[-1].strip().startswith('///'):
                        new_body.pop()
                    new_body.append(ref_replacements.pop(fname))
                    j += 1
                    continue
            
            # Check for enum field: Priority? priority; or SectionType? type;
            enum_match = re.match(r'\s+(Priority|Probability|Impact|Status|SectionType)\?\s+(\w+);', bl)
            if enum_match:
                fname = enum_match.group(2)
                if fname in form_field_names:
                    while new_body and new_body[-1].strip().startswith('///'):
                        new_body.pop()
                    skip_next_blank = True
                    j += 1
                    continue
            
            # Skip blank lines that follow removed fields
            if skip_next_blank and stripped == '':
                skip_next_blank = False
                j += 1
                continue
            
            skip_next_blank = False
            new_body.append(bl)
            j += 1
        
        output.extend(new_body)
        modified_count += 1
    
    if modified_count == 0:
        return 0
    
    # Ensure import
    result = '\n'.join(output)
    needs_import = '@Form(' in result or '@Reference(' in result or 'TextSection ' in result
    has_import = "import 'package:tom_specs_core/tom_specs_core.dart';" in result
    
    if needs_import and not has_import:
        # Insert after 'library;' line or at top
        if '\nlibrary;\n' in result:
            result = result.replace('\nlibrary;\n', "\nlibrary;\n\nimport 'package:tom_specs_core/tom_specs_core.dart';\n", 1)
        else:
            result = f"import 'package:tom_specs_core/tom_specs_core.dart';\n\n{result}"
    
    with open(filepath, 'w') as f:
        f.write(result)
    
    return modified_count


# ============================================================================
# Main
# ============================================================================

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    class_doc = os.path.join(base, 'doc', 'field_classification.md')

    print(f'Parsing field classification from {class_doc}...')
    classifications = parse_classification(class_doc)
    print(f'Found classifications for {len(classifications)} classes')

    # Print category summary
    total_form = sum(1 for cls in classifications.values() for _, c, _ in cls if c == 'form')
    total_text = sum(1 for cls in classifications.values() for _, c, _ in cls if c == 'text')
    total_long = sum(1 for cls in classifications.values() for _, c, _ in cls if c == 'long')
    total_ref  = sum(1 for cls in classifications.values() for _, c, _ in cls if c == 'ref')
    print(f'  form={total_form}, text={total_text}, long={total_long}, ref={total_ref}')

    source_dirs = [
        os.path.join(base, 'lib', 'src', 'common'),
        os.path.join(base, 'lib', 'src', 'pd_project_definition'),
    ]

    total_files = 0
    total_classes = 0

    for src_dir in source_dirs:
        if not os.path.isdir(src_dir):
            continue
        for fname in sorted(os.listdir(src_dir)):
            if not fname.endswith('.dart'):
                continue
            filepath = os.path.join(src_dir, fname)
            count = process_file(filepath, classifications)
            if count > 0:
                total_files += 1
                total_classes += count
                print(f'  Modified: {fname} ({count} classes)')

    print(f'\nDone. Modified {total_files} files, {total_classes} classes.')


if __name__ == '__main__':
    main()
