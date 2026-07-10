<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use PHPUnit\Framework\TestCase;

final class UpdateAssetsTest extends TestCase {

  public static function setUpBeforeClass(): void {
    parent::setUpBeforeClass();

    // Define the generator's helpers without running the recording.
    putenv('SCRIPT_RUN_SKIP=1');
    require_once dirname(__DIR__, 3) . '/assets/update-assets.php';
  }

  public function testAsciinemaPlayerComponentsAreIdentical(): void {
    $root = dirname(__DIR__, 4);

    $consumer = file_get_contents($root . '/docs/src/components/AsciinemaPlayer/AsciinemaPlayer.js');
    $scaffold = file_get_contents($root . '/.scaffold/docs/src/components/AsciinemaPlayer/AsciinemaPlayer.js');

    $this->assertNotFalse($consumer);
    $this->assertNotFalse($scaffold);
    $this->assertSame($consumer, $scaffold, 'AsciinemaPlayer.js must stay byte-identical across the two docs sites.');
  }

  public function testBuildInitExpectScript(): void {
    $script = buildInitExpectScript('/work/ws', 'MyNs', 'myproj', 'Jane');

    $this->assertStringContainsString('cd "/work/ws"', (string) $script);
    $this->assertStringContainsString('type_text "MyNs"', (string) $script);
    $this->assertStringContainsString('type_text "myproj"', (string) $script);
    $this->assertStringContainsString('type_text "Jane"', (string) $script);
    $this->assertStringContainsString('expect "Namespace (PascalCase):"', (string) $script);
    $this->assertStringContainsString('expect "Proceed with project init"', (string) $script);
  }

  public function testSanitizeCastCleansHeaderPathsAndSpawn(): void {
    $cast = implode("\n", [
      '{"version":2,"width":80,"height":24,"timestamp":123,"command":"expect /x/init.exp","env":{"SHELL":"/bin/sh"}}',
      '[0.1, "o", "spawn bash --norc\r\n"]',
      '[0.2, "o", "at /work/ws now\r\n"]',
      '[0.3, "o", "home /home/me end\r\n"]',
    ]) . "\n";

    $result = sanitizeCast($cast, '/work/ws', '/home/me');
    $lines = explode("\n", trim($result));

    $header = json_decode($lines[0], TRUE);
    if (!is_array($header)) {
      $this->fail('Sanitised cast header is not valid JSON.');
    }

    $this->assertSame('./init.sh', $header['command']);
    $this->assertArrayNotHasKey('timestamp', $header);
    $this->assertArrayNotHasKey('env', $header);
    $this->assertStringNotContainsString('spawn ', (string) $result);
    $this->assertStringNotContainsString('/work/ws', (string) $result);
    $this->assertStringContainsString('/home/user/project', (string) $result);
    $this->assertStringContainsString('/home/user end', (string) $result);
  }

  public function testAppendEndPauseAddsTrailingEvent(): void {
    $cast = implode("\n", [
      '{"version":2,"width":80,"height":24}',
      '[0.1, "o", "a"]',
      '[2.5, "o", "b"]',
    ]) . "\n";

    $result = appendEndPause($cast, 6);
    $lines = explode("\n", trim($result));

    $last = json_decode($lines[count($lines) - 1], TRUE);
    if (!is_array($last)) {
      $this->fail('Appended event is not valid JSON.');
    }

    $this->assertEqualsWithDelta(8.5, $last[0], PHP_FLOAT_EPSILON);
    $this->assertSame('o', $last[1]);
  }

}
