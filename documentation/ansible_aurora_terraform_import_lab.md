# Ansible + Aurora PostgreSQL + Terraform Import Lab

## 1. Fix AI-generated Ansible YAML indentation

```bash
sed -i 's/\t/  /g' playbooks/create_table.yml
sed -i 's/\t/  /g' playbooks/create_replica.yml
```

## 2. Create `emp` table with Ansible

Final `playbooks/create_table.yml`:

```yaml
---
- name: Create emp table on Aurora PostgreSQL
  hosts: localhost
  gather_facts: false
  collections:
    - community.postgresql

  vars:
    db_host: bt01-aurora.cluster-cijxwe4ckz1m.us-east-1.rds.amazonaws.com
    db_name: postgres
    db_user: postgres
    db_password: "{{ postgresql_admin_password }}"

  tasks:
    - name: Create emp table
      community.postgresql.postgresql_query:
        login_host: "{{ db_host }}"
        login_db: "{{ db_name }}"
        login_user: "{{ db_user }}"
        login_password: "{{ db_password }}"
        query: |
          CREATE TABLE IF NOT EXISTS emp (
            id INT,
            sal INT
          );
```

### Debugging change

The AI-generated playbook originally used:

```yaml
db_password: "{{ lookup('env', 'PGPASSWORD') }}"
```

`PGPASSWORD` was empty, causing:

```text
fe_sendauth: no password supplied
```

The password source was changed to:

```yaml
db_password: "{{ postgresql_admin_password }}"
```

No other change was made to the playbook.

## 3. Install AWS Ansible collection

```bash
ansible-galaxy collection install amazon.aws
```

## 4. Install the Python AWS SDK

```bash
dnf install python3-pip -y
pip3 install boto3
```

Verify:

```bash
python3 -c "import boto3, botocore; print('boto3', boto3.__version__); print('botocore', botocore.__version__)"
```

## 5. Terraform resource for the Aurora reader

```hcl
resource "aws_rds_cluster_instance" "reader" {
  identifier         = "bt01-aurora-reader-1"
  cluster_identifier = "bt01-aurora"
  instance_class     = "db.t4g.medium"
  engine             = "aurora-postgresql"
}
```

## 6. Import the existing reader into Terraform

```bash
terraform import aws_rds_cluster_instance.reader bt01-aurora-reader-1
```

This associates the existing AWS resource with:

```text
aws_rds_cluster_instance.reader
```

in Terraform state.

## 7. Verify

```bash
terraform state list
```

Then:

```bash
terraform plan
```

Before import, Terraform treated the reader as something it needed to create:

```text
# aws_rds_cluster_instance.reader will be created
+ resource "aws_rds_cluster_instance" "reader"
```

After import, the existing reader is represented in Terraform state.

## 8. Deregister from Terraform state

For classroom cleanup:

```bash
terraform state rm aws_rds_cluster_instance.reader
```

This removes the resource from **Terraform state only**. It does **not** delete the Aurora reader from AWS.

Do not use:

```bash
terraform destroy
```

for this cleanup demonstration.

## 9. Complete flow

```text
AI-generated Ansible playbook
        ↓
Fix YAML indentation
        ↓
Ansible creates PostgreSQL table
        ↓
Install amazon.aws + boto3
        ↓
Ansible AWS/RDS automation
        ↓
Aurora reader exists in AWS
        ↓
terraform import
        ↓
Terraform state
        ↓
terraform plan
        ↓
terraform state rm
        ↓
Reader remains in AWS
```
