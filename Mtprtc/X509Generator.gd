extends Node2D

var crypto = Crypto.new()
var key = CryptoKey.new()
var cert = X509Certificate.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	CreateX509Cert()
	pass
func CreateX509Cert():
	# Generate new RSA key.
	key = crypto.generate_rsa(4096)
	# Generate new self-signed certificate with the given key. CN=127.0.0.1
	
	cert = crypto.generate_self_signed_certificate(key,"CN=127.0.0.1,O=Home Company,C=IT","20230101000000", "20330101000000")
	# Save key and certificate in the user folder.
	var  directory = DirAccess.open("user://Certificate")
	if directory:
		pass # Replace with function body.
	else:
		DirAccess.make_dir_absolute("user://Certificate")	
	key.save("user://Certificate/godot.key")
	cert.save("user://Certificate/godot.crt")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
