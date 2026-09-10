# Jenkins + GitHub + Ansible + Liquibase

## Objective

Create a simple Jenkins job that:

```text
GitHub
   ↓
Jenkins checks out repository
   ↓
Jenkins workspace
   ↓
Ansible playbook
   ↓
Liquibase
   ↓
PostgreSQL
```

The repository is public, so no GitHub credentials are required for checkout.

---

# 1. Prerequisites

The Jenkins server must have access to:

- Git
- Ansible
- Liquibase
- PostgreSQL connectivity

The project repository used in this lab is:

```text
https://github.com/postgreshelp/devops-for-pg-master.git
```

The repository branch used in this exercise is:

```text
master
```

The playbook executed by Jenkins is:

```text
playbooks/liquibase_deploy.yml
```

---

# 2. Create a Jenkins Freestyle Job

Open Jenkins.

Select:

```text
New Item
```

Enter the job name:

```text
paylite-liquibase-deploy
```

Select:

```text
Freestyle project
```

Click:

```text
OK
```

---

# 3. Configure GitHub Source Code Management

Open the job configuration.

Find:

```text
Source Code Management
```

Select:

```text
Git
```

## Repository URL

Enter:

```text
https://github.com/postgreshelp/devops-for-pg-master.git
```

## Credentials

Leave credentials as:

```text
- none -
```

The repository is public.

## Branch

Under the branch specification, enter:

```text
*/master
```

The configuration is therefore:

```text
Source Code Management
    Git

    Repository URL:
    https://github.com/postgreshelp/devops-for-pg-master.git

    Credentials:
    none

    Branch Specifier:
    */master
```

---

# 4. Why We Use Jenkins Workspace

Do NOT add:

```bash
cd /opt/devops-for-pg-master
```

Jenkins automatically checks out the Git repository into the Jenkins workspace.

For this job, the workspace will look similar to:

```text
/var/lib/jenkins/workspace/paylite-liquibase-deploy
```

After Git checkout, the repository files are available there:

```text
/var/lib/jenkins/workspace/paylite-liquibase-deploy/
├── ansible.cfg
├── inventory/
├── playbooks/
├── terraform/
└── ...
```

Therefore Jenkins can directly execute:

```bash
ansible-playbook playbooks/liquibase_deploy.yml
```

---

# 5. Add the Build Step

Scroll to:

```text
Build Steps
```

Select:

```text
Add build step
```

Choose:

```text
Execute shell
```

Enter:

```bash
ansible-playbook playbooks/liquibase_deploy.yml
```

Do not add:

```bash
cd /opt/devops-for-pg-master
```

Jenkins is already executing the build from its workspace.

---

# 6. Save the Job

Click:

```text
Save
```

Then select:

```text
Build Now
```

---

# 7. What Jenkins Does

When the job starts, Jenkins first checks out the configured Git repository.

The console output should contain steps similar to:

```text
Fetching changes from the remote Git repository
```

Then:

```text
Checking out Revision <commit>
```

Then Jenkins runs the build step:

```text
+ ansible-playbook playbooks/liquibase_deploy.yml
```

The complete flow is:

```text
GitHub
  │
  │ checkout
  ▼
Jenkins Workspace
  │
  │ ansible-playbook
  ▼
playbooks/liquibase_deploy.yml
  │
  ▼
Liquibase
  │
  ▼
PostgreSQL
```

---

# 8. Example Successful Git Checkout

A successful checkout looks similar to:

```text
Fetching changes from the remote Git repository
Fetching upstream changes from
https://github.com/postgreshelp/devops-for-pg-master.git

Checking out Revision 6a027317...
```

This confirms that Jenkins is getting the code directly from GitHub.

---

# 9. Example Successful Ansible Execution

Jenkins then executes:

```bash
ansible-playbook playbooks/liquibase_deploy.yml
```

The playbook can perform tasks such as:

```text
Check Liquibase installation
Display Liquibase version
Validate Liquibase changelog
Deploy database changes
```

The exact tasks depend on the current `liquibase_deploy.yml` in the repository.

---

# 10. Important Jenkins Concept

The Jenkins job does not depend on a manually cloned copy of the repository.

Instead:

```text
Developer
    │
    │ git push
    ▼
GitHub
    │
    │ checkout
    ▼
Jenkins
    │
    ▼
Jenkins workspace
    │
    ▼
Ansible
```

This means Jenkins always starts with the version of the repository that it checks out for that build.

---

# 11. Troubleshooting

## Git checkout fails

Check:

```text
Repository URL
Branch Specifier
Network connectivity
```

For this public repository, credentials are normally not required.

---

## Ansible command not found

If Jenkins reports:

```text
ansible-playbook: command not found
```

Ansible is not available in the environment used by Jenkins.

Check on the Jenkins server:

```bash
which ansible-playbook
```

and:

```bash
ansible-playbook --version
```

---

## Liquibase command not found

If the Ansible playbook reports that Liquibase cannot be executed, check:

```bash
which liquibase
```

and:

```bash
liquibase --version
```

---

## PostgreSQL connection failure

If Liquibase reports a PostgreSQL connection error, check the database hostname, port, database name, username, password, and network connectivity.

For example, an incorrect RDS hostname can produce:

```text
UnknownHostException
```

This means the hostname could not be resolved and the failure occurs before Liquibase can connect to PostgreSQL.

---

# 12. First Jenkins Job — Minimal Configuration

For this first job, the important configuration is only:

## Source Code Management

```text
Git

Repository:
https://github.com/postgreshelp/devops-for-pg-master.git

Branch:
*/master

Credentials:
none
```

## Build Step

```bash
ansible-playbook playbooks/liquibase_deploy.yml
```

That's it.

---

# 13. Final Flow

```text
                  GitHub
                    │
                    │ git checkout
                    ▼
              Jenkins Job
                    │
                    ▼
          Jenkins Workspace
                    │
                    │ Execute shell
                    ▼
        ansible-playbook
        playbooks/liquibase_deploy.yml
                    │
                    ▼
                Liquibase
                    │
                    ▼
              PostgreSQL
```

This is the first simple Jenkins implementation before introducing more advanced Jenkins automation such as pipelines or a `Jenkinsfile`.
