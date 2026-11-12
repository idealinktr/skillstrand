# Capture a task

Save a dictated to-do only after the person confirms the title, then ask about a due date.

## Overview

`capture-to-task` calls `CreateTask` after confirmation and `SetTaskDue` only if the follow-up names a date.

## Steps

1. `CaptureToTaskSkill.draft(from:)` takes the title from the first non-empty line, at most 80 characters. The rest are notes. An empty capture fails with ``SkillFailureCode/emptyInput``.
2. `CaptureToTaskSkill.run(_:)` asks “Create the task…?” before it records a create step.
3. Declining cancels and says nothing was saved.
4. Confirming asks “Add a due date?”.
5. Skip completes with the title only. A date completes with both. A blank date fails and asks again.

`SkillErrorMapping` turns the failure into the dialog “Needs a value: …”.
