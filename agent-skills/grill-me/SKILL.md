---
name: grill-me
description: Interview the user relentlessly about a task, plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when the user wants to stress-test a plan, get grilled on a design, pressure-test an approach, or mentions "grill me".
---

# Grill Me

Interview me relentlessly about every aspect of this task until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. If a question can be answered by exploring the codebase, explore the codebase instead. For each question, provide your recommended answer.

Scale the interrogation to the size and risk of the work. A full project buildout can take about an hour, a huge feature about 30 minutes, a small add-on about 15 minutes, and a PR-sized change that a human could implement in less than a day should take about 5 minutes.

If relevant, pressure-test requirements and quality attributes directly: performance, reliability, security, usability, maintainability, observability, scalability, cost, and acceptance criteria.

If the project has ADRs or decision docs in `$PROJECT_ROOT_DIR/docs`, read the relevant ones and challenge new decisions that appear to unintentionally conflict with older recorded decisions. Record any decisions made in a new document per task.