function ConvertTo-CliXml {
    <#
        .SYNOPSIS
            Serializes PSObjects into CliXml formatted string data.

        .DESCRIPTION
            Serializes PSObjects into CliXml formatted string data.

        .PARAMETER InputObject
            Object to serialize.

        .NOTES
            #Function borrowed from Joel Bennett (http://poshcode.org/4544)
            #Original Author Oisin Grehan (http://poshcode.org/1672)

        .EXAMPLE
            ConvertTo-CliXml -InputObject $Services

            Description
            -----------
            Serializes PSObjects into CliXml formatted string data.
    #>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$InputObject
)
    begin {
        $type = [PSObject].Assembly.GetType('System.Management.Automation.Serializer')
        $ctor = $type.GetConstructor('instance,nonpublic', $null, @([System.Xml.XmlWriter]), $null)
        $sw = New-Object System.IO.StringWriter
        $xw = New-Object System.Xml.XmlTextWriter $sw
        $serializer = $ctor.Invoke($xw)
    }
    process {
        try {
            [void]$type.InvokeMember("Serialize", "InvokeMethod,NonPublic,Instance", $null, $serializer, [object[]]@($InputObject))

        } catch {
            Write-Warning "Could not serialize $($InputObject.GetType()): $_"
        }
    }
    end {
        [void]$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $serializer, @())
        $sw.ToString()
        $xw.Close()
        $sw.Dispose()
    }
}
