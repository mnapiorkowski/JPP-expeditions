# On students:
expeditions: expeditions.sav
	spld --static --exechome=/opt/sicstus/bin/ expeditions.sav -o expeditions
	expeditions.sav: mn429573.pl
	echo "compile('expeditions.pl'). save_program('expeditions.sav')." | sicstus

# Alternatively, for local uses:
# expeditions: expeditions.pl
# 	swipl --goal=expeditions --stand_alone=true -o expeditions -c expeditions.pl
