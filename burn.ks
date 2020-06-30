// burn the next maneuver node.
run once libguido.

parameter wrp is 0.

myinit().
until NOT hasnode {
	set mynode to nextnode.
	exec_n(mynode,wrp).
}
myexit().

