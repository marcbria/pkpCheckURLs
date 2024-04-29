#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

BASEURL="demo.publicknowledgeproject.org/ojs3/testdrive"     # Replace with your base_url
JOURNAL="testdrive-journal"                                  # Replace with your journal's slug

# Additional examples (could be dissabled)
#
# BASEURL="ada-revista01.precarietat.net"	# Dockerized with http behind a reverse proxy.
# JOURNAL="revista01"				# Single-tenant: Subdomain, RESTful with journalSlug.
# 
# BASEURL="papers.uab.cat"			# Dockerized with http behind a reverse proxy.
# JOURNAL="papers"				# Single-tenant: Subdomain, RESTful, NO journalSlug.
#
# BASEURL="revistes.uab.cat/brumal"		# Dockerized with http behind a reverse proxy.
# JOURNAL="brumal"				# Single-tenant: Folder, RESTful, NO journalSlug.
#
# BASEURL="ada-revista03.precarietat.net"	# Dockerized with http behind a reverse proxy.
# JOURNAL="revista03"				# Single-tenant: Subdomain, RESTful with journalSlug.

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
checkUrl() {
    url=$1
    comment=$2

    # Get the response code of the first URL
    initialResponseCode=$(curl -ks -o /dev/null -w "%{http_code}" "$url")

    # Get the final URL and the response code after following all redirects
    finalUrl=$(curl -sSL -o /dev/null -w "%{url_effective}" "$url")
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

# Lists of OJS entrypoints (work in progress).
# Use the one you like to test as first argument in the script call.
# Documentation: https://docs.pkp.sfu.ca/dev/api/ojs/3.4#tag/Access

# Common list of urls as OJS works "out of the box". Any OJS site sould pass this basic test.
# Rules for domain, explicit index.php (no RESTful), mutli-tenant, https and httpS.
listBasic=(
  "http://$BASEURL/index.php"                                                   	"HTTP is defined (explicit and hopefully redirected to HTTPS)"
  "http://$BASEURL"                                                           	        "HTTP is defined for home (redirected to index.php with HTTPS)"
  "https://$BASEURL"                                                             	"Main page (usually redirected)"
  "https://$BASEURL/index.php"                                                   	"Main page destination (explicit)"
  "https://$BASEURL/index.php/index"                                                    "OJS site's index (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/about"                                           "Example of journal's verbs (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"  'Call including $$$call$$$ (explicit)'
  "https://$BASEURL/index.php/$JOURNAL/oai"                                             "Entrypoint for OAI at journal (explicit)"
  "https://$BASEURL/index.php/index/oai"                                                "Entrypoint for OAI at site-wide (explicit)"
  "https://$BASEURL/index.php/$JOURNAL/api/v1/contexts/1"                               "Entrypoint for API at journal (explicit)"
  "https://$BASEURL/index.php/_/api/v1/contexts/1"                                      "New 3.4 entrypoint for API at site-wide (explicit)"
  "https://$BASEURL/index.php/index/install/install"                                    "Installation entrypoint (explicit and redirected once installed)"
)

# DOMain or subdomain, RESTful, journalSlug in a MULTI-tenant site (unconfirmed list)
listRestful=(
  "https://$BASEURL/index"                                                              "OJS site's index (RESTful)"
  "https://$BASEURL/$JOURNAL/about"                                                     "Example of journal's verbs (RESTful)"
  "https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"            'Call including $$$call$$$ (RESTful)'
  "https://$BASEURL/$JOURNAL/oai"                                                       "Entrypoint for OAI at journal (RESTful)"
  "https://$BASEURL/index/oai"                                                          "Entrypoint for OAI at site-wide (RESTful)"
  "https://$BASEURL/$JOURNAL/api/v1/contexts/1"                                         "Entrypoint for API at journal (RESTful)"
  "https://$BASEURL/_/api/v1/contexts/1"                                                "New 3.4 entrypoint for API at site-wide (RESTful)"
  "https://$BASEURL/index/install/install"                                              "Installation entrypoint (RESTful and redirected)"
)

# DOMain or subdomain, RESTful, NO journalSlug in a SINGLE-tenant site (unconfirmed list)
listNoslug=(
  "https://$BASEURL/about"                                                              "Example of journal's verbs (RESTful & noSlug)"
  "https://$BASEURL/\$\$\$call\$\$\$/page/page/css?name=stylesheet"                     'Call including $$$call$$$ (RESTful & noSlug)'
  "https://$BASEURL/oai"                                                                "Entrypoint for OAI at journal (RESTful & noSlug)"
  "https://$BASEURL/admin/oai"                                                          "Entrypoint for OAI at site-wide (RESTful)"
  "https://$BASEURL/admin/index/oai"                                                    "Entrypoint for OAI at site-wide (RESTful & noSlug)"
  "https://$BASEURL/api/v1/contexts/1"                                                  "Entrypoint for API at journal (RESTful & noSlug)"
)

urlList=''

# Select URLs list based on parameter
case ${1} in
    basic)
        urlList=("${listBasic[@]}")
    ;;
    restful)
        urlList=("${listRestful[@]}")
    ;;
    noslug)
        urlList=("${listNoslug[@]}")
    ;;
    *)
        echo "Sytnax: ./pkpCheckUrls.sh basic"
        echo ""
        echo "Please provide a valid set of urls to test. Existing options are:"
        echo "- [basic] Usual set of urls ANY site should pass. Rules defined for domain or subdomain. No Restful, Multi-tenant. With JournalSlug."
        echo "- [restful] Set of urls for: Domain or subdomain. Restful. Multi-tenant. With JournalSlug."
        echo "- [noslug] Set fo urls for: Domain or subdomain. Restfull. Single-tenant. Without JournalSlug."
        echo ""
        echo "You can run the script multiple times with different sets on same journal to discover how resilent is it."
	echo "Right now sets are acumulative: if you wanto to set your wit with [noslug], you should pass first [basic] and [rest] sets."
        exit 1
    ;;
esac

echo ""
echo "Base URL:           $BASEURL"
echo "Journal's context:  $JOURNAL"
echo ""

for ((i = 0; i < ${#urlList[@]}; i += 2)); do
    checkUrl "${urlList[i]}" "${urlList[i+1]}"
done

# Summarize and show results
echo ""
echo    "===========================================SUMMARY OF YOUR URL's HEALTH ====================================================="
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
