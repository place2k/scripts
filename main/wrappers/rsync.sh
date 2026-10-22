#!/usr/bin/bash
exec /usr/bin/rsync -hav -WUXAH --preallocate --partial $@
