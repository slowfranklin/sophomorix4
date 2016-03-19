#
# Regular cron jobs for the sophomorix4-1.0.0 package
#
0 4	* * *	root	[ -x /usr/bin/sophomorix4-1.0.0_maintenance ] && /usr/bin/sophomorix4-1.0.0_maintenance
