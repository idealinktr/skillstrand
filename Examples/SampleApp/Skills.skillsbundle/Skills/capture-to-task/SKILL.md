---
name: capture-to-task
description: Turn a short capture into a task after the person confirms the title, then ask whether to add a due date. Use when someone dictates or pastes a to-do.
---

This skill is guidance for a complex request. It does not run the tools by itself.

Use CreateTask only after the person confirms the title. Use SetTaskDue only if they then choose to add a date.

1. Read the capture. The title is the first non-empty line, trimmed to 80 characters. The rest are notes. If there is no title, ask for one and stop.
2. Show the title and ask whether to create the task. Do not invent a due date in this step.
3. If they decline, call nothing and say that nothing was saved.
4. If they confirm, call CreateTask with the title and notes.
5. Then ask whether to add a due date. If they skip, stop. If they name a date, call SetTaskDue. If the date is blank, ask again.
