#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

BASEURL="demo.publicknowledgeproject.org/ojs3/testdrive"     # Replace with your base_url
JOURNAL="testdrive-journal"                                  # Replace with your journal's slug

BASEURL="ada-revista01.precarietat.net"
JOURNAL="revista01"

# Initialize variables
errors=0
valid=0
redirected=0
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
            ;;
        # Active are valid
        200)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Active"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ;;
        # Unauthorized are valid
        403)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Unauthorized"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((valid++))
            ;;
        # Permanent redirections are valid
        301 | 308)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Permanent redirection"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((redirected++))
            ((valid++))
            ;;
        # Temporal redirections are valid
        302 | 303 | 307)
            echo -e "${formatted_count} --> ${GREEN}VALID${NC} - Temporal redirection"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((redirected++))
            ((valid++))
            ;;
        # Anything else is Unknown and are invalid.
        *)
            echo -e "${formatted_count} --> ${RED}UNKNOWN${NC} - Need to be checked"
	    echo -e "       URL Type: $comment"
            echo -e "       Response: $response_code: $url"
            ((unknown++))
            ((errors++))
            ;;
    esac
    ((count++))
}

# Lists of OJS entrypoints (work in progress).
# Use the one you like to test as first argument in the script call.
#
# Existing options are:
# - listNoRestMulti: No Restful. Multi-tenant.
# - listRestSingle: Restfull. Single-tenant.

# No Restful and multi-tenant installation
listNoRestMulti=(
  "https://$BASEURL/index.php"                                                   "Main page (usually redirected)"
  "https://$BASEURL"                                                             "Main page (usually redirected)"
  "https://$BASEURL/index"                                                       "OJS site's index"
  "https://$BASEURL/$JOURNAL/about"                                              "Example of journal's verbs"
  "https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"     'Call including $$$call$$$'
  "https://$BASEURL/$JOURNAL/api/v1/contexts/1"                                  "Entrypoint for API in journal"
  "https://$BASEURL/$JOURNAL/oai"                                                "Entrypoint for OAI in journal"
  "https://$BASEURL/index/install/install"                                       "Installation path (redirected when installed)"
)

# Restful and single-tenant installation (untested list)
listRestSingle=(
  "https://$BASEURL"                                                             "Main page (usually redirected)"
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
if [[ "$1" == "listNoRestMulti" ]]; then
    urlList=("${listNoRestMulti[@]}")
elif [[ "$1" == "listRestSingle" ]]; then
    urlList=("${listRestSingle[@]}")
else
    echo "Inexistent or invalid parameter."
    echo "Sytnax: ./pkpCheckUrls.sh listNoRestMulti"
    echo ""
    echo "Please provide a valid set of urls to test like:"
    echo "- listNoRestMulti: Check NO RESTful and MULTI tenant site."
    echo "- listRestSingle: Check RESTful and SINGLE tenant site."
    exit 1
fi

echo ""
for ((i = 0; i < ${#urlList[@]}; i += 2)); do
    check_url "${urlList[i]}" "${urlList[i+1]}"
done

# Summarize and show results
echo ""
echo    "===========================================SUMMARY OF YOUR URL's HEALTH ====================================================="
if [ $valid -gt 0 ]; then
    echo -e "- ${GREEN}VALID:${NC} $valid" - Active, Unauthorized and Redirected urls are Valid.
    echo    "  - Redirect: $redirected - Redirected url are usually valid, but url destination need to be add to the list and checked too."
fi
if [ $errors -gt 0 ]; then
    echo -e "- ${RED}ERRORS${NC}: $errors - Errors NEED that be fixed. Errors include notFound and other unknown codes."
    echo    "  - Unknown: $unknown - URLs that returned an unexpected code and need a detailed review. Considered errors."
fi
echo    "============================================================================================================================="

if [ $errors -eq 0 ]; then
  echo -e "${GREEN}RESULT: Looks like your URLs are healthy.${NC}"
else
  echo -e "${RED}RESULT: There are $errors errors in your URLs that probably need to be fixed.${NC}"
fi
echo "============================================================================================================================="
