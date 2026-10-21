param(
    [Parameter(Mandatory)]
    [string] $Image,
    [Parameter(Mandatory)]
    [string] $PhpVersion,
    [Parameter(Mandatory)]
    [ValidateSet('runtime', 'debug')]
    [string] $Target,
    [string] $XdebugVersion = '3.5.3'
)

$ErrorActionPreference = 'Stop'

function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) {
        throw "Docker failed (exit ${LASTEXITCODE}): docker $args"
    }
}

$runtimeCheck = Join-Path $PSScriptRoot 'check-runtime.php'
$fixtures = Join-Path $PSScriptRoot 'fixtures'
$expectedDebug = if ($Target -eq 'debug') { '1' } else { '0' }

Invoke-Docker run --rm `
    --mount "type=bind,source=$runtimeCheck,target=/tmp/check-runtime.php,readonly" `
    -e "EXPECTED_PHP=$PhpVersion" `
    -e "EXPECTED_DEBUG=$expectedDebug" `
    -e "EXPECTED_XDEBUG=$XdebugVersion" `
    $Image php /tmp/check-runtime.php

Invoke-Docker run --rm $Image apache2ctl -t
$modules = Invoke-Docker run --rm $Image apache2ctl -M
if (($modules -join "`n") -notmatch 'rewrite_module') {
    throw 'Apache rewrite_module is not enabled'
}

$containerName = 'apache-php-test-' + [guid]::NewGuid().ToString('N')
$curl = if ($IsWindows) { 'curl.exe' } else { 'curl' }

try {
    Invoke-Docker run --detach --name $containerName `
        --publish '127.0.0.1::80' `
        --mount "type=bind,source=$fixtures,target=/var/www/html,readonly" `
        $Image | Out-Null

    $address = Invoke-Docker port $containerName 80/tcp
    $response = & $curl --fail --silent --show-error `
        --retry 15 --retry-connrefused --retry-delay 1 --retry-max-time 30 --max-time 5 `
        "http://$address/health"
    if ($LASTEXITCODE -ne 0 -or $response -ne $PhpVersion) {
        Invoke-Docker logs $containerName
        throw "Apache HTTP/PHP/rewrite check failed: expected '$PhpVersion', got '$response'"
    }
    Write-Output "PASS: Apache serves PHP $PhpVersion over HTTP through mod_rewrite"
}
finally {
    Invoke-Docker rm --force $containerName | Out-Null
}
