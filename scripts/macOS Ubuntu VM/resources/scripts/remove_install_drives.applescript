# -----------------------------------------------------------------------------
# FILE:         remove_install_drives.applescript
# AUTHOR:       Aiden Kimmerling <apkimmerling@gmail.com>
# CREATED:      07-23-2026
# LAST EDITED:  07-23-2026
# DESCRIPTION:  Uses AppleScript to communicate with UTM to remove the install
#								drives after install completes. This script is ran by build_vm.sh
#								and should not be used by itself.
# USAGE:        Used by build_vm.sh
# DEPENDS:      AppleScript, build_vm.sh, UTM
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

on run argv
	if (count of argv) < 1 then
		error "Usage: osascript remove_install_drives.applescript <name> <reboot>"
	end if
	
	# Sets all args
	set vmName to item 1 of argv
	set rebootVM to (item 2 of argv) as boolean
	
	tell application "UTM"
		set vm to virtual machine named vmName
		
		# Wait until virtual machine is stopped
		log "=== Waiting until virtual machine installs and stops ==="
		repeat until status of vm is stopped
			delay 2
		end repeat
		
		log "=== Virtual machine is stopped. Updating configuration ==="
		
		set config to configuration of vm
		
		# Updates the drives configuration to only include the main drive
		set mainDrive to item 1 of drives of config
		set drives of config to {{mainDrive}}
		
		update configuration of vm with config
		
		log "=== Virtual machine configuration updated. Starting... ==="
		
		if rebootVM then
			log "=== Starting virtual machine ==="
			start vm
		else
			log "=== Open UTM to get started ==="
		end if
	end tell
end run
