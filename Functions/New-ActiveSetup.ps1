function New-ActiveSetup {
    param(
        [Parameter(Mandatory, HelpMessage = "Name of the active registry task")]
        $KeyName,
        [Parameter(Mandatory, HelpMessage = "The command to run")]
        $CommandValue
    )

    $asPath = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$KeyName"
    New-Item $asPath -force -ea Stop | Out-Null
    New-ItemProperty -LiteralPath $asPath -Name '(default)' -Value $KeyName -PropertyType String -Force -ea stop | Out-Null
    New-ItemProperty -LiteralPath $asPath -Name 'Version' -Value '1' -PropertyType String -Force -ea stop | Out-Null
    New-ItemProperty -LiteralPath $asPath -Name 'StubPath' -Value $CommandValue -PropertyType String -Force -ea stop | Out-Null

}