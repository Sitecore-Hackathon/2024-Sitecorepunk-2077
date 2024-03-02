<#
.SYNOPSIS
    Driven by the Microsoft Azure AI Speech, this Sitecore PowerShell Extensions utility 
    allows Content Authors and Marketers to generate audio versions of their content.  

.DESCRIPTION
    Azure AI Speech is a cloud-based API service.
    https://azure.microsoft.com/en-us/products/ai-services/ai-speech

    - This solution requires the following two Azure Resources:
        - Azure AI Services 
        - Azure Storage Account

    - API Keys for both Azure services must be configured on the API Settings item: 
        - '/sitecore/system/Modules/PowerShell/Script Library/Sitecorepunk2077/API Settings'

    - This script provides a Ribbon button under the Home tab titled 'Generate Audio'.

    - The Ribbon button is configured to only show when the context item inherits from the '/sitecore/templates/Feature/Sitecorepunk2077/Text to Speech' template. 

    - If the Audio URL field is populated, the Ribbon button title changes to 'Regenerate Audio'

    - Click 'Generate Audio'/'Regenerate Audio' button opens a dialog.  The following fields are available for the user to configure:
        - 1. `Field to convert to speech` (radio button list; RTE and multi-line fields available of the item will be listed; user can select one)
            - If the 'Speech Content Override' field is populated on the template, 'Speech Content Override' becomes an option for selection. 
        - 2. `Include Title?` (standalone radio button; static; if checked, the Title will be included in the spoken audio file prior to the article content)
        - 3. `Voice` (radio button list; dynamic based on item context language; preselected list of AI Neural voices for natral sounding speech; 4 languages supported [en-US, ja-JP, de-DE, da])
        - 4. `Speech Rate` (OPTIONAL; expects an double value; defaults to 1.0 if left empty)

    This script works with custom item Templates in Sitecore.

.NOTES
    This script was developed to work as `Ribbon Button` PowerShell Script item.

.AUTHOR
    Gabe Streza
    Team `Sitecorepunk 2077` - Sitecore Hackathon 2024 
#>


function Invoke-AudioStreamFetch {
    param (
        [Parameter(Mandatory = $true)]
        [Item]$TargetItem,

        [Parameter(Mandatory = $true)]
        [string]$FieldName,

        [Parameter(Mandatory = $true)]
        [string]$Language,

        [Parameter(Mandatory = $true)]
        [string]$VoiceName,

        [Parameter(Mandatory = $true)]
        [string]$VoiceLanguage,

        [Parameter(Mandatory = $true)]
        [string]$VoiceGender,

        [Parameter(Mandatory = $true)]
        [bool]$IncludeTitle
    )

    # Handle Override selection for Title
    if($IncludeTitle -eq $true){
        if($FieldName -eq "Speech Content Override"){
            $SpokenText = "$($TargetItem.Fields["Speech Title Override"].Value). "
        }else{
            $SpokenText = "$($TargetItem.Fields["Title"].Value). "
        }
    }
    $SpokenText += $TargetItem.Fields[$FieldName].Value

    # Sanitze string - strip HTML
    Write-Host "SpokenText before sanitation: $SpokenText"
    $sanitizedSpokenTextFieldValue = $SpokenText -replace '<[^>]+>', '';
    $sanitizedSpokenTextFieldValue = $sanitizedSpokenTextFieldValue -replace '\"', '';
    $sanitizedSpokenTextFieldValue = $sanitizedSpokenTextFieldValue -replace '\?', '';
    $sanitizedSpokenTextFieldValue = $sanitizedSpokenTextFieldValue -replace '&nbsp;', '';
    $sanitizedSpokenTextFieldValue = $sanitizedSpokenTextFieldValue.replace("`n", " ").replace("`r", " ")
    $SpokenText = $sanitizedSpokenTextFieldValue
    $SpokenText = Remove-HtmlAndDecode -HtmlString $SpokenText
    Write-Host "SpokenText after sanitation: $SpokenText"

    $FileID = $TargetItem.ID.ToString().Replace("{", "").Replace("}", "")
    $TargetLanguage = $TargetItem.Language.Name
    $TargetVersion = "v$($TargetItem.Version.Number)"
    $LocalFileName = "tts-audio-$FileID-$TargetLanguage-$TargetVersion-$VoiceName.mp3"
    Write-Host "LocalFileName: $LocalFileName"

    $AudioFilePath = Join-Path -Path $script:TempFolderPath -ChildPath $LocalFileName
    Write-Host "AudioFilePath: $AudioFilePath"
    # Headers and body for the POST request
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $script:AzureAIServicesSubscriptionKey
        "Content-Type" = "application/ssml+xml"
        "X-Microsoft-OutputFormat" = $script:AudioOutputFormat
    }
    
    Write-Host "Before body"
    # SSML body
    # Correctly formatted SSML body
    $body = @"
    <speak version='1.0' xml:lang='$VoiceLanguage'>
        <voice xml:lang='$VoiceLanguage' xml:gender='$VoiceGender' name='$VoiceName'>
        $SpokenText
        </voice>
    </speak>
"@
     $body

    try {
        Write-Host "Fetching audio stream"
        $response = Invoke-RestMethod -Uri $script:AzureAIServicesEndpointUrl -Method Post -Headers $headers -Body $body -OutFile $AudioFilePath
        Write-Host "Audio stream saved to $AudioFilePath"

         # Proceed to upload the file
        Upload-FileToAzureStorage -AudioFilePath $AudioFilePath -LocalFileName $LocalFileName
        if($script:blobUrl -ne ""){
            Write-Host "BlobUrl: $script:blobUrl"
            Write-Host "Updating Audio URL field on $($TargetItem.ID)"
            $admin = Get-User -Identity "sitecore\admin" 
            New-UsingBlock (New-Object Sitecore.Security.Accounts.UserSwitcher $admin) {
                $TargetItem.Editing.BeginEdit()
                $TargetItem["Audio URL"] = $script:blobUrl
                $TargetItem.Editing.EndEdit() > $null
            }
        }
    }
    catch [System.Net.WebException] {
        # An error occured calling the API
        Write-Host 'Error calling API' -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
        return $null
    }
   
    Write-Host "Operation completed"
}

function Remove-HtmlAndDecode {
    param(
        [string]$HtmlString
    )

    # First, remove HTML tags
    $noHtml = $HtmlString -replace '<[^>]+>', ''

    # Then, decode HTML encoded characters
    $decodedText = [System.Net.WebUtility]::HtmlDecode($noHtml)

    return $decodedText
}

# Function to generate the authorization header for Azure Storage REST API
function Get-AuthorizationHeader {
    param(
        [string]$method,
        [string]$blobName,
        [string]$contentLength,
        [string]$contentType
    )

    # Construct the request
    $requestDate = [System.DateTime]::UtcNow.ToString("R")
    $xmsVersion = "2017-04-17"
    $canonicalizedHeaders = "x-ms-blob-type:BlockBlob`nx-ms-date:$requestDate`nx-ms-version:$xmsVersion"
    $canonicalizedResource = "/$script:StorageAccountName/$script:StorageContainerName/$blobName"
    $stringToSign = "$method`n`n`n$contentLength`n`n$contentType`n`n`n`n`n`n`n$canonicalizedHeaders`n$canonicalizedResource"
    $bytesToSign = [Text.Encoding]::UTF8.GetBytes($stringToSign)
    $keyBytes = [Convert]::FromBase64String($StorageAccountKey)
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = $keyBytes
    $signature = $hmacsha256.ComputeHash($bytesToSign)
    $signature = [Convert]::ToBase64String($signature)
    $authorizationHeader = "SharedKey ${StorageAccountName}:$signature"

    return @{
        "Authorization" = $authorizationHeader
        "x-ms-date" = $requestDate
        "x-ms-version" = $xmsVersion
        "x-ms-blob-type" = "BlockBlob"
        "Content-Length" = $contentLength
        "Content-Type" = $contentType
    }
}

# Function to upload the file to Azure Storage Container using REST API
function Upload-FileToAzureStorage {
    [Parameter(Mandatory = $true)]
    [string]$AudioFilePath,
    [Parameter(Mandatory = $true)]
    [string]$LocalFileName

    $blobName = $LocalFileName
    $fileContent = Get-Content -Path $AudioFilePath -Raw -Encoding Byte
    $contentLength = $fileContent.Length
    $contentType = "audio/mpeg"
    $method = "PUT"

    $headers = Get-AuthorizationHeader -method $method -blobName $blobName -contentLength $contentLength -contentType $contentType
    $uri = "https://$script:StorageAccountName.blob.core.windows.net/$script:StorageContainerName/$blobName"
    $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $fileContent -ContentType $contentType
    Write-Host "File '$AudioFilePath' uploaded to Azure Storage Container '$script:StorageContainerName'."

    # Construct the URL
    $constructedAudioUrl = "https://$script:StorageAccountName.blob.core.windows.net/$script:StorageContainerName/$blobName"
    
    # Print the URL to the host
    Write-Host "The URL of the uploaded file is: $constructedAudioUrl"
    $script:blobUrl = $constructedAudioUrl

}

#region Azure AI Services
$script:AzureAIServicesSubscriptionKey = "00000000000000000000000000000000" #"95894af2fb4b498fb24ebf972e95f6af"
$script:AzureAIServicesEndpointRegion = ""
$script:AzureAIServicesEndpointUrl = ""
$script:AudioOutputFormat = "audio-24khz-48kbitrate-mono-mp3"

# Settings item is located at `/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings`
$settingsItem = Get-Item "{D51D7222-0F22-4D20-911C-F0D1A677440C}"
if ($null -eq $settingsItem) {
    Show-Alert "API Settings item is missing.  Please reinstall the module."
    Exit
}

# Validate Azure AI Services Key
if ($settingsItem.Fields["Azure AI Services Key"].Value -ne "") {
    if ($settingsItem.Fields["Azure AI Services Key"].Value.Length -ne "32") {
        Show-Alert "Azure AI Services Key must be 32 characters in length.  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
        Exit
    }
    $script:AzureAIServicesSubscriptionKey = $settingsItem.Fields["Azure AI Services Key"].Value
    Write-Host "AzureAIServicesSubscriptionKey: $script:AzureAIServicesSubscriptionKey"
}
else {
    Show-Alert "Azure AI Services Key must be populated on the 'API Settings'  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
    Exit 
}

# Validate Azure AI Endpoint Region
if ($settingsItem.Fields["Azure AI Endpoint Region"].Value -ne "") {
    $script:AzureAIServicesEndpointRegion = $settingsItem.Fields["Azure AI Endpoint Region"].Value
    $script:AzureAIServicesEndpointUrl = "https://$script:AzureAIServicesEndpointRegion.tts.speech.microsoft.com/cognitiveservices/v1"
    Write-Host "AzureAIServicesEndpointRegion: $script:AzureAIServicesEndpointRegion"
    Write-Host "AzureAIServicesEndpointUrl: $script:AzureAIServicesEndpointUrl"
}
else {
    Show-Alert "Azure AI Endpoint Region must be populated on the 'API Settings' item.  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
    Exit 
}
#endregion

#region Azure Storage
$script:StorageAccountName = ""
$script:StorageAccountKey = ""
$script:StorageContainerName = ""

# Validate Azure Storage Account Name
if ($settingsItem.Fields["Storage Account Name"].Value -ne "") {
    $script:StorageAccountName = $settingsItem.Fields["Storage Account Name"].Value
    Write-Host "StorageAccountName: $script:StorageAccountName"
}
else {
    Show-Alert "Storage Account Name must be populated on the 'API Settings'  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
    Exit 
}

# Validate Azure Storage Key
if ($settingsItem.Fields["Storage Key"].Value -ne "") {
    $script:StorageAccountKey = $settingsItem.Fields["Storage Key"].Value
    Write-Host "StorageAccountKey: $script:StorageAccountKey"
}
else {
    Show-Alert "Storage Account Key must be populated on the 'API Settings'  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
    Exit 
}

# Validate Azure Storage Container Name
if ($settingsItem.Fields["Storage Container Name"].Value -ne "") {
    $script:StorageContainerName = $settingsItem.Fields["Storage Container Name"].Value
    Write-Host "StorageContainerName: $script:StorageContainerName"
}
else {
    Show-Alert "Storage Container Name must be populated on the 'API Settings'  `n`nPlease check the value on '/sitecore/system/Modules/PowerShell/Script Library/TextToSpeech/API Settings'. `n`n ID: '{D51D7222-0F22-4D20-911C-F0D1A677440C}'"
    Exit 
}
#endregion

#region Local Temp Location Validation
# Define the temp folder path
$script:TempFolderPath = Join-Path -Path $SitecoreDataFolder -ChildPath "temp"

# Ensure the temp folder exists
if (-not (Test-Path -Path $script:TempFolderPath)) {
    New-Item -ItemType Directory -Path $script:TempFolderPath
    Write-Host "Temporary folder created at: $script:TempFolderPath"
} else {
    Write-Host "Temporary folder already exists at: $script:TempFolderPath"
}
#endregion

# Get the current context item, Write to console
Write-Host "Item ID: $($SitecoreContextItem.ID)"
Write-Host "Item Language: $($SitecoreContextItem.Language.Name)"
Write-Host "Item Version: $($SitecoreContextItem.Version.Number)"

# Obtain context item's Multi-Line Text, and Rich Text fields (ignore module, System fields)
$fieldOptions = New-Object System.Collections.Specialized.OrderedDictionary
$SitecoreContextItem.Fields | Where-Object { 
    (($_.TypeKey -eq "multi-line text" -or $_.TypeKey -eq "rich text") -and 
    $_.Name -notlike "__*" -and 
    $_.TypeKey -ne "text" -and 
    $_.TypeKey -ne "single-line text" -and 
    $_.Name -ne "Audio URL") 
} | ForEach-Object {
    if (-not [string]::IsNullOrEmpty($SitecoreContextItem.Fields[$_.Name].Value)) {
        # Check if the key already exists before adding
        if (-not $fieldOptions.Contains($_.Name)) {
            $fieldOptions.Add($_.Name, $_.Name)
        }
    }
}

# Language Name variable for current context language name
$currentItemLanguage = $SitecoreContextItem.Language.Name

# Azure AI Speech Neural Voice options
$voiceOptions = New-Object System.Collections.Specialized.OrderedDictionary
if($currentItemLanguage -eq "en"){
    # English (US) Neural Voices
    $voiceOptions.Add("Christopher (Neural, Male, en-US)", "en-US-ChristopherNeural|en-Us|Male")
    $voiceOptions.Add("Brian (Neural, Male, en-US)", "en-US-BrianNeural|en-US|Male")
    $voiceOptions.Add("Aria (Neural, Female, en-US)", "en-US-AriaNeural|en-US|Female")
    $voiceOptions.Add("Emma (Neural, Female, en-US)", "en-US-EmmaNeural|en-US|Female")

    # English (UK) Neural Voices
    $voiceOptions.Add("Alfie (Neural, Male, en-GB)", "en-GB-AlfieNeural|en-GB|Male")
    $voiceOptions.Add("Sonia (Neural, Female, en-GB)", "en-GB-SoniaNeural|en-GB|Female")

}elseif($currentItemLanguage -eq "ja-JP"){
    # Japanese Neural Voices
    $voiceOptions.Add("Naoki (Neural, Male, ja-JP)", "ja-JP-NaokiNeural|ja-JP|Male")
    $voiceOptions.Add("Nanami (Neural, Female, ja-JP)", "ja-JP-NanamiNeural|ja-JP|Female")
}
elseif($currentItemLanguage -match "de-"){
    # German Neural Voices
    $voiceOptions.Add("Conrad (Neural, Male, de-DE)", "de-DE-ConradNeural|de-DE|Male")
    $voiceOptions.Add("Amala (Neural, Female, de-DE)", "de-DE-AmalaNeural|de-DE|Female")
}
elseif($currentItemLanguage -eq "da"){
    # Danish Neural Voices
    $voiceOptions.Add("Jeppe (Neural, Male, da-DK)", "da-DK-JeppeNeural|da-DK|Male")
    $voiceOptions.Add("Amala (Neural, Female, da-DK)", "da-DK-ChristelNeural|da-DK|Female")
}

# 'Include title?' checkbox
$includeTitleParams = New-Object System.Collections.Specialized.OrderedDictionary
$includeTitleParams.Add("Include Title", "true")

# Window with options to select language and field to analyze
$dialogProps = @{
    Parameters       = @(
        @{ Name = "fieldSelected"; Title = "Field to convert to speech"; options = $fieldOptions; editor = "radio" },
        @{ Name = "includeTitle"; Title = "Include Title?"; options = $includeTitleParams; editor = "radio"  }
        @{ Name = "voiceSelection"; Title = "Voice"; Options = $voiceOptions; Editor = "radio" },
        @{ Name = "speechRate"; Title = "Speech Rate (normal = 1.0)"; DefaultValue = "1.0"; Tooltip = "Enter a rate between 0.5 (slow) and 2.0 (fast)"; Editor = "text" }
    )
    Description      = "Select a field to generate an audio version of the field's text using Microsoft Azure's AI Text-to-Speech Service.`nModifying: $($SitecoreContextItem.Language.Name) | $($SitecoreContextItem.Version.Number)" 
    Title            = "Text to Speech Audio Generator" 
    OkButtonName     = "Continue" 
    CancelButtonName = "Cancel"
    Width            = 425 
    Height           = 325 
    Icon             = "multimedia/32x32/fadeout_sound.png"
}

# Wait for user input from options menu
$dialogResult = Read-Variable @dialogProps
if ($dialogResult -ne "ok") {
    # Exit if cancelled
    Exit
}
# Handle include bool (didn't want to use a checkbox due to the UI, this approach was necessary)
$includeTitleBool = $includeTitle -eq "true"

# Speech rate selection validation
if ($speechRate -notmatch "^\d+(\.\d+)?$") {
    # Default if not provided
    $speechRate = "1.0"
}
$speechRateValue = [double]$speechRate
if ($speechRateValue -lt 0.5 -or $speechRateValue -gt 2.0) {
    Show-Alert "The speech rate must be between 0.5 and 2.0. Falling back to 1.0."
    Exit
}

# Voice defaults
$VoiceName = ""
$VoiceLanguage = ""
$VoiceGender = ""

# Split the voice selection value by pipe, set name, gender, language variables
if($voiceSelection -ne ""){
    $VoiceSplit = $voiceSelection.Split('|')
    $VoiceName = $VoiceSplit[0]
    $VoiceGender = $VoiceSplit[1]
    $VoiceLanguage = $VoiceSplit[2]
}

# Execute the function to fetch and upload the audio stream
Invoke-AudioStreamFetch -TargetItem $SitecoreContextItem `
    -FieldName $fieldSelected `
    -Language $currentItemLanguage `
    -VoiceName $VoiceName `
    -VoiceLanguage $VoiceLanguage `
    -VoiceGender $VoiceGender `
    -IncludeTitle $includeTitleBool