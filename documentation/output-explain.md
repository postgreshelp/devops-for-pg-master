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
