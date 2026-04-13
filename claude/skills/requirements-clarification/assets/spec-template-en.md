# Feature: XXX

**Author**:
**Date**:
**Status**: Draft / In Review / Approved

---

<!-- This document is the communication artifact between agent and user at quality gates.
     Focus on WHAT and WHY, not HOW (implementation details belong in tasks.md and code).
     Sub-structure within each section is flexible — organize as needed, don't force a fixed format. -->

## 1. Background

### 1.1 Problem Statement
<!-- What problem exists today? Why is this feature needed? What is the impact on users/system? -->

### 1.2 Current State Analysis
<!-- Filled by agent after codebase research: relevant modules, existing implementation, key interfaces, technical constraints -->

### 1.3 Use Cases
<!-- In what scenarios will this feature be used? -->

## 2. Goals and Scope

### 2.1 Goals
<!-- Core problem to solve, measurable success criteria -->

### 2.2 Non-Goals
<!-- What is explicitly out of scope -->

## 3. Requirements

### 3.1 Functional Requirements
<!-- What capabilities must the system have?
     Write "what the system should do", not "how the system does it".
     ✅ Correct: "Support filtering scan results by condition"
     ❌ Wrong: "Add a filter callback in ScanIterator" -->

### 3.2 Non-Functional Requirements
<!-- Performance, compatibility, scalability constraints (only those relevant to this feature).
     Write constraints and metrics, not implementation.
     ✅ Correct: "Single request latency < 10ms"
     ❌ Wrong: "Use caching to reduce latency" -->

---
<!-- Gate 1 (Requirements Understanding) ends here.
     Sections below are filled under the system-design skill. -->

## 4. Design

### 4.1 Overview
<!-- High-level approach, architecture diagram (if applicable). Focus on key decisions and trade-offs, not implementation details. -->

### 4.2 Key Design Decisions
<!-- For each important decision: list options, rationale, trade-offs.
     Consider these dimensions as relevant (skip what doesn't apply):
     - Interface design: API contracts, compatibility
     - Data model: schema, storage format
     - Concurrency model: thread safety, locking strategy
     - Error handling: failure modes, recovery mechanisms
     - Performance: hot paths, memory overhead -->

### 4.3 Trade-offs
<!-- Strengths and limitations of the chosen approach -->

## 5. Alternatives Considered
<!-- Approaches considered but not adopted, and why -->

## 6. Test Plan
<!-- Test strategy, coverage targets, test types. No need to write specific test cases. -->

## 7. Observability and Operations
<!-- Fill only when the change affects observability, configuration, or operations. Otherwise mark N/A.
     Includes: monitoring metrics, logging, alerting, configuration parameters, upgrade/rollback considerations. -->

## 8. References
<!-- Related papers, documentation, industry approaches (if any) -->
