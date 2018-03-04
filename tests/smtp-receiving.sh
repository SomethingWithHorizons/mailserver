#!/bin/bash

MAIL_SERVER_IP=${1}

function tester() {
  DESCRIPTION=${1}
  COMMAND=${2}

  if [ -n "`eval ${COMMAND}`" ]; then
    echo -e "[\e[32mSUCCESS\e[39m] ${DESCRIPTION}"
  else
    echo -e "[\e[31mFAILED\e[39m] ${DESCRIPTION}"
  fi
}

if [ ! `command -v swaks` ]; then
  echo "Make sure that 'swak' is installed."
  exit
fi

if [ -z ${MAIL_SERVER_IP} ]; then
  echo "Mailserver IP address should be specified, you can get this address by using 'ip address'"
  exit
fi

echo " " > /var/log/mail.log
echo " " > /var/log/mail.err
echo " " > /var/log/mail.info

tester "Test whether e-mails to a known user / known domain combination gets accepted" \
        "swaks --to john.doe@example.org --server ${MAIL_SERVER_IP} | grep '250 2.0.0 Ok: queued as'"
# RISKY TEST (race condition)
#tester "Test whether the known, specific, alias correctly got resolved" \
#       "grep 'to=<john.doe@example.org>, orig_to=<jane.doe@example.org>' /var/log/mail.log"

tester "Test whether e-mails to a known, catchall alias get accepted" \
        "swaks --to catchall@example.org --server ${MAIL_SERVER_IP} | grep '250 2.0.0 Ok: queued as'"
# RISKY TEST (race condition)
#tester "Test whether the known catch-all alias correctly got resolved" \
#        "grep 'to=<jack.doe@example.org>, orig_to=<catchall@example.org>' /var/log/mail.log"

tester "Test whether e-mails to a known user/unknown domain combination get rejected" \
        "swaks --to john.doe@unknowndomain.org --server ${MAIL_SERVER_IP} | grep '454 4.7.1 <john.doe@unknowndomain.org>: Relay access denied'"
tester "Test whether e-mails addressed to a known, specific, alias get accepted" \
        "swaks --to jane.doe@example.org --server ${MAIL_SERVER_IP} | grep '250 2.0.0 Ok: queued as'"

echo ""

echo "Removing catch-all alias from database"
mysql -e"DELETE FROM \`mailserver\`.\`aliases\` WHERE \`source\` = '@example.org';"

tester "Test whether e-mails to an unknown user / known domain get rejected" \
        "swaks --to unknownuser@example.org --server ${MAIL_SERVER_IP} | grep '550 5.1.1 <unknownuser@example.org>: Recipient address rejected: User unknown in virtual mailbox table'"

echo "Restoring catch-all alias in database"
mysql -e"INSERT INTO \`mailserver\`.\`aliases\` (\`domain\`, \`source\`, \`destination\`) VALUES ('example.org', '@example.org', 'jack.doe@example.org');"
