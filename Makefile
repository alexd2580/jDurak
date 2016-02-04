.PHONY: default clean build run lib getwindowlib getmaclib package-linux package-windows package-mac package

default:

clean_server:
	@[ ! -e jDurak_server.love ] || rm jDurak_server.love

clean_client:
	@[ ! -e jDurak_client.love ] || rm jDurak_client.love

clean: clean_server clean_client
	@[ ! -e pkg ] || rm -r pkg
	@[ ! -e lib ] || rm -r lib
	@[ ! -e temp ] || rm -r temp

server: clean_server
	@cd src/lib && zip -q -r -0 ../../jDurak_server.love *
	@cd src/server && zip -q -r -0 ../../jDurak_server.love *
	@love jDurak_server.love

client: clean_client
	@cd src/lib && zip -q -r -0 ../../jDurak_client.love *
	@cd src/client && zip -q -r -0 ../../jDurak_client.love *
	@love jDurak_client.love
