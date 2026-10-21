<?php

function check(bool $condition, string $message): void
{
    if (!$condition) {
        fwrite(STDERR, "FAIL: {$message}\n");
        exit(1);
    }
    echo "PASS: {$message}\n";
}

$expectedPhp = getenv('EXPECTED_PHP');
$expectedDebug = getenv('EXPECTED_DEBUG') === '1';

check(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION === $expectedPhp, 'PHP version');

foreach (['gd', 'mysqli', 'PDO', 'pdo_mysql', 'ftp', 'soap'] as $extension) {
    check(extension_loaded($extension), "Extension {$extension}");
}

$gd = gd_info();
check($gd['FreeType Support'], 'GD FreeType support');
check($gd['JPEG Support'], 'GD JPEG support');
check($gd['PNG Support'], 'GD PNG support');
check(extension_loaded('xdebug') === $expectedDebug, 'Xdebug only in debug images');

if ($expectedDebug) {
    check(phpversion('xdebug') === getenv('EXPECTED_XDEBUG'), 'Xdebug version');
    check(ini_get('xdebug.mode') === 'debug,develop', 'Xdebug modes');
    check(ini_get('xdebug.start_with_request') === 'trigger', 'Xdebug starts on trigger');
    check(ini_get('xdebug.client_host') === 'host.docker.internal', 'Xdebug client host');
    check(ini_get('xdebug.client_port') === '9003', 'Xdebug client port');
}
