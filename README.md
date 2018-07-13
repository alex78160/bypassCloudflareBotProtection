# bypassCloudflareBotProtection
a shell script using curl and nodejs to bypass the cloudflare bot protection : retrieves the clearance cookie like a browser. 
You must pass the url you want to access as a parameter to the script
1. get the control page
2. extract the JavaScript control code
3. calculate jschl_answer and extract 2 other parameters
4. perform a get request on the control url with the 3 parameters and retrieve the clearance cookie in the HTTP response

