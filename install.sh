#!/usr/bin/env bash

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
btrfs su cr /mnt/@boot
btrfs su cr /mnt/@home
btrfs su cr /mnt/@var
btrfs su cr /mnt/@opt
btrfs su cr /mnt/@tmp
btrfs su cr /mnt/@.snapshots
umount /mnt

# creating folders to mount the other subvolumes at
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@ ${MAINDISK} /mnt
mkdir /mnt/{boot,home,var,opt,tmp,.snapshots}
mount -o subvol=@boot ${MAINDISK} /mnt/boot
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@home ${MAINDISK} /mnt/home
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@opt ${MAINDISK} /mnt/opt
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@tmp ${MAINDISK} /mnt/tmp
mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@.snapshots ${MAINDISK} /mnt/.snapshots
mount -o subvol=@var ${MAINDISK} /mnt/var


echo "-- Installing Arch on Main Drive       --"
pacstrap /mnt base base-devel ${LINUXKERNEL} ${LINUXKERNEL}-headers linux-firmware ${UCODE} btrfs-progs sudo --noconfirm --needed

echo "-- Post install main configuration run...     --"
# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab


echo "--	Ch-rooting into install mount point"
arch-chroot /mnt

echo "-- installing grub networkmanager & vim"
pacman -S grub networkmanager vim --noconfirm --needed

echo "--	Configuring Grub"
grub-install --target=i386-pc ${DRIVE}
grub-mkconfig -o /boot/grub/grub.cfg

echo "--	Seting up timezone"
timedatectl --no-ask-password set-timezone ${TIMEZONE}

echo "--	Syncing hardware and system clock"
hwclock --systohc

echo "--	Setting System Locale"
localectl --no-ask-password set-locale LANG="${LOCALE}"
localectl --no-ask-password set-locale LC_TIME="${LOCALE}"
locale-gen
echo LANG=${LOCALE} >> /etc/locale.conf

echo "--	Writting Hostname"
echo ${HOSTNAME} >> /etc/hostname

echo "--	Network Setup almost done..."
systemctl enable NetworkManager
systemctl start NetworkManager

echo "--	Set Password for Root"
echo "Enter password for root user: "
passwd

echo "--	Creating main  user"
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
