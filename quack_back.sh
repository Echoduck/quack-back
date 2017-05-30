#!/bin/bash

# CST Backup Script v.1

# todo: options for printers only, data only, or data + printers

function backup_printers {
echo -n "Backing up printers..."

if [[ "$(ls /etc/cups/ | grep -c 'printers.conf')" -ne "0" ]]
then
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
    tar cpf $USERNAME.PPDS.tar -C /etc/cups/ppd/ .

    # Deletes temp file created by sed command
    rm $file.bak;

    echo "done!";

else
    echo "no printers found!";
fi
}

function backup_data {
# Browser backup phase

# Safari
echo -n "Backing up Safari..."

# Check for folder
if [[ "$(ls /Users/$USERNAME/Library/ | grep -c 'Safari')" -ne "0" ]]
then
  tar cpf $USERNAME.Safari.tar -C /Users/$USERNAME/Library/Safari/ .
  tar cpf $USERNAME.SafariPreferences.tar -C /Users/$USERNAME/Library/Preferences/ com.apple.Safari.plist
  echo "done!"
else
  echo "no Safari profiles found."
fi

# Chrome
echo -n "Backing up Chrome..."
# Check for profile folder
PROFILE=$(ls /Users/$USERNAME/Library/Application\ Support/Google/Chrome/ | grep -e '^Profile' -e '^Default')
tar cpf $USERNAME.Chrome.tar -C /Users/$USERNAME/Library/Application\ Support/Google/Chrome/"$PROFILE"/ Bookmarks
echo "done!"

# Firefox
echo -n "Backing up Firefox..."
if [[ "$(ls /Users/$USERNAME/Library/Application\ Support/ | grep -c 'Firefox')" -ne "0" ]]
then
  tar cpf $USERNAME.Firefox.tar -C /Users/$USERNAME/Library/Application\ Support/Firefox/Profiles/ .
  echo "done!"
else
  echo "no Firefox profiles found."
fi

# User data backup phase

echo -n "Backing up Desktop..."
tar cpf $USERNAME.Desktop.tar -C /Users/$USERNAME/Desktop/ .
echo "done!"

echo -n "Backing up Documents..."
tar cpf $USERNAME.Documents.tar -C /Users/$USERNAME/Documents/ .
echo "done"

echo -n "Backing up Pictures..."
tar cpf $USERNAME.Pictures.tar -C /Users/$USERNAME/Pictures/ .
echo "done!"

echo -n "Backing up Music..."
tar cpf $USERNAME.Music.tar -C /Users/$USERNAME/Music/ .
echo "done!"

echo -n "Backing up Movies..."
tar cpf $USERNAME.Movies.tar -C /Users/$USERNAME/Movies/ .
echo "done!"

echo -n "Backing up Downloads..."
tar cpf $USERNAME.Downloads.tar -C /Users/$USERNAME/Downloads/ .
echo "done!"

echo -n "Backing up files in user directory..."

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
}

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
read user;

if [[ "$user" -gt "${#USERS[*]}" ]] || [[ "$user" -lt "0" ]]
then
	echo "Invalid input - please only enter one of the numbers on the list";
	exit 1;

elif [[ "$(grep -c '[[:digit:]]' <<< $user)" == "0" ]]
then
	echo "Invalid input - please only enter numbers";
	exit 1;
fi

user=$(($user-1));

echo -n "You chose ${USERS[$user]}. Is this correct? (y/n) "

read yn;


if [[ "$yn" =~ "y" ]]
then
	echo "Let's go!";
        USERNAME=${USERS[$user]};
else
	echo "Quitting program";
	exit 1;
fi

echo "1. Printers and data"
echo "2. Data only"
echo "3. Printers only"
echo -n "What would you like to backup? "

read choice;

mkdir $USERNAME;
cd $USERNAME;

echo "Created directory "$USERNAME

if [[ "$choice" == "1" ]]
then
  backup_printers
  backup_data

elif [[ "$choice" == "2" ]]
then  
  backup_data

elif [[ "$choice" == "3" ]]
then
  backup_printers

else
  echo "Quiting program"
  exit 1;
fi

# Generate list of installed applications

ls /Applications > installed_apps.txt
