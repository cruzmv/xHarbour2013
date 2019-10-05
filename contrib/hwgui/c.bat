cd lib
del hwgui.lib
cd..
d:\devel\xharbour_maio_2013\bin\xbuild hwgui.lib.xbp -NoErr
copy hwgui.lib lib\hwgui.lib 
del hwgui.lib
del *.log
del xbuild.windows.ini