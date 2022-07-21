# Installation

## Prerequisties

* Clone this repo.  This doc will assume you've cloned it to `${HOME}/dev/zxcv`.
* Bash or Zsh.  Preferably Zsh, but you decide.  Something marginally recent.
* Install [asdf](https://asdf-vm.com/guide/getting-started.html), curl, [fzf](https://github.com/junegunn/fzf) and [jq >= 1.6](https://stedolan.github.io/jq/download/).
  * Install the asdf Terraform plugin - `asdf plugin add terraform`

## Configuration

* Create `${HOME}/.config/zxcv/zxcv.cfg` with this content --
    ```
    t.hostname=app.terraform.io  # The hostname of your TFC/TFE server.
    t.organization=myorg         # The default TFC/TFE org to use.
    ```
  Pick whatever directory you like.  By convention, on Linux/Mac it would be in `${HOME}/.config/zxcv`, but it can be anywhere.  This directory will become the value if `$ZXCV_CFGDIR` below.

* Make sure you have a TFC/TFE API token set locally.  IOW... do a `terraform login`.  The token will be stored in `${HOME}/.terraformrc` (older Terraform versions) or `${HOME}/.terraform.d/credentials.tfrc.json` (newer Terraform versions).  It doesn't matter at all which file is used.  We'll always first use the latter, even if an older Terraform CLI is being used.
  * :bangbang: Note that there's a potential chicken-n-egg situation here.  You can't do a `terraform login` unless a proper CLI is first installed, which might not be the case.  If you don't yet have it installed, you can login to TFC/TFE and go to `User Settings / Tokens / Create API Token` and then create a `${HOME}/.terraform.d/credentials.tfrc.json` file with this content --

    ```
    {
      "credentials": {
        "<insert-tfc/tfe-hostname-here>": {
          "token": "<insert-token-text-here>"
        }
      }
    }
    ```

    For example --

    ```
    {
      "credentials": {
        "app.terraform.io": {
          "token": "yQltSuG3Ehtp2g.atlasv1.lhEXASnbwJNA2UKiFvhOqfdExZAKPXjKIcyUffvsnduQiaEBZ3C9Bf7onoEZAg0w"
        }
      }
    }
    ```

* Edit your shell config.  In the simplest form...
  * Edit `${HOME}/.zshrc` (or `${HOME}/.bashrc`) and include these lines near the top...
      ```
      # Change ${HOME}/dev if you cloned someplace else.
      export REPO_BASEDIR="${HOME}/dev"
      export ZXCV_BASEDIR="${REPO_BASEDIR}/zxcv"
      # Change to the directory where you created `zxcv.cfg` above.
      export ZXCV_CFGDIR="${HOME}/.config/zxcv"
      for f in ${ZXCV_BASEDIR}/misc/*.sh; do [[ -f "$f" ]] && . "$f"; done
      sall ${ZXCV_BASEDIR}/zxcv
      ```
  * There are plenty of better ways to configure your shell.  This is the simplest.

* Restart your shell.

DONE!  You can now run `t cfg-check` and see if you have any **E**rrors or **W**arnings.

# Usage

There are three basic pieces of functionality provided -
  1. Terraform CLI version management (not too different than tfenv or plenty of other tools, including 'naked' asdf)
  2. Terraform CLI extensions to add functionality not found in the `terraform` CLI.
  3. API Query Wrappers - oq, mq, sq, sv, wq, etc.  To provide convenience commands to query the TFC/TFE API.

It's important to recognize that, in addition to the functionality described here, `t` is simply a pass-through for "regular" `terraform` CLI commands.  *ANY* command that you would typically use `terraform` for, can be run from `t` simply be replacing `terraform` with `t`.  If you would normally run `terraform apply --auto-approve`, you can simply run `t apply --auto-approve` and achieve the *EXACT* same results.  *ALL* `terraform` CLI syntax is supported.

## Terraform CLI Version Management

Naked `t` will give you a list of version management commands that can be run.  Primarily several variations of `t switch` which is roughly inline with tfenv.  `t prune` cleans unused versions from the `asdf` shim cache.  `t local` provides `asdf` local functionality.  If you're new to `asdf` or the shell, note that `t switch ...` is shell session specific.  If you have two shells open, doing a `t switch ...` in one will have no impact on the other.  You can also set a "machine default" version by using the [asdf global](https://asdf-vm.com/guide/getting-started.html#global) feature.

## Terraform CLI Extensions

Currently the only ready extension is `t kill`.  This must be run from a TF project root directory and will provide a UI to enable you to selectively delete (with our without confirmation) resources from the current state.

More to come...

## Terraform API Query Wrappers

The idea behind these commands is to provide CLI-based convenience functionality to easily query TFC/TFE.  Including the ability to pipe the results into other commands (normal Linuxy stuff).

The query commands follow the same pattern.  There is a standard set of syntax that can be applied to any command.  The list of fields that can be queried vary by command and are, unfortunately, not documented clearly by Hashicorp.  My best advice is to look at the [API docs](https://www.terraform.io/cloud-docs/api-docs) or at the specific API Response Schema links below.  Anything included in the JSON `attributes` object can be included as a field in the query result set.

## Common syntax

`t cmd [--title|--json] [--org orgname] [--sort sortspec] [field-list] `

`cmd` - one of `mq`, `oq`, `sq`, `sv` or `wq`.

`org orgname` - query resources in the specified orgname.  Defaults to either the organization specified in `${HOME}/.config/zxcv/zxcv.cfg` or the organization defined in the current workspace state, if it exists.

`--title|--json` - optional and mutually exclusive.  `--title` - include a column title in text-output mode (the default).  `--json` - the output is valid JSON.

`--sort sortspec` - optionally sort by the comma-seperated list of fields.

`--help` - brief, command-specific help, including a list of common fields to include in the query results.

The command line arguments can appear in any order other than `cmd`, which must be the first argument.  Examples --

| Command | Description |
| --- | --- |
| `t sq` | naked state query that produces identical results to `terraform state list` |
| `t sq id arn --sort arn` | state query that additionally includes the `id` and `arn` fields and with the text output sorted by `arn`, ascending. |
| `t oq --json name email created-at` | organization query output in JSON format. |
| `t mq --title --org myorg created-at email` | module query for the `myorg` organization with column titles in the text output. |
| `t wq --json --sort -id` | workspace query sorted by `id`, descending and output in JSON format. |

:bangbang:
The schema found in the `attributes` object of the API response is specific to each query type.  Further, some queries (eg. `sq`) will return a custom `attributes` schema for each resource instance type.  For example, the schema returned by an `aws_s3_bucket` instance is markedly different than the schema returned by an `aws_vpc` instance.

:bangbang:
The `attributes` object can, itself, contain objects.  As an example, AWS resources include an `attributes.tags_all` object.  If that object is included in a query field list (eg. `t sq --title tags_all`) the result might be --

| resource | tags_all |
| --- | --- |
| `aws_cloudtrail.trail` | `{"env":"prod","iac_framework":"ngtf","iac_provider":"aws","stack":"core"}` |
| `aws_vpc.es` | `{"Name":"prod-core","env":"prod","iac_framework":"ngtf","iac_provider":"aws","stack":"core"}` |

In other words, in text output mode the object is returned as JSON.  This same query in JSON output mode (`t sq --json tags_all`) would produce --
```
[
  {
    "resource": "aws_cloudtrail.trail",
    "tags_all": {
      "env":"prod",
      "iac_framework":"ngtf",
      "iac_provider":"aws",
      "stack":"core"
    }
  },
  {
    "resource": "aws_vpc.es",
    "tags_all": {
      "Name":"prod-core",
      "env":"prod",
      "iac_framework":"ngtf",
      "iac_provider":"aws",
      "stack":"core"
    }
  },

]
```

Further, you can report on specific attributes in an object.  The output of `t sq tags_all.name tags_all.iac_framework` might be --

| resource | name | iac_framework |
| --- | --- | --- |
| `aws_cloudtrail.trail` | `-` | `ngtf` |
| `aws_vpc.es` | `prod-core` | `ngtf` |

## Parameter Sets

Common queries options can be stored in a Parameter Set file.  By defaut, these files are stored in `$ZXCV_CFGDIR`.  A different default location can be used by setting `$ZXCV_PSDIR` or explicitly specifying an explicit file on the command line.

Parameter sets save you from having to remember re-type long command lines.  For example --

Instead of having to remember and type --

`t wq --json --dump --all --sort -resource-count,-updated-at org created-at updated-at terraform-version resource-count`

you can store these options in a file (ie. `${ZXCV_PSDIR}/wqda.ps`) like so --

```
--json --dump --all
--sort -resource-count,-updated-at
org created-at updated-at terraform-version resource-count
```

and then execute it with --

```
t wq @wqda.ps
```

Parameters from the set are inserted *exactly* in the sequence they are found in the command line.  For example, in the above, if you wanted to use all the parameters specified in the set *except* you wanted the output in text instead of JSON, you can override the `--json` parameter simply by --

```
t wq @wqda.ps --title
```

This will produce the command line --

`t wq --json --dump --all --sort -resource-count,-updated-at org created-at updated-at terraform-version resource-count --title`

with the `--json` at the beginning (from the Parameter Set) being overridden by the `--title` at the end.

## Queries

### _mq - Module Query_
Query the modules in the organization's registry.  This query does not offer any additional options beyond the Common Syntax described above.  Cross-organization searching (similar to --dump in wq) is not yet supported.

[API Response Schema](https://www.terraform.io/cloud-docs/api-docs/private-registry/modules#sample-response)

Common fields to include in a mq query are: `name`, `provider`, `updated-at` and `version-statuses`.

### _oq - Organization Query_
Query the organizations defined in TFC/TFE.  This query does not offer any additional options beyond the Common Syntax described above.

[API Response Schema](https://www.terraform.io/cloud-docs/api-docs/organizations#sample-response)

Common fields to include in an oq query are: `email` and `created-at`.

### _pq - Provider Query_
Query the providers in the organization's registry.  This query does not offer any additional options beyond the Common Syntax described above.  Cross-organization searching (similar to --dump in wq) is not yet supported.

[API Response Schema](https://www.terraform.io/cloud-docs/api-docs/private-registry/providers#sample-response)

Common fields to include in a pq query are: `name`, `created-at` and `updated-at`.

### _sq - State Query_
Query the most recent state for the workpace active in the current working directory, which must be a Terraform project root.  A naked query (ie. `t sq`) will produce identical result to `terraform state list`.

Unfortunately, the state API Response Schema is not well documented by Hashicorp.  The state can be found by hitting a "Hosted State Download" URL.  Any field found in `.Instances[].attributes` can be included in a sq query.  Also note that the scheme for each `attribute` block will be different for each resource type represented.

Common fields to include in a sq query are: `arn`, `id`, `tags` and `tags_all`.

### _wq - Workspace Query_

`t wq terraform-version resource-count`

`# This will take a minute and dump all workspaces in all orgs.`

`t wq --dump --all --progress terraform-version resource-count created-at updated-at`

`t wq --json vcs-repo working-directory`

[API Response Schema](https://www.terraform.io/cloud-docs/api-docs/workspaces#sample-response)
