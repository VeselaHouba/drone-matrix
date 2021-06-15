def main(ctx):
  return [
    step_lint(),
    step_hetzner("debian-10"),
    step_hetzner("ubuntu-18.04"),
    step_hetzner("ubuntu-20.04")
  ]

def step_lint():
  return {
    "kind": "pipeline",
    "name": "linter",
    "steps": [
      {
        "name": "Lint",
        "image": "veselahouba/molecule",
        "commands": [
          "shellcheck_wrapper",
          "flake8",
          "yamllint .",
          "ansible-lint"
        ]
      }
    ]
  }

def step_hetzner(os):
  return {
    "kind": "pipeline",
    "depends_on": [
        "linter",
    ],
    "name": "molecule-%s" % os,
    "steps": [
      {
        "name": "Lint",
        "image": "veselahouba/molecule",
        "commands": [
          "shellcheck_wrapper",
          "flake8",
          "yamllint .",
          "ansible-lint"
        ]
      },
      {
        "name": "Molecule test",
        "image": "veselahouba/molecule",
        "environment": {
          "HCLOUD_TOKEN": {
            "from_secret": "HCLOUD_TOKEN"
          }
        },
        "commands": [
          "ansible --version",
          "molecule --version",
          "REF=$$(echo $DRONE_COMMIT_REF | awk -F'/' '{print $$3}'|sed 's/_/-/g')",
          "REPO_NAME=$$(echo $DRONE_REPO_NAME | sed 's/_/-/g')",
          "MOLECULE_IMAGE=%s" % os,
          "export MOLECULE_IMAGE REPO_NAME REF",
          "molecule test --all"
        ]
      }
    ]
  }
