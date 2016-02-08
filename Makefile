.PHONY: default clean build run lib getwindowlib getmaclib package-linux package-windows package-mac package

default:

clean:
	@[ ! -e jDurak_client.love ] || rm jDurak_client.love
	@[ ! -e pkg ] || rm -r pkg
	@[ ! -e lib ] || rm -r lib
	@[ ! -e temp ] || rm -r temp

server:
	@cd src && lua server/main.lua

client: clean
	@zip -q -r -0 jDurak_client.love assets/*
	@cd src && zip -q -r -0 ../jDurak_client.love common/*
	@cd src/client && zip -q -r -0 ../../jDurak_client.love main.lua conf.lua
	@love jDurak_client.love
