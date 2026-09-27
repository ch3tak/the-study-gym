-- Maths only (docs/PLAN.md: "Math only. Permanently."). Hides every
-- non-maths Class 9 subject. The read_subjects policy (status <> 'hidden')
-- then keeps them from every client. Rows are kept, not deleted, so
-- chapters, questions and attempts that reference them stay intact.
-- A new file rather than an edit to 001, which is already applied live.
-- Safe to re-run.

begin;

update subjects
set status = 'hidden'
where class_id = 'cbse_9'
  and code <> 'maths';

commit;
