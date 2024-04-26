$url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"
$d = Invoke-WebRequest -Uri $url -UseBasicParsing
$urlRegex = 'https?://(?:[-\w.]|(?:%[\da-fA-F]{2}))+/[-\w./?%&=]*\.json'
$urldownload = [regex]::Match($d.RawContent , $urlRegex).Value
$downloadjson= Invoke-WebRequest -Uri $urldownload 
$parseword = $downloadjson.RawContent
$jsonStartIndex = $parseword.IndexOf('{')
$jsonEndIndex = $parseword.LastIndexOf('}')
$jsonlenght = $jsonEndIndex - $jsonStartIndex + 1
$jsonString = $parseword.Substring($jsonStartIndex, $jsonlenght)

$jsonObject = $jsonString | ConvertFrom-Json


$filteredIPv4Objects = $jsonObject.values | Where-Object { $_.name -match '^AzureResourceManager\.' -and $_.properties.addressPrefixes -notmatch '::' }

$ips = @()

# Iterate over filtered objects and extract IPv4 IP addresses
$filteredIPv4Objects | ForEach-Object {
    $_.properties.addressPrefixes | ForEach-Object {
        # Check if the IP address is not a /32 CIDR block
        if ($_ -notmatch '::' -and $_ -notmatch '/32$') {
            $ipInfo = @{
                IPAddressOrRange = $_
                Action = "allow"
            }
            # Add IP rule to the array
            $ips += $ipInfo
        }
    }
}



$ips 

# Update the storage account network rule set to whitelist ips
Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroupName -Name $storageAccountName -IpRule $ips
