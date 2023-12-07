#!/bin/bash

BASE_DIR="/tmp/unbind-script"
DIALOG_COMMAND_FILE="/tmp/dialogCommand"
LOG_PATH="$BASE_DIR/migrate_AD.log"

# Cleanup and prepare
if [[ ! -d "$BASE_DIR" ]]; then
    mkdir "$BASE_DIR"
fi

exec 1> >(tee -a "$LOG_PATH")
exec 2>&1
set -x 


POPUP_PATH="/usr/local/bin/dialog"
DATE=$(date +%Y-%m-%d_%H:%M:%S)
LOG_ARCHIVE="$BASE_DIR/migrate_AD_$DATE.log"
currentUser="$(stat -f '%Su' /dev/console)"
uid="$(id -u $currentUser)"
ADComputerName="$(dsconfigad -show | grep Account | cut -d "=" -f2 | tr -d " " | tr -d "$")"


# To exit from subprocesses...
PROC=$$
trap "exit 1" 10

ScriptLogging(){

    DATE=$(date +%Y-%m-%d\ %H:%M:%S)
    echo "$DATE" " $1"
}

# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    ExitWithError
  fi
}

# Exit function.
ExitWithError() {
    Cleanup
    set -e
    kill -10 $PROC
}

Cleanup() {
    PopupKillProgress
    mv $LOG_PATH $LOG_ARCHIVE
}

PopUpShowResult() {
    # Show text in a window with the specified title 
    # and message with only one button
    local title="$1"
    local message="$2"
    local icon="$3"
    local options="$4"

    "$POPUP_PATH" --title "$title" \
    --message "$message" \
    --icon "$icon" \
    "$options"\
    --mini
}

PopupAskPermission() {
    # Show text in a window with the specified title, message and two buttons
    local title="$1"
    local message="$2"
    local icon="$3"
    local button1text="$4"
    local button2text="$5"
    local options="$6"

    if [[ -z "$button1text" ]]; then 
        button1text="Proceed"
    fi

    if [[ -z "$button2text" ]]; then
        button2text="Exit"
    fi

    "$POPUP_PATH" --title "$title" \
    --message "$message" \
    --icon "$icon"  \
    --button1text "$button1text"  \
    --button2text "$button2text" \
    "$options" \
    --mini
    echo $?
}

PopupShowProgress() {
    local title="$1"
    local message="$2"
    local icon="$3"
    local options="$4"
    
    if [[ ! -f "$DIALOG_COMMAND_FILE" ]]; then
        touch "$DIALOG_COMMAND_FILE"
    fi

    "$POPUP_PATH" --title "$title" \
    --message "$message" \
    --icon "$icon" \
    --progress \
    --commandfile "$DIALOG_COMMAND_FILE" \
    --mini

}

PopupKillProgress() {
    echo "quit:" >> "$DIALOG_COMMAND_FILE"
    sleep 0.1
    rm "$DIALOG_COMMAND_FILE"
}

ValidMobileAccount() {
    local netacc="$1"
    accounttype=`/usr/bin/dscl . -read /Users/"$netacc" AuthenticationAuthority | head -2 | awk -F'/' '{print $2}' | tr -d '\n'`
    mobileusercheck=`/usr/bin/dscl . -read /Users/"$netacc" AuthenticationAuthority | head -2 | awk -F'/' '{print $1}' | tr -d '\n' | sed 's/^[^:]*: //' | sed s/\;/""/g`
    if [[ "$accounttype" == "Active Directory" ]] && [[ "$mobileusercheck" == "LocalCachedUser" ]]; then
        echo "VALID"
    else
        echo "INVALID"
    fi
}


RemoveAD(){

    # This function force-unbinds the Mac from the existing Active Directory domain
    # and updates the search path settings to remove references to Active Directory 

    searchPath=`/usr/bin/dscl /Search -read . CSPSearchPath | grep Active\ Directory | sed 's/^ //'`

    # Force unbind from Active Directory
    /usr/sbin/dsconfigad -remove -force -u "username" -p "password"
    
    # Deletes the Active Directory domain from the custom /Search
    # and /Search/Contacts paths
    
    /usr/bin/dscl /Search/Contacts -delete . CSPSearchPath "$searchPath"
    /usr/bin/dscl /Search -delete . CSPSearchPath "$searchPath"
    
    # Changes the /Search and /Search/Contacts path type from Custom to Automatic
    
    /usr/bin/dscl /Search -change . SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
    /usr/bin/dscl /Search/Contacts -change . SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
}

PasswordMigration(){

    # macOS 10.14.4 will remove the the actual ShadowHashData key immediately 
    # if the AuthenticationAuthority array value which references the ShadowHash
    # is removed from the AuthenticationAuthority array. To address this, the
    # existing AuthenticationAuthority array will be modified to remove the Kerberos
    # and LocalCachedUser user values.
 

    AuthenticationAuthority=$(/usr/bin/dscl -plist . -read /Users/$netname AuthenticationAuthority)
    Kerberosv5=$(echo "${AuthenticationAuthority}" | xmllint --xpath 'string(//string[contains(text(),"Kerberosv5")])' -)
    LocalCachedUser=$(echo "${AuthenticationAuthority}" | xmllint --xpath 'string(//string[contains(text(),"LocalCachedUser")])' -)
    
    # Remove Kerberosv5 and LocalCachedUser
    if [[ ! -z "${Kerberosv5}" ]]; then
        /usr/bin/dscl -plist . -delete /Users/$netname AuthenticationAuthority "${Kerberosv5}"
    fi
    
    if [[ ! -z "${LocalCachedUser}" ]]; then
        /usr/bin/dscl -plist . -delete /Users/$netname AuthenticationAuthority "${LocalCachedUser}"
    fi
}

### Start process ###

# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

ScriptLogging "Checking AD bind..."
if [[ -n "$(dsconfigad -show | grep Account | cut -d "=" -f2 | tr -d " " | tr -d "$")" ]]; then
    res=$(PopupAskPermission "Your Mac is bound to Active Directory" "If you wish to unbind your mac from Active Directory press \"Proceed\"" "info")
    if [[ "$res" -eq 0 ]]; then
        ScriptLogging "Unbinding..."
        RemoveAD
        # Check if unbound was successfull
        if [[ -n "$(dsconfigad -show | grep Account | cut -d "=" -f2 | tr -d " " | tr -d "$")" ]]; then
            PopUpShowResult "Something went wrong" "Failed to unbind your Mac from Active directory.\nSee $LOG_PATH for details" "warning"
            ExitWithError
        fi
    else
        ScriptLogging "User cancelled operation. Exiting"
        Cleanup
        exit 0
    fi
    
fi

ScriptLogging "Looking for mobile accounts..."
for username in $(who | grep console | cut -d ' ' -f1); do
    if [[ $(ValidMobileAccount "$username") == "VALID" ]]; then
        netname="${username}"
    fi
done

if [[ -n "$netname" ]]; then
    ScriptLogging "Valid mobile account: $netname. Converting to a local account with the same username and UID."
    PopupShowProgress "Setting things up" "Converting mobile user account. Please wait..." "/System/Library/CoreServices/Applications/Directory Utility.app" &

    # Remove the account attributes that identify it as an Active Directory mobile account
            
    /usr/bin/dscl . -delete /users/$netname cached_groups
    /usr/bin/dscl . -delete /users/$netname cached_auth_policy
    /usr/bin/dscl . -delete /users/$netname CopyTimestamp
    /usr/bin/dscl . -delete /users/$netname AltSecurityIdentities
    /usr/bin/dscl . -delete /users/$netname SMBPrimaryGroupSID
    /usr/bin/dscl . -delete /users/$netname OriginalAuthenticationAuthority
    /usr/bin/dscl . -delete /users/$netname OriginalNodeName
    /usr/bin/dscl . -delete /users/$netname SMBSID
    /usr/bin/dscl . -delete /users/$netname SMBScriptPath
    /usr/bin/dscl . -delete /users/$netname SMBPasswordLastSet
    /usr/bin/dscl . -delete /users/$netname SMBGroupRID
    /usr/bin/dscl . -delete /users/$netname PrimaryNTDomain
    /usr/bin/dscl . -delete /users/$netname AppleMetaRecordName
    /usr/bin/dscl . -delete /users/$netname PrimaryNTDomain
    /usr/bin/dscl . -delete /users/$netname MCXSettings
    /usr/bin/dscl . -delete /users/$netname MCXFlags

    # Migrate password and remove AD-related attributes

    PasswordMigration

    # Refresh Directory Services
    if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -lt 7 ) ]]; then
        dsservice="DirectoryService"
    else
        dsservice="opendirectoryd"
    fi
    /usr/bin/killall "$dsservice"
    sleep 2

    # Waiting for directory services to come up
    count=0
    while [[ -z "$(pgrep $dsservice)" ]] && [[ $count -lt 60 ]]; do 
        ScriptLogging "Waiting for Directory Services to come up... $count"
        let count++
        sleep 1
    done

    if [[ $count -eq 60 ]]; then
        PopupKillProgress
        PopUpShowResult "Something went wrong" "Directory services not starting. Please contact support." "warning"
        ExitWithError
    fi

    # Checking if migration was successfull
    accounttype=`/usr/bin/dscl . -read /Users/"$netname" AuthenticationAuthority | head -2 | awk -F'/' '{print $2}' | tr -d '\n'`
    if [[ "$accounttype" = "Active Directory" ]]; then
        PopupKillProgress
        PopUpShowResult "Something went wrong" "Something went wrong with the conversion process.\nThe $netname account is still an AD mobile account.\nSee $LOG_PATH for details" "warning"
        ExitWithError
    fi

    # Setting up permissions for homefolder
    homedir=$(/usr/bin/dscl . -read /Users/"$netname" NFSHomeDirectory  | awk '{print $2}')

    ScriptLogging "Home directory location: $homedir"
    ScriptLogging "Updating home folder permissions for the $netname account"
    /usr/sbin/chown -R "$netname" "$homedir"

    # Add user to the staff group on the Mac
    ScriptLogging "Adding $netname to the staff group on this Mac."
    /usr/bin/dscl . append /Groups/staff GroupMembership "$netname"

    # Uncomment next line if you want to give admin rights to user
    /usr/bin/dscl . append /Groups/admin GroupMembership "$netname"

    PopupKillProgress
fi

PopUpShowResult "We are done!" "Your mac is successfully unbound from Active Directory!\nPlease, use Kerberos SSO Extension menu to log in to your corporate account" "/System/Library/CoreServices/Applications/Ticket Viewer.app" 
Cleanup
exit 0
