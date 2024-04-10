# vs2termux
Simple script designed to install forge or fabric server with glibc support on native termux.

```wget https://raw.githubusercontent.com/sa1672ndo/vs2termux/main/vs2server.sh```
```sh vs2server.sh```

Known bugs:
Server crashes on world creation with an error "Bad system call". This is a glibc-runner bug, which should be fixed when the new update releases.
