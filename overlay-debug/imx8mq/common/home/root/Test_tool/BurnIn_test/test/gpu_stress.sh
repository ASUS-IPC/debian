#!/bin/sh

export XDG_RUNTIME_DIR="/run/user/0"

#run glmark2-es2-wayland, benchmark - refract
glmark2-es2-wayland --benchmark refract --run-forever > /dev/null &
#for i in {1..4};
#do
	glmark2-es2-wayland --benchmark refract --run-forever --off-screen > /dev/null &
#	sleep 1
#done
