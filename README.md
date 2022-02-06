# gitlab-ci.yml

GitLab CI templates and snippets

## trivy

The CI snippet is an adapted `Trivy.gitlab-ci.yml` from section "GitLab CI using Trivy container" on https://aquasecurity.github.io/trivy/v0.22.0/advanced/integrations/gitlab-ci/.

The HTML and the JSON templates are copied from https://github.com/aquasecurity/trivy/blob/main/contrib/.

The reports are placed in `$CI_PROJECT_DIR/.trivy-reports`.

The full image name has to be placed in `$FULL_IMAGE_NAME`.

The jobs are assigned to stage `scan`.

## vault

The CI snippet puts the shell script `vault_secrets.sh` into artifacts.

The job is assigned to stage `vault_secrets_sh`.

The shell script `vault_secrets.sh` interpretes a yaml file describing vault secrets, for instance:

```yaml
secrets:
  - VAULT_AUTH_ROLE: terraform
    SSH_PRIVATE_KEY:
      vault: ssh/ssh_private_key@gitlab
    TF_VAR_ssh_key_name:
      vault: ssh/ssh_key_name@gitlab
    DNS_API_TOKEN:
      vault: dns/dns_api_token@gitlab
  - VAULT_AUTH_ROLE: application
    APPLICATION_REGISTRY_AUTH:
      vault: applications/registry_auth@gitlab
    TEST_LONG_PATH:
      vault: applications/subfolder/test_long_path@gitlab    
```

There are two usages:

```bash
./vault_secrets vault-yml | sh
```

shows the commands produced by `vault_secrets.sh`.

```bash
./vault_secrets vault-yml | sh | sh
```

executes the commands produced by `vault_secrets.sh`.

You have to set `VAULT_ADDR` and possibly `VAULT_CACERT` for using `vault_secrets.sh`.
