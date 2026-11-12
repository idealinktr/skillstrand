# Search and open

Find a library item by name and open it.

## Overview

`search-and-open` uses the string query on `LibraryItem`. One hit opens. Several hits wait for a choice. A choice that was not in the hit list fails.

## Steps

1. An empty query fails before the catalog is scanned.
2. “kiln” against the starter catalog opens Kiln log.
3. “field” returns Field notes and Field guide.
4. Choosing Field guide opens that item. Choosing Kiln log, which was not a hit, fails with ``SkillFailureCode/notFound``.

On device, `LibraryItemEntity` conforms to `IndexedEntity` and `LibraryItemQuery` conforms to `EntityStringQuery` and `IndexedEntityQuery`.
