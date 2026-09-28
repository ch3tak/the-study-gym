#!/usr/bin/env bash
# Applies every migration and seed, in dependency order, to the Postgres at
# $DATABASE_URL and stops at the first error. Seeds interleave with
# migrations because each seed's header names the migration it needs
# (e.g. seed 002 runs after 20260927000000).
set -euo pipefail
cd "$(dirname "$0")/.."

FILES=(
  ci/auth_shim.sql
  migrations/20260926000000_core_schema.sql
  migrations/20260926000001_profile_on_signup.sql
  seed/001_cbse_9_maths_science.sql
  migrations/20260927000000_m9_maths_id_convention_and_new_chapters.sql
  seed/002_m9_coord_poly.sql
  migrations/20260928000000_m9_maths_remaining_chapters.sql
  seed/003_m9_remaining_chapters.sql
  migrations/20260929000000_mission_levels.sql
  seed/004_surface_area_volume_mission.sql
  migrations/20260930000000_theory_lessons.sql
  seed/005_surface_area_volume_theory.sql
  seed/006_maths_only.sql
  migrations/20261001000000_units_nodes_trial_meta.sql
  seed/007_course_structure.sql
  seed/007_course_structure.sql   # twice on purpose: proves it's idempotent
  ci/checks.sql
)

for f in "${FILES[@]}"; do
  echo "== $f"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -f "$f"
done
echo "All ${#FILES[@]} files applied."
