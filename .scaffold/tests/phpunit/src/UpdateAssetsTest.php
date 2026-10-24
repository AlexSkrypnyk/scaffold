<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class UpdateAssetsTest extends TestCase {

  protected const HEADER = '{"version":2,"width":80,"height":24}';

  public static function setUpBeforeClass(): void {
    parent::setUpBeforeClass();

    self::requireGenerator();
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
    $this->assertStringContainsString('send_user "' . STEP_MARKER . '"', (string) $script);
    $this->assertStringContainsString('send -- "$text\r"', (string) $script);
    $this->assertStringContainsString('expect "$label*: " { answer $text }', (string) $script);
    $this->assertSame(1, substr_count($script, 'send_user'), 'Only the answer proc writes the step marker.');
    $this->assertStringNotContainsString('send -h', (string) $script);
    $this->assertStringNotContainsString('send_human', (string) $script);
    $this->assertStringNotContainsString('sleep', (string) $script);

    $session = implode("\n", [
      'expect "\$ " { answer "./init.sh" }',
      'reply "Namespace (PascalCase)" "MyNs"',
      'reply "Project" "myproj"',
      'reply "Author" "Jane"',
      'reply "Use PHP"',
      'reply "Use CLI command app"',
      'reply "CLI command name"',
      'reply "Build PHAR"',
      'reply "Use NodeJS"',
      'reply "Use Shell"',
      'reply "Shell command name"',
      'reply "Use Docker"',
      'reply "Use GitHub release drafter"',
      'reply "Use GitHub PR author auto-assign"',
      'reply "Use GitHub funding"',
      'reply "Use GitHub PR template"',
      'reply "Use Renovate"',
      'reply "Use docs"',
      'reply "Use GitHub Actions linting"',
      'reply "Use scheduled builds"',
      'reply "Use AI agents"',
      'reply "AI architecture docs"',
      'reply "Remove this script"',
      'reply "Proceed with project init"',
      'expect "\$ " { answer "exit" }',
      'expect eof',
    ]);
    $this->assertStringContainsString($session, (string) $script, 'Every prompt is answered through the answer proc, in order.');
  }

  public function testSanitizeCastCleansHeaderAndPaths(): void {
    $cast = implode("\n", [
      '{"version":2,"width":80,"height":24,"timestamp":123,"command":"expect /x/init.exp","env":{"SHELL":"/bin/sh"}}',
      '[0.1, "o", "spawn bash --norc\r\n"]',
      '',
      '[0.2, "o", "at /work/ws now\r\n"]',
      '[0.3, "o", "home /home/me end\r\n"]',
    ]) . "\n";

    $result = sanitizeCast($cast, '/work/ws', '/home/me');
    $lines = explode("\n", rtrim($result, "\n"));

    $header = json_decode($lines[0], TRUE);
    if (!is_array($header)) {
      $this->fail('Sanitized cast header is not valid JSON.');
    }

    $this->assertSame('./init.sh', $header['command']);
    $this->assertArrayNotHasKey('timestamp', $header);
    $this->assertArrayNotHasKey('env', $header);
    $this->assertCount(4, $lines, 'Empty lines are dropped and events are kept.');
    $this->assertStringNotContainsString('/work/ws', (string) $result);
    $this->assertStringContainsString('/home/user/project', (string) $result);
    $this->assertStringContainsString('/home/user end', (string) $result);
    $this->assertStringEndsWith("\"]\n", $result);
  }

  /**
   * @param list<string> $events
   * @param list<string> $expected
   */
  #[DataProvider('dataProviderCanonicalizeCast')]
  public function testCanonicalizeCast(array $events, array $expected): void {
    $cast = implode("\n", array_merge([self::HEADER], $events)) . "\n";

    $result = canonicalizeCast($cast);

    $this->assertSame(implode("\n", array_merge([self::HEADER], $expected)) . "\n", $result);
  }

  public static function dataProviderCanonicalizeCast(): \Iterator {
    $m = self::marker();

    yield 'no events' => [
      [],
      [],
    ];

    yield 'no marker yields 1 step at 0' => [
      ['[0.5, "o", "a"]', '[1.7, "o", "b"]'],
      ['[0,"o","ab"]'],
    ];

    yield 'steps are cut at markers and spaced by STEP_DELAY' => [
      ['[0.05, "o", "$ "]', '[0.06, "o", "' . $m . '"]', '[3.3, "o", "./init.sh\r\n"]', '[3.7, "o", "Name: "]', '[3.71, "o", "' . $m . 'Acme\r\n"]'],
      ['[0,"o","$ "]', '[1,"o","./init.sh\r\nName: "]', '[2,"o","Acme\r\n"]'],
    ];

    yield 'marker split across chunk boundary is joined first' => [
      ['[0.1, "o", "a\u001b]scaffold-"]', '[0.2, "o", "step\u0007b"]'],
      ['[0,"o","a"]', '[1,"o","b"]'],
    ];

    yield 'leading marker drops the empty step' => [
      ['[0.1, "o", "' . $m . 'a"]'],
      ['[0,"o","a"]'],
    ];

    yield 'adjacent markers drop the empty step' => [
      ['[0.1, "o", "a' . $m . $m . 'b"]'],
      ['[0,"o","a"]', '[1,"o","b"]'],
    ];

    yield 'trailing marker drops the empty step' => [
      ['[0.1, "o", "a' . $m . '"]'],
      ['[0,"o","a"]'],
    ];

    yield 'spawn echo is stripped from the stream head' => [
      ['[0.01, "o", "spawn bash "]', '[0.02, "o", "--norc\r\n$ "]'],
      ['[0,"o","$ "]'],
    ];

    yield 'non-output and malformed events are dropped' => [
      ['[0.1, "o", "a"]', '[0.2, "i", "typed"]', 'not json', '[0.3, "o"]', '[0.4, "o", 5]', '[0.5, "r", "80x24"]', '[0.6, "o", "b"]', '[0.7, "x", "0"]'],
      ['[0,"o","ab"]'],
    ];

    yield 'slashes and unicode are not escaped' => [
      ['[0.1, "o", "/home/user/project ✓"]'],
      ['[0,"o","/home/user/project ✓"]'],
    ];

    yield 'control characters stay escaped' => [
      ['[0.1, "o", "\u001b[?2004h$ "]'],
      ['[0,"o","\u001b[?2004h$ "]'],
    ];
  }

  public function testCanonicalizeCastIgnoresChunkingAndTiming(): void {
    $m = self::marker();

    $first = implode("\n", [
      self::HEADER,
      '[0.051, "o", "spawn bash --norc --noprofile\r\n"]',
      '[0.052, "o", "$ ' . $m . '"]',
      '[3.338, "o", "./init.sh\r\n"]',
      '[3.757, "o", "Namespace: "]',
      '[3.758, "o", "' . $m . '"]',
      '[7.322, "o", "MyNamespace\r\nSummary\r\n"]',
      '[7.334, "o", "line 1\r\nline 2\r\n' . $m . '"]',
      '[9.1, "x", "0"]',
    ]) . "\n";

    $second = implode("\n", [
      self::HEADER,
      '[0.1, "o", "spawn bash --norc --noprofile\r\n$ "]',
      '[0.2, "o", "' . $m . './init.sh\r\nNamespace: ' . $m . 'MyNa"]',
      '[1.5, "o", "mespace\r\nSummary\r\nline 1\r\n"]',
      '[1.500038, "o", "line 2\r\n"]',
      '[1.6, "o", "' . $m . '"]',
      '[2.0, "x", "0"]',
    ]) . "\n";

    $this->assertSame(canonicalizeCast($first), canonicalizeCast($second));
    $this->assertSame(implode("\n", [
      self::HEADER,
      '[0,"o","$ "]',
      '[1,"o","./init.sh\r\nNamespace: "]',
      '[2,"o","MyNamespace\r\nSummary\r\nline 1\r\nline 2\r\n"]',
    ]) . "\n", canonicalizeCast($first));
  }

  #[DataProvider('dataProviderStripSpawnEcho')]
  public function testStripSpawnEcho(string $stream, string $expected): void {
    $this->assertSame($expected, stripSpawnEcho($stream));
  }

  public static function dataProviderStripSpawnEcho(): \Iterator {
    yield 'empty' => ['', ''];
    yield 'no echo' => ["$ ls\r\n", "$ ls\r\n"];
    yield 'spawn later in the stream is kept' => ["$ echo\r\nspawn bash\r\n", "$ echo\r\nspawn bash\r\n"];
    yield 'echo without line break is kept' => ['spawn bash', 'spawn bash'];
    yield 'echo only' => ["spawn bash\r\n", ''];
    yield 'echo followed by output' => ["spawn bash --norc\r\n$ ", '$ '];
  }

  public function testAppendEndPauseAddsTrailingEvent(): void {
    $cast = implode("\n", [
      self::HEADER,
      '[0,"o","a"]',
      '[2,"o","b"]',
    ]) . "\n";

    $result = appendEndPause($cast, 6);
    $lines = explode("\n", trim($result));

    $last = json_decode($lines[count($lines) - 1], TRUE);
    if (!is_array($last)) {
      $this->fail('Appended event is not valid JSON.');
    }

    $this->assertEqualsWithDelta(8, $last[0], PHP_FLOAT_EPSILON);
    $this->assertSame('o', $last[1]);
  }

  /**
   * Define the generator's helpers without running the recording.
   */
  protected static function requireGenerator(): void {
    putenv('SCRIPT_RUN_SKIP=1');
    require_once dirname(__DIR__, 3) . '/assets/update-assets.php';
  }

  /**
   * The step marker as it appears inside a JSON-encoded cast event.
   *
   * Data providers run before setUpBeforeClass(), so the generator is loaded
   * here as well.
   */
  protected static function marker(): string {
    self::requireGenerator();

    return substr((string) json_encode(STEP_MARKER), 1, -1);
  }

}
