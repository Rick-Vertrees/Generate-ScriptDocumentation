[CmdletBinding()]

param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$fPath,

    [Parameter(Mandatory=$false,Position=1)]
    [string]$Author
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$Regex = "^(?<filePath>.*\\)(?<FileName>[^\\]*)(?<Extention>\..*)$"
$fPath -match $Regex >> $Null

$fExtention = $Matches.Extention

$cOutfile = $Matches.FilePath + $Matches.FileName + "_Commented.ps1"
$mOutfile = $Matches.FilePath + $Matches.FileName + "_Man.txt"
$ScriptName = $Matches.FileName + $Matches.Extention

$OPEN_AI_ORG = <Your Open AI Org ID>
$OPEN_AI_KEY = <Your Open AI Secret Key>
$Uri = "https://api.openai.com/v1/chat/completions"
$contenttype = "application/json"
$Model = "gpt-3.5-turbo"

$gContent = Get-Content $fPath
$cContext = "Rule Set: `r`n"
$cContext += "Author = $Author" + " `r`n"
$cContext += "Script Name = $ScriptName" +" `r`n" 
$cContext += "Please return the below code with code comments and a comment header using the above rule set: `r`n"
$cContent = $cContext + $gContent
$mContext = "Rule Set: `r`n"
$mContext += "Author = $Author" + " `r`n"
$mContext += "Script Name = $ScriptName" +" `r`n"
$mContext += "Programming Language = language associated with the $fExtention extention `r`n"
$mContext += "Man Page Style = Specific to Programming Language `r`n"
$mContext += "Include Examples `r`n"
$mContext += "Please create a manual page for the below code using the above rule set: `r`n"
$mContent = $mContext + $gContent

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

$cResponse = Invoke-RestMethod -Uri $Uri -Headers $Header -Body $cBody -Method Post -ContentType $contenttype
Write-host "Response one recieved"
$mResponse = Invoke-RestMethod -Uri $Uri -Headers $Header -Body $mBody -Method Post -ContentType $contenttype
Write-host "Response two recieved"

$rContent = $cResponse.choices.message.content
$rContent | Out-File -FilePath $cOutfile -Force

$rContent = $mResponse.choices.message.content
$rContent | Out-File -FilePath $mOutfile -Force
