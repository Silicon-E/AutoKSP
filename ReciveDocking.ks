print "Listen for docking message.".
LOCAL next_message IS -1.
WHEN NOT SHIP:MESSAGES:EMPTY then
{
	print "Got message.".
	SET next_message TO SHIP:MESSAGES:POP.
	if next_message:content = "dock" 
	{
		print "Message was a docking message. Point toward sender.".
		sas off.
		// Message:SENDER is Boolean false when the sender no longer exists
		lock steering to choose ship:facing if next_message:sender:typename="Boolean" else (next_message:sender:position - ship:controlpart:position):direction.
	}
}
WAIT UNTIL next_message <> -1.
// When docked:
WAIT UNTIL next_message:sender:typename="Boolean" or next_message:sender=ship. // Message:SENDER is Boolean false when the sender no longer exists
UNLOCK steering.
print "Done.".