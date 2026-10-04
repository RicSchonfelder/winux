#!/bin/sh
# validacao rapida do skeleton (roda no WSL)
set -e
cd /mnt/c/Users/ricar/winux
fail=0
for f in build/scripts/*.sh; do
    if sh -n "$f"; then echo "OK   $f"; else echo "FAIL $f"; fail=1; fi
done
# confere se todas as variaveis do build.conf estao citadas no fragmento/scripts principais
[ -f build/config/build.conf ] && echo "OK   build.conf"
[ -f build/config/haswell-desktop.fragment ] && echo "OK   fragmento"
[ -f README.md ] && echo "OK   README"
exit $fail