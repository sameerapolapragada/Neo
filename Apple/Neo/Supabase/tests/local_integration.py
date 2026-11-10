#!/usr/bin/env python3
"""Live checks against the local Neo Supabase stack.

This script refuses any API or database URL that is not on 127.0.0.1.
It does not call the hosted project and it does not reset a database.
"""

import json
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

NEO_DIR = Path(__file__).resolve().parents[2]
SUPABASE_DIR = NEO_DIR / "Supabase"
MIGRATIONS = SUPABASE_DIR / "migrations"
DB_CONTAINER = "supabase_db_neo-companion-local"
HISTORICAL_MIGRATIONS = [
    "20261105010000_create_companion_core.sql",
    "20261105010100_companion_rls_and_storage.sql",
    "20261105010200_companion_account_deletions.sql",
]
DELETION_MIGRATION = "20261106010000_companion_deletion_guards.sql"
EXPECTED_MIGRATIONS = HISTORICAL_MIGRATIONS + [DELETION_MIGRATION]
PASSED = []
FAILED = []


def check(name, ok, detail=""):
    if ok:
        PASSED.append(name)
        print(f"PASS  {name}")
    else:
        FAILED.append(name)
        print(f"FAIL  {name}{': ' + detail if detail else ''}")


def load_env():
    completed = subprocess.run(
        ["supabase", "status", "--workdir", str(NEO_DIR), "-o", "env"],
        check=True,
        text=True,
        capture_output=True,
    )
    env = {}
    for line in completed.stdout.splitlines():
        if "=" not in line or line.startswith("Stopped"):
            continue
        key, value = line.split("=", 1)
        env[key] = value.strip().strip('"')
    return env


def require_local(env):
    api = env.get("API_URL", "")
    database = env.get("DB_URL", "")
    if not api.startswith("http://127.0.0.1:"):
        sys.exit(f"Refusing non-local API URL: {api}")
    if "127.0.0.1:55422" not in database or "supabase.co" in database:
        sys.exit(f"Refusing unexpected database URL: {database}")
    mapping = subprocess.run(
        ["docker", "port", DB_CONTAINER, "5432"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout
    if "55422" not in mapping:
        sys.exit(f"Refusing to query {DB_CONTAINER}; published port is {mapping.strip()}")
    return api, env["ANON_KEY"]


def psql(sql):
    completed = subprocess.run(
        [
            "docker",
            "exec",
            "-i",
            DB_CONTAINER,
            "psql",
            "-U",
            "postgres",
            "-d",
            "postgres",
            "-v",
            "ON_ERROR_STOP=1",
            "-At",
            "-c",
            sql,
        ],
        check=True,
        text=True,
        capture_output=True,
    )
    return completed.stdout.strip()


def sql_json(sql):
    raw = psql(f"select coalesce(json_agg(row_to_json(q)), '[]'::json)::text from ({sql}) q;")
    return json.loads(raw)


def http(method, url, token, payload=None, content_type="application/json", extra_headers=None):
    data = None
    headers = {
        "apikey": ANON,
        "Authorization": f"Bearer {token}",
    }
    if payload is not None:
        if isinstance(payload, bytes):
            data = payload
        else:
            data = json.dumps(payload).encode()
        headers["Content-Type"] = content_type
    if extra_headers:
        headers.update(extra_headers)
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read()
            return response.status, body, dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, error.read(), dict(error.headers)


def json_body(body):
    if not body:
        return None
    return json.loads(body.decode())


def signup(email):
    status, body, _ = http(
        "POST",
        f"{API}/auth/v1/signup",
        ANON,
        {"email": email, "password": "local-test-password"},
    )
    parsed = json_body(body) or {}
    token = parsed.get("access_token")
    user = parsed.get("user") or {}
    if status not in (200, 201) or not token or not user.get("id"):
        raise RuntimeError(f"signup failed for {email}: {status} {body[:300]!r}")
    return user["id"], token


def rest(method, path, token, payload=None, extra_headers=None):
    headers = {"Prefer": "return=representation"}
    if extra_headers:
        headers.update(extra_headers)
    return http(method, f"{API}/rest/v1/{path}", token, payload, extra_headers=headers)


def strip_sql_comments(text):
    output = []
    index = 0
    while index < len(text):
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            index = len(text) if end < 0 else end + 2
            output.append(" ")
            continue
        if text.startswith("--", index):
            end = text.find("\n", index)
            index = len(text) if end < 0 else end + 1
            output.append("\n")
            continue
        output.append(text[index])
        index += 1
    return "".join(output)


def migration_safety():
    files = sorted(path.name for path in MIGRATIONS.glob("*.sql"))
    check("migration directory contains the versioned companion files", files == EXPECTED_MIGRATIONS, str(files))
    for name in HISTORICAL_MIGRATIONS:
        sql = strip_sql_comments((MIGRATIONS / name).read_text()).lower()
        for forbidden in ("drop table", "drop schema", "truncate", "delete from", "drop column"):
            check(f"{name} has no {forbidden}", forbidden not in sql)
        for expo in ("lifestyle_answers", "future_snapshots", "missing_moments"):
            check(f"{name} does not mention {expo}", expo not in sql)
    deletion_sql = strip_sql_comments((MIGRATIONS / DELETION_MIGRATION).read_text()).lower()
    for forbidden in ("drop table", "drop schema", "truncate", "drop column", "delete from storage"):
        check(f"{DELETION_MIGRATION} has no {forbidden}", forbidden not in deletion_sql)
    check(
        "deletion migration only deletes companion moment rows from inside functions",
        "delete from public.companion_moment_media" in deletion_sql
        and "delete from public.companion_moments" in deletion_sql
        and "delete from public.companion_pets" not in deletion_sql,
    )
    storage_sql = strip_sql_comments((MIGRATIONS / EXPECTED_MIGRATIONS[1]).read_text()).lower()
    check(
        "storage migration drops only the named companion policies before replacing them",
        storage_sql.count("drop policy if exists") == 16 and "drop table" not in storage_sql,
    )


def catalog():
    versions = psql("select version || ' ' || name from supabase_migrations.schema_migrations order by version;")
    check(
        "schema migrations are the three companion versions",
        versions.splitlines()
        == [
            "20261105010000 create_companion_core",
            "20261105010100 companion_rls_and_storage",
            "20261105010200 companion_account_deletions",
            "20261106010000 companion_deletion_guards",
        ],
        versions,
    )
    tables = sql_json(
        """
        select c.relname as name, c.relrowsecurity as rls
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'public' and c.relkind = 'r'
        order by 1
        """
    )
    names = [row["name"] for row in tables]
    check(
        "public tables are only the companion tables",
        names
        == [
            "companion_account_deletions",
            "companion_deletion_jobs",
            "companion_moment_media",
            "companion_moments",
            "companion_pets",
            "companion_storage_cleanup",
        ],
        str(names),
    )
    check("RLS is enabled on every companion table", all(row["rls"] for row in tables))
    indexes = set(
        psql(
            """
            select indexname from pg_indexes
            where schemaname = 'public' and tablename like 'companion_%'
            order by 1
            """
        ).splitlines()
    )
    for expected in (
        "companion_pets_owner_created_idx",
        "companion_moments_timeline_idx",
        "companion_moments_category_idx",
        "companion_moment_media_order_idx",
        "companion_moment_media_owner_idx",
    ):
        check(f"index {expected} exists", expected in indexes)
    constraints = set(
        psql(
            """
            select conname from pg_constraint
            where connamespace = 'public'::regnamespace
            order by 1
            """
        ).splitlines()
    )
    for expected in (
        "companion_pets_name_check",
        "companion_pets_species_check",
        "companion_pets_weight_check",
        "companion_pets_photo_path_check",
        "companion_moments_owner_pet_fkey",
        "companion_moments_category_check",
        "companion_moment_media_owner_moment_fkey",
        "companion_moment_media_path_check",
        "companion_moment_media_mime_check",
        "companion_moment_media_size_check",
        "companion_account_deletions_stage_check",
    ):
        check(f"constraint {expected} exists", expected in constraints)
    triggers = set(
        psql(
            """
            select tgname from pg_trigger t
            join pg_class c on c.oid = t.tgrelid
            join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and not t.tgisinternal
            order by 1
            """
        ).splitlines()
    )
    for expected in (
        "companion_pets_updated_at",
        "companion_pets_owner_lock",
        "companion_moments_updated_at",
        "companion_moments_owner_lock",
        "companion_moment_media_owner_lock",
    ):
        check(f"trigger {expected} exists", expected in triggers)
    policies = sql_json(
        """
        select schemaname, tablename, policyname, cmd, roles::text as roles
        from pg_policies
        where schemaname in ('public', 'storage')
        order by schemaname, tablename, policyname
        """
    )
    policy_names = [row["policyname"] for row in policies]
    expected_policies = []
    for table in ("companion_pets", "companion_moments", "companion_moment_media"):
        for command in ("select", "insert", "update", "delete"):
            expected_policies.append(f"{table}_{command}")
    expected_policies.extend(
        [
            "companion_pet_media_select",
            "companion_pet_media_insert",
            "companion_pet_media_update",
            "companion_pet_media_delete",
        ]
    )
    check(
        "RLS policies match the Phase 1 set",
        set(policy_names) == set(expected_policies) and len(policy_names) == len(expected_policies),
        str(policy_names),
    )
    check(
        "policies apply only to authenticated",
        all(row["roles"] == "{authenticated}" for row in policies),
    )
    deletion_policies = [row for row in policies if row["tablename"] == "companion_account_deletions"]
    check("account deletion log has no client policy", deletion_policies == [])
    moment_date = psql(
        """
        select data_type from information_schema.columns
        where table_schema = 'public' and table_name = 'companion_moments' and column_name = 'moment_date'
        """
    )
    check("moment_date is a date column", moment_date == "date", moment_date)
    pet_columns = set(
        psql(
            """
            select column_name from information_schema.columns
            where table_schema = 'public' and table_name = 'companion_pets'
            """
        ).splitlines()
    )
    check(
        "pet columns match the Swift row",
        pet_columns
        == {
            "id",
            "owner_id",
            "name",
            "species",
            "breed",
            "birthday",
            "adoption_date",
            "weight",
            "weight_unit",
            "favorite_toy",
            "personality",
            "profile_photo_path",
            "gender",
            "microchip_id",
            "is_favorite",
            "deletion_pending",
            "created_at",
            "updated_at",
        },
        str(sorted(pet_columns)),
    )
    grants = psql(
        """
        select grantee || ' ' || table_name || ' ' || privilege_type
        from information_schema.role_table_grants
        where table_schema = 'public' and table_name like 'companion_%'
          and grantee in ('anon', 'authenticated', 'public')
        order by 1
        """
    )
    grant_lines = [line for line in grants.splitlines() if line]
    check("anon and public have no companion grants", all(not line.startswith(("anon ", "public ")) for line in grant_lines), grants)
    check(
        "authenticated can read and write pets, moments, and media",
        all(
            f"authenticated {table} {privilege}" in grant_lines
            for table in ("companion_pets", "companion_moments", "companion_moment_media")
            for privilege in ("SELECT", "INSERT", "UPDATE")
        ),
        grants,
    )
    check(
        "authenticated cannot delete companion rows directly",
        all(not line.endswith(" DELETE") or "companion_account_deletions" in line for line in grant_lines)
        and all(
            f"authenticated {table} DELETE" not in grant_lines
            for table in ("companion_pets", "companion_moments", "companion_moment_media")
        ),
        grants,
    )
    check(
        "authenticated cannot use the deletion log",
        all("companion_account_deletions" not in line for line in grant_lines),
        grants,
    )
    bucket = sql_json(
        """
        select id, public, file_size_limit, allowed_mime_types::text as mime
        from storage.buckets
        where id = 'companion-pet-media'
        """
    )
    check("private JPEG bucket exists", len(bucket) == 1 and bucket[0]["public"] is False, str(bucket))
    check("bucket limit is 10 MB", len(bucket) == 1 and bucket[0]["file_size_limit"] == 10485760, str(bucket))
    check("bucket allows JPEG only", len(bucket) == 1 and bucket[0]["mime"] == "{image/jpeg}", str(bucket))


def insert_pet(token, owner, name):
    status, body, _ = rest(
        "POST",
        "companion_pets",
        token,
        {"owner_id": owner, "name": name, "species": "Dog"},
    )
    rows = json_body(body) or []
    return status, rows[0] if isinstance(rows, list) and rows else None, body


def insert_moment(token, owner, pet_id, title, category, moment_date, created_at=None):
    payload = {
        "owner_id": owner,
        "pet_id": pet_id,
        "title": title,
        "category": category,
        "moment_date": moment_date,
    }
    if created_at:
        payload["created_at"] = created_at
    status, body, _ = rest("POST", "companion_moments", token, payload)
    rows = json_body(body) or []
    return status, rows[0] if isinstance(rows, list) and rows else None, body


def behavior(user_a, token_a, user_b, token_b):
    status, pet, raw = insert_pet(token_a, user_a, "Milo")
    check("User A creates a pet", status in (200, 201) and pet and pet["owner_id"] == user_a, raw[:300].decode())
    if not pet:
        return
    pet_id = pet["id"]
    status, daily, raw = insert_moment(token_a, user_a, pet_id, "Park", "Daily", "2026-05-02")
    check("User A creates a Daily moment", status in (200, 201) and daily and daily["category"] == "Daily", raw[:300].decode())
    status, milestone, raw = insert_moment(token_a, user_a, pet_id, "Gotcha", "Milestone", "2026-05-02")
    check(
        "User A creates a Milestone moment",
        status in (200, 201) and milestone and milestone["category"] == "Milestone",
        raw[:300].decode(),
    )
    if not daily or not milestone:
        return
    file_id = str(uuid.uuid4())
    media_path = f"{user_a}/moments/{daily['id']}/{file_id}.jpg"
    status, body, _ = rest(
        "POST",
        "companion_moment_media",
        token_a,
        {
            "owner_id": user_a,
            "moment_id": daily["id"],
            "storage_path": media_path,
            "sort_order": 0,
            "mime_type": "image/jpeg",
            "file_size": 1200,
        },
    )
    media_rows = json_body(body) or []
    check("User A uploads media metadata", status in (200, 201) and media_rows and media_rows[0]["storage_path"] == media_path, body[:300].decode())

    status, body, _ = rest("GET", "companion_pets?select=id,name", token_a)
    pets = json_body(body) or []
    check("User A reads their pet", status == 200 and any(row["id"] == pet_id for row in pets), body[:300].decode())
    status, body, _ = rest("GET", f"companion_moments?pet_id=eq.{pet_id}&select=id,category,moment_date", token_a)
    moments = json_body(body) or []
    check(
        "User A reads their moments and the date stays date-only",
        status == 200 and {row["moment_date"] for row in moments} == {"2026-05-02"} and len(moments) == 2,
        body[:400].decode(),
    )
    milestones = [row for row in moments if row["category"] == "Milestone"]
    check("Milestone count includes only Milestone moments", len(milestones) == 1)

    status, body, _ = rest("GET", "companion_pets?select=id", token_b)
    check("User B cannot read User A's pet", status == 200 and json_body(body) == [], body[:300].decode())
    status, body, _ = rest("GET", f"companion_moments?pet_id=eq.{pet_id}&select=id", token_b)
    check("User B cannot read User A's moments", status == 200 and json_body(body) == [], body[:300].decode())
    status, _, raw = insert_moment(token_b, user_b, pet_id, "Stolen", "Daily", "2026-05-03")
    attached = psql(f"select count(*) from public.companion_moments where pet_id = '{pet_id}' and owner_id = '{user_b}';")
    check("User B cannot attach a moment to User A's pet", status >= 400 and attached == "0", f"status {status} rows {attached} {raw[:240]!r}")

    status, body, _ = rest("PATCH", f"companion_pets?id=eq.{pet_id}", token_b, {"owner_id": user_b, "name": "Taken"})
    owner_after_b = psql(f"select owner_id::text || ' ' || name from public.companion_pets where id = '{pet_id}';")
    check("User B cannot change User A's owner_id", owner_after_b == f"{user_a} Milo", f"status {status} {owner_after_b}")
    status, body, _ = rest("PATCH", f"companion_pets?id=eq.{pet_id}", token_a, {"owner_id": user_b})
    owner_after_a = psql(f"select owner_id::text from public.companion_pets where id = '{pet_id}';")
    check("User A cannot reassign their own owner_id", status >= 400 and owner_after_a == user_a, f"status {status} {body[:240]!r}")

    status, body, _ = rest("GET", "companion_pets?select=id", ANON)
    check("anonymous request cannot read pets", status in (401, 403), f"status {status} {body[:240]!r}")
    status, body, _ = rest("GET", "companion_moments?select=id", ANON)
    check("anonymous request cannot read moments", status in (401, 403), f"status {status} {body[:240]!r}")
    status, body, _ = rest("GET", "companion_moment_media?select=id", ANON)
    check("anonymous request cannot read media metadata", status in (401, 403), f"status {status} {body[:240]!r}")

    status, extra_pet, _ = insert_pet(token_a, user_a, "Ada")
    check("an owner can have multiple pets", status in (200, 201) and extra_pet is not None)
    status, body, _ = rest(
        "GET",
        "companion_pets?name=eq.Ada&select=birthday,adoption_date,weight,microchip_id,profile_photo_path,favorite_toy,breed,personality",
        token_a,
    )
    optional = (json_body(body) or [{}])[0]
    check(
        "optional profile fields may be absent",
        optional.get("birthday") is None
        and optional.get("adoption_date") is None
        and optional.get("weight") is None
        and optional.get("microchip_id") is None
        and optional.get("profile_photo_path") is None
        and optional.get("favorite_toy") is None
        and optional.get("breed") == ""
        and optional.get("personality") == "",
        str(optional),
    )

    status, first, _ = insert_moment(token_a, user_a, pet_id, "First", "Daily", "2026-03-01", "2026-03-01T12:00:00Z")
    status_second, second, _ = insert_moment(token_a, user_a, pet_id, "Second", "Adventure", "2026-03-01", "2026-03-01T10:00:00Z")
    status_old, old, _ = insert_moment(token_a, user_a, pet_id, "Old", "Daily", "2026-01-01", "2026-01-01T10:00:00Z")
    status, body, _ = rest(
        "GET",
        f"companion_moments?pet_id=eq.{pet_id}&title=in.(First,Second,Old)&select=title&order=moment_date.desc,created_at.desc,id.desc",
        token_a,
    )
    titles = [row["title"] for row in (json_body(body) or [])]
    check(
        "moments order by date and then creation time",
        status_second in (200, 201) and status_old in (200, 201) and first and titles == ["First", "Second", "Old"],
        str(titles),
    )
    status, body, headers = rest(
        "GET",
        f"companion_moments?pet_id=eq.{pet_id}&title=in.(First,Second,Old)&select=title&order=moment_date.desc,created_at.desc,id.desc",
        token_a,
        extra_headers={"Range": "0-0"},
    )
    page = json_body(body) or []
    check("moment pagination returns the first ordered row", status in (200, 206) and [row["title"] for row in page] == ["First"], str(page))

    status, _, raw = insert_moment(token_a, user_a, str(uuid.uuid4()), "Missing", "Daily", "2026-05-04")
    check("a moment cannot reference a pet that does not exist", status >= 400, f"status {status} {raw[:200]!r}")
    status, _, raw = insert_pet_invalid(token_a, user_a)
    check("invalid species is rejected", status >= 400, f"status {status} {raw[:200]!r}")
    status, body, _ = rest("POST", "companion_pets", token_a, {"owner_id": user_a, "name": "A", "species": "Dog"})
    check("a one-character pet name is rejected", status >= 400, body[:200].decode())
    status, body, _ = rest(
        "POST",
        "companion_moment_media",
        token_a,
        {
            "owner_id": user_a,
            "moment_id": daily["id"],
            "storage_path": media_path,
            "sort_order": 0,
            "mime_type": "image/jpeg",
            "file_size": 10,
        },
    )
    check("duplicate media sort order is rejected", status >= 400, body[:200].decode())
    status, body, _ = rest(
        "POST",
        "companion_moment_media",
        token_a,
        {
            "owner_id": user_a,
            "moment_id": daily["id"],
            "storage_path": f"{user_b}/moments/{daily['id']}/{uuid.uuid4()}.jpg",
            "sort_order": 1,
            "mime_type": "image/jpeg",
        },
    )
    check("media metadata cannot point at another owner's folder", status >= 400, body[:200].decode())

    status, removable, _ = insert_moment(token_a, user_a, pet_id, "Temporary", "Daily", "2026-06-01")
    if removable:
        rest(
            "POST",
            "companion_moment_media",
            token_a,
            {
                "owner_id": user_a,
                "moment_id": removable["id"],
                "storage_path": f"{user_a}/moments/{removable['id']}/{uuid.uuid4()}.jpg",
                "sort_order": 0,
                "mime_type": "image/jpeg",
            },
        )
        before = psql(f"select count(*) from public.companion_moment_media where moment_id = '{removable['id']}';")
        status, _, _ = rest("DELETE", f"companion_moments?id=eq.{removable['id']}", token_a)
        after = psql(f"select count(*) from public.companion_moment_media where moment_id = '{removable['id']}';")
        check(
            "direct moment delete is rejected and media remains",
            before == "1" and status >= 400 and after == "1",
            f"status {status} {before} -> {after}",
        )

    status, doomed, _ = insert_pet(token_a, user_a, "Temporary")
    if doomed:
        moment_status, doomed_moment, _ = insert_moment(token_a, user_a, doomed["id"], "Gone", "Milestone", "2026-07-01")
        if doomed_moment:
            rest(
                "POST",
                "companion_moment_media",
                token_a,
                {
                    "owner_id": user_a,
                    "moment_id": doomed_moment["id"],
                    "storage_path": f"{user_a}/moments/{doomed_moment['id']}/{uuid.uuid4()}.jpg",
                    "sort_order": 0,
                    "mime_type": "image/jpeg",
                },
            )
        status, _, _ = rest("DELETE", f"companion_pets?id=eq.{doomed['id']}", token_a)
        remaining = psql(
            f"""
            select
              (select count(*) from public.companion_pets where id = '{doomed['id']}')::text || ' ' ||
              (select count(*) from public.companion_moments where pet_id = '{doomed['id']}')::text || ' ' ||
              (select count(*) from public.companion_moment_media where moment_id = '{doomed_moment['id'] if doomed_moment else uuid.uuid4()}')::text
            """
        )
        check(
            "direct pet delete is rejected and rows remain",
            moment_status in (200, 201) and status >= 400 and remaining == "1 1 1",
            f"status {status} {remaining}",
        )

    storage(user_a, token_a, user_b, token_b, pet_id)


def insert_pet_invalid(token, owner):
    status, body, _ = rest("POST", "companion_pets", token, {"owner_id": owner, "name": "Nope", "species": "Dragon"})
    return status, None, body


def storage(user_a, token_a, user_b, token_b, pet_id):
    file_id = str(uuid.uuid4())
    path = f"{user_a}/pets/{pet_id}/profile/{file_id}.jpg"
    jpeg = b"\xff\xd8\xff" + b"\x00" * 64
    status, body, _ = upload(token_a, path, jpeg, "image/jpeg")
    stored = psql(
        f"""
        select coalesce(owner::text, 'null') || ' ' || count(*)::text
        from storage.objects
        where bucket_id = 'companion-pet-media' and name = '{path}'
        group by owner
        """
    )
    check("authorized JPEG upload", status in (200, 201) and stored == f"{user_a} 1", f"status {status} {stored} {body[:240]!r}")

    status, body, _ = upload(token_a, f"{user_a}/pets/{pet_id}/profile/{uuid.uuid4()}.png", jpeg, "image/png")
    check("unsupported file type is rejected", status >= 400, f"status {status} {body[:240]!r}")
    oversized = b"\xff\xd8\xff" + b"\x00" * (10 * 1024 * 1024)
    status, body, _ = upload(token_a, f"{user_a}/pets/{pet_id}/profile/{uuid.uuid4()}.jpg", oversized, "image/jpeg")
    check("oversized upload is rejected", status >= 400, f"status {status} {body[:240]!r}")

    status, body, _ = upload(token_b, path, jpeg, "image/jpeg")
    still_owner = psql(
        f"select owner::text from storage.objects where bucket_id = 'companion-pet-media' and name = '{path}';"
    )
    check("cross-user upload is rejected", status >= 400 and still_owner == user_a, f"status {status} owner {still_owner} {body[:240]!r}")

    status, body, _ = download(token_b, path)
    check("cross-user object read is rejected", status >= 400 or body != jpeg, f"status {status} bytes {len(body)}")
    status, body, _ = http("GET", f"{API}/storage/v1/object/public/companion-pet-media/{path}", ANON)
    check("private bucket has no public object URL", status >= 400, f"status {status}")
    status, body, _ = upload(ANON, f"{user_a}/pets/{pet_id}/profile/{uuid.uuid4()}.jpg", jpeg, "image/jpeg")
    check("anonymous upload is rejected", status >= 400, f"status {status} {body[:200]!r}")

    status, body, _ = http(
        "POST",
        f"{API}/storage/v1/object/sign/companion-pet-media/{path}",
        token_a,
        {"expiresIn": 120},
    )
    signed = json_body(body) or {}
    signed_path = signed.get("signedURL") or signed.get("signedUrl") or ""
    check(
        "authorized signed URL is created",
        status == 200 and signed_path and "/object/public/" not in signed_path,
        f"status {status} {body[:240]!r}",
    )
    if signed_path:
        signed_url = signed_path if signed_path.startswith("http") else f"{API}/storage/v1{signed_path}"
        read_status, read_body, _ = http("GET", signed_url, ANON)
        check("signed URL reads the private object", read_status == 200 and read_body == jpeg, f"status {read_status}")

    status, body, _ = http(
        "POST",
        f"{API}/storage/v1/object/sign/companion-pet-media/{path}",
        token_b,
        {"expiresIn": 120},
    )
    check("User B cannot sign User A's object", status >= 400, f"status {status} {body[:200]!r}")

    status, body, _ = http(
        "POST",
        f"{API}/storage/v1/object/sign/companion-pet-media/{path}",
        token_a,
        {"expiresIn": 2},
    )
    short = json_body(body) or {}
    short_path = short.get("signedURL") or short.get("signedUrl") or ""
    if short_path:
        short_url = short_path if short_path.startswith("http") else f"{API}/storage/v1{short_path}"
        immediate, _, _ = http("GET", short_url, ANON)
        time.sleep(4)
        expired, _, _ = http("GET", short_url, ANON)
        check(
            "signed URL expires",
            status == 200 and immediate == 200 and expired >= 400,
            f"create {status} immediate {immediate} later {expired}",
        )
    else:
        check("signed URL expires", False, f"short URL was not created: {status} {body[:200]!r}")

    status, body, _ = http(
        "DELETE",
        f"{API}/storage/v1/object/companion-pet-media",
        token_b,
        {"prefixes": [path]},
    )
    remains = psql(
        f"select count(*) from storage.objects where bucket_id = 'companion-pet-media' and name = '{path}';"
    )
    check("cross-user object deletion is rejected", remains == "1", f"status {status} remains {remains} {body[:200]!r}")
    status, _, _ = http(
        "DELETE",
        f"{API}/storage/v1/object/companion-pet-media",
        token_a,
        {"prefixes": [path]},
    )
    remains = psql(
        f"select count(*) from storage.objects where bucket_id = 'companion-pet-media' and name = '{path}';"
    )
    check("the owner can delete their own object", status in (200, 204) and remains == "0", f"status {status} remains {remains}")


def upload(token, path, data, content_type):
    return http(
        "POST",
        f"{API}/storage/v1/object/companion-pet-media/{path}",
        token,
        data,
        content_type=content_type,
        extra_headers={"x-upsert": "false"},
    )


def download(token, path):
    return http("GET", f"{API}/storage/v1/object/authenticated/companion-pet-media/{path}", token)


def function_call(name, token, payload):
    return http("POST", f"{API}/functions/v1/{name}", token, payload)


def object_count(name):
    escaped = name.replace("'", "''")
    return psql(
        "select count(*) from storage.objects "
        f"where bucket_id = 'companion-pet-media' and name = '{escaped}';"
    )


def deletion_flows():
    suffix = uuid.uuid4().hex[:8]
    user_a, token_a = signup(f"delete-a-{suffix}@example.com")
    user_b, token_b = signup(f"delete-b-{suffix}@example.com")
    status, body, _ = function_call(
        "delete-moment",
        "not-a-jwt",
        {"momentId": str(uuid.uuid4()), "petId": str(uuid.uuid4())},
    )
    check("invalid authentication is rejected", status == 401, f"status {status} {body[:180]!r}")
    status, body, _ = function_call(
        "delete-moment",
        token_a,
        {"momentId": str(uuid.uuid4()), "petId": str(uuid.uuid4()), "ownerId": user_a},
    )
    check("a client-supplied owner id is rejected", status == 400, f"status {status} {body[:180]!r}")

    status, pet, _ = insert_pet(token_a, user_a, "Keeper")
    status_other, other_pet, _ = insert_pet(token_a, user_a, "Other")
    if not pet or not other_pet:
        check("deletion fixtures were created", False, "pet insert failed")
        return
    other_profile = f"{user_a}/pets/{other_pet['id']}/profile/{uuid.uuid4()}.jpg"
    upload(token_a, other_profile, b"\xff\xd8\xff" + b"\x11" * 32, "image/jpeg")
    profile = f"{user_a}/pets/{pet['id']}/profile/{uuid.uuid4()}.jpg"
    upload(token_a, profile, b"\xff\xd8\xff" + b"\x22" * 32, "image/jpeg")
    rest(
        "PATCH",
        f"companion_pets?id=eq.{pet['id']}",
        token_a,
        {"profile_photo_path": profile},
    )
    moment_status, moment, _ = insert_moment(token_a, user_a, pet["id"], "Five", "Daily", "2026-08-01")
    paths = []
    if moment:
        for order in range(5):
            path = f"{user_a}/moments/{moment['id']}/{uuid.uuid4()}.jpg"
            upload(token_a, path, b"\xff\xd8\xff" + bytes([order]) * 16, "image/jpeg")
            rest(
                "POST",
                "companion_moment_media",
                token_a,
                {
                    "owner_id": user_a,
                    "moment_id": moment["id"],
                    "storage_path": path,
                    "sort_order": order,
                    "mime_type": "image/jpeg",
                    "file_size": 20,
                },
            )
            paths.append(path)
    check("five moment photographs were stored", moment_status in (200, 201) and len(paths) == 5 and all(object_count(path) == "1" for path in paths))
    if not moment:
        return

    favorite, _, _ = rest(
        "PATCH",
        f"companion_moments?id=eq.{moment['id']}",
        token_a,
        {"is_favorite": True},
    )
    check("favorite update still works before deletion", favorite in (200, 204), f"status {favorite}")
    media_delete, _, _ = rest("DELETE", f"companion_moment_media?moment_id=eq.{moment['id']}", token_a)
    check("direct media delete is rejected", media_delete >= 400, f"status {media_delete}")

    stranger_moment, stranger_body, _ = function_call(
        "delete-moment",
        token_b,
        {"momentId": moment["id"], "petId": pet["id"]},
    )
    stranger_pet, _, _ = function_call("delete-pet", token_b, {"petId": pet["id"]})
    check(
        "another owner cannot delete the moment or its images",
        stranger_moment == 404 and stranger_pet == 404 and all(object_count(path) == "1" for path in paths),
        f"moment {stranger_moment} pet {stranger_pet} {stranger_body[:160]!r}",
    )

    missing_status, missing_moment, _ = insert_moment(token_a, user_a, pet["id"], "Missing file", "Daily", "2026-08-02")
    missing_path = f"{user_a}/moments/{missing_moment['id']}/{uuid.uuid4()}.jpg" if missing_moment else ""
    if missing_moment:
        rest(
            "POST",
            "companion_moment_media",
            token_a,
            {
                "owner_id": user_a,
                "moment_id": missing_moment["id"],
                "storage_path": missing_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
            },
        )
    missing_delete, missing_body, _ = function_call(
        "delete-moment",
        token_a,
        {"momentId": missing_moment["id"], "petId": pet["id"]},
    ) if missing_moment else (0, b"", {})
    missing_rows = psql(
        f"select count(*) from public.companion_moments where id = '{missing_moment['id']}';"
    ) if missing_moment else "1"
    check(
        "a missing storage object is still removed from the database",
        missing_status in (200, 201) and missing_delete == 200 and missing_rows == "0" and object_count(missing_path) == "0",
        f"create {missing_status} delete {missing_delete} rows {missing_rows} {missing_body[:160]!r}",
    )

    retry_moment = None
    retry_path = ""
    psql(
        """
        create table if not exists public.neo_deletion_test_fail (id integer primary key);
        insert into public.neo_deletion_test_fail values (1) on conflict do nothing;
        create or replace function public.neo_test_fail_moment_delete()
        returns trigger
        language plpgsql
        as $fn$
        begin
          if exists (select 1 from public.neo_deletion_test_fail) then
            delete from public.neo_deletion_test_fail;
            raise exception 'simulated database failure';
          end if;
          return old;
        end
        $fn$;
        drop trigger if exists neo_test_fail_moment_delete on public.companion_moments;
        create trigger neo_test_fail_moment_delete
        before delete on public.companion_moments
        for each row execute function public.neo_test_fail_moment_delete();
        """
    )
    try:
        retry_status, retry_moment, _ = insert_moment(token_a, user_a, pet["id"], "Retry row", "Adventure", "2026-08-03")
        retry_path = f"{user_a}/moments/{retry_moment['id']}/{uuid.uuid4()}.jpg"
        upload(token_a, retry_path, b"\xff\xd8\xff" + b"\x33" * 16, "image/jpeg")
        rest(
            "POST",
            "companion_moment_media",
            token_a,
            {
                "owner_id": user_a,
                "moment_id": retry_moment["id"],
                "storage_path": retry_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
                "file_size": 20,
            },
        )
        first, first_body, _ = function_call(
            "delete-moment",
            token_a,
            {"momentId": retry_moment["id"], "petId": pet["id"]},
        )
        first_parsed = json_body(first_body) or {}
        still_there = psql(f"select count(*) from public.companion_moments where id = '{retry_moment['id']}';")
        job_paths = psql(
            "select coalesce(array_length(object_paths, 1), 0) "
            f"from public.companion_deletion_jobs where owner_id = '{user_a}' "
            f"and target_kind = 'moment' and target_id = '{retry_moment['id']}';"
        )
        check(
            "a database deletion failure keeps the path for retry",
            retry_status in (200, 201)
            and first == 409
            and first_parsed.get("stage") == "records"
            and still_there == "1"
            and job_paths not in ("", "0"),
            f"status {first} rows {still_there} paths {job_paths} {first_body[:180]!r}",
        )
    finally:
        psql(
            """
            drop trigger if exists neo_test_fail_moment_delete on public.companion_moments;
            drop function if exists public.neo_test_fail_moment_delete();
            drop table if exists public.neo_deletion_test_fail;
            """
        )
    if not retry_moment:
        check("the database deletion can be retried", False, "retry fixture was not created")
        return
    second, second_body, _ = function_call(
        "delete-moment",
        token_a,
        {"momentId": retry_moment["id"], "petId": pet["id"]},
    )
    second_rows = psql(f"select count(*) from public.companion_moments where id = '{retry_moment['id']}';")
    check(
        "the database deletion can be retried",
        second == 200 and second_rows == "0" and object_count(retry_path) == "0",
        f"status {second} rows {second_rows} {second_body[:160]!r}",
    )
    third, _, _ = function_call(
        "delete-moment",
        token_a,
        {"momentId": retry_moment["id"], "petId": pet["id"]},
    )
    check("a duplicate moment deletion is safe", third == 200, f"status {third}")

    removed, removed_body, _ = function_call(
        "delete-moment",
        token_a,
        {"momentId": moment["id"], "petId": pet["id"]},
    )
    removed_rows = psql(
        f"select count(*) from public.companion_moments where id = '{moment['id']}';"
    )
    check(
        "the owner deletes a five-photo memory without orphaned objects",
        removed == 200 and removed_rows == "0" and all(object_count(path) == "0" for path in paths),
        f"status {removed} rows {removed_rows} {removed_body[:160]!r}",
    )

    pet_delete, pet_body, _ = function_call("delete-pet", token_a, {"petId": pet["id"]})
    pet_rows = psql(
        f"""
        select
          (select count(*) from public.companion_pets where id = '{pet['id']}')::text || ' ' ||
          (select count(*) from public.companion_pets where id = '{other_pet['id']}')::text
        """
    )
    check(
        "pet deletion removes that pet and its profile image only",
        pet_delete == 200 and pet_rows == "0 1" and object_count(profile) == "0" and object_count(other_profile) == "1",
        f"status {pet_delete} rows {pet_rows} {pet_body[:160]!r}",
    )
    again, _, _ = function_call("delete-pet", token_a, {"petId": pet["id"]})
    check("a duplicate pet deletion is safe", again == 200, f"status {again}")

    account_owner, account_token = signup(f"delete-account-{suffix}@example.com")
    account_pet_status, account_pet, _ = insert_pet(account_token, account_owner, "Account")
    account_path = f"{account_owner}/pets/{account_pet['id']}/profile/{uuid.uuid4()}.jpg" if account_pet else ""
    if account_pet:
        upload(account_token, account_path, b"\xff\xd8\xff" + b"\x44" * 16, "image/jpeg")
        rest("PATCH", f"companion_pets?id=eq.{account_pet['id']}", account_token, {"profile_photo_path": account_path})
    missing_password, _, _ = function_call("delete-account", account_token, {"confirm": True})
    wrong_password, _, _ = function_call(
        "delete-account",
        account_token,
        {"confirm": True, "password": "not-the-password"},
    )
    check(
        "account deletion rejects a missing or wrong password before deleting data",
        missing_password == 400 and wrong_password == 401 and object_count(account_path) == "1",
        f"missing {missing_password} wrong {wrong_password}",
    )
    account_status, account_body, _ = function_call(
        "delete-account",
        account_token,
        {"confirm": True, "password": "local-test-password"},
    )
    account_rows = psql(f"select count(*) from public.companion_pets where owner_id = '{account_owner}';") if account_pet else "1"
    check(
        "account deletion removes owned photos and leaves the other account",
        account_pet_status in (200, 201)
        and account_status == 200
        and account_rows == "0"
        and object_count(account_path) == "0"
        and object_count(other_profile) == "1",
        f"status {account_status} rows {account_rows} {account_body[:180]!r}",
    )

    other_password_status, other_password_body, _ = http(
        "POST",
        f"{API}/auth/v1/signup",
        ANON,
        {"email": f"delete-other-{suffix}@example.com", "password": "different-user-password"},
    )
    other_password_user = (json_body(other_password_body) or {}).get("user") or {}
    wrong_owner_password, _, _ = function_call(
        "delete-account",
        account_token,
        {"confirm": True, "password": "different-user-password"},
    ) if account_status != 200 else (0, b"", {})
    # The account above was deleted. Use a fresh account for the different-password check.
    fresh_owner, fresh_token = signup(f"delete-fresh-{suffix}@example.com")
    fresh_status, fresh_pet, _ = insert_pet(fresh_token, fresh_owner, "Fresh")
    fresh_path = ""
    if fresh_pet:
        fresh_path = f"{fresh_owner}/pets/{fresh_pet['id']}/profile/{uuid.uuid4()}.jpg"
        upload(fresh_token, fresh_path, b"\xff\xd8\xff" + b"\x55" * 16, "image/jpeg")
        rest("PATCH", f"companion_pets?id=eq.{fresh_pet['id']}", fresh_token, {"profile_photo_path": fresh_path})
    different_password, _, _ = function_call(
        "delete-account",
        fresh_token,
        {"confirm": True, "password": "different-user-password"},
    )
    fresh_rows = psql(f"select count(*) from public.companion_pets where id = '{fresh_pet['id']}';") if fresh_pet else "0"
    check(
        "another user's password cannot delete this account",
        other_password_status in (200, 201)
        and other_password_user.get("id")
        and fresh_status in (200, 201)
        and different_password == 401
        and fresh_rows == "1"
        and object_count(fresh_path) == "1",
        f"different {different_password} rows {fresh_rows}",
    )

    one_status, one_moment, _ = insert_moment(fresh_token, fresh_owner, fresh_pet["id"], "One", "Daily", "2026-08-04") if fresh_pet else (0, None, {})
    one_path = f"{fresh_owner}/moments/{one_moment['id']}/{uuid.uuid4()}.jpg" if one_moment else ""
    if one_moment:
        upload(fresh_token, one_path, b"\xff\xd8\xff" + b"\x66" * 16, "image/jpeg")
        rest(
            "POST",
            "companion_moment_media",
            fresh_token,
            {
                "owner_id": fresh_owner,
                "moment_id": one_moment["id"],
                "storage_path": one_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
                "file_size": 20,
            },
        )
    one_delete, _, _ = function_call(
        "delete-moment",
        fresh_token,
        {"momentId": one_moment["id"], "petId": fresh_pet["id"]},
    ) if one_moment else (0, b"", {})
    check(
        "the owner deletes a one-photo memory",
        one_status in (200, 201) and one_delete == 200 and object_count(one_path) == "0",
        f"create {one_status} delete {one_delete}",
    )

    multi_status, multi_pet, _ = insert_pet(fresh_token, fresh_owner, "Many")
    multi_paths = []
    multi_moments = []
    if multi_pet:
        for index, day in enumerate(("2026-08-05", "2026-08-06")):
            moment_status, multi_moment, _ = insert_moment(
                fresh_token, fresh_owner, multi_pet["id"], f"Memory {index}", "Daily", day
            )
            if not multi_moment:
                continue
            path = f"{fresh_owner}/moments/{multi_moment['id']}/{uuid.uuid4()}.jpg"
            upload(fresh_token, path, b"\xff\xd8\xff" + bytes([index + 7]) * 16, "image/jpeg")
            rest(
                "POST",
                "companion_moment_media",
                fresh_token,
                {
                    "owner_id": fresh_owner,
                    "moment_id": multi_moment["id"],
                    "storage_path": path,
                    "sort_order": 0,
                    "mime_type": "image/jpeg",
                    "file_size": 20,
                },
            )
            multi_paths.append(path)
            multi_moments.append(multi_moment["id"])
    multi_delete, _, _ = function_call("delete-pet", fresh_token, {"petId": multi_pet["id"]}) if multi_pet else (0, b"", {})
    multi_left = psql(
        "select count(*) from public.companion_moments where pet_id = "
        f"'{multi_pet['id']}';"
    ) if multi_pet else "2"
    check(
        "pet deletion removes every moment and photograph for that pet",
        multi_status in (200, 201)
        and len(multi_paths) == 2
        and multi_delete == 200
        and multi_left == "0"
        and all(object_count(path) == "0" for path in multi_paths)
        and fresh_rows == "1",
        f"status {multi_delete} moments {multi_left}",
    )

    replace_status, replace_moment, _ = insert_moment(
        fresh_token, fresh_owner, fresh_pet["id"], "Replace", "Daily", "2026-08-07"
    ) if fresh_pet else (0, None, {})
    old_path = new_path = ""
    if replace_moment:
        old_path = f"{fresh_owner}/moments/{replace_moment['id']}/{uuid.uuid4()}.jpg"
        new_path = f"{fresh_owner}/moments/{replace_moment['id']}/{uuid.uuid4()}.jpg"
        upload(fresh_token, old_path, b"\xff\xd8\xff" + b"\x77" * 16, "image/jpeg")
        upload(fresh_token, new_path, b"\xff\xd8\xff" + b"\x88" * 16, "image/jpeg")
        rest(
            "POST",
            "companion_moment_media",
            fresh_token,
            {
                "owner_id": fresh_owner,
                "moment_id": replace_moment["id"],
                "storage_path": old_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
                "file_size": 20,
            },
        )
    replace_call, replace_body, _ = http(
        "POST",
        f"{API}/rest/v1/rpc/companion_replace_moment_media",
        fresh_token,
        {
            "p_moment_id": replace_moment["id"],
            "p_media": [{
                "storage_path": new_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
                "file_size": 20,
            }],
        },
    ) if replace_moment else (0, b"", {})
    replaced = json_body(replace_body) if replace_moment else {}
    removed_paths = (replaced or {}).get("removed") or []
    stranger_cleanup, _, _ = function_call("cleanup-storage", token_b, {"paths": [old_path]}) if old_path else (0, b"", {})
    after_stranger = object_count(old_path) if old_path else "0"
    owner_cleanup, _, _ = function_call("cleanup-storage", fresh_token, {"paths": [old_path, new_path]}) if old_path else (0, b"", {})
    check(
        "photo replacement keeps the new file and cleanup cannot remove another owner's file",
        replace_status in (200, 201)
        and replace_call == 200
        and old_path in removed_paths
        and stranger_cleanup == 400
        and after_stranger == "1"
        and owner_cleanup == 200
        and object_count(old_path) == "0"
        and object_count(new_path) == "1",
        f"rpc {replace_call} body {replace_body[:180]!r} stranger {stranger_cleanup} after {after_stranger}",
    )

    race_status, race_moment, _ = insert_moment(
        fresh_token, fresh_owner, fresh_pet["id"], "Race", "Daily", "2026-08-08"
    ) if fresh_pet else (0, None, {})
    race_path = f"{fresh_owner}/moments/{race_moment['id']}/{uuid.uuid4()}.jpg" if race_moment else ""
    if race_moment:
        upload(fresh_token, race_path, b"\xff\xd8\xff" + b"\x99" * 16, "image/jpeg")
        rest(
            "POST",
            "companion_moment_media",
            fresh_token,
            {
                "owner_id": fresh_owner,
                "moment_id": race_moment["id"],
                "storage_path": race_path,
                "sort_order": 0,
                "mime_type": "image/jpeg",
                "file_size": 20,
            },
        )
    race_results = []
    if race_moment:
        def race_delete():
            try:
                status, _, _ = function_call(
                    "delete-moment",
                    fresh_token,
                    {"momentId": race_moment["id"], "petId": fresh_pet["id"]},
                )
                race_results.append(status)
            except Exception as error:
                race_results.append(str(error))
        threads = [threading.Thread(target=race_delete) for _ in range(2)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()
    race_rows = psql(f"select count(*) from public.companion_moments where id = '{race_moment['id']}';") if race_moment else "1"
    check(
        "concurrent moment deletions finish without leaving the photograph",
        race_status in (200, 201)
        and sorted(race_results) == [200, 200]
        and race_rows == "0"
        and object_count(race_path) == "0",
        f"results {race_results} rows {race_rows}",
    )

    sql_delete = subprocess.run(
        [
            "docker", "exec", "-i", DB_CONTAINER, "psql", "-U", "postgres", "-d", "postgres",
            "-v", "ON_ERROR_STOP=1", "-c",
            "begin; "
            f"select set_config('request.jwt.claims', '{{\"sub\":\"{fresh_owner}\",\"role\":\"authenticated\"}}', true); "
            "set local role authenticated; "
            f"delete from public.companion_pets where id = '{fresh_pet['id']}'; "
            "rollback;",
        ],
        text=True,
        capture_output=True,
    ) if fresh_pet else subprocess.CompletedProcess(args=[], returncode=1, stdout="", stderr="missing pet")
    check(
        "an authenticated SQL session cannot delete a pet directly",
        fresh_pet is not None
        and sql_delete.returncode != 0
        and "permission denied" in (sql_delete.stderr or "").lower()
        and psql(f"select count(*) from public.companion_pets where id = '{fresh_pet['id']}';") == "1",
        (sql_delete.stderr or sql_delete.stdout or "")[-240:],
    )


def security_catalog():
    rows = sql_json(
        """
        select p.proname as name,
               p.prosecdef as security_definer,
               coalesce(array_to_string(p.proconfig, ','), '') as config,
               has_function_privilege('authenticated', p.oid, 'execute') as authenticated,
               has_function_privilege('anon', p.oid, 'execute') as anon
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname like 'companion\\_%'
        order by p.proname
        """
    )
    by_name = {row["name"]: row for row in rows}
    definers = [
        "companion_guard_pet",
        "companion_guard_moment",
        "companion_guard_moment_media",
        "companion_replace_moment_media",
        "companion_abandon_empty_moment",
    ]
    check(
        "security definer companion functions pin search_path",
        all(
            by_name[name]["security_definer"] is True
            and "search_path=public" in by_name[name]["config"]
            for name in definers
        ),
        str({name: by_name.get(name) for name in definers}),
    )
    check(
        "authenticated cannot execute deletion guard functions",
        all(by_name[name]["authenticated"] is False and by_name[name]["anon"] is False for name in definers[:3]),
    )
    check(
        "authenticated can replace media and abandon an empty moment",
        by_name["companion_replace_moment_media"]["authenticated"] is True
        and by_name["companion_abandon_empty_moment"]["authenticated"] is True
        and by_name["companion_replace_moment_media"]["anon"] is False
        and by_name["companion_abandon_empty_moment"]["anon"] is False,
    )


def main():
    global API, ANON
    env = load_env()
    API, ANON = require_local(env)
    migration_safety()
    catalog()
    suffix = uuid.uuid4().hex[:8]
    user_a, token_a = signup(f"user-a-{suffix}@example.com")
    user_b, token_b = signup(f"user-b-{suffix}@example.com")
    behavior(user_a, token_a, user_b, token_b)
    security_catalog()
    deletion_flows()
    print(f"\nRan {len(PASSED) + len(FAILED)}  passed {len(PASSED)}  failed {len(FAILED)}")
    return 1 if FAILED else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        print(error.stderr or error.stdout)
        sys.exit(1)
