# --------------------------------------------------------------------------------- Change This ---------------------------------------------------------------------------------
# personal info
[string] $token = "<authorization_token>"

# from/to server ids
[string] $channelIdFromChannel = "<channel_id_to_take_message_from>"
[string] $channelIdToChannel = "<channel_id_to_send_message_to>"

# ------------------------------------------------------------------------------ Don't Touch Below ------------------------------------------------------------------------------
[string] $hashFileName = "latestMessageHash.txt"
[string] $hashSaved = ""
[string] $apiVersion = "v8"

while($true) {
    # request to get the latest message in the Discord channel
    $apiUrl = "https://discord.com/api/$apiVersion/channels/$channelIdFromChannel/messages?limit=1"
    $lastMessage = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri $apiUrl `
                                                                    -Headers @{authorization = $token})
    # get the message content
    $lastMessageContent =  $lastMessage.content

    # check if the discord message is the same one from before
    $messageStream = [IO.MemoryStream]::new([byte[]][char[]]$lastMessageContent)
    [string] $encryptedMessageHash = Get-FileHash -InputStream $messageStream -Algorithm SHA256 | Select-Object -ExpandProperty "Hash"

    try {
        $hashSaved = Get-Content -Path "$PSScriptRoot\$hashFileName" -ErrorAction Stop
    } catch {
        $hashSaved = ""
    }

    if($hashSaved -ne $encryptedMessageHash)
    {
        # post the content message to the other Discord channel
        Invoke-WebRequest -Uri "https://discord.com/api/$apiVersion/channels/$channelIdToChannel/messages" `
                          -Method "POST" `
                          -Headers @{"authorization"=$token} `
                          -ContentType "application/json" `
                          -Body "{`"content`":`"$lastMessageContent`",`"tts`":false}" | Out-Null

        # save the hash of the message to not send the same one more than once
        $encryptedMessageHash | Out-File -FilePath "$PSScriptRoot\$hashFileName" -Force -Confirm:$false
    }

    Start-Sleep -Seconds 5
}