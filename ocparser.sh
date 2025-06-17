# Define colors
BLACK="\e[30m"
GRAY="\e[37m"
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
WHITE="\e[97m"
ENDCOLOR="\e[0m"

# Define input variables
PLIST=$1
PWD=$(PWD)

# Usage Statement
usage() {          echo
                   echo 'ocparser.sh <path/to/plist.config>'
                   echo
        }

# Checks for variable input and if the incorrect number shows command usage
if [ "$#" -le 0  ];
       then
          usage
            exit
fi

# Detect the OS and pick the appropriate version of OCValidate
OS=$(uname)

# Set the appropriate executable based on the OS
case "$OS" in
    Darwin)
        OCVALIDATE="$PWD/ocvalidate"
        ;;
    Linux)
        OCVALIDATE="$PWD/ocvalidate.linux"
        ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT)
        OCVALIDATE="$PWD/ocvalidate.exe"
        ;;
    *)
        echo "Unsupported OS: $OS"
	echo "OCValidate checks will be unavailable"
        ;;
esac

# Define version of OCValidate
OCVALIDATEVERSION=$($OCVALIDATE | grep -i version | awk '{print $12}' | sed 's/!/''/g')

# Title header
printf -- "\n"
printf -- "${WHITE}---------------------\n"
printf -- "OpenCore plist Parser\n"
printf -- "---------------------\n"
printf -- "${GREEN}\n"

#Checks for unsupported configs, prebuilts, etc
FORCE=$2
USFOUND=0

unsupported() {
    local TYPE="$1"
    printf -- "${RED}Unsupported configuration detected!\n\n"
    printf -- "${GREEN}Type:\n\n"
    printf -- "${WHITE}%s\n\n" "$TYPE"
    printf -- "${ENDCOLOR}"
}

if [[ "$FORCE" != "--force" ]]; then
    if grep .efi "$PLIST" | grep string | uniq | cut -d '<' -f2 | cut -d '>' -f2 | egrep -v 'requires' | grep -q 'run-efi-updater'; then
        unsupported "Prebuilt (OpCore Simplify)"
        USFOUND=1
    fi

    if grep -qiE 'MaLd0n|olarila' "$PLIST"; then
        unsupported "Prebuilt (Olarila)"
        USFOUND=1
    fi

    if grep -A2 Comment "$PLIST" | sort | uniq | cut -d '<' -f2 | cut -d '>' -f2 | egrep -v 'Contents|Extensions|/' | grep -q '^V[0-9]'; then
        unsupported "Configurator (OCAT/OCC)"
        USFOUND=1
    fi

    if [[ $USFOUND -eq 1 ]]; then
        exit 0
    fi
else
    printf -- "${YELLOW}Bypassing unsupported configuration checks (--force flag set)\n"
    printf -- "${GREEN}\n"
fi

# Setup all the various searches and parsings for the config
HEADERS=$(egrep 'key|string' "$PLIST" | sed -n '/ACPI/q;p' | cut -d \< -f2 | cut -d \> -f2 | sed '/^$/d')
DRIVERS=$(grep .efi "$PLIST" | grep string | uniq | cut -d \< -f2 | cut -d \> -f2 | egrep -v 'requires' | sort | grep -v 'run-efi-updater')
SSDTS=$(grep .aml "$PLIST" | uniq | cut -d \< -f2 | cut -d \> -f2 | egrep -v 'requires' | sort)
KEXTS=$(grep .kext "$PLIST" | sort | uniq | cut -d \< -f2 | cut -d \> -f2 | egrep -v 'Contents|Extensions|\/' | sort)
BOOTARGS=$(grep -A1 boot-arg "$PLIST" | head -n2 | tail -n1 | uniq | cut -d \< -f2 | cut -d \> -f2 | sed '/^$/d')
SMBIOS=$(egrep -A1 'MLB|ROM|SystemProductName|SystemSerialNumber|SystemUUID' "$PLIST" | uniq | cut -d \< -f2 | cut -d \> -f2 | sed '/^--$/d' | sed 's/MLB/Board ID/g' | sed 's/ROM/\nROM/g' | sed 's/SystemProductName/\nModel Name/g' | sed 's/SystemSerialNumber/\nSerial Number/g' | sed 's/SystemUUID/\nUUID/g')
FRAMEBUFFERS=$(egrep -A1 'framebuffer|AAPL,ig-platform-id' "$PLIST" | tr -d '[:blank:]' | cut -d \< -f2 | cut -d \> -f2 | sed '/^$/d')
SECUREBOOTMODEL=$(egrep -A1 'SecureBootModel' "$PLIST" | cut -d \< -f2 | cut -d \> -f2 | tail -n 1)
OPENCANOPYCHECK=$(grep -i OpenCanopy "$PLIST" | tail -n 1)
KEYBOARDLANGUAGESET=$(grep -A1 prev-lang:kbd "$PLIST" | egrep 'string|data' | cut -d \< -f2 | cut -d \> -f2 | sed 's/^$/'None'/g' | egrep -v 'backlight|prev-lang' | cut -d , -f2 | sed 's/ set /''/g' | grep -v 'run-efi-updater' | sed '/^$/d')
KEYBOARDLANGUAGESETSTRING=$(grep -A1 prev-lang:kbd "$PLIST" | egrep 'string|data' | grep -B1 kbd | head -n 1 | cut -d \< -f2 | cut -d \> -f1 | sed s/string/String/g | sed s/data/Data/g)

# Runs the plist through OCValidate
printf -- "OpenCore Validate Check (v$OCVALIDATEVERSION): ${WHITE}\n"
printf -- "\n"
$OCVALIDATE "$PLIST" | grep -v NOTE | sed '1{/^$/d;}' | sed $'1{/^$/d\n}'

# Checks the headers section of the file
printf -- "${GREEN}\n"
printf -- "Headers Section:\n"
printf -- "${GRAY}\n"
printf -- "$HEADERS\n"
printf -- "\n"

# Checks the drivers section of the file
printf -- "${GREEN}Drivers:\n"
printf -- "${GRAY}\n"
printf -- "$DRIVERS\n"
printf -- "\n"
printf -- "${RED}Total Drivers: " && echo "$DRIVERS" | wc -l | awk '{print $1}'
printf -- "\n"

# Checks the SSDTs in the file
printf -- "${GREEN}SSDTs:\n"
printf -- "${GRAY}\n"
printf -- "$SSDTS\n"
printf -- "\n"
printf -- "${RED}Total SSDTs: " && echo "$SSDTS" | wc -l | awk '{print $1}'
printf -- "\n"

# Checks the kexts in the file
printf -- "${GREEN}Kexts:\n"
printf -- "${GRAY}\n"
printf -- "$KEXTS\n"
printf -- "${RED}\n"
printf -- "Total kexts: " && echo "$KEXTS" | wc -l | awk '{print $1}'

# Checks the boot-args in the file, Converts the bootarg single line list into an array for counting and prints
printf -- "${GREEN}\n"
printf -- "boot-args:\n"
printf -- "${GRAY}\n"
read -ra ARG_ARRAY <<< "$BOOTARGS"
BOOTARGSCOUNT=${#ARG_ARRAY[@]}
printf -- "$BOOTARGS\n"
printf -- "${RED}\n"
printf -- "Total boot-args: $BOOTARGSCOUNT"
printf -- "${GREEN}\n"

# Checks for SMBIOS information in the file
printf -- "${GREEN}\n"
printf -- "SMBIOS:\n"
printf -- "${GRAY}\n"
printf -- "$SMBIOS\n"
printf -- "${GREEN}\n"

# Checks for framebuffer info in the file
printf -- "Framebuffers:\n"
printf -- "${GRAY}\n"
printf -- "$FRAMEBUFFERS\n"
printf -- "${GREEN}\n"

# Checks the state of SecureBootModel
printf -- "Secure Boot Model:\n"
printf -- "${GRAY}\n"
printf -- "$SECUREBOOTMODEL\n"
printf -- "${GREEN}\n"

# Checks if OpenCanopy is enabled/disabled
printf -- "Open Canopy:\n"
printf -- "${GRAY}\n"
if [[ $OPENCANOPYCHECK =~ (OpenCanopy.efi) ]]; then
    printf -- "Enabled\n"
else
    printf -- "Disabled\n"
fi
printf -- "${GREEN}\n"

# Checks for the correct keyboard and language defaults for the installer
printf -- "Keyboard Language Set:\n"
printf -- "${GRAY}\n"
printf -- "$KEYBOARDLANGUAGESET\n"
printf -- "${GREEN}\n"
printf -- "Keyboard Language Field Type:\n"
printf -- "${GRAY}\n"
printf -- "$KEYBOARDLANGUAGESETSTRING\n"
printf -- "\n"
printf -- "${ENDCOLOR}"
