-- Fixed surrender with sane percentage and only visible to the attacking team.
Vote:new("surrender")
	:description("Forfeits the match in favor of the defending team")
	:pass("ref surrender")
	:percent(55)
	:team()
	:attacker()