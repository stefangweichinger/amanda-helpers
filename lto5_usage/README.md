## using LTO-5 drives with AES-256-CTR encryption

Main points for the config, these two scripts are called from amanda.

```
# encrypt, use with server_encrypt "/whatever/encrypt":
#!/bin/sh

AMANDA_HOME=~amanda
PASSPHRASE=$AMANDA_HOME/.am_passphrase    # required
RANDFILE=$AMANDA_HOME/.rnd
export RANDFILE

if [ "$1" = -d ]; then
    /usr/bin/openssl enc -pbkdf2 -d -aes-256-ctr -salt -pass fd:3 3< "${PASSPHRASE}"
else
    /usr/bin/openssl enc -pbkdf2 -e -aes-256-ctr -salt -pass fd:3 3< "${PASSPHRASE}"
fi
```

```
# zstd-compression3, use with server_custom_compress "/whatever/zstd-compression3 :
#!/bin/sh
if [[ "$1" == "-d" ]]; then
    zstd -dqcf
else
    zstd -qc -3 -T0
fi
```

## source

https://www.eevblog.com/forum/general-computing/lto-tape-usage-(modern-tape-drives)/

Email by https://marc.info/?a=163290377200001&r=1&w=2

https://marc.info/?l=amanda-users&m=164546702906365&w=2
