#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

BASEURL="demo.publicknowledgeproject.org/ojs3/testdrive"     # Replace with your base_url
JOURNAL="testdrive-journal"                                  # Replace with your journal's slug

# BASEURL="ada-revista01.precarietat.net"
# JOURNAL="revista01"

# Initialize variables
errors=0
notFound=0
valid=0
active=0
redirected=0
unauthorized=0
unknown=0
count=1

# Check if the url is valid or not.
check_url() {
    url=$1
    comment=$2

    response_code=$(curl -ks -o /dev/null -w "%{http_code}" "$url")
    formatted_count=$(printf "%02d" $count)

    case $response_code in
        # Not Found are errors
        404)
            echo -e "${formatted_count} --> ${RED}INVALID${NC} - Not Found"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((errors++))
            ((notFound++))
            ;;
        # Active are valid
        200)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Active"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ((active++))
            ;;
        # Unauthorized are valid
        403)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Unauthorized"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ((unauthorized++))
            ;;
        # Permanent redirections are valid
        301 | 308)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Permanent redirection"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ((redirected++))
            ;;
        # Temporal redirections are valid
        302 | 303 | 307)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Temporal redirection"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ((redirected++))
            ;;
        # Anything else is Unknown and are invalid.
        *)
            echo -e "${formatted_count} --> ${RED}UNKNOWN${NC} - Need to be checked"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((errors++))
            ((unknown++))
            ;;
    esac
    ((count++))
}

# Lists of OJS entrypoints (work in progress).
# Use the one you like to test as first argument in the script call.

# Common list of urls as OJS works "out of the box". Any OJS site sould pass this basic test.
listBasic=(
  "https://$BASEURL"                                                             	"Main page (usually redirected)"
  "https://$BASEURL/index.php"                                                   	"Main page destination (explicit)"
  "https://$BASEURL/index.php/index"                                                    "OJS site's index (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/about"                                           "Example of journal's verbs (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"  'Call including $$$call$$$ (explicit)'
  "https://$BASEURL/index.php/$JOURNAL/api/v1/contexts/1"                               "Entrypoint for API in journal (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/oai"                                             "Entrypoint for OAI in journal (explicit)"
  "https://$BASEURL/index.php/index/install/install"                                    "Installation entrypoint (explicit and redirected once installed)"
)

# DOMain or subdomain install with RESTful and MULTI-tenant site (unconfirmed list)
listDomRestMulti=(
  "https://$BASEURL"                                                             "Main page (usually redirected)"
  "https://$BASEURL/index"                                                       "OJS site's index"
  "https://$BASEURL/$JOURNAL/about"                                              "Example of journal's verbs"
  "https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"     'Call including $$$call$$$'
  "https://$BASEURL/$JOURNAL/api/v1/contexts/1"                                  "Entrypoint for API in journal"
  "https://$BASEURL/$JOURNAL/oai"                                                "Entrypoint for OAI in journal"
  "https://$BASEURL/index/install/install"                                       "Installation path (redirected when installed)"
)

# DOMain or subdomain install with RESTful and SINGLE-tenant installation (unconfirmed list)
listDomRestSingle=(
  "https://$BASEURL"                                                             "Main page (usually redirected)"
  "https://$BASEURL/index.php"                                                 	 "Main page destination (explicit)"
  "https://$BASEURL/index"                                                       "OJS site's index"
  "https://$BASEURL/$JOURNAL/about"                                              "Example of journal's verbs"
  "https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"     'Call including $$$call$$$'
  "https://$BASEURL/$JOURNAL/api/v1/contexts/1"                                  "Entrypoint for API in journal"
  "https://$BASEURL/$JOURNAL/oai"                                                "Entrypoint for OAI in journal"
  "https://$BASEURL/index/install/install"                                       "Installation path (redirected when installed)"
  "https://$BASEURL/admin"                                                       "Single-tenant: Admin page (if defined in base_url[index]"
  "https://$BASEURL/api/v1/contexts/1"                                           "Single-tenant: Entrypoint for API in site"
  "https://$BASEURL/oai"                                                         "Single-tenant: Entrypoint for OAI in site"
)

urlList=''

# Select URLs list based on parameter
case ${1} in
    basic)
        urlList=("${listBasic[@]}")
    ;;
    domNorestMulti)
        urlList=("${listDomRestMulti[@]}")
    ;;
    domRestSingle)
        urlList=("${listDomRestSingle[@]}")
    ;;
    *)
        echo "Sytnax: ./pkpCheckUrls.sh listNoRestMulti"
        echo ""
        echo "Please provide a valid set of urls to test. Existing options are:"
        echo "- [basic] Usual set of urls ANY site should pass. Rules defined for domain or subdomain. No Restful, Multi-tenant. With JOURNAL slug."
        echo "- [domNorestMulti] Set of urls for: Domain or subdomain. No Restful. Multi-tenant. With JOURNAL slug."
        echo "- [domRestSingle] Set fo urls for: Domain or subdomain. Restfull. Single-tenant. Without JOURNAL slug."
        echo ""
        echo "You can run the script multiple times with different sets on same journal to discover how resilent is it."
        exit 1
    ;;
esac

echo ""
echo "Base URL:           $BASEURL"
echo "Journal's context:  $JOURNAL"
echo ""

for ((i = 0; i < ${#urlList[@]}; i += 2)); do
    check_url "${urlList[i]}" "${urlList[i+1]}"
done

# Summarize and show results
echo ""
echo    "===========================================SUMMARY OF YOUR URL's HEALTH ====================================================="
if [ $valid -gt 0 ]; then
    echo -e "  [${GREEN}VALID:${NC} $valid]        Includes:  Active, Unauthorized and Redirected urls."
    echo    "    - Active:       $active - Active are final pages returning a valid 200 status code."
    echo    "    - Redirections: $redirected - Redirected url are usually valid, but url destination need to be add to the list and checked too."
    echo    "    - Unauthorized: $unauthorized - Unauthorized pages are valid endpoints requesting for authorization."
fi
if [ $errors -gt 0 ]; then
    echo -e "  [${RED}ERRORS${NC}: $errors]        Includes: notFound and other unknown codes. They should be fixed."
    echo    "  - Not Found: $noFound - When an url is Not Found usually means your site is missconfigurated."
    echo    "  - Unknown:   $unknown - URLs that returned an unexpected code are considered errors and need a detailed review."
fi
echo    "-----------------------------------------------------------------------------------------------------------------------------"

if [ $errors -eq 0 ]; then
  echo -e "  ${GREEN}RESULT: Looks like your URLs are healthy.${NC}"
else
  echo -e "  ${RED}RESULT: There are $errors errors in your URLs that probably need to be fixed.${NC}"
fi
echo "============================================================================================================================="
