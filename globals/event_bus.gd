extends Node

func rpc_signal(signal_name: String, args: Array = []):
	send_signal.rpc(signal_name, args)

@rpc("any_peer", 'call_local')
func send_signal(signal_name: String, args: Array = []):
	if args:
		callv("emit_signal", [signal_name] + args)
	else:
		emit_signal(signal_name)

signal database_built()

signal request_cube()
