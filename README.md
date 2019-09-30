# bypassCloudflareBotProtection
a shell script using curl and nodejs to bypass the cloudflare bot protection : retrieves the clearance cookie like a browser.

You must pass the url you want to access as a parameter to the script

Usage : ./bypassCloudflare.sh "https://www.123456.com"

There are 2 versions because sometimes the controls are not the same, I will update the scripts each time I find a new protection.
In the second version, I introduced a new variable torstring="--socks5 127.0.0.1:9150" and I inserted this string inside each curl command I make. This makes curl use the Tor proxy configured on localhost, using the port 9150. Of course, you can customize these values to use your own proxy. And if you don't need it, you can wait for my next update which will include an option or just define torstring to an empty string : torstring="" 
The principle is the same for bypassCloudflare.sh and bypassCloudflareNewControls.sh :

1. get the control page
2. extract the JavaScript control code
3. calculate jschl_answer and extract other parameters
For the second version (bypassCloudflareNewControls.sh), jschl_answer is much more complicated to calculate because I have to manage JavaScript functions, and they also introduced a new hidden div with a dynamically calculated id, containing an expression which can be converted to a decimal number.
4. perform a get request on the control url with the 3 parameters and retrieve the clearance cookie in the HTTP response

Once this is done, the clearance cookie is stored in a file and can be used in curl requests to behave like a browser.

Note that the headers passed to curl requests (-H) come from browser requests and they might not all be required.

I needed this feature (get clearance cookie like a browser) to write a more complicated shell script to authenticate on a torrent web site (curl credentials and store session cookies) and download thousands of files, browsing all the pages in each category (with curl requests and the required cookies).
It saves me a lot of time : I no longer have to click everywhere, wait, read, download a file and repeat that during hours.

=================================================================================


