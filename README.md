pasta
=====

Simple SSH pastebin client.

The script writes content recieved via stdin to a pre-configured location via
SSH.

## Usage

On first run, the script will create the config file `~/.config/pastarc` and
do a guided configuration of the script.

### Examples

```console
$ xclip -selection c -o | pasta filename # upload your clipboard
$ pasta -xp filename.png # take a screenshot with import(1) and upload that
$ pasta -xp # take a screenshow with import(1) and upload that with a random file name
```


## References

Inspiration: https://codemadness.org/paste-service.html

