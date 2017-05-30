#!/bin/bash

echo "type the name of the user to restore";
read user;
echo -n "You typed $user. Is this correct? (y/n)";

read yn;

if [[ "$yn" =~ "y" ]]
then
	if [[ "$(ls | grep $user.printers)" ]]
	then
		echo "Found $user.printers!";
	else
		echo "Could not find $user.printers!";
	exit 1;
	fi
else
	echo "Quiting program";
	exit 1;
fi 

# Extract Desktop archive
echo "Unpacking $user Desktop..." -n
tar xpf $user.Desktop.tar -C /Users/$user/Desktop/
echo "done!"

# Extract Documents archive
echo "Unpacking $user Documents..." -n
tar xpf $user.Documents.tar -C /Users/$user/Documents/
echo "done!"

# Extract Downloads archive
echo "Unpacking $user Downloads..." -n
tar xpf $user.Downloads.tar -C /Users/$user/Downloads/
echo "done!"

# Extract Pictures archive
echo "Unpacking $user Pictures..." -n
tar xpf $user.Pictures.tar -C /Users/$user/Pictures/
echo "done!"

# Extract Music archive
echo "Unpacking $user Music..." -n
tar xpf $user.Music.tar -C /Users/$user/Music/
echo "done!"

# Extract Movies archive
echo "Unpacking $user Movies..." -n
tar xpf $user.Movies.tar -C /Users/$user/Movies/
echo "done!"

# Extract StickiesDatabase archive
echo "Unpacking $user stickies..." -n
tar xpf $user.StickiesDatabase.tar -C /Users/$user/Library/
echo "done!"

# Extract user directory archive
echo "Unpacking $user user directory files..." -n
tar xpf $user.user_dir.tar -C /Users/$user/
echo "done!"

echo "Installing printers..." -n

tar xpf $user.ppds.tar 
file="$user.printers"
# Read printer information from backup file and install printer

while IFS=',' read -r DESCRIPTION PPD NAME IP; do
	PPD=$(sed -e '/^[[:digit:]]/ s/^/_/' -e 's/-/_/' <<< $NAME).ppd;
	
	# Install selected printer
	echo -n "Installing $DESCRIPTION...";
	lpadmin -E -p "$NAME" -v "$IP" -D "$DESCRIPTION" -P "$user/$PPD" -o printer-is-shared=false; 
	
	cupsenable "$NAME"; 
	cupsaccept "$NAME";
	echo "done!";

done < $file 

# Extract miscellaneous printer stuff
echo "Wrapping it up..." -n

tar xpf $user.KONICAFOLDERS.tar -C /Library/Printers/
tar xpf $user.KONICAPPDS.tar -C /Library/Printers/PPDs/Contents/Resources/
tar xpf $user.PRINTERAPPS.tar -C /Users/$user/Library/Printers/

