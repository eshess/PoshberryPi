Function Get-EncryptedPSK {
    <#
    .SYNOPSIS
        Generates the 32 byte encrypted hex string wpa_supplicant uses to connect to wifi

    .DESCRIPTION
        Generates the 32 byte encrypted hex string wpa_supplicant uses to connect to wifi

    .PARAMETER Credential
        A credential object containing the SSID and PSK used to connect to wifi

    .EXAMPLE
        $EncryptedPSK = Get-EncryptedPSK -Credential $Credential

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param (
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    if(!$PSBoundParameters.ContainsKey("Credential"))
    {
        $Credential = Get-Credential -Message "Please enter your Network SSID in the username field and passphrase as the password"
    }
    $NetCred = $Credential.GetNetworkCredential()
    $Salt = [System.Text.Encoding]::ASCII.GetBytes($Credential.UserName)
    $rfc = [System.Security.Cryptography.Rfc2898DeriveBytes]::New($NetCred.Password,$Salt,4096)
    Write-Output (Convert-ByteArrayToHexString -ByteArray $rfc.GetBytes(32) -Delimiter "").ToLower()
}
