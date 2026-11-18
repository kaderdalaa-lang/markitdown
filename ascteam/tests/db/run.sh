#!/usr/bin/env bash
# Local DB test: fresh database, auth stub, migrations, RLS checks.
# Needs a local Postgres. Supabase itself is not used here.
set -euo pipefail
DB=${DB:-ascteam_test}
HERE="$(cd "$(dirname "$0")" && pwd)"
MIG="$HERE/../../migrations"
PSQL="psql -X -q -v ON_ERROR_STOP=1"
$PSQL -d postgres -c "drop database if exists $DB" -c "create database $DB"
$PSQL -d $DB -f "$HERE/supabase_stub.sql"
$PSQL -d $DB -f "$MIG/0001_init.sql"
$PSQL -d $DB -f "$MIG/0002_reminders.sql"
$PSQL -d $DB -f "$MIG/0003_member_privacy.sql"
$PSQL -d $DB -f "$HERE/rls.test.sql" | grep -E "ok |FAIL|PASSED"
