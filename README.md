pasta
=====

Simple SSH pastebin client.

The script writes content recieved via stdin to a pre-configured location via
SSH.

## Usage

On first run, the script will create the config file `~/.config/pastarc` and
do a guided configuration of the script.

### Examples

```
    $ xclip -o | pasta filename
    $ pasta -p -x filename.png
```


## References

Inspiration: https://codemadness.org/paste-service.html

