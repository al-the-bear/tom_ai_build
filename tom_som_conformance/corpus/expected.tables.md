<!-- docspec: demo-document/1.0 -->
# <!--[DEMO]--> <a id="DEMO"></a> Demo Document

## <!--[TTL] codeSpec="DemoTitle" units="demo_server"--> <a id="TTL"></a> Document Title

Hello

## <!--[SUM]--> <a id="SUM"></a> Executive Summary

Line one
Line two

Line four

## <!--[PRI]--> <a id="PRI"></a> Priority

high

## <!--[CNT]--> <a id="CNT"></a> Count

3

## <!--[DET]--> <a id="DET"></a> Details & Contacts

Captured during the November review.
 Owner: this line is prose, not the field.

| TomSpecField | Value |
| --- | --- |
| Owner | Bob |

Contact: bob@example.com
- on call: weekdays
- backup: alice@example.com

| TomSpecField | Value |
| --- | --- |
| Estimate | 8 |
| Weight | 2.5 |
| Active | true |
| Priority | high |
| Pattern | `^[a-z0-9](-?[a-z0-9]){1,62}$` |

## <!--[items]--> <a id="items"></a> Work Items

### <!--[items-1]--> <a id="items-1"></a> Task 1

First

#### <!--[STS]--> <a id="STS"></a> Status

open

### <!--[items-2]--> <a id="items-2"></a> Task 2

Second line A
with ```triple``` ticks

#### <!--[STS]--> <a id="STS"></a> Status

done

## <!--[REF-LST]--> <a id="REF-LST"></a> Refs

### <!--[REF-SPEC]--> <a id="REF-SPEC"></a> Reference to the Spec

spec §1.2

### <!--[REF-2]--> <a id="REF-2"></a> Refs 2

ADR7

## <!--[CARD-LST]--> <a id="CARD-LST"></a> Cards

::: {.records}
| Id | Title | Note |
| --- | --- | --- |
| <a id="CARD-ALPHA"></a>CARD-ALPHA | Alpha Card | first card |
| <a id="CARD-2"></a>CARD-2 |  | second card |
:::

## <!--[META]--> <a id="META"></a> Meta

### <!--[OWNR]--> <a id="OWNR"></a> Owner

alice

### <!--[tags]--> <a id="tags"></a> Tags

#### <!--[tags-1]--> <a id="tags-1"></a> Tags 1

on

#### <!--[tags-2]--> <a id="tags-2"></a> Tags 2

no

#### <!--[tags-3]--> <a id="tags-3"></a> Tags 3

1:30

#### <!--[tags-4]--> <a id="tags-4"></a> Tags 4

plain

## <!--[CTRL]--> <a id="CTRL"></a> Control

ctrl-owner

### <!--[CTRL-SUM]--> <a id="CTRL-SUM"></a> Summary

Controlled summary

## <!--[NOTE] units="demo_client,demo_server"--> <a id="NOTE"></a> Notes

Wrapper-section text

### <!--[NOTE-BDY]--> <a id="NOTE-BDY"></a> Body

Section-kind body

## <!--[MIX]--> <a id="MIX"></a> Mixed<br>slots

<!-- slot: content -->

_Extrapolated._

| TomSpecField | Value |
| --- | --- |
| Lead | Ada |
| Risk | low |

<!-- slot: narrative -->

First narrative.


After two blank lines.
 Lead: label-shaped prose

<!-- slot: tail -->

Tail text.

<!-- slot: alt -->

| TomSpecField | Value |
| --- | --- |
| Lead | Bob |

## <!--[DLV-LST]--> <a id="DLV-LST"></a> Deliverables

### <!--[DLV-1]--> <a id="DLV-1"></a> Deliverable 1

| TomSpecField | Value |
| --- | --- |
| UnitId | demo_client |
| Kind | client |
| Component | ARCM-COMP-UI |

| Section | TomSpecField | Value |
| --- | --- | --- |
| <a id="DLR-1"></a>DLR-LST / DLR-1 | Area | CE-NV |
|  | Mapping | dart-tom |

### <!--[DLV-2]--> <a id="DLV-2"></a> Deliverable 2

| TomSpecField | Value |
| --- | --- |
| UnitId | demo_server |
| Kind | server |
| DeploymentTarget | DEPTAR-DEPL-API |

| Section | TomSpecField | Value |
| --- | --- | --- |
| <a id="DLR-1"></a>DLR-LST / DLR-1 | Area | CE-DB |
|  | Mapping | dart-tom |
| <a id="DLR-2"></a>DLR-LST / DLR-2 | Area | CE-NV |
|  | Mapping | dart-tom |
| <a id="DLE-1"></a>DLE-LST / DLE-1 | Emitter | openapi |

