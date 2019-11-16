# bin

Command Line Tool

## file2slack

- usage

```
usage:
  file2slack

  environment SLACK_WEB_API_TOKEN is required.
  prease set SLACK_WEB_API_TOKEN

  export SLACK_WEB_API_TOKEN=*****

options)
  -f : filename (if this option is not exist, to post the stdin.)
  -c : post channel
  -t : file title
```

- specified target file 

```
file2slack -f hoge.png -c channnel_a -t imagefile
```

- from stdin

```
cat hoge.json | jq '.fuga' | sort | uniq -c | file2slack -c channel_b -t summary
```

## ansi_colorlist

echo colorlist

## server

run static server in current directory

- usage

```
Usage: simpleserver [command] [port]

  simple server

Options:
  command(required),  [start|stop|restart]
  port,               server port.
```

## wcmd

execute command when file changed

- example 

```
wcmd bundle exec rspec
```

## watch-server

## mbsplit

split by bytesize with multibyte character

Check whether the specified number of bytes per line is exceeded

- example 

```
mbsplit dir1 dir2 filename 5000
```

## jq2esc

jq with transform escaped sequence

```
cat hoge.json | jq2esc '.hoge'
```

## gluediff

text diff between glue job

```
gluediff awsProfile jobName1 jobName2
```

## traceback
