# Persistence across Pod replacement

[All evidence](../README.md)

Report: [Persistence report](../../persistence-test.md)

Recorded 2026-10-27 in wordpress.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Baseline | [persistence-before.txt](persistence-before.txt) | Original Pod names and PVC volume bindings. |
| 2. WordPress replacement | [persistence-after-wordpress.txt](persistence-after-wordpress.txt) | New WordPress Pod with the original MySQL Pod and volume bindings. |
| 3. MySQL replacement | [persistence-after-mysql.txt](persistence-after-mysql.txt) | New MySQL Pod with the same persistent volumes. |

## Interpretation and limits

Compare Pod names and VOLUME identifiers across all three captures. Article/image survival was checked manually and recorded in the report; listings alone do not establish content integrity.
