WHEN NOT SHIP:MESSAGES:EMPTY then 
{
	SET rec TO SHIP:MESSAGES:POP.
	print "1".
	if rec:content = "dock" 
		{
			print "2".
			sas off.
			lock steering to (rec:sender:position - ship:controlpart:position):direction.
		}
}
until false
{
	set a to 1+1.
}