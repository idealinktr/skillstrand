---
name: search-and-open
description: Find a library item by the name someone says and open it. Use when they ask to open a note, list, or log that is already in the app.
---

This skill is guidance. Prefer the OpenLibraryItem tool, and do not open an item the person has not identified.

1. Run the library item's string query with the words they said.
2. If nothing matches, say so and stop. Do not create an item.
3. If one item matches, call OpenLibraryItem with that item.
4. If several match, ask which one and wait. Then call OpenLibraryItem with the choice.
5. Ignore a choice that was not in the matches.
