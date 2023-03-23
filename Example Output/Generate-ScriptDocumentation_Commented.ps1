<#
.SYNOPSIS
This script generates a commented version of a PowerShell script and a manual page for the script.

.PARAMETER fPath
The file path of the PowerShell script to be documented.

.PARAMETER Author
The author of the script. Optional.

.EXAMPLE
Generate-ScriptDocumentation.ps1 -fPath C:\Scripts\MyScript.ps1 -Author "John Doe"
This example generates a commented version of MyScript.ps1 and a manual page for the script with author name "John Doe".

.NOTES
Author: Richard Vertrees
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$fPath,
    [Parameter(Mandatory=$false,Position=1)]
    [string]$Author
)

# Set security protocol for API call
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Extract file name and extension from file path
$Regex = "^(?<filePath>.*\\)(?<FileName>[^\\]*)(?<Extention>\..*)$"
$fPath -match $Regex >> $Null
$fExtention = $Matches.Extention

# Set output file names
$cOutfile = $Matches.FilePath + $Matches.FileName + "_Commented.ps1"
$mOutfile = $Matches.FilePath + $Matches.FileName + "_Man.txt"
$ScriptName = $Matches.FileName + $Matches.Extention

# Set OpenAI API credentials and endpoint
$OPEN_AI_ORG = <Your Open AI Org ID>
$OPEN_AI_KEY = <Your Open AI Secret Key>
$Uri = "https://api.openai.com/v1/chat/completions"
$contenttype = "application/json"
$Model = "gpt-3.5-turbo"

# Read script content and add context for API call
$gContent = Get-Content $fPath
$cContext = "Rule Set: `r`n"
$cContext += "Author = $Author" + " `r`n"
$cContext += "Script Name = $ScriptName" +" `r`n"
$cContext += "Please return the below code with code comments and a comment header using the above rule set: `r`n"
$cContent = $cContext + $gContent

# Add context for manual page and API call
$mContext = "Rule Set: `r`n"
$mContext += "Author = $Author" + " `r`n"
$mContext += "Script Name = $ScriptName" +" `r`n"
$mContext += "Programming Language = language associated with the $fExtention extention `r`n"
$mContext += "Man Page Style = Specific to Programming Language `r`n"
$mContext += "Include Examples `r`n"
$mContext += "Please create a manual page for the below code using the above rule set: `r`n"
$mContent = $mContext + $gContent

# Set API call headers and body for commented script
$Header = @{
    Authorization = "Bearer $OPEN_AI_KEY"
    "OpenAI-Organization" = $OPEN_AI_Org
}
$cJson = @{
    model = $Model
    messages = @(@{
        role = "assistant"
        content = $cContent
        }
    )
    temperature = 0.2
} | ConvertTo-Json
$cBody = [System.Text.Encoding]::UTF8.GetBytes($cJson)

# Set API call headers and body for manual page
$mJson = @{
    model =$Model
    messages = @(@{
        role = "assistant"
        content = $mContent
        }
    )
    temperature = 0.2
} | ConvertTo-Json
$mBody = [System.Text.Encoding]::UTF8.GetBytes($mJson)

# Call OpenAI API for commented script and manual page
$cResponse = Invoke-RestMethod -Uri $Uri -Headers $Header -Body $cBody -Method Post -ContentType $contenttype
Write-host "Response one recieved"
$mResponse = Invoke-RestMethod -Uri $Uri -Headers $Header -Body $mBody -Method Post -ContentType $contenttype
Write-host "Response two recieved"

# Extract API response content and write to output files
$rContent = $cResponse.choices.message.content
$rContent | Out-File -FilePath $cOutfile -Force

$rContent = $mResponse.choices.message.content
$rContent | Out-File -FilePath $mOutfile -Force
