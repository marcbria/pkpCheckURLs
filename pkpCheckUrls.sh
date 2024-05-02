#!/bin/bash

# Arguments
pType=${1}          # Type of test (see generateUrlList)
pServers=${2}       # List of servers to test.

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Initialize variables
BASEURL="demo.publicknowledgeproject.org/ojs3/testdrive"
JOURNAL="testdrive-journal"
ADMINURL="demo.publicknowledgeproject.org/ojs3/testdrive"


# Set all counters to it's initial value.
initializeCounters() {
    declare -g \
        errors=0 \
        notFound=0 \
        valid=0 \
        active=0 \
        redirected=0 \
        unauthorized=0 \
        unknown=0 \
        count=1
}

# Check if the url is valid or not.
# - url: Adress to be checked.
# - comment: Explanations about the adress.
checkUrl() {
    url=$1
    comment=$2

    # Get the response code of the first URL
    initialResponseCode=$(curl -ks -o /dev/null -w "%{http_code}" "$url")

    # Get the final URL and the response code after following all redirects
    finalUrl=$(curl -ksSL -o /dev/null -w "%{url_effective}" "$url")
    finalResponseCode=$(curl -ks -o /dev/null -w "%{http_code}" "$finalUrl")

    formattedCount=$(printf "%02d" $count)

    case $finalResponseCode in
        # Not Found are errors
        404)
            echo -e "${formattedCount} --> ${RED}INVALID${NC} - Not Found"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((errors++))
            ((notFound++))
            ;;
        # Active are valid
        200)
            echo -e "${formattedCount} --> ${GREEN}VALID${NC} - Active"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((valid++))
            ((active++))
            ;;
        # Unauthorized are valid
        403)
            echo -e "${formattedCount} --> ${GREEN}VALID${NC} - Unauthorized"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((valid++))
            ((unauthorized++))
            ;;
        # Permanent redirections are valid
        301 | 308)
            echo -e "${formattedCount} --> ${GREEN}VALID${NC} - Permanent redirection"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((valid++))
            ((redirected++))
            ;;
        # Temporal redirections are valid
        302 | 303 | 307)
            echo -e "${formattedCount} --> ${GREEN}VALID${NC} - Temporal redirection"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((valid++))
            ((redirected++))
            ;;
        # Anything else is Unknown and are invalid.
        *)
            echo -e "${formattedCount} --> ${RED}UNKNOWN${NC} - Need to be checked"
	        echo -e "       URL Type: $comment"
            echo -e "       First Response: $initialResponseCode: $url"
	        echo -e "       Last response:  $finalResponseCode: $finalUrl"
            ((errors++))
            ((unknown++))
            ;;
    esac
    ((count++))
}


# Shows the type of text that is going to be performed.
displayTestInfo() {
    echo "===================================================== TESTING ================================================================"
    echo "  Base URL:           $BASEURL"
    echo "  Type of test:       $pType"
    echo "===================================================== TESTING ================================================================"
    echo ""
}

# Function to display tests results summary
displaySummary() {

    # Summarize and show results
    echo ""
    echo "=========================================== SUMMARY OF YOUR URL's HEALTH ====================================================="
    echo ""
    echo "  Base URL:           $BASEURL"
    echo "  Journal's context:  $JOURNAL"
    echo "  Base[index] URL:    $ADMINURL"
    echo ""

    if [ $valid -gt 0 ]; then
        echo -e "  [${GREEN}VALID:${NC} $valid]"
        echo    "    - Active:       $active - Active are final pages returning a valid 200 status code."
        echo    "    - Redirections: $redirected - Redirected url are usually valid, but url destination need to be add to the list and checked too."
        echo    "    - Unauthorized: $unauthorized - Unauthorized pages are valid endpoints requesting for authorization."
    fi
    if [ $errors -gt 0 ]; then
        echo -e "  [${RED}ERRORS${NC}: $errors]"
        echo    "    - Not Found:    $notFound - When an url is Not Found usually means your site is missconfigurated."
        echo    "    - Unknown:      $unknown - URLs that returned an unexpected code are considered errors and need a detailed review."
    fi
    echo    "-----------------------------------------------------------------------------------------------------------------------------"

    if [ $errors -eq 0 ]; then
        echo -e "  ${GREEN}RESULT: Looks like your URLs are healthy.${NC}"
    else
        echo -e "  ${RED}RESULT: There are $errors errors in your URLs that probably need to be fixed.${NC}"
    fi
    echo "============================================================================================================================="
    echo ""
    echo ""
}


# Generate a list of URLs to be tested based on params.
# The lists of OJS endpoints need to be validated by PKP (work in progress).
# Use the one you like to test as first argument in the script call.
# Documentation: https://docs.pkp.sfu.ca/dev/api/ojs/3.4#tag/Access
# - listType: Type of list you like to generate
# - urlListRef: Variable to return the generated array.
generateUrlList() {
    local listType="$1"
    declare -n urlListRef="$2"

    case ${listType} in

      # Essential list of urls that any OJS should pass.
      # This list of urls as OJS works "out of the box".
      # Rules for domain, explicit index.php (no RESTful), mutli-tenant, https and httpS.
      basic)
        urlListRef=(
        "http://$BASEURL/index.php"                                                   	"HTTP is defined (explicit and hopefully redirected to HTTPS)"
        "http://$BASEURL"                                                           	"HTTP is defined for home (redirected to index.php with HTTPS)"
        "https://$BASEURL"                                                             	"Main page (usually redirected)"
        "https://$BASEURL/index.php"                                                   	"Main page destination (explicit)"
        "https://$BASEURL/index.php/index"                                                    "OJS site's index (explicit)"
        "https://$BASEURL/index.php/$JOURNAL/about"                                           "Example of journal's verbs (explicit)"
        "https://$BASEURL/index.php/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"  'Call including $$$call$$$ (explicit)'
        "https://$BASEURL/index.php/$JOURNAL/oai"                                             "Journal  OAI endpoint (explicit)"
        "https://$BASEURL/index.php/index/oai"                                                "Sitewide OAI endpoint (explicit)"
        "https://$BASEURL/index.php/$JOURNAL/api/v1/contexts/1"                               "Journal  API endpoint (explicit)"
        "https://$BASEURL/index.php/_/api/v1/contexts/1"                                      "Sitewide API endpoint for OJS 3.4 (explicit)"
        "https://$BASEURL/index.php/index/install/install"                                    "Installation endpoint (explicit and redirected once installed)"
        #  "https://${ADMINURL}/$JOURNAL/index.php/index/admin"                                  "Journal  Admin's base pages (explicit)"
        "https://${ADMINURL}/index.php/index/admin"                                           "Sitewide Admin's base pages (explicit)"
        )
      ;;

      restful)
        # DOMain or subdomain, RESTful, journalSlug in a MULTI-tenant site (unconfirmed list)
        urlListRef=(
        "https://$BASEURL/index"                                                              "OJS site's index (RESTful)"
        "https://$BASEURL/$JOURNAL/about"                                                     "Example of journal's verbs (RESTful)"
        "https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"            'Call including $$$call$$$ (RESTful)'
        "https://$BASEURL/$JOURNAL/oai"                                                       "Journal  OAI endpoint (RESTful)"
        "https://$BASEURL/index/oai"                                                          "Sitewide OAI endpoint (RESTful)"
        "https://$BASEURL/$JOURNAL/api/v1/contexts/1"                                         "Journal  API endpoint (RESTful)"
        "https://$BASEURL/_/api/v1/contexts/1"                                                "Sitewide API new 3.4 endpoint (RESTful)"
        "https://$BASEURL/index/install/install"                                              "Installation endpoint (RESTful and redirected)"
        #   "https://${ADMINURL}/$JOURNAL/index/admin"                                            "Journal  Admin's base pages (explicit)"
        "https://${ADMINURL}/index/admin"                                                     "Sitewide Admin's base pages (RESTful)"
        )
      ;;

      noslug)
        # DOMain or subdomain, RESTful, NO journalSlug in a SINGLE-tenant site (unconfirmed list)
        urlListRef=(
        "https://$BASEURL/about"                                                              "Example of journal's verbs (RESTful & noSlug)"
        "https://$BASEURL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"                     'Call including $$$call$$$ (RESTful & noSlug)'
        "https://$BASEURL/oai"                                                                "Journal  OAI endpoint (RESTful & noSlug)"
        "https://${ADMINURL}/index/oai"                                                       "Sitewide Admin's base pages (RESTful & noSlug)"
        "https://$BASEURL/admin/index/oai"                                                    "Sitewide OAI endpoint (RESTful & noSlug)"
        "https://$BASEURL/api/v1/contexts/1"                                                  "Journal  API endpoint (RESTful & noSlug)"
        "https://${ADMINURL}/index/admin"                                                     "Sitewide Admin's base pages (RESTful & noSlug)"
        )
      ;;
    esac

}


# Select URLs list based on parameter
# case ${1} in
#     basic)
#         urlList=("${listBasic[@]}")
#     ;;
#     restful)
#         urlList=("${listRestful[@]}")
#     ;;
#     noslug)
#         urlList=("${listNoslug[@]}")
#     ;;
#     *)
#         echo "Sytnax: ./pkpCheckUrls.sh basic"
#         echo ""
#         echo "Please provide a valid set of urls to test. Existing options are:"
#         echo "- [basic] Usual set of urls ANY site should pass. Rules defined for domain or subdomain. No Restful, Multi-tenant. With JournalSlug."
#         echo "- [restful] Set of urls for: Domain or subdomain. Restful. Multi-tenant. With JournalSlug."
#         echo "- [noslug] Set fo urls for: Domain or subdomain. Restfull. Single-tenant. Without JournalSlug."
#         echo ""
#         echo "You can run the script multiple times with different sets on same journal to discover how resilent is it."
# 	    echo "Right now sets are acumulative: if you wanto to set your wit with [noslug], you should pass first [basic] and [rest] sets."
#         exit 1
#     ;;
# esac


# If an external file is provided as argument
if [ $# -eq 2 ]; then
    # Check if the provided file exists
    if [ -f "$pServers" ]; then
        # Read each line of the file
        while IFS=, read -r line; do

            # Check if the line does not start with "#", if yes, process it
            if [[ ! "$line" == \#* ]]; then

                # Show test info
                displayTestInfo

                # Split the line into variables
                IFS=',' read -r BASEURL JOURNAL ADMINURL <<< "$line"

                # Builds a list of url to check based on the type of test and journal params.
                generateUrlList "$pType" urlList

                # Initialize all counters before the test
                initializeCounters

                # Iterate the generated list
                for ((i = 0; i < ${#urlList[@]}; i += 2)); do
                    checkUrl "${urlList[i]}" "${urlList[i+1]}"
                done

                # Show the summary of results
                displaySummary

            fi
        done < "$pServers"
    else
        echo "Error: File $pServers not found."
        exit 1
    fi
else

    # If no external file is provided, apply the test to this site:
    BASEURL="demo.publicknowledgeproject.org/ojs3/testdrive"
    JOURNAL="testdrive-journal"
    ADMINURL="demo.publicknowledgeproject.org/ojs3/testdrive"

    # Show test info
    displayTestInfo

    # Builds a list of url to check based on the type of test and journal params.
    generateUrlList "$pType" urlList

    # Initialize all counters before the test
    initializeCounters

    # Iterate the generated list
    for ((i = 0; i < ${#urlList[@]}; i += 2)); do
        checkUrl "${urlList[i]}" "${urlList[i+1]}"
    done

    # Show the summary of results
    displaySummary
fi

