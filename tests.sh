#!/bin/bash

function tester() {
  DESCRIPTION=${1}
  COMMAND=${2}

  if ( `eval ${COMMAND}` ); then
    echo -e "[\e[32mSUCCESS\e[39m] ${DESCRIPTION}"
  else
    echo -e "[\e[31mFAILED\e[39m] ${DESCRIPTION}"
  fi
}

echo "Verify whether Postfix correctly (in)validates domain names:"
tester "Domain 'example.org' exists" \
        "test 1 -eq `postmap -q example.org mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf`"
tester "Domain 'example.com' not exists" \
        "test -z `postmap -q example.com mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf`"

echo ""

echo "Verify whether Postfix correctly (in)validates email addresses:"
tester "User account 'john.doe@example.org' exists" \
        "test 1 -eq `postmap -q john.doe@example.org mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf`"
tester "User account 'jane.doe@example.org' not exists" \
        "test -z `postmap -q jane.doe@example.org mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf`"

echo ""

echo "Verify whether Postfix correctly resolves aliases:"
tester "Alias 'jane.doe@example.org' forwards to 'john.doe@example.org'" \
        "test john.doe@example.org = `postmap -q jane.doe@example.org mysql:/etc/postfix/mysql-virtual-alias-maps.cf`"
tester "Catch-all alias '@example.org' forwards to 'jack.doe@example.org'" \
        "test jack.doe@example.org = `postmap -q @example.org mysql:/etc/postfix/mysql-virtual-alias-maps.cf`"
tester "No alias for 'foo.bar@example.com'" \
        "test -z `postmap -q foo.bar@example.com mysql:/etc/postfix/mysql-virtual-alias-maps.cf`"

echo ""

echo "Verify whether Postfix correctly resolves mail2mail requests:"
tester "'john.doe@example.org' exists" \
        "test john.doe@example.org = `postmap -q john.doe@example.org mysql:/etc/postfix/mysql-email2email.cf`"
tester "'jane.doe@example.org' not exists" \
        "test -z `postmap -q jane.doe@example.org mysql:/etc/postfix/mysql-email2email.cf`"
