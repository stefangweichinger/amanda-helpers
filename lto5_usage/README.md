## using LTO-5 drives with AES-256-CTR encryption

Main points for the config, these two scripts are called from amanda.

Install binary "zstd" from the repository of your distribution.

Use the two provided scripts:

1. The script "encrypt" goes to "/usr/local/sbin/encrypt"
Then configure your amanda dumptype with the option:

```
server_encrypt "/usr/local/sbin/encrypt"
```

2. The script "zstd-compression3" goes to "/usr/local/sbin/zstd-compression3"
Use it in your amanda dumptype with:

```
server_custom_compress "/usr/local/sbin/zstd-compression3"
```

If you want to use multiple different compression levels, copy `zstd-compression3` to `zstd-compression5`, for example
and edit the zstd-compression-level as in:

```
else
  zstd -qc -5 -T0
fi
```

then call that script in your dumptype definition.

## source

https://www.eevblog.com/forum/general-computing/lto-tape-usage-(modern-tape-drives)/

Email by https://marc.info/?a=163290377200001&r=1&w=2

https://marc.info/?l=amanda-users&m=164546702906365&w=2
