extends RigidBody3D

var bowl_tag:String

func Wakeup():
	sleeping = false
	
func Sleep():
	sleeping = true
