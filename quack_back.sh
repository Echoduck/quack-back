#!/bin/bash

# CST Backup Script v.1

# 5/1/17 - replaced cp -a with tar commands

# Generate list of users on device
list=$(ls /Users/ | grep -v -e 'student' -e 'testing' -e 'Shared' -e '.localized');

# Counter for USER array index
var=0; 

# Add users to array for use with selection menu
for i in $list; do 

	USERS[$var]=$i;
	var=$(($var+1)); 
	echo "$var. $i"; 
done

# Start selection menu
echo -n "Choose a username from the list: ";
read choice;

if [[ "$choice" -gt "${#USERS[*]}" ]] || [[ "$choice" -lt "0" ]]
then
	echo "Invalid input - please only enter one of the numbers on the list";
	exit 1;

elif [ "$(grep -c '[[:digit:]]' <<< $choice)" == "0" ]
then
	echo "Invalid input - please only enter numbers";
	exit 1;
fi

choice=$(($choice-1));

echo -n "You chose ${USERS[$choice]}. Is this correct? (y/n) "

read yn;

if [[ "$yn" =~ "y" ]]
then
	echo "Let's go!";
        USERNAME=${USERS[$choice]};
else
	echo "Quitting program";
	exit 1;
fi

mkdir $USERNAME;
cd $USERNAME;

echo "Created directory "$USERNAME

echo -n "Backing up printers...";

if [[ "$(ls /etc/cups/ | grep -c 'printers.conf')" -ne "0" ]]
then

    # Printer backup phase
    # Initialize backup file
    file=$USERNAME.printers;
    var=0;

    # Extract printer descriptions from /etc/cups/printers.conf
    # and write them to the backup file
    awk '/^Info/ {for(i=2; i<=NF; i++) printf $i (i==NF?ORS:OFS)}' /etc/cups/printers.conf > $file

    # Extract printer name, PPD file, and IP address from /etc/cups/printers.conf,
    # format them csv style, and append data to the previous backup file
    grep '<Printer' /etc/cups/printers.conf | while read -r line; do
            
            # Counter to keep track of line numbers
            var=$((var+1));

            # Isolates name and PPD from string
            NAME=$(sed -e 's/<Printer //g' -e 's/>//g' <<< $line);
            PPD=$(sed -e '/^[[:digit:]]/ s/^/_/' -e 's/-/_/' <<< $NAME); 
            
            # Appends name and PPD to text file
            sed -i.bak "$var s/$/,$NAME,$PPD/" $file;
    done

    grep DeviceURI /etc/cups/printers.conf | while read -r line; do
            
            # Counter to keep track of line numbers
            var=$((var+1)); 
            
            # Isolates IP address from string
            IP=$(sed 's/DeviceURI //g' <<< $line);
            
            # Adds escaped "/" chars to IP for later use with sed command
            IP=$(sed 's/\//\\\//g' <<< $IP);
            
            # Appends URI and IP to its related line in the text file
            sed -i.bak "$var s/$/,$IP/" $file;
            
    done

    # Backup printer apps
    tar cpf $USERNAME.PRINTERAPPS.tar -C /Users/$USERNAME/Library/Printers/ .

    # Check for KONICA printers
    if [[ "$(ls /Library/Printers/ | grep -c KONICA)" -ne "0" ]]
    then
        #km_dir="Library/Printers/PPDs/Contents/Resources"
        #mkdir -p $km_dir 
        #cp -a /Library/Printers/KONICAMINOLTA/. Library/Printers/KONICAMINOLTA
        #ls /$km_dir | grep KONICA | while read -r line; do
        #    cp -a /$km_dirm$line $km_dir
        #done
        
        tar cpf $USERNAME.KONICAFOLDERS.tar -C /Library/Printers/ KONICAMINOLTA/.
        ls /Library/Printers/PPDs/Contents/Resources/ | grep KONICA | while read -r line; do
            tar rpf $USERNAME.KONICAPPDS.tar -C /Library/Printers/PPDs/Contents/Resources/ $line;
        done
    fi



    # Copies all non-KM PPD files to a separate folder
    #cp -a /etc/cups/ppd/ ppd;
    tar cpf $USERNAME.ppds.tar -C /etc/cups/ppd/ .

    # Deletes temp file created by sed command
    rm $file.bak;

    echo "done!";

else
    echo "no printers found!";
fi

# Browser backup phase

# Safari
echo -n "Backing up Safari..."
#cp -a /Users/$USERNAME/Library/Safari Safari
tar cpf $USERNAME.Safari.tar -C /Users/$USERNAME/Library/Safari/ .

#mkdir preferences
#cp -a /Users/$USERNAME/Library/Preferences/com.apple.Safari.plist preferences/com.apple.Safari.plist
tar cpf $USERNAME.SafariPreferences.tar -C /Users/$USERNAME/Library/Preferences/ com.apple.Safari.plist
echo "done!"

# Chrome
echo -n "Backing up Chrome..."
#cp -a /Users/$USERNAME/Library/Application\ Support/Google/Chrome/Default Default
# Check for profile folder
PROFILE=$(ls /Users/$USERNAME/Library/Application\ Support/Google/Chrome/ | grep -e '^Profile' -e '^Default')
tar cpf $USERNAME.Chrome.tar -C /Users/$USERNAME/Library/Application\ Support/Google/Chrome/"$PROFILE"/ Bookmarks
echo "done!"

# Firefox
echo -n "Backing up Firefox..."
#cp -a /Users/$USERNAME/Library/Application\ Support/Firefox/Profiles/* Firefox
if [[ "$(ls /Users/$USERNAME/Library/Application\ Support/ | grep -c 'Firefox')" -ne "0" ]]
then
tar cpf $USERNAME.Firefox.tar -C /Users/$USERNAME/Library/Application\ Support/Firefox/Profiles/ .
fi
echo "done!"

# User data backup phase

echo -n "Backing up Desktop..."
#cp -a /Users/$USERNAME/Desktop Desktop
tar cpf $USERNAME.Desktop.tar -C /Users/$USERNAME/Desktop/ .
echo "done!"

echo -n "Backing up Documents..."
#cp -a /Users/$USERNAME/Documents Documents
tar cpf $USERNAME.Documents.tar -C /Users/$USERNAME/Documents/ .
echo "done"

echo -n "Backing up Pictures..."
#cp -a /Users/$USERNAME/Pictures Pictures
tar cpf $USERNAME.Pictures.tar -C /Users/$USERNAME/Pictures/ .
echo "done!"

echo -n "Backing up Music..."
#cp -a /Users/$USERNAME/Music Music
tar cpf $USERNAME.Music.tar -C /Users/$USERNAME/Music/ .
echo "done!"

echo -n "Backing up Movies..."
#cp -a /Users/$USERNAME/Movies Movies
tar cpf $USERNAME.Movies.tar -C /Users/$USERNAME/Movies/ .
echo "done!"

echo -n "Backing up Downloads..."
#cp -a /Users/$USERNAME/Downloads Downloads
tar cpf $USERNAME.Downloads.tar -C /Users/$USERNAME/Downloads/ .
echo "done!"

echo -n "Backing up files in user directory..."

#mkdir user_directory_files

#ls -p /Users/$USERNAME/ | grep -v / | grep -v '^\.' | while read -r line; do
    #cp -a /Users/$USERNAME/"$line" user_directory_files/"$line";
#    tar rpf $USERNAME.user_dir.tar -C /Users/$USERNAME/ $line       
#done

ls -p /Users/$USERNAME/ | grep -v / | grep -v '^\.' | tar cpf $USERNAME.user_dir.tar -C /Users/$USERNAME/ -T -

echo "done!"

# Backup trash contents?

# Check for sticky notes

echo -n "Backing up sticky notes..."

NOTES=$(ls /Users/$USERNAME/Library/ | grep 'StickiesDatabase')

if [[ "$NOTES" =~ "StickiesDatabase" ]]
then
    #cp -a /Users/$USERNAME/Library/StickiesDatabase StickiesDatabase
    tar cpf $USERNAME.StickiesDatabase.tar -C /Users/$USERNAME/Library/ StickiesDatabase
    echo "done!"
else
    echo "no sticky notes found."
fi

# Generate list of installed applications

ls /Applications > installed_apps.txt
