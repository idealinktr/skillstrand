# Schedule a reminder

Turn a vague time into one confirmed reminder.

## Overview

`scheduled-reminder` does not invent a clock time. The app passes the concrete choices, such as Friday at 9:00 and Friday at 6:00.

## Steps

1. A blank title fails with ``SkillFailureCode/emptyInput``.
2. An empty choice list fails with ``SkillFailureCode/notFound``.
3. More than one choice, and no selection, asks which time.
4. One selected time asks “Schedule … for …?”.
5. Declining schedules nothing. Confirming completes with the title and that time.

A single choice skips the disambiguation and goes straight to confirmation.
