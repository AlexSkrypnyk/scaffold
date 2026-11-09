<?php

declare(strict_types=1);

namespace YourNamespace\App\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Roll dice command.
 *
 * Rolls one or more dice and prints each roll and the total.
 */
class RollDiceCommand extends Command {

  /**
   * Minimum number of sides on a die.
   */
  protected const int MIN_SIDES = 2;

  /**
   * Maximum number of dice in a single roll.
   */
  protected const int MAX_COUNT = 100;

  /**
   * {@inheritdoc}
   */
  protected function configure(): void {
    $this
      ->setName('roll-dice')
      ->setDescription('Rolls dice')
      ->addOption(name: 'sides', mode: InputOption::VALUE_REQUIRED, description: 'Number of sides on each die', default: '6')
      ->addOption(name: 'count', mode: InputOption::VALUE_REQUIRED, description: 'Number of dice to roll', default: '1');
  }

  /**
   * {@inheritdoc}
   */
  protected function execute(InputInterface $input, OutputInterface $output): int {
    try {
      $sides = $this->parseInteger($input->getOption('sides'), 'sides', self::MIN_SIDES, PHP_INT_MAX);
      $count = $this->parseInteger($input->getOption('count'), 'count', 1, self::MAX_COUNT);
    }
    catch (\InvalidArgumentException $exception) {
      $output->writeln(sprintf('<error>%s</error>', $exception->getMessage()));

      return Command::FAILURE;
    }

    $rolls = [];
    for ($i = 0; $i < $count; $i++) {
      $rolls[] = $this->rollDie($sides);
    }

    $output->writeln(sprintf('Rolled %dd%d: %s', $count, $sides, implode(', ', $rolls)));
    $output->writeln(sprintf('<info>Total: %d</info>', array_sum($rolls)));

    return Command::SUCCESS;
  }

  /**
   * Parse an option value as an integer within a range.
   *
   * @param mixed $value
   *   The raw option value.
   * @param string $name
   *   The option name, used in the error message.
   * @param int $min
   *   The minimum allowed value.
   * @param int $max
   *   The maximum allowed value.
   *
   * @return int
   *   The parsed value.
   *
   * @throws \InvalidArgumentException
   *   When the value is not an integer within the range.
   */
  protected function parseInteger(mixed $value, string $name, int $min, int $max): int {
    $parsed = is_string($value) ? filter_var($value, FILTER_VALIDATE_INT, ['options' => ['min_range' => $min, 'max_range' => $max]]) : FALSE;

    if ($parsed === FALSE) {
      $range = $max === PHP_INT_MAX ? sprintf('an integer of at least %d', $min) : sprintf('an integer from %d to %d', $min, $max);

      throw new \InvalidArgumentException(sprintf('The "--%s" option must be %s.', $name, $range));
    }

    return $parsed;
  }

  /**
   * Roll a single die.
   *
   * @param int $sides
   *   Number of sides on the die.
   *
   * @return int
   *   A value from 1 to $sides.
   */
  protected function rollDie(int $sides): int {
    return random_int(1, $sides);
  }

}
