..\..\premake4.exe embed
..\..\premake4.exe --to=./build/codeblocks.macosx --os=macosx codeblocks
..\..\premake4.exe --to=./build/codeblocks.unix --os=linux codeblocks
..\..\premake4.exe --to=./build/codeblocks.windows --os=windows codeblocks

..\..\premake4.exe --to=./build/codelite.macosx --os=macosx codelite
..\..\premake4.exe --to=./build/codelite.unix --os=linux codelite
..\..\premake4.exe --to=./build/codelite.windows --os=windows codelite

..\..\premake4.exe --to=./build/gmake.macosx --os=macosx gmake
..\..\premake4.exe --to=./build/gmake.unix --os=linux gmake
..\..\premake4.exe --to=./build/gmake.windows --os=windows gmake

..\..\premake4.exe --to=./build/vs2005 --os=windows vs2005
..\..\premake4.exe --to=./build/vs2008 --os=windows vs2008
..\..\premake4.exe --to=./build/vs2010 --os=windows vs2010
..\..\premake4.exe --to=./build/vs2012 --os=windows vs2012
..\..\premake4.exe --to=./build/xcode3 --os=macosx xcode3
pause
