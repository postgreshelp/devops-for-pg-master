# DevOps for PostgreSQL DBA — Master Lab

**PostgresHelp Labs**

> For concept explanations, mental models, and expected outputs — see the `documentation/` folder.

---

## The Pipeline

```
Git commit
    │
    ▼
Jenkins  (orchestrates all stages)
    │
    ├──────────────────────────────────────┐──────────────────────────────────────┐
    ▼                                      ▼                                      ▼
Terraform                              Ansible                               Liquibase
Provision AWS infra                    Configure PostgreSQL                   Deploy schema
VPC · Subnets · Aurora                 Roles · Grants · Maintenance           Schema · Tables
    │                                      │                                      │
    └──────────────────────────────────────┴──────────────────────────────────────┘
                                           │
                                           ▼
                                     Running System
                                           │
                                           ▼
                                       Grafana
                                   Monitor · Alert
                                     (read-only)
```

---

## Clone to Your Local Machine

```bash
git clone https://github.com/postgreshelp/devops-for-pg-master.git
cd devops-for-pg-master
```

---

## Commands

### Git

```bash
git init
git config user.name "your-name"
git config user.email "your-email"
git remote add origin https://github.com/postgreshelp/devops-for-pg-master.git
git add .
git status
git commit -m "your message"
git branch -M master
git push -u origin master
git pull
```

---

### Terraform

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply
terraform import aws_vpc.default_import <vpc-id>
terraform -version
```

---

### AWS CLI

```bash
aws --version
aws configure
aws sts get-caller-identity
aws ec2 describe-vpcs --vpc-ids <vpc-id>
```

---

### Ansible

```bash
ansible --version
ansible-galaxy collection install community.postgresql
ansible-galaxy collection list
ansible-inventory --graph
ansible postgresql -m ping
ansible-playbook playbooks/postgresql_admin.yml --syntax-check
ansible-playbook playbooks/postgresql_admin.yml
ansible-playbook playbooks/postgresql_admin_full.yml
ansible-playbook playbooks/postgresql_role.yml
ansible-playbook playbooks/liquibase_deploy.yml
ansible-playbook playbooks/liquibase_deploy.yml --tags rollback
```

---

### Liquibase

```bash
cd liquibase
liquibase --version
liquibase validate
liquibase status
liquibase update
liquibase tag v1.0
liquibase rollback v1.0
liquibase rollbackCount 2
```

---

### PostgreSQL / psql

```bash
psql --version
psql -h mypgrds.cijxwe4ckz1m.us-east-1.rds.amazonaws.com -U postgres -d postgres
```

```sql
SELECT version();
SELECT current_database();
\du
\dn
\dt paylite.*
```

---

## Project Structure

```
.
├── ansible.cfg                          # Ansible project config
├── inventory/
│   ├── hosts                            # Host groups
│   └── group_vars/
│       └── postgresql.yml              # DB connection variables
├── playbooks/
│   ├── postgresql_admin.yml            # Starter — version + current db
│   ├── postgresql_admin_full.yml       # Full DBA operations (9 tasks)
│   ├── postgresql_role.yml             # Role creation
│   └── liquibase_deploy.yml           # Deploy + rollback via Liquibase
├── liquibase/
│   ├── liquibase.properties            # Liquibase connection config
│   ├── db.changelog-master.yaml        # Master changelog
│   └── changelog/
│       ├── 001-create-schema.sql       # changeset paylite:001
│       └── 002-create-table.sql        # changeset paylite:002
├── providers.tf                         # AWS provider config
├── data.tf                              # Read default VPC
├── outputs.tf                           # Output VPC IDs
├── aws-create-vpc.tf                    # Create bt01_vpc
├── aws-networking.tf                    # IGW · subnets · route table
├── aws-aurora.tf                        # Aurora cluster + instance
├── aws-default-import.tf               # Import existing VPC exercise
├── documentation/                       # Full concept docs — read before labs
│   ├── 00-index.md
│   ├── 01-terraform-vpc-aurora-reference.md
│   ├── 02-08-windows-setup-guide.md
│   ├── 09-12-liquibase-ansible-verify.md
│   ├── 13-theory-manual-toolchain.md
│   └── 14-command-cheatsheet.md
└── README.md
```

---

*PostgresHelp Labs · Build. Operate. Automate. Grow.*
