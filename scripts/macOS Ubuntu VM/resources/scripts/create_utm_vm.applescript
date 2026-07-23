# -----------------------------------------------------------------------------
# FILE:         create_utm_vm.applescript
# AUTHOR:       Aiden Kimmerling <apkimmerling@gmail.com>
# CREATED:      07-23-2026
# LAST EDITED:  07-23-2026
# DESCRIPTION:  Uses AppleScript to communicate with UTM to make a new VM with
#								configuration set by build_vm.sh. Should not be used by itself.
# USAGE:        Used by build_vm.sh
# DEPENDS:      AppleScript, build_vm.sh, UTM
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

on run argv
	if (count of argv) < 8 then
		error "Usage: osascript create_utm_vm.applescript <name> <vm_notes> <cpu_cores> <disk_gb> <memory_mb> <iso_path> <seed_path> <open_vm> <delete_vm>"
	end if
	
	# Sets all args
	set vmName to item 1 of argv
	set vmNotes to item 2 of argv
	set cpuCores to (item 3 of argv) as integer
	set diskSizeMB to ((item 4 of argv) as integer) * 1024
	set memoryMB to (item 5 of argv) as integer
	set isoFile to POSIX file (item 6 of argv)
	set seedFile to POSIX file (item 7 of argv)
	set openVM to (item 8 of argv) as boolean
	set deleteVM to (item 9 of argv) as boolean
	
	set vmIcon to "ubuntu"
	
	tell application "UTM"
		# If a virtual machine has the same name as `vmName`, delete it
		set matchingVMs to every virtual machine whose name is vmName
		
		if deleteVM then
			if (count of matchingVMs) > 0 then
				log "=== Virtual machine found in UTM with the same name of " & vmName & ". Deleting... ==="
				delete item 1 of matchingVMs
			end if
		else
			error "=== Virtual machine found in UTM with the same name of " & vmName & ". Cannot proceed. ==="
		end if
		
		# Set the virtual machine configuration with the seed and 
		# iso image, new VirtIO disk, basic network and GPU cards
		log "=== Creating virtual machine config ==="
		set vmConfig to ¬
			{name:vmName, icon:vmIcon, notes:vmNotes, architecture:"aarch64", machine:"virt", memory:memoryMB, cpu cores:cpuCores, hypervisor:true, uefi:true, directory share mode:none, drives:{¬
				{guest size:diskSizeMB, interface:VirtIO}, ¬
				{source:seedFile, interface:VirtIO}, ¬
				{source:isoFile, interface:VirtIO} ¬
					}, network interfaces:{¬
				{hardware:"virtio-net-pci", mode:shared} ¬
					}, displays:{¬
				{hardware:"virtio-gpu-pci", dynamic resolution:false} ¬
					} ¬
				} ¬
				
		# Creates the virtual machine
		log "=== Creating virtual machine ==="
		set vm to make new virtual machine with properties {backend:qemu, configuration:vmConfig}
		
		# Starts the virtual machine and activates the UTM window
		if openVM then
			log "=== Opening virtual machine ==="
			activate
			start vm
		else
			log "=== Open UTM to get started ==="
		end if
	end tell
end run
