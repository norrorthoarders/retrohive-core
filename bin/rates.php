#!/usr/bin/env php
<?php
/**
 * Fetch what a dollar is worth, and record it for today.
 *
 * Run from maintenance, so an instance showing kronor keeps converting at a rate
 * from this week rather than from whenever somebody last pressed a button.
 *
 * Prints nothing on success unless asked, because a nightly job that writes to
 * stdout every night writes to somebody's mailbox every night.
 *
 * Usage:
 *   ./bin/rates.php              fetch today's
 *   ./bin/rates.php --verbose    and say what happened
 */
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

define('APP_ROOT', dirname(__DIR__));
define('BASE_PATH', '');

require APP_ROOT . '/src/helpers.php';
require APP_ROOT . '/src/proxy.php';
require APP_ROOT . '/src/db.php';
require APP_ROOT . '/src/version.php';
require APP_ROOT . '/src/log.php';
require APP_ROOT . '/src/metadata.php';

$verbose = in_array('--verbose', $argv, true) || in_array('-v', $argv, true);

$out = exchange_rates_refresh();

if ($out['error'] !== null) {
    // On stderr and non-zero, because the caller is a scheduler that will
    // otherwise report a night that failed as a night that worked.
    fwrite(STDERR, $out['error'] . "\n");
    exit(1);
}

if ($verbose) {
    printf("%d exchange rate%s recorded.\n", $out['written'], $out['written'] === 1 ? '' : 's');
}
