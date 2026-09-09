## `ansible-inventory --graph`

```
@all:                          ← every host Ansible knows about
  |--@postgresql:              ← the [postgresql] group from inventory/hosts
  |  |--localhost              ← the host inside that group
  |--@ungrouped:               ← hosts not in any named group
```

**What each part means:**

```
@all
 │
 └── built-in group — always exists, contains every host

@postgresql
 │
 └── your group — defined by [postgresql] in inventory/hosts
     playbooks target this with:  hosts: postgresql

@ungrouped
 │
 └── hosts listed in the inventory file but not inside any group
     ideally this should be empty
```

**Why run it?**

Before running any playbook, this confirms:
- Ansible picked up the right inventory file (`ansible.cfg` → `inventory = ./inventory/hosts`)
- Your host is in the right group
- No typo in the group name that would cause `hosts: postgresql` to silently skip everything

## `ansible postgresql -m ping`

```
[WARNING]: Platform linux on host localhost is using the discovered Python interpreter at
/usr/bin/python3.9, but future installation of another Python interpreter could change the
meaning of that path.
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}
```

**What each part means:**

```
localhost | SUCCESS          ← host name | connection result
                               SUCCESS = Ansible reached the host and got a response

"discovered_interpreter_python": "/usr/bin/python3.9"
                             ← Ansible found Python at this path automatically
                               Ansible modules run as Python scripts on the target host
                               so Python must exist — this confirms it does

"changed": false             ← ping never modifies anything on the host
                               false is the correct and expected value here

"ping": "pong"               ← the actual ping/pong handshake succeeded
```

**The WARNING — harmless:**

```
[WARNING]: Platform linux on host localhost is using the discovered Python interpreter
           at /usr/bin/python3.9
                │
                └── Ansible auto-detected Python because no explicit interpreter
                    was set in inventory/group_vars/postgresql.yml
                    Not an error — just Ansible saying "I guessed, and I succeeded"

To silence it permanently, pin the interpreter in group_vars/postgresql.yml:
    ansible_python_interpreter: /usr/bin/python3.9
```

**Why run it?**

`--graph` confirmed the host is in the right group.
`ping` confirms Ansible can actually **connect** to that host and **execute** on it.
These two together are the full pre-flight check before running any playbook.

## `ansible-playbook playbooks/postgresql_role.yml`

```
PLAY [Manage PostgreSQL roles] ***************************************

TASK [Create application role] ***************************************
localhost | ok => {
    "changed": false
}

PLAY RECAP ***********************************************************
localhost : ok=1    changed=0    unreachable=0    failed=0
```

**What each part means:**

```
PLAY [Manage PostgreSQL roles]
      │
      └── play name from the playbook — confirms the right playbook ran

TASK [Create application role]
      │
      └── task name — one task in this playbook

localhost | ok
      │       │
      │       └── ok = task ran successfully, no error
      └── the host it ran against

"changed": false
      │
      └── role already existed OR was just created
          if created for the first time → changed: true
          if role already existed       → changed: false  (idempotent — no duplicate)
```

**PLAY RECAP — read this first after every playbook run:**

```
localhost : ok=1    changed=0    unreachable=0    failed=0
             │         │              │               │
             │         │              │               └── failed tasks — must be 0
             │         │              └── hosts Ansible could not connect to — must be 0
             │         └── tasks that actually modified something
             └── tasks that ran without error (including no-change tasks)

ok=1, failed=0  → playbook succeeded
changed=0       → role already existed, nothing modified (idempotent re-run)
changed=1       → role was created for the first time
```

**What ran in PostgreSQL:**

```sql
CREATE ROLE paylite_app WITH LOGIN PASSWORD 'PayliteApp123!';
-- community.postgresql.postgresql_user with state: present
-- "user" in Ansible = role with LOGIN privilege in PostgreSQL
```

**The WARNING — harmless (same as ansible ping):**

```
[WARNING]: Platform linux on host localhost is using the discovered
           Python interpreter at /usr/bin/python3.9
      │
      └── Ansible auto-detected Python — not an error
          silence it by adding to group_vars/postgresql.yml:
          ansible_python_interpreter: /usr/bin/python3.9
```

## Liquibase Tag & Rollback — Full Cycle

---

### `liquibase tag v1.0`

```
Successfully tagged 'postgres@jdbc:postgresql://bt01-aurora-instance-1...:5432/postgres'
Liquibase command 'tag' was executed successfully.
```

```
tag v1.0
  |
  └── bookmarks the current state in DATABASECHANGELOG
      001 (create schema)  <- v1.0 tag written here
      002 (create table)   <- v1.0 tag written here (last applied row gets the tag)
```

---

### `liquibase update` — 003 failed first (typo), then succeeded

**First attempt — SQL typo:**
```
Running Changeset: changelog/003-add-column.sql::003::paylite

ERROR: syntax error at or near "tabe"
  Position: 7
[Failed SQL: (0) alter tabe paylite.employee add column salary2 int]
```

```
alter tabe paylite.employee ...
       ^^^^
       typo — should be "table"
       Liquibase sent the SQL to PostgreSQL, PostgreSQL rejected it
       changeset 003 is NOT recorded in DATABASECHANGELOG
       next liquibase update will retry 003 automatically
```

**Second attempt — typo fixed:**
```
Running Changeset: changelog/003-add-column.sql::003::paylite

UPDATE SUMMARY
Run:                          1
Total change sets:            3

Liquibase: Update has been successful.
```

```
Run:           1   <- 003 applied now
Previously run: 2  <- 001 and 002 already in DATABASECHANGELOG, skipped
Filtered out:   0  <- nothing excluded
Total:          3  <- master changelog has 3 includes
```

---

### `liquibase tag v2.0`

```
Successfully tagged 'postgres@jdbc:postgresql://...'
```

```
DATABASECHANGELOG state after v2.0 tag:

| Changeset | Tag  |
|-----------|------|
| 001       |      |
| 002       | v1.0 |  <- v1.0 written on last row at time of tagging
| 003       | v2.0 |  <- v2.0 written on last row at time of tagging
```

---

### `liquibase rollback --tag v1.0`

```
Rolling Back Changeset: changelog/003-add-column.sql::003::paylite
Liquibase command 'rollback' was executed successfully.
```

```
rollback --tag v1.0
  |
  └── find v1.0 in DATABASECHANGELOG
      roll back everything applied AFTER v1.0, in reverse order
      |
      └── 003 (add column)  -> runs: ALTER TABLE paylite.employee DROP COLUMN salary2
          002 and 001 untouched  <- they are AT or BEFORE v1.0

DATABASECHANGELOG after rollback:

| Changeset | Tag  |
|-----------|------|
| 001       |      |
| 002       | v1.0 |  <- still here, untouched

003 row removed — salary2 column dropped from paylite.employee
```

**Verify:**
```bash
liquibase history   # 003 row gone
liquibase status    # shows 1 changeset pending (003 ready to re-apply)
liquibase update    # re-applies 003 if needed
```

## `ansible-playbook playbooks/liquibase_deploy.yml` — Full Output

---

### Play 1 of 2 — Deploy

```
PLAY [Deploy database changes using Liquibase]
```

```
Two plays in one playbook file:
  Play 1  → always runs  (deploy)
  Play 2  → only runs with --tags rollback (rollback)
            but here it ran because the playbook has no when: guard on the play
```

---

#### TASK: Check Liquibase installation

```
ok: [localhost]
interpreter at /usr/bin/python3.9 ...
```

```
Warning = informational only, not an error.
Ansible found Python at /usr/bin/python3.9 automatically.
Nothing to fix — this fires once per play on every run.
```

---

#### TASK: Display Liquibase version

```
"Liquibase Version: 5.0.4"
"Java Home: /usr/lib/jvm/java-21-amazon-corretto.x86_64 (Version 21.0.12.1)"
```

```
Liquibase 5.0.4 running on Java 21 (Amazon Corretto)
JDBC driver: postgresql.jar 42.7.8

version check = confirms the tool exists before doing any database work
```

---

#### TASK: Validate Liquibase changelog

```
ok: [localhost]
stdout_lines: []
```

```
Empty stdout = clean validation
Liquibase parsed all three changelog files without errors
No missing files, no syntax problems, no unknown changesets
```

---

#### TASK: Check Liquibase status

```
"1 changeset has not been applied to postgres@jdbc:postgresql://..."
"     changelog/003-add-column.sql::003::paylite"
```

```
DATABASECHANGELOG state before this run:

  001  applied  (create schema)
  002  applied  (create table)   <- v1.0 tag is here
  003  PENDING  (add column)     <- status shows this one

status = diff between master changelog and DATABASECHANGELOG
```

---

#### TASK: Apply Liquibase changes

```
changed: [localhost]
```

```
UPDATE SUMMARY
Run:                          1   <- 003 applied now
Previously run:               2   <- 001 and 002 already recorded, skipped
Filtered out:                 0   <- nothing excluded
-------------------------------
Total change sets:            3   <- master changelog has 3 includes
```

```
"changed" = Ansible registered that something actually changed in the system
"ok"      = would mean nothing changed (all changesets already applied)
```

---

#### TASK: Tag the database state after successful deploy

```
changed: [localhost]
stdout_lines: []
```

```
liquibase tag v2.0  (as written in the playbook)

DATABASECHANGELOG after tag:
  001  |
  002  | v1.0
  003  | v2.0   <- tag written on the last applied row

Empty stdout = success. Liquibase only prints on error or with --log-level.
```

---

#### TASK: Verify PayLite employee table

```
"employee_table.query_result": [
    {
        "table_name": "employee",
        "table_schema": "paylite"
    }
]
```

FROM   information_schema.tables
WHERE  table_schema = 'paylite'
  AND  table_name   = 'employee';

1 row returned -> table exists -> deploy confirmed
```

---

### Play 2 of 2 — Rollback

```
PLAY [Rollback database changes using Liquibase]
```

---

#### TASK: Check current Liquibase status before rollback

```
"postgres@jdbc:postgresql://...is up to date"
```

```
```

---

#### TASK: Rollback to tag v1.0

```
changed: [localhost]
stdout_lines: []
```

```
liquibase rollback --tag v1.0

What Liquibase did:
  Find v1.0 in DATABASECHANGELOG
  Identify every changeset applied AFTER v1.0
  Roll them back in REVERSE order

  003 (add column)  -> runs: ALTER TABLE paylite.employee DROP COLUMN salary2
  002 untouched     <- 002 IS v1.0, not after it
  001 untouched

DATABASECHANGELOG after rollback:
  001  |
  002  | v1.0   <- last row. 003 row removed.
```

---

#### TASK: Verify employee table is gone after rollback

```
"msg": "WARNING — table still exists after rollback, investigate"
```

```
This warning fired because the playbook verification checks:
  "is the employee table gone?"

But rollback to v1.0 only undid changeset 003 (add column).
Changeset 002 (CREATE TABLE) is AT v1.0, not after it — so the table
still exists. That is CORRECT behaviour.

The verify task is checking the wrong thing.
What it should check instead:
  SELECT column_name FROM information_schema.columns
  WHERE  table_schema = 'paylite'
    AND  table_name   = 'employee'
    AND  column_name  = 'salary2';

  0 rows = rollback succeeded (salary2 column dropped)
```

---

### PLAY RECAP

```
localhost : ok=18  changed=3  unreachable=0  failed=0  skipped=0
```

```
ok=18      -> 18 tasks ran and passed
changed=3  -> 3 tasks actually changed state:
               1. liquibase update  (applied 003)
               2. liquibase tag     (wrote v2.0)
               3. liquibase rollback (dropped salary2 column)
failed=0   -> clean run end to end
```

---

### Key Takeaway — rollback scope

```
rollback --tag v1.0
    |
    +-- undoes: everything AFTER v1.0
    +-- keeps:  everything AT or BEFORE v1.0

v1.0 was tagged after 001 + 002.
So 001 (schema) and 002 (table) survive the rollback.
Only 003 (add column salary2) was undone.

To remove the table you would need to rollback past v1.0 — to a point
before 002 was applied — using rollbackCount or a tag set before 002.
```

## Jenkins Build — `ansible-playbook playbooks/liquibase_deploy.yml`

---

### Jenkins Header

```
Started by user admin
Running as SYSTEM
Building in workspace /var/lib/jenkins/workspace/create jon
```

```
Started by user admin   -> admin clicked "Build Now" in Jenkins UI
Running as SYSTEM       -> Jenkins daemon user on the Linux host
Workspace               -> /var/lib/jenkins/workspace/create jon
                           Jenkins creates one workspace folder per job
```

```
Jenkins build flow:
  admin clicks Build Now
       |
       v
  Jenkins SYSTEM user
       |
       v
  /bin/sh -xe /tmp/jenkins887866345099254812.sh   <- generated temp script
       |
       +-- cd /opt/devops-for-pg-master           <- your repo location
       +-- ansible-playbook playbooks/liquibase_deploy.yml
```

```
/bin/sh flags:
  -x  -> echo every command before running it (visible in build log)
  -e  -> exit immediately if any command returns non-zero
         this is why Jenkins marks the build FAILED on first error
```

---

### Shell Commands Logged

```
+ cd /opt/devops-for-pg-master
+ ansible-playbook playbooks/liquibase_deploy.yml
```

```
The + prefix = -x flag printing each command before execution
Two commands Jenkins ran:
  1. cd to the repo directory
  2. run the playbook
```

---

### Play 1 — Deploy

Same execution as manual run. Key results:

```
TASK: Validate    -> ok      (changelog syntax clean)
TASK: Status      -> 003 pending
TASK: Update      -> changed (003 applied, Run: 1)
TASK: Tag         -> changed (v2.0 written to DATABASECHANGELOG)
TASK: Verify      -> employee table present
```

```
changed: [localhost] means Ansible detected a real state change
ok:      [localhost] means state already matched — nothing to do
```

---

### Play 2 — Rollback

```
TASK: Status before rollback  -> "is up to date"  (all 3 applied)
TASK: Rollback to v1.0        -> changed
TASK: Verify table gone       -> WARNING — table still exists
```

```
WARNING is expected — this is correct rollback behaviour.

Rollback to v1.0 timeline:
  001 create schema  ]
  002 create table   ] <- v1.0 tag  (these survive rollback)
  003 add column     ]              (this gets undone: DROP COLUMN salary2)

The employee table still exists because it was created by 002,
which is AT v1.0 — not after it.

The playbook verify task checks "is table gone?" which is the wrong
question for a column-level rollback. The correct check is:
  SELECT column_name FROM information_schema.columns
  WHERE  table_schema = 'paylite'
    AND  table_name   = 'employee'
    AND  column_name  = 'salary2';
  -- 0 rows = rollback succeeded
```

---

### PLAY RECAP

```
localhost : ok=18  changed=3  unreachable=0  failed=0  skipped=0
```

```
ok=18      -> 18 tasks completed
changed=3  -> update + tag + rollback
failed=0   -> no task returned a non-zero exit code
```

---

### Jenkins Footer

```
Finished: SUCCESS
```

```
Jenkins build statuses:
  SUCCESS  -> all shell commands exited 0
  FAILURE  -> a command exited non-zero (because of -e flag)
  UNSTABLE -> tests ran but some failed (not applicable here)
  ABORTED  -> user cancelled mid-run

"Finished: SUCCESS" here means:
  ansible-playbook returned exit code 0
  Jenkins recorded the build as green
```

---

### Manual vs Jenkins — What Changed

```
Manual run:
  cd /opt/devops-for-pg-master
  ansible-playbook playbooks/liquibase_deploy.yml

Jenkins run:
  /bin/sh -xe <temp-script>
    cd /opt/devops-for-pg-master
    ansible-playbook playbooks/liquibase_deploy.yml

Result:   identical — same playbook, same Aurora endpoint, same output
Benefit:  Jenkins gives you a build history, timestamps, and logs
          you can trigger this from a git push (pipeline trigger)
          without SSH-ing into the server
```

