#!/usr/bin/env bash


echo "\n #################################################### \n$HR"
echo "\n Arch linux Bare-Bones BTRFS automatic Installation.  \n$HR"
echo "\n #################################################### \n$HR"

echo "\n Please provide necesarie system information up next: \n$HR"

lsblk

echo "Please enter the drive you will use (example /dev/sda)"
read DRIVE																	
echo "Please enter the partition for full system installation: (example /dev/sda1)"
read MAINDISK
echo "Please enter your swap partition: (example /dev/sda2)"
read SWAPDISK
echo "Please enter your prefer Linux kernel: (example: linux-lts)"
read LINUXKERNEL
echo "Please enter ucode: (example intel-ucode)"
read UCODE
echo "Please enter your Timezone: (example America/Montevideo)"
read TIMEZONE
echo "Please enter your locale: (example en_US.UTF-8)"
read LOCALE
echo "Please enter desire hostname (example arch-VM)"
read HOSTNAME
echo "And enter the user name to be use on the this device"
read USER

echo -e "\nFormating Disk...\n$HR"
# btfs root
mkfs.btrfs -f ${MAINDISK}
# Swap
mkswap ${SWAPDISK}
swapon ${SWAPDISK}

echo -e "\nMounting BTRFS subvolumes...\n$HR"
mount ${MAINDISK} /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@boot
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@log
btrfs su cr /mnt/@.snapshots
umount /mnt

# creating folders to mount the other subvolumes at
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@ ${MAINDISK} /mnt
mkdir /mnt/{boot,home,var/cache,var/log,.snapshots}
mount -o subvol=@boot ${MAINDISK} /mnt/boot
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@home ${MAINDISK} /mnt/home
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@cache ${MAINDISK} /mnt/var/cache
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@log ${MAINDISK} /mnt/var/log
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@.snapshots ${MAINDISK} /mnt/.snapshots


echo "\n-- Installing Arch on Main Driven\n$HR"
pacstrap /mnt base base-devel ${LINUXKERNEL} ${LINUXKERNEL}-headers linux-firmware ${UCODE} btrfs-progs sudo --noconfirm --needed

echo "\n--	Generating fstab\n$HR"
# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

echo "\n--	Ch-rooting into install mount point\n$HR"
arch-chroot /mnt

echo "\n-- Installing some basic tools\n$HR"
pacman -S grub networkmanager vim --noconfirm --needed

echo "\n--	Configuring Grub\n$HR"
grub-install --target=i386-pc ${DRIVE}
grub-mkconfig -o /boot/grub/grub.cfg

echo "\n--	Establishing timezone\n$HR"
timedatectl --no-ask-password set-timezone ${TIMEZONE}

echo "\n--	Syncing hardware and system clock\n$HR"
hwclock --systohc

echo "\n--	Stating Locale\n$HR"
localectl --no-ask-password set-locale LANG="${LOCALE}"
localectl --no-ask-password set-locale LC_TIME="${LOCALE}"
locale-gen
echo LANG=${LOCALE} >> /etc/locale.conf

echo "\n--	Writting Hostname\n$HR"
echo ${HOSTNAME} >> /etc/hostname

echo "\n--	Starting Network Service, almost done...\n$HR"
systemctl enable NetworkManager
systemctl start NetworkManager

echo "\n--	Pease set Password for Root\n$HR"
echo "Enter password for root user: "
passwd

echo "\n--	Creating main  user\n$HR"
useradd -mG wheel ${USER}
echo "Enter password for user niko"
passwd ${USER}


echo 
" Require Manual intervention: Execute Now:
1)  Add btrfs module by adding btrfs inside module section >> ( MODULES=btrfs ).
	`vim /etc/mkinitcpio.conf`
2) Recreate Linux mkinitcpio image by executing:
	`mkinitcpio -p linux-lts`
3) Give users from the wheel group full sudo access:

###############################################################################
# After finishing the top manual intervention execute the next commands:
exit
umount -l /mnt
reboot
###############################################################################
"
