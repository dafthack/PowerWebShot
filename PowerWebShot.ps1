function Invoke-PowerWebShot{
<#
  .SYNOPSIS

    This module will 

    Invoke-PowerWebShot
    Author: Beau Bullock (@dafthack)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None

  .DESCRIPTION

    This module 

  .PARAMETER URL

    Username 

  .PARAMETER UrlList

    The host

  .PARAMETER Threads

    The usern

  .PARAMETER OutputDir

    The Pas
 

  .EXAMPLE

    C:\PS> Invoke-PowerWebShot -

    Description
    -----------
    This command will c

 #>


  Param
  (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]
    $URL = "",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]
    $UrlList = "",

    [Parameter(Position = 2, Mandatory = $false)]
    [string]
    $Threads = "",

    [Parameter(Position = 3, Mandatory = $false)]
    [string]
    $OutputDir = ""
  )

if (($URL -eq "") -and ($UrlList -eq ""))
    {
        Write-Output "[*] No URL's were specified to be scanned. Please use the -URL option to specify a single URL or -UrlList to specify a list."
        break
    }

# Load up the Selenium and PhantomJS drivers

$SeleniumDriverPath = ".\WebDriver.dll"
Add-Type -path $SeleniumDriverPath
[OpenQA.Selenium.PhantomJS.PhantomJSOptions]$options = New-Object OpenQA.Selenium.PhantomJS.PhantomJSOptions
#$caps = [OpenQA.Selenium.Remote.DesiredCapabilities]::phantomjs()
#$caps.SetCapability('CapabilityType.ACCEPT_SSL_CERTS', $true)
$cli_args = @()
$cli_args +=  "--web-security=no"
$cli_args += "--ignore-ssl-errors=yes"
$options.AddAdditionalCapability("phantomjs.cli.args", $cli_args)
$options.AddAdditionalCapability("phantomjs.page.settings.ignore-ssl-errors", $true)
$options.AddAdditionalCapability("phantomjs.page.settings.webSecurityEnabled", $false)
$options.AddAdditionalCapability("phantomjs.page.settings.userAgent", "Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko")
$phantomjspath = ".\"
$driver = New-Object OpenQA.Selenium.PhantomJS.PhantomJSDriver($phantomjspath, $options)
#$uri = "https://self-signed.badssl.com"
#$driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver($uri,$caps)

$driver.Url = "about:constant"

# If no output directory was named we will create one in with the current date/time.
If($OutputDir -eq "")
    {
        $OutputDir = Get-Date -format yyyy-MM-dd-HHmmss
    }

# Testing to see if the output directory exists. If not, we'll create it.
$TestOutputDir = Test-Path $OutputDir
If($TestOutputDir -ne $True)
    {
        Write-Output "[*] The output directory $OutputDir does not exist. Creating directory $OutputDir."
        mkdir $OutputDir
    }

# Getting the full path of the output dir.
$OutputPath = Convert-Path $OutputDir

  ## Choose to ignore any SSL Warning issues caused by Self Signed Certificates      
  ## Code From http://poshcode.org/624

  ## Create a compilation environment
  $Provider=New-Object Microsoft.CSharp.CSharpCodeProvider
  $Compiler=$Provider.CreateCompiler()
  $Params=New-Object System.CodeDom.Compiler.CompilerParameters
  $Params.GenerateExecutable=$False
  $Params.GenerateInMemory=$True
  $Params.IncludeDebugInformation=$False
  $Params.ReferencedAssemblies.Add("System.DLL") > $null

$TASource=@'
  namespace Local.ToolkitExtensions.Net.CertificatePolicy {
    public class TrustAll : System.Net.ICertificatePolicy {
      public TrustAll() { 
      }
      public bool CheckValidationResult(System.Net.ServicePoint sp,
        System.Security.Cryptography.X509Certificates.X509Certificate cert, 
        System.Net.WebRequest req, int problem) {
        return true;
      }
    }
  }
'@ 
  $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
  $TAAssembly=$TAResults.CompiledAssembly

  ## We now create an instance of the TrustAll and attach it to the ServicePointManager
  $TrustAll=$TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
  [System.Net.ServicePointManager]::CertificatePolicy=$TrustAll
  
  ## end code from http://poshcode.org/624

# Function to escape filenames of websites. Credit to: https://chrisseroka.wordpress.com/2012/11/27/get-website-screenshots-with-custom-web-crawler/
function EscapeFileName{
        param($filename)

        $pattern = "[{0}]" -f ([Regex]::Escape([String] [System.IO.Path]::GetInvalidFileNameChars()))              
        $newfile = [Regex]::Replace($filename, $pattern, '')
        $newfile
    }

# Function to screenshot the website with Selenium. Credit to: https://chrisseroka.wordpress.com/2012/11/27/get-website-screenshots-with-custom-web-crawler/
$global:images = @()
$global:UrlNames = @()
$global:PrevName = ""

function Take-ScreenShot{
        param($driver, $name)

        
        $fileName = ($name + ".png")
        $fileName = EscapeFileName -filename $fileName
        $driver.Url = $name
        $driver.Manage().Window.Maximize()

        if (($driver.Url -eq "") -or ($driver.Url -eq "about:blank") -or ($driver.Url -eq "about:constant") -or ($driver.Url -eq $PrevName))
        {
            Write-Output "[*] Something went wrong for $name"
        }
        else
        {
        $driver.GetScreenshot().SaveAsFile(($OutputPath + "\" + $fileName), [System.Drawing.Imaging.ImageFormat]::Png)
        $global:images += $filename
        $global:UrlNames += $name
        }

        
        $global:PrevName = $driver.Url
        $driver.Navigate().Back()
    }

# If only one URL was specified let's just screenshot that. Else go through the list of URLs.
If($URL -ne "")
    {
        Take-ScreenShot -driver $driver -name $URL

    } 
else
    {
        $URLArray = @()
        $URLArray = Get-Content $UrlList
        Foreach ($link in $UrlArray)
            {
                Write-Output "[*] Now analyzing $link"
                Take-ScreenShot -driver $driver -name $link
            }
    }

# Now we generate an HTML page containing the screenshots for rapid analysis.

function GenerateHtml{
    param($images, $OutputPath)
    $Html = @()
    $Html = "<html><body>
    <style>
#sample{
    width:300px;
    height:300px;
    overflow:hidden;
    position: relative;
    border: 1px solid black;
}

#sample img {
    position: absolute;
    top: 0px;
    left: 0px;
}

#wrapper {
  margin-left: 500px;

}
#content {
  float: right;
  width: 100%;
}
#sidebar {
  float: left;
  width: 200px;
  margin-left: -200px;
  background-color: #808080;
}
#cleared {
  clear: both;
}
</style>"
    $counter = 0
    foreach($img in $images)
    {
	    
        $Html += '<div id ="wrapper">
<div id ="sidebar"><p><a href="'
        $Html += $global:UrlNames[$counter]
        $Html += '">'
        $Html += $global:UrlNames[$counter]
        $Html += '</a></p></div>'
        $Html += '<div id ="content">'
        $Html += '<div id="sample"><a href="'
        $Html += $img
        $Html += '">'
        $Html += "<img src='$img' style=`"max-width:300px`"/></a></div></div>"
        $Html += '<div id="cleared"></div>
</div>
<br>
<br>
<br>'
        
        $counter++
    }
    $Html += "</body></html>"
    $Html | Out-File -FilePath ($OutputPath + "\" + "report.html")
    }

GenerateHtml -images $global:images -OutputPath $OutputPath

$driver.Quit()



}