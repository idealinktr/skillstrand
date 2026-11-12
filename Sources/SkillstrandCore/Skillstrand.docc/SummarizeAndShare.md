# Summarize and share

Shorten one note, pick a destination, and confirm before sharing.

## Overview

`summarize-and-share` never calls `ShareSummary` until the person has seen the summary and agreed.

## Steps

1. With no note, the run asks which note.
2. `SummarizeAndShareSkill.summary(of:limit:)` collapses whitespace and, past the limit, cuts on the last space and adds an ellipsis.
3. The destination choice is Messages, Mail, or Copy.
4. The confirmation quotes the summary and the destination.
5. Declining shares nothing. Confirming completes with the destination name.
