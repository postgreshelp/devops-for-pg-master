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
