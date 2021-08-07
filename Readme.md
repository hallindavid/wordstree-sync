
# WordsTree Sync

## Usage

```shell
sh wtsync.sh {action} {document_id} {file}"
```

> **Important**:
> 1. ensure `~/.wordstree exists`
> 2. ensure token is a line

## Start

First, you need a token. For that, you can run:

```shell
sh wtsync.sh
```

That will create `~/.wordstree` and prompt for you to add your credentials.

### Open file for presentation

> Still ugly

```shell
sh wtsync.sh pull {document-id} --show
```

### Download document as pure markdown content

```shell
sh wtsync.sh pull {document-id} {file}
```

### Download document as JSON

```shell
sh wtsync.sh pull {document-id} {file} --markdown
```

## TODO

- check that we have 3 parameters
- check that we have a valid file location
- ensure valid token & auth check
- if not, then ask for email & password
- ensure valid document id
