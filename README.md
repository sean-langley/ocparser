## OpenCore Parser

This is a quick script I wrote to help parse the config.plist file used for OpenCore on Hackintosh systems. It is designed for a quick summary of a config.plist to help with troubleshooting. It is in no way a replacement for properly following the Dortania or ChefsKiss guides.

It has a few useful features

 - Checks for the running operating system and maps the required version of OCValidate
   
 - Checks the config.plist with OCValidate (Includes version 1.0.4, but 
   can be changed as needed)
      
 - Lists out the following
	 - Header Information
	 - Drivers/Tools Information (Including counts)
	 - Kext Information (Including counts)
	 - Boot Arguments (Including counts)
	 - SMBIOS Information, including
		 - Board ID (MLB)
		 - ROM ID
		 - Model ID/Name
		 - Serial Number
		 - UUID
	 - Framebuffers (If present)
	 - SecureBootModel State
	 - OpenCanopy State (Enabled/Disabled)
	 - Keyboard and Language Set
 - Scanning features for the following (Halts by default, can be bypassed with --force)
	 - OpCore Simplify
	 - Olarila
	 - OpenCore Configurator/OpenCore Auxillary Tools

Any suggestions or improvements are welcome. 

