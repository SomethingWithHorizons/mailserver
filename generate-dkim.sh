#!/bin/bash

# Default values
BITS="2048"
SELECTOR="mail"

for i in "$@"
do
case $i in
    --domain=*)
    DOMAIN="${i#*=}"
    shift
    ;;
    --bits=*)
    BITS="${i#*=}"
    shift
    ;;
    --selector=*)
    SELECTOR="${i#*=}"
    shift
    ;;
    *)
    ;;
esac
done

if [ ! `command -v opendkim-genkey` ]; then
   echo "Tool 'opendkim-genkey' doesn't seem to be installed. You can install this by installing the 'opendkim-tools' package."

   exit 1
fi

if [ -z "${DOMAIN}" ]; then
   echo "A domain must be specified with '--domain', e.g. '--domain=example.org'."

   exit 1
fi

# Create a temporary directory where the opendkim generated files will be stored
cd `mktemp -d`

# Generate a DKIM key for specified domain
echo "Generating DKIM key for '${DOMAIN}'..."
opendkim-genkey --restrict --bits=${BITS} --selector=${SELECTOR} --domain=${DOMAIN}

# Put the generated file contents in variables
PRIVATE_KEY=`cat ${SELECTOR}.private`
PUBLIC_DNS=`cat ${SELECTOR}.txt | tr -d '\n'`

PUBLIC_KEY=`echo ${PUBLIC_DNS} | sed 's/" "//g' | cut -d '"' -f2`
STRIPPED_PRIVATE_KEY=`cat ${SELECTOR}.private | tr -d '\n' | sed 's/-----\(BEGIN\|END\) RSA PRIVATE KEY-----//g'`

mysql -e"INSERT INTO \`mailserver\`.\`dkim\` (\`domain\`, \`selector\`, \`private_key\`, \`public_key\`) VALUES ('${DOMAIN}', '${SELECTOR}', '${STRIPPED_PRIVATE_KEY}', '${PUBLIC_KEY}') ON DUPLICATE KEY UPDATE \`private_key\` = '${STRIPPED_PRIVATE_KEY}', \`public_key\` = '${PUBLIC_KEY}';"

echo -e "\nThe keys are succesfully generated!"
echo -e "Please create/update a TXT record with host '${SELECTOR}._domainkey' containing:"
echo -e "\n${PUBLIC_KEY}"
