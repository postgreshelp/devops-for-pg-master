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
