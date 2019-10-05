d:\devel\xharbour_maio_2013\bin\xbuild syg_pgsql.lib.xbp -Noerr

del *.log
del *.ini

copy syg_pgsql.lib D:\devel\xharbour_maio_2013\contrib\syg_pgsql.lib /y

D:\devel\bcc58\bin\implib -a libpq.lib libpq.dll
