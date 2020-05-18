#!/bin/bash -u
#
# See https://nmap.org/book/ndiff-man-periodic.html
#
# TARGETS should be set by env variable
# MAILTO should be set by env variable
# INTERVAL how many seconds to wait between runs, default to 86400

# Check if mandatory environment variables are set
: ${TARGETS?"You need to set TARGETS environment variable (space separated list of servers to scan)."}
: ${MAILTO?"You need to set the MAILTO environment variable (email to send diffs to)."}
: ${SMTP_HOST?"You need to set the SMTP_HOST environment variable."}
: ${SMTP_PORT?"You need to set the SMTP_PORT environment variable."}
: ${SMTP_USER?"You need to set the SMTP_USER environment variable."}
: ${SMTP_PASS?"You need to set the SMTP_PASS environment variable."}
: ${SMTP_FROM?"You need to set the SMTP_FROM environment variable."}

# Default sleep interval to 1 day (86400 seconds)
INTERVAL=${INTERVAL:-86400}

# Default nmap options to -PN
OPTIONS=${OPTIONS:--PN}

# Configure msmtprc
cat << EOF > /etc/msmtprc
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
syslog on
account default
host $SMTP_HOST
port $SMTP_PORT
auth on
user $SMTP_USER
password $SMTP_PASS
from $SMTP_FROM
EOF

# Send an email to inform that the nmap scan has started
mail -s "Starting nmap scan diff for ${TARGETS}" ${MAILTO} < /dev/null

cd /results
LAST_RUN_FILE='.lastrun'

while true; do

    # If the last run file exists, we should only sleep for the time
    # specified minus the time that's already elapsed.
    if [ -e "${LAST_RUN_FILE}" ]; then
        LAST_RUN_TS=$(date -r ${LAST_RUN_FILE} +%s)
        NOW_TS=$(date +%s)
        LAST_RUN_SECS=$(expr ${NOW_TS} - ${LAST_RUN_TS})
        SLEEP=$(expr ${INTERVAL} - ${LAST_RUN_SECS})
        if [ ${SLEEP} -gt 0 ]; then
            UNTIL_SECS=$(expr ${NOW_TS} + ${SLEEP})
            echo $(date) "- sleeping until" $(date --date="@${UNTIL_SECS}") "(${SLEEP}) seconds"
            sleep ${SLEEP}
        fi
    fi

    START_TIME=$(date +%s)
    echo $(date) '- starting all targets, options: ' ${OPTIONS}
    echo '=================='

    DATE=`date +%Y-%m-%d_%H-%M-%S`
    for TARGET in ${TARGETS}; do
        CUR_LOG=scan-${TARGET/\//-}-${DATE}.xml
        PREV_LOG=scan-${TARGET/\//-}-prev.xml
        DIFF_LOG=scan-${TARGET/\//-}-diff

        echo
        echo $(date) "- starting ${TARGET}"
        echo "------------------"

        # Scan the target
        nmap ${OPTIONS} ${TARGET} -oX ${CUR_LOG}

        # If there's a previous log, diff it
        if [ -e ${PREV_LOG} ]; then

            # Exclude the Nmap version and current date - the date always changes
            ndiff ${PREV_LOG} ${CUR_LOG} | egrep -v '^(\+|-)Nmap ' > ${DIFF_LOG}
            if [ -s ${DIFF_LOG} ]; then
                # The diff isn't empty, show it on screen for docker logs and email it
                echo 'Emailing diff log:'
                cat ${DIFF_LOG}
                cat ${DIFF_LOG} | mail -s "nmap scan diff for ${TARGET}" ${MAILTO}

                # Set the current nmap log file to reflect the last date changed
                ln -sf ${CUR_LOG} ${PREV_LOG}
            else
                # No changes so remove our current log
                rm ${CUR_LOG}
            fi
            rm ${DIFF_LOG}
        else
            # Create the previous scan log
            ln -sf ${CUR_LOG} ${PREV_LOG}
        fi
    done

    touch ${LAST_RUN_FILE}
    END_TIME=$(date +%s)
    echo
    echo $(date) "- finished all targets in" $(expr ${END_TIME} - ${START_TIME}) "second(s)"
done
