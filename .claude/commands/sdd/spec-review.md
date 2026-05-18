---
description: Adversarial review of the feature spec from security, performance, edge-case, scalability, and regulatory perspectives to catch blind spots before planning.
handoffs:
  - label: Clarify Spec Requirements
    agent: sdd:clarify
    prompt: Clarify specification requirements based on review findings
    send: true
  - label: Update Specification
    agent: sdd:specify
    prompt: Update the feature specification to address review findings
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Act as a **devil's advocate** — challenge the current feature specification from multiple adversarial perspectives to find gaps, risks, and blind spots that the spec author may have missed. This is a read-only analysis that produces a structured critique. No files are modified.

This command is designed to run AFTER `/sdd:specify` (and optionally after `/sdd:clarify`) but BEFORE `/sdd:plan`. It adds the most value when the spec is considered "ready" but has not yet been translated into architecture.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured review report. The user decides which findings to address (via `/sdd:clarify`, `/sdd:specify`, or manual edits).

**Adversarial Mindset**: Your job is to find problems, not to praise. A spec with zero findings is suspicious — push harder. However, do not fabricate issues. Every finding must cite a specific spec section or absence.

**Constitution Authority**: If `.specify/memory/constitution.md` exists, all findings must be evaluated against its principles. Constitution violations are automatically CRITICAL.

## Execution Steps

### 1. Initialize Review Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root once. Parse JSON for:
- `FEATURE_DIR`
- `FEATURE_SPEC`

If FEATURE_SPEC does not exist, abort and instruct user to run `/sdd:specify` first.
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Load Review Context

- **REQUIRED**: Read the feature spec at FEATURE_SPEC
- **IF EXISTS**: Read `.specify/memory/constitution.md` for principle validation
- **IF EXISTS**: Read `.specify/memory/lessons-learned.md` — filter to entries tagged `[phase:specify]` or `[phase:all]` for known specification pitfalls from past features

### 3. Adversarial Analysis Passes

Analyze the spec from each of the following perspectives. For each perspective, actively look for what is **missing, vague, contradictory, or risky**. Do not accept vague language at face value.

#### A. Security & Privacy

- Are authentication and authorization requirements explicitly defined for every user action?
- Are there data exposure risks? (What sensitive data is collected, stored, transmitted?)
- Are injection vectors addressed? (User input validation, file uploads, URL parameters)
- Are session management requirements specified? (Timeout, concurrent sessions, invalidation)
- Are data protection requirements defined? (Encryption at rest/transit, PII handling)
- Are audit/logging requirements defined for security-relevant events?
- Does the spec mention CSRF, XSS, or SQL injection protection where applicable?
- Are there assumptions about "trusted" input that could be exploited?

#### B. Performance & Scalability

- Are there response time or throughput targets? If yes, are they measurable? If no, flag the absence.
- Are there unbounded operations? (Lists without pagination, queries without limits, file uploads without size limits)
- Are caching requirements specified for frequently accessed data?
- Are there N+1 query risks in described data relationships?
- Are there operations that should be asynchronous but are described as synchronous?
- What happens under 10x the expected load? Are degradation strategies defined?
- Are database index requirements implied but not stated?
- Are there bulk operations that need batch processing?

#### C. Edge Cases & Error Handling

- What happens when required data is missing or malformed?
- What happens when external dependencies fail? (APIs, services, databases)
- What happens with concurrent access? (Race conditions, optimistic locking, duplicate submissions)
- Are empty states defined? (No data, first-time user, cleared data)
- Are boundary conditions specified? (Maximum lengths, minimum values, date ranges)
- What happens when the user does something unexpected? (Back button, double-click, tab switching)
- Are timeout behaviors defined for long-running operations?
- Are rollback/recovery requirements defined for partial failures?

#### D. Data Integrity & Consistency

- Are uniqueness constraints defined where needed?
- Are referential integrity rules specified? (What happens when a referenced entity is deleted?)
- Are state transitions explicitly defined? (Valid state changes, guards, side effects)
- Are data validation rules complete? (Format, range, required fields, cross-field validation)
- Are there implicit ordering assumptions that could break under concurrency?
- Are there data migration or backward compatibility requirements?
- Are there temporal constraints? (Time zones, daylight saving, expiration dates)

#### E. Regulatory & Compliance

- Are there data retention or deletion requirements? (GDPR right to be forgotten, data lifecycle)
- Are there accessibility requirements? (WCAG compliance level, keyboard navigation, screen readers)
- Are there audit trail requirements? (Who changed what, when, compliance logging)
- Are there geographic or jurisdictional constraints? (Data residency, export controls)
- Are there industry-specific compliance requirements? (PCI-DSS for payments, HIPAA for health data)
- If not applicable, explicitly note that no regulatory requirements were identified.

### 4. Cross-Perspective Analysis

After individual passes, look for **cross-cutting issues**:

- Security requirements that conflict with usability requirements
- Performance requirements that conflict with data integrity requirements
- Edge cases that reveal missing functional requirements
- Scalability concerns that require additional functional requirements (pagination, rate limiting)
- Lessons learned from past features that apply to current spec gaps

### 5. Severity Assignment

Classify each finding:

- **CRITICAL**: Blocks planning — security vulnerability, missing core requirement, constitution violation, data integrity risk that could cause data loss
- **HIGH**: Should fix before planning — ambiguous requirement with multiple conflicting interpretations, missing error handling for likely failure modes, performance risk with no mitigation
- **MEDIUM**: Should address — missing edge case that affects user experience, vague success criteria, incomplete state transition definition
- **LOW**: Consider for later — nice-to-have clarifications, minor wording improvements, future-proofing suggestions

### 6. Produce Review Report

Output a Markdown report with this structure:

```markdown
## Spec Review: [Feature Name]

**Spec**: [path to spec.md]
**Date**: [today]
**Perspectives Analyzed**: Security, Performance, Edge Cases, Data Integrity, Regulatory

### Summary

- **Critical**: [count] findings
- **High**: [count] findings
- **Medium**: [count] findings
- **Low**: [count] findings
- **Overall Assessment**: [BLOCK — critical issues must be resolved | CAUTION — high issues should be addressed | PROCEED — spec is solid with minor notes]

### Critical Issues (must fix before planning)

| ID | Perspective | Spec Section | Finding | Recommendation |
|----|-------------|-------------|---------|----------------|
| R-001 | Security | §FR-003 | [specific finding] | [specific fix] |

### High Issues (should address before planning)

| ID | Perspective | Spec Section | Finding | Recommendation |
|----|-------------|-------------|---------|----------------|
| R-002 | Performance | §SC-001 | [specific finding] | [specific fix] |

### Medium Issues (address during planning or clarification)

| ID | Perspective | Spec Section | Finding | Recommendation |
|----|-------------|-------------|---------|----------------|

### Low Issues (consider for future)

| ID | Perspective | Spec Section | Finding | Recommendation |
|----|-------------|-------------|---------|----------------|

### Perspectives Summary

| Perspective | Findings | Highest Severity | Key Concern |
|-------------|----------|-----------------|-------------|
| Security & Privacy | [count] | [severity] | [one-line summary] |
| Performance & Scalability | [count] | [severity] | [one-line summary] |
| Edge Cases & Error Handling | [count] | [severity] | [one-line summary] |
| Data Integrity & Consistency | [count] | [severity] | [one-line summary] |
| Regulatory & Compliance | [count] | [severity] | [one-line summary] |
```

### 7. Provide Next Actions

Based on the review results:

- **If CRITICAL issues exist**: Strongly recommend resolving via `/sdd:clarify` or `/sdd:specify` before proceeding to `/sdd:plan`
- **If only HIGH/MEDIUM**: Recommend addressing high issues; medium issues can be deferred to planning phase
- **If only LOW**: Spec is solid — proceed to `/sdd:plan` with confidence
- Provide specific suggested prompts for `/sdd:clarify` or `/sdd:specify` that address the top findings

### 8. Offer Targeted Fix Assistance

Ask the user:

> "Would you like me to help address the top [N] findings? I can hand off to `/sdd:clarify` to refine the spec, or you can edit the spec directly."

Do NOT apply changes automatically. The user decides which findings to address and how.

## Review Guidelines

### Quality Standards

- **Every finding must cite a specific spec section** (e.g., `§FR-003`, `§US-2`, `§SC-001`) or explicitly note a missing section (e.g., `[MISSING: no error handling section]`)
- **Every finding must include a concrete recommendation** — not just "this is vague" but "define the maximum upload size in MB and the error message shown when exceeded"
- **Findings must be actionable** — the spec author should know exactly what to add, change, or clarify
- **Avoid false positives** — do not flag requirements that are genuinely clear and complete
- **Avoid scope creep** — do not suggest features beyond what the spec describes; focus on gaps in what IS described
- **Minimum findings**: A well-written spec should still have at least 3-5 findings across all perspectives. If you find fewer, you are not looking hard enough.
- **Maximum findings**: Cap at 30 total to keep the review actionable. If more issues exist, prioritize by severity and note overflow.

### What This Is NOT

- NOT a code review (no implementation exists yet)
- NOT a checklist validation (use `/sdd:checklist` for that)
- NOT a consistency analysis (use `/sdd:analyze` for cross-artifact checks)
- NOT a spec rewrite (this is read-only adversarial critique)

### Relationship to Other Commands

- **After** `/sdd:specify` and optionally `/sdd:clarify` — the spec should be "ready"
- **Before** `/sdd:plan` — findings inform architectural decisions
- **Complements** `/sdd:checklist` — checklists test requirement quality; this tests requirement completeness and risk
- **Complements** `/sdd:analyze` — analyze checks cross-artifact consistency; this challenges the spec itself

Context for review focus: $ARGUMENTS
