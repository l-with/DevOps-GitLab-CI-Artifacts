# gitlab-ci.yml

GitLab CI templates and snippets

## trivy

The CI snippet is an adapted `Trivy.gitlab-ci.yml` from section "GitLab CI using Trivy container" on https://aquasecurity.github.io/trivy/v0.22.0/advanced/integrations/gitlab-ci/.

The HTML template `html.tpl` is copied from https://github.com/aquasecurity/trivy/blob/main/contrib/html.tpl.

The report is placed in `$CI_PROJECT_DIR/.trivy/gl-container-scanning-report.html`.

The full image name has to be placed in `$FULL_IMAGE_NAME`.

The exit code on critcal severity can overidden by TRIVY_EXIT_CODE_CRITICAL.
