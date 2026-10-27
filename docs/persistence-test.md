# Persistence verification

Date: 2026-10-27
Context: kiratech
Namespace: wordpress

## Procedure
1. Opened the published "Kiratech persistence test" post.
2. Confirmed that its text and uploaded image were visible.
3. Replaced the WordPress Pod using rollout restart.
4. Waited for the rollout, reopened port-forward and refreshed the page.
5. Confirmed that the text and image remained visible.
6. Replaced the MySQL Pod using rollout restart.
7. Waited for both Deployments to become available.
8. Reopened port-forward and refreshed the page.
9. Confirmed that the title, text and image remained visible.

## Observed results
- WordPress Pod changed from wordpress-6656c7d6b6-676xn
  to wordpress-6d9554df8d-rs8kg.
- MySQL Pod changed from wordpress-mysql-64bf7fbb89-2h6c7
  to wordpress-mysql-d9c76cbdd-vbhlk.
- Both replacement Pods were Running and Ready with zero restarts.
- Both PVCs remained Bound to the same volumes.
- Browser checks were performed manually.

Result: PASS for data persistence across Pod replacement.

## Evidence
- evidence/persistence-before.txt
- evidence/persistence-after-wordpress.txt
- evidence/persistence-after-mysql.txt

## Scope and limitations
MySQL data persists in /var/lib/mysql.
WordPress content, including uploads, persists in /var/www/html/wp-content.

This test does not verify backup restoration, node failure recovery
or data survival after PVC or cluster deletion.
