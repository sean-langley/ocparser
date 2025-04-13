## OpenCore Parser

This is a quick script I wrote to help parse the config.plist file used for OpenCore on Hackintosh systems. It is designed for a quick summary of a config.plist to help with troubleshooting. It is in no way a replacement for properly following the Dortania or ChefsKiss guides.

It has a few useful features:

• Checks the config.plist with OCValidate (Includes version 1.0.4, but can be changed as needed)
• Lists out the following
	• Header Information
	• Drivers/Tools Information (Including counts)
	• Kext Information (Including counts)
	• Boot Arguments (Including counts)
	• SMBIOS Information
	• Framebuffers (If used)
	• SecureBootModel State
	• OpenCanopy State (Enabled/DIsabled)
	• Keyboard and Language Sets
• Also includes scanning features for the following. This check can be bypassed with --force:
	• Checks for OpCore Simplify
	• Checks for Olarila
	• Checks for OpenCore Configurator/Opencore Auxillary Tools
