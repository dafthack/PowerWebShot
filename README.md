# PowerWebShot
A PowerShell tool for taking screenshots of multiple web servers quickly. 

## Requirements
This tool utilizes Selenium and PhantomJS to screenshot web servers. I've included the phantomjs.exe and Selenium WebDriver.dll in this repository but if you would like to download them directly from their sources they can be found here:

Selenium - http://www.seleniumhq.org/download/

PhantomJS - http://phantomjs.org/

The phantomjs.exe and WebDriver.dll must be in the current working directory of the PowerWebShot.ps1 script.

## Usage
PowerWebShot can be used to screenshot a single URL with the -URL option or a list of URL's from a file with the -UrlList option. Each web server will have a thumbnail generated and added to an HTML report at report.html in the output directory. 

First, run powershell.exe and import the script with:
``` PowerShell
C:\PS> Import-Module PowerWebShot.ps1
```
### Screenshot a single URL
This command will take a screenshot of http://www.google.com and add it to a file called report.html in an automatically generated directory with the current date/time as the folder title.
``` PowerShell
C:\PS> Invoke-PowerWebShot -URL http://www.google.com
```
### Screenshot a list of URLs and output to a custom directory
This command will take a screenshot each of the URLs in the file "urllist.txt" and add them to a file called report.html. Each screenshot and the report will be located in a directory called "web-server-screenshot-directory".

``` PowerShell
C:\PS> Invoke-PowerWebShot -UrlList urllist.txt -OutputDir web-server-screenshot-directory
```

## PowerWebShot Options
``` 
URL             - A single URL to screenshot.
UrlList         - A list of URL's one per line to screenshot.
OutputDir       - The directory to output the screenshots to. If none is specified one will be created automatically.
```

## Special Thanks
Thanks goes to Chris Truncer for developing EyeWitness (https://github.com/ChrisTruncer/EyeWitness), which this tool was heavily inspired by.
