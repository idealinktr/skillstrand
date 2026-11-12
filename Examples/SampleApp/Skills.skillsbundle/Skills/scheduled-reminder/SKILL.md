---
name: scheduled-reminder
description: Schedule a reminder when the person names a title and a time. Use when a phrase such as Friday could mean more than one moment and they must pick one.
---

This skill is guidance. ScheduleReminder runs only after one time is chosen and the person confirms it.

1. If the title is missing, ask what the reminder is for and stop.
2. Resolve the time phrase to concrete choices the app provides. If none match, say so and stop.
3. If more than one choice matches, ask which time and wait. Ignore a choice that is not in the list.
4. Show the title and the one time, and ask whether to schedule it.
5. If they decline, call nothing and say that nothing was scheduled.
6. If they confirm, call ScheduleReminder with the title and that time.
