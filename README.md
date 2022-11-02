# Krokit: Tool to setup OpenGrok source code search engine

## Usage:
### `krokit [options]... /path/to/project/source`

Krokit makes it easy to setup OpenGrok source code search engine.

## Command line options:
```
    -a  --add    <project-path>      -- Generate index and add project to opengrok
    -d  --deploy <opengrok-package>  -- Deploy Opengrok before adding projects
    -r  --delete <project-name>      -- Delete project from Opengrok indexing
    -i  --init                       -- Initial setup to download and install dependencies
    -V  --verbose                    -- Enable verbose mode
    -v  --version                    -- Print Krokit version
    -h  --help                       -- Show this help menu
```

### Requirements:
	 OpenGrok <= 1.5.12, OpenJRE-8 and Tomcat-9 servelet

### Initial setup:
Initialize setup with `--init` option before deploying your projects.

