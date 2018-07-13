# bypassCloudflareBotProtection
a shell script using curl and nodejs to bypass the cloudflare bot protection : retrieves the clearance cookie like a browser.

You must pass the url you want to access as a parameter to the script

Usage : ./bypassCloudflare.sh https://www.123456.com

1. get the control page
2. extract the JavaScript control code
3. calculate jschl_answer and extract 2 other parameters
4. perform a get request on the control url with the 3 parameters and retrieve the clearance cookie in the HTTP response

Once this is done, the clearance cookie is stored in a file and can be used in curl requests to behave like a browser.

Note that the headers passed to curl requests (-H) come from browser requests and they might not all be required.

