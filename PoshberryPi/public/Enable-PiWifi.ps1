Function Enable-PiWifi {
    <#
    .SYNOPSIS
        Enables wifi on the next boot of your Pi

    .DESCRIPTION
        Creates a 'wpa_supplicant.conf' file on the specified boot volume with desired settings to connect to wifi

    .PARAMETER KeyMgmt
        eg WPA-PSK

    .PARAMETER WifiCredential
        Credential object with the Username set to the WIFI SSID and the password set to the PSK

    .PARAMETER CountryCode
        eg US

    .PARAMETER Path
        Drive letter of boot volume

    .PARAMETER EncryptPSK
        Switch parameter for storing your PSK as encrypted text or plain text

    .EXAMPLE
        Enable-PiWifi -PSK $PSK -SSID $SSID -Path "D:"

        # Creates a 'wpa_supplicant.conf' file with default settings where possible on the boot volume mounted to D:
    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter()]
        [string]$KeyMgmt = "WPA-PSK",
        [Parameter()]
        [System.Management.Automation.PSCredential]$WifiCredential,
        [Parameter()]
        [string]$CountryCode = "US",
        [Parameter()]
        [switch]$EncryptPSK
    )
    if(!$PSBoundParameters.ContainsKey("WifiCredential"))
    {
        $WifiCredential = Get-Credential -Message "Please enter your Network SSID in the username field and passphrase as the password"
    }
    if($EncryptPSK){
        $PSK = Get-EncryptedPSK -WifiCredential $WifiCredential
    } else {
        $PSK = $WifiCredential.GetNetworkCredential().Password
    }
    $SSID = $WifiCredential.UserName
    $Output = @"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=$CountryCode

network={
    ssid="$SSID"
    psk=$PSK
    key_mgmt=$KeyMgmt
}
"@
    $Output.Replace("`r`n","`n") | Out-File "$Path\wpa_supplicant.conf" -Encoding ascii
}
